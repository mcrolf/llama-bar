import Foundation

struct InstalledModel: Identifiable, Hashable, Decodable {
    struct Details: Hashable, Decodable {
        let family: String?
        let parameterSize: String?
        let quantizationLevel: String?
    }

    let name: String
    let size: Int64
    let modifiedAt: Date
    let details: Details

    var id: String { name }
}

struct LoadedModel: Identifiable, Hashable, Decodable {
    let name: String
    let sizeVram: Int64
    let contextLength: Int?
    let expiresAt: Date

    var id: String { name }
}

struct PullProgress: Hashable, Decodable {
    let status: String
    let completed: Int64?
    let total: Int64?

    var fraction: Double? {
        guard let completed, let total, total > 0 else { return nil }
        return Double(completed) / Double(total)
    }
}

struct OllamaError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// The Ollama HTTP API (https://github.com/ollama/ollama/blob/main/docs/api.md).
struct OllamaClient {
    static let local = OllamaClient(baseURL: URL(string: "http://127.0.0.1:11434")!)

    let baseURL: URL

    func version() async throws -> String {
        try await get("api/version", as: VersionResponse.self).version
    }

    func installedModels() async throws -> [InstalledModel] {
        try await get("api/tags", as: ModelsResponse<InstalledModel>.self).models
            .sorted { $0.name < $1.name }
    }

    func loadedModels() async throws -> [LoadedModel] {
        try await get("api/ps", as: ModelsResponse<LoadedModel>.self).models
    }

    /// Loads `model` into memory for the server's configured keep-alive.
    func load(_ model: String) async throws {
        try await send("api/generate", method: "POST", body: GenerateRequest(model: model, keepAlive: nil))
    }

    func unload(_ model: String) async throws {
        try await send("api/generate", method: "POST", body: GenerateRequest(model: model, keepAlive: 0))
    }

    func delete(_ model: String) async throws {
        try await send("api/delete", method: "DELETE", body: ModelRequest(model: model))
    }

    /// Streams download progress; cancelling the consuming task cancels the download.
    func pull(_ model: String) -> AsyncThrowingStream<PullProgress, Error> {
        AsyncThrowingStream { continuation in
            let download = Task {
                do {
                    let request = try makeRequest("api/pull", method: "POST", body: ModelRequest(model: model))
                    let (lines, response) = try await URLSession.shared.bytes(for: request)
                    for try await line in lines.lines {
                        let event = try Self.decoder.decode(PullEvent.self, from: Data(line.utf8))
                        if let error = event.error { throw OllamaError(message: error) }
                        continuation.yield(PullProgress(status: event.status ?? "", completed: event.completed, total: event.total))
                    }
                    try Self.checkStatus(of: response, body: Data())
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in download.cancel() }
        }
    }

    // MARK: - Transport

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            guard let date = OllamaDate.parse(text) else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unrecognized date \(text)"))
            }
            return date
        }
        return decoder
    }()

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    private func get<Response: Decodable>(_ path: String, as type: Response.Type) async throws -> Response {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.timeoutInterval = 3
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.checkStatus(of: response, body: data)
        return try Self.decoder.decode(Response.self, from: data)
    }

    private func send(_ path: String, method: String, body: some Encodable) async throws {
        let (data, response) = try await URLSession.shared.data(for: makeRequest(path, method: method, body: body))
        try Self.checkStatus(of: response, body: data)
    }

    private func makeRequest(_ path: String, method: String, body: some Encodable) throws -> URLRequest {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        request.httpBody = try Self.encoder.encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300  // Loading a large model from disk can take minutes.
        return request
    }

    private static func checkStatus(of response: URLResponse, body: Data) throws {
        guard let status = (response as? HTTPURLResponse)?.statusCode, !(200..<300).contains(status) else { return }
        let message = (try? decoder.decode(ErrorResponse.self, from: body))?.error ?? "Ollama returned HTTP \(status)"
        throw OllamaError(message: message)
    }
}

private struct VersionResponse: Decodable { let version: String }
private struct ModelsResponse<Model: Decodable>: Decodable { let models: [Model] }
private struct ErrorResponse: Decodable { let error: String }
private struct ModelRequest: Encodable { let model: String }
private struct GenerateRequest: Encodable { let model: String; let keepAlive: Int? }

private struct PullEvent: Decodable {
    let status: String?
    let completed: Int64?
    let total: Int64?
    let error: String?
}

enum OllamaDate {
    private static let withFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private static let withoutFraction = ISO8601DateFormatter()
    private static let excessFractionDigits = try! NSRegularExpression(pattern: #"(\.\d{3})\d+"#)

    /// Ollama emits RFC 3339 with nanoseconds; ISO8601DateFormatter accepts at most milliseconds.
    static func parse(_ text: String) -> Date? {
        let range = NSRange(text.startIndex..., in: text)
        let trimmed = excessFractionDigits.stringByReplacingMatches(in: text, range: range, withTemplate: "$1")
        return withFraction.date(from: trimmed) ?? withoutFraction.date(from: trimmed)
    }
}

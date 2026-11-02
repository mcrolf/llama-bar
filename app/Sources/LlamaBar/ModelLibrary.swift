import Foundation

/// Models installed in Ollama, plus the pulls downloading new ones.
@Observable @MainActor
final class ModelLibrary {
    struct Pull: Identifiable {
        let model: String
        var progress: PullProgress?
        var failure: String?

        var id: String { model }
    }

    private(set) var installedModels: [InstalledModel] = []
    private(set) var pulls: [Pull] = []
    private(set) var lastError: String?

    private let client: OllamaClient
    private var downloads: [String: Task<Void, Never>] = [:]

    init(client: OllamaClient = .local) {
        self.client = client
    }

    var installedNames: [String] { installedModels.map(\.name) }

    func refresh() async {
        do {
            installedModels = try await client.installedModels()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func pull(_ model: String) {
        guard downloads[model] == nil else { return }
        pulls.removeAll { $0.model == model }
        pulls.append(Pull(model: model))
        downloads[model] = Task {
            await download(model)
            downloads[model] = nil
        }
    }

    func cancelPull(_ model: String) {
        downloads[model]?.cancel()
    }

    func dismissPull(_ model: String) {
        pulls.removeAll { $0.model == model }
    }

    func delete(_ model: String) async {
        do {
            try await client.delete(model)
            await refresh()
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func download(_ model: String) async {
        do {
            for try await progress in client.pull(model) {
                updatePull(model) { $0.progress = progress }
            }
            dismissPull(model)
            await refresh()
        } catch {
            if Task.isCancelled {
                dismissPull(model)
            } else {
                updatePull(model) { $0.failure = error.localizedDescription }
            }
        }
    }

    private func updatePull(_ model: String, _ change: (inout Pull) -> Void) {
        guard let index = pulls.firstIndex(where: { $0.model == model }) else { return }
        change(&pulls[index])
    }
}

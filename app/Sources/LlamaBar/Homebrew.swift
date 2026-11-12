import Foundation

/// The Homebrew CLI, which bin/setup uses to install Ollama and OpenCode.
enum Homebrew {
    struct Missing: LocalizedError {
        var errorDescription: String? { "Homebrew is required: https://brew.sh" }
    }

    /// A formula's versions from `brew info --json=v2`.
    struct Formula: Hashable, Decodable {
        let name: String
        /// nil when Homebrew has not installed the formula.
        let installedVersion: String?
        let latestVersion: String
        let isOutdated: Bool

        private enum CodingKeys: String, CodingKey {
            case name, versions, installed, outdated
            case linkedKeg = "linked_keg"
        }

        private struct Versions: Decodable { let stable: String }
        private struct Installation: Decodable { let version: String }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            latestVersion = try container.decode(Versions.self, forKey: .versions).stable
            // The linked keg is the version on PATH when several are installed.
            let installations = try container.decode([Installation].self, forKey: .installed)
            installedVersion = try container.decodeIfPresent(String.self, forKey: .linkedKeg) ?? installations.last?.version
            isOutdated = try container.decode(Bool.self, forKey: .outdated)
        }
    }

    private struct InfoResponse: Decodable {
        let formulae: [Formula]
    }

    /// Fetches the latest formula definitions, so `info` reports current latest versions.
    static func update() async throws {
        _ = try await run(["update", "--quiet"])
    }

    static func info(_ formulae: [String]) async throws -> [Formula] {
        try decodeInfo(try await run(["info", "--json=v2"] + formulae))
    }

    static func upgrade(_ formula: String) async throws {
        _ = try await run(["upgrade", formula])
    }

    static func decodeInfo(_ json: Data) throws -> [Formula] {
        try JSONDecoder().decode(InfoResponse.self, from: json).formulae
    }

    private static func run(_ arguments: [String]) async throws -> Data {
        guard let executable else { throw Missing() }
        return try await Shell.run(executable, arguments)
    }

    private static var executable: URL? {
        ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
            .first(where: FileManager.default.isExecutableFile(atPath:))
            .map { URL(fileURLWithPath: $0) }
    }
}

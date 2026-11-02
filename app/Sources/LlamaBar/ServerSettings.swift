import Foundation

/// The `.env` values that bin/setup, bin/configure-server and bin/opencode-ollama read.
struct ServerSettings: Equatable {
    static let defaultModelKey = "OLLAMA_MODEL"
    static let contextLengthKey = "OLLAMA_CONTEXT_LENGTH"
    static let keepAliveKey = "OLLAMA_KEEP_ALIVE"
    static let minimumContextLength = 2048

    /// The model OpenCode (and so T3 Code) starts new sessions with.
    var defaultModel: String
    var contextLength: Int
    var keepAlive: String

    init(defaultModel: String, contextLength: Int, keepAlive: String) {
        self.defaultModel = defaultModel
        self.contextLength = contextLength
        self.keepAlive = keepAlive
    }

    /// Mirrors the fallbacks in bin/setup and bin/configure-server.
    init(env: EnvFile) {
        defaultModel = env.value(for: Self.defaultModelKey) ?? "devstral-small-2:24b"
        contextLength = env.value(for: Self.contextLengthKey).flatMap(Int.init) ?? 32768
        keepAlive = env.value(for: Self.keepAliveKey) ?? "30m"
    }

    func applied(to env: EnvFile) -> EnvFile {
        var updated = env
        updated.set(Self.defaultModelKey, to: defaultModel)
        updated.set(Self.contextLengthKey, to: String(contextLength))
        updated.set(Self.keepAliveKey, to: keepAlive)
        return updated
    }

    /// The LaunchAgent bakes in context length and keep-alive; the default model is read per launch.
    func requiresServerRestart(comparedTo previous: ServerSettings) -> Bool {
        contextLength != previous.contextLength || keepAlive != previous.keepAlive
    }

    /// Values are sourced by bash and substituted by sed, so only safe shapes are accepted.
    var validationError: String? {
        if !ModelName.isValid(defaultModel) {
            return "Choose an installed model as the default."
        }
        if contextLength < Self.minimumContextLength {
            return "Context length must be at least \(Self.minimumContextLength) tokens."
        }
        if keepAlive.range(of: #"^-?\d+(\.\d+)?(ms|s|m|h)?$"#, options: .regularExpression) == nil {
            return "Keep-alive must be a duration such as 30m or 1h, 0 to unload immediately, or -1 to keep models loaded."
        }
        return nil
    }
}

enum ModelName {
    /// Ollama names look like `name:tag` or `namespace/name:tag`.
    static func isValid(_ name: String) -> Bool {
        name.range(of: #"^[A-Za-z0-9][A-Za-z0-9._:/-]*$"#, options: .regularExpression) != nil
    }
}

struct ServerSettingsStore {
    let project: Project

    func load() -> ServerSettings {
        ServerSettings(env: readEnv())
    }

    func save(_ settings: ServerSettings) throws {
        try settings.applied(to: readEnv()).text.write(to: project.envFile, atomically: true, encoding: .utf8)
    }

    /// A first save starts from .env.example so its comments carry over.
    private func readEnv() -> EnvFile {
        let text = (try? String(contentsOf: project.envFile, encoding: .utf8))
            ?? (try? String(contentsOf: project.envExampleFile, encoding: .utf8))
            ?? ""
        return EnvFile(text: text)
    }
}

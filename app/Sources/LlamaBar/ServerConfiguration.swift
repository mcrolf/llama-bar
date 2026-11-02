import Foundation

struct InvalidSettings: LocalizedError {
    let errorDescription: String?
}

/// The saved `.env` settings, applied to the Ollama LaunchAgent when they change.
@Observable @MainActor
final class ServerConfiguration {
    private(set) var settings: ServerSettings
    private(set) var isRestartingServer = false

    private let store: ServerSettingsStore

    init(store: ServerSettingsStore = ServerSettingsStore(project: .current)) {
        self.store = store
        settings = store.load()
    }

    func setDefaultModel(_ model: String) async throws {
        var updated = settings
        updated.defaultModel = model
        try await save(updated)
    }

    /// Writes `.env`, then restarts the server through bin/configure-server when its settings changed.
    func save(_ updated: ServerSettings) async throws {
        if let problem = updated.validationError { throw InvalidSettings(errorDescription: problem) }
        let needsRestart = updated.requiresServerRestart(comparedTo: settings)
        try store.save(updated)
        settings = updated
        guard needsRestart else { return }

        isRestartingServer = true
        defer { isRestartingServer = false }
        _ = try await Shell.run(store.project.configureServer)
    }
}

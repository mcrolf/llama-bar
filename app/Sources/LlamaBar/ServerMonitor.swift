import Foundation

/// Polls the local Ollama server for reachability and the models loaded in memory.
@Observable @MainActor
final class ServerMonitor {
    private static let pollInterval = Duration.seconds(5)

    private(set) var version: String?
    private(set) var loadedModels: [LoadedModel] = []
    private(set) var lastError: String?
    private(set) var isSetUp = ServerMonitor.hasRunSetup()

    private let client: OllamaClient
    private var polling: Task<Void, Never>?

    init(client: OllamaClient = .local) {
        self.client = client
    }

    var isReachable: Bool { version != nil }
    var loadedMemory: Int64 { loadedModels.reduce(0) { $0 + $1.sizeVram } }

    func isLoaded(_ model: String) -> Bool {
        loadedModels.contains { $0.name == model }
    }

    /// Starts the LaunchAgent if Ollama is down, then keeps the status current.
    func start() {
        guard polling == nil else { return }
        polling = Task { [weak self] in
            await self?.startServerIfStopped()
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.pollInterval)
                await self?.refresh()
            }
        }
    }

    func refresh() async {
        isSetUp = Self.hasRunSetup()
        do {
            version = try await client.version()
            loadedModels = try await client.loadedModels()
            lastError = nil
        } catch {
            version = nil
            loadedModels = []
            lastError = error.localizedDescription
        }
    }

    func restartServer() async {
        await perform { try await Shell.launchctl("kickstart", "-k", Self.serviceTarget) }
    }

    func load(_ model: String) async {
        await perform { try await self.client.load(model) }
    }

    func unload(_ model: String) async {
        await perform { try await self.client.unload(model) }
    }

    private func startServerIfStopped() async {
        await refresh()
        guard !isReachable else { return }
        await perform { try await Shell.launchctl("kickstart", Self.serviceTarget) }
    }

    private func perform(_ action: () async throws -> Void) async {
        do {
            try await action()
            await refresh()
        } catch {
            lastError = error.localizedDescription
        }
    }

    private static func hasRunSetup() -> Bool {
        FileManager.default.fileExists(atPath: Project.serverLaunchAgent.path)
    }

    private static var serviceTarget: String { "gui/\(getuid())/\(Project.serverLabel)" }
}

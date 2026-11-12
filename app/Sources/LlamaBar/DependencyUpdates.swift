import Foundation

/// The tools bin/setup installs with Homebrew.
enum Dependency: String, CaseIterable, Identifiable {
    case ollama
    case opencode

    var id: Self { self }
    var formula: String { rawValue }

    var title: String {
        switch self {
        case .ollama: "Ollama"
        case .opencode: "OpenCode"
        }
    }
}

/// Installed and latest versions of the dependencies, and their Homebrew upgrades.
@Observable @MainActor
final class DependencyUpdates {
    private(set) var formulae: [Dependency: Homebrew.Formula] = [:]
    private(set) var isChecking = false
    private(set) var upgrading: Dependency?
    private(set) var failure: String?

    private let server: ServerMonitor

    init(server: ServerMonitor) {
        self.server = server
    }

    /// Homebrew holds a lock while it works, so one command runs at a time.
    var isBusy: Bool { isChecking || upgrading != nil }

    func check() async {
        guard !isBusy else { return }
        isChecking = true
        defer { isChecking = false }
        do {
            try await Homebrew.update()
            failure = nil
        } catch {
            failure = "Could not fetch the latest versions: \(error.localizedDescription)"
        }
        // Installed versions are still worth showing when the fetch fails, such as offline.
        await readVersions()
    }

    func upgrade(_ dependency: Dependency) async {
        guard !isBusy else { return }
        upgrading = dependency
        defer { upgrading = nil }
        do {
            try await Homebrew.upgrade(dependency.formula)
            failure = nil
            // The running server still uses the old binary, and Homebrew's cleanup removes
            // the libraries it loads models with.
            if dependency == .ollama { await server.restartServer() }
        } catch {
            failure = error.localizedDescription
        }
        await readVersions()
    }

    private func readVersions() async {
        do {
            let formulae = try await Homebrew.info(Dependency.allCases.map(\.formula))
            self.formulae = Dictionary(uniqueKeysWithValues: formulae.compactMap { formula in
                Dependency(rawValue: formula.name).map { ($0, formula) }
            })
        } catch {
            failure = error.localizedDescription
        }
    }
}

import Foundation

/// The scripts and `.env` this app drives: the checkout a source build came from (recorded
/// in Info.plist by bin/build-app), or the bundled runtime of a release build.
/// LLAMA_BAR_ROOT overrides both when running with `swift run`.
struct Project {
    static let current = Project(root: locateRoot())
    static let serverLabel = "com.mcrolf.llama-bar.ollama"
    static let serverLog = URL.libraryDirectory.appending(path: "Logs/llama-bar/ollama.log")
    /// Written by bin/configure-server, so its presence means setup has run.
    static let serverLaunchAgent = URL.libraryDirectory.appending(path: "LaunchAgents/\(serverLabel).plist")

    let root: URL

    var envFile: URL { root.appending(path: ".env") }
    var envExampleFile: URL { root.appending(path: ".env.example") }
    var launcher: URL { root.appending(path: "bin/opencode-ollama") }
    var configureServer: URL { root.appending(path: "bin/configure-server") }
    var setup: URL { root.appending(path: "bin/setup") }

    private static func locateRoot() -> URL {
        let override = ProcessInfo.processInfo.environment["LLAMA_BAR_ROOT"]
        let checkout = Bundle.main.object(forInfoDictionaryKey: "LlamaBarRoot") as? String
        if let path = override ?? checkout { return URL(fileURLWithPath: path, isDirectory: true) }
        return BundledRuntime.isBundled
            ? BundledRuntime.installRoot
            : URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    }
}

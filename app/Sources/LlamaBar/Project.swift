import Foundation

/// The Llama Bar checkout this app drives. bin/build-app records its path in
/// Info.plist; LLAMA_BAR_ROOT overrides it when running with `swift run`.
struct Project {
    static let current = Project(root: locateRoot())
    static let serverLabel = "com.mcrolf.llama-bar.ollama"
    static let serverLog = FileManager.default.homeDirectoryForCurrentUser
        .appending(path: "Library/Logs/llama-bar/ollama.log")

    let root: URL

    var envFile: URL { root.appending(path: ".env") }
    var envExampleFile: URL { root.appending(path: ".env.example") }
    var launcher: URL { root.appending(path: "bin/opencode-ollama") }
    var configureServer: URL { root.appending(path: "bin/configure-server") }

    private static func locateRoot() -> URL {
        let override = ProcessInfo.processInfo.environment["LLAMA_BAR_ROOT"]
        let bundled = Bundle.main.object(forInfoDictionaryKey: "LlamaBarRoot") as? String
        let path = override ?? bundled ?? FileManager.default.currentDirectoryPath
        return URL(fileURLWithPath: path, isDirectory: true)
    }
}

import Darwin
import Foundation

/// Release builds carry the repo's scripts in Contents/Resources/runtime and run them from
/// Application Support: the scripts write .env and the OpenCode config beside themselves,
/// and writing inside a signed bundle would break its signature.
enum BundledRuntime {
    static let installRoot = URL.applicationSupportDirectory.appending(path: "Llama Bar", directoryHint: .isDirectory)

    private static var source: URL? {
        Bundle.main.resourceURL.map { $0.appending(path: "runtime", directoryHint: .isDirectory) }
            .flatMap { FileManager.default.fileExists(atPath: $0.path) ? $0 : nil }
    }

    static var isBundled: Bool { source != nil }

    /// Copies this app version's scripts over the installed ones. Files the scripts create
    /// (.env, opencode.generated.json) are not in the bundle, so they survive updates.
    static func install() throws {
        guard let source else { return }
        try install(from: source, into: installRoot)
    }

    static func install(from source: URL, into root: URL) throws {
        let relativePaths = FileManager.default.enumerator(atPath: source.path)
        while let relativePath = relativePaths?.nextObject() as? String {
            guard relativePaths?.fileAttributes?[.type] as? FileAttributeType == .typeRegular else { continue }
            try replace(root.appending(path: relativePath), with: source.appending(path: relativePath))
        }
    }

    private static func replace(_ destination: URL, with file: URL) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: destination.path) { try fileManager.removeItem(at: destination) }
        try fileManager.copyItem(at: file, to: destination)
        // A downloaded app's files carry the quarantine flag, and Gatekeeper would refuse to
        // open the copied, unsigned scripts in Terminal.
        removexattr(destination.path, "com.apple.quarantine", 0)
    }
}

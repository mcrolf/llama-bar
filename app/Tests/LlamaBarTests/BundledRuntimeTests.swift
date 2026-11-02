import XCTest
@testable import LlamaBar

final class BundledRuntimeTests: XCTestCase {
    private var bundle: URL!
    private var installRoot: URL!

    override func setUpWithError() throws {
        let scratch = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        bundle = scratch.appending(path: "runtime")
        installRoot = scratch.appending(path: "Application Support/Llama Bar")
        try write("#!/bin/bash\necho v2\n", to: bundle.appending(path: "bin/setup"))
        try write("OLLAMA_MODEL=devstral-small-2:24b\n", to: bundle.appending(path: ".env.example"))
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: bundle.deletingLastPathComponent())
    }

    func testFirstInstallCopiesEveryFile() throws {
        try BundledRuntime.install(from: bundle, into: installRoot)
        XCTAssertEqual(try read("bin/setup"), "#!/bin/bash\necho v2\n")
        XCTAssertEqual(try read(".env.example"), "OLLAMA_MODEL=devstral-small-2:24b\n")
    }

    func testUpdateReplacesScriptsAndKeepsUserSettings() throws {
        try write("#!/bin/bash\necho v1\n", to: installRoot.appending(path: "bin/setup"))
        try write("OLLAMA_MODEL=gpt-oss:20b\n", to: installRoot.appending(path: ".env"))

        try BundledRuntime.install(from: bundle, into: installRoot)

        XCTAssertEqual(try read("bin/setup"), "#!/bin/bash\necho v2\n")
        XCTAssertEqual(try read(".env"), "OLLAMA_MODEL=gpt-oss:20b\n")
    }

    func testKeepsScriptsExecutable() throws {
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: bundle.appending(path: "bin/setup").path)
        try BundledRuntime.install(from: bundle, into: installRoot)
        XCTAssertTrue(FileManager.default.isExecutableFile(atPath: installRoot.appending(path: "bin/setup").path))
    }

    private func write(_ text: String, to file: URL) throws {
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: file, atomically: true, encoding: .utf8)
    }

    private func read(_ relativePath: String) throws -> String {
        try String(contentsOf: installRoot.appending(path: relativePath), encoding: .utf8)
    }
}

import XCTest
@testable import LlamaBar

final class EnvFileTests: XCTestCase {
    private let example = """
    # Copy to .env to override defaults, then rerun bin/setup.
    OLLAMA_MODEL=devstral-small-2:24b
    OLLAMA_CONTEXT_LENGTH=32768

    """

    func testReadsAssignmentsAndIgnoresComments() {
        let env = EnvFile(text: example)
        XCTAssertEqual(env.value(for: "OLLAMA_MODEL"), "devstral-small-2:24b")
        XCTAssertNil(env.value(for: "OLLAMA_KEEP_ALIVE"))
    }

    func testLastAssignmentWinsLikeBash() {
        let env = EnvFile(text: "OLLAMA_MODEL=a\nexport OLLAMA_MODEL=\"b\"")
        XCTAssertEqual(env.value(for: "OLLAMA_MODEL"), "b")
    }

    func testSetReplacesExistingAssignmentInPlace() {
        var env = EnvFile(text: example)
        env.set("OLLAMA_MODEL", to: "gpt-oss:20b")
        XCTAssertEqual(env.text, example.replacingOccurrences(of: "devstral-small-2:24b", with: "gpt-oss:20b"))
    }

    func testSetAppendsMissingKeyBeforeTrailingNewline() {
        var env = EnvFile(text: example)
        env.set("OLLAMA_KEEP_ALIVE", to: "1h")
        XCTAssertTrue(env.text.hasSuffix("OLLAMA_CONTEXT_LENGTH=32768\nOLLAMA_KEEP_ALIVE=1h\n"))
    }

    func testSetOnEmptyFile() {
        var env = EnvFile(text: "")
        env.set("OLLAMA_MODEL", to: "qwen3:8b")
        XCTAssertEqual(env.text, "OLLAMA_MODEL=qwen3:8b\n")
    }
}

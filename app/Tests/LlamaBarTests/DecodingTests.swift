import XCTest
@testable import LlamaBar

/// Pins the shapes of Ollama's API, `opencode stats --json`, and `brew info --json=v2` that the app relies on.
final class DecodingTests: XCTestCase {
    func testParsesOllamaNanosecondTimestamps() throws {
        let date = try XCTUnwrap(OllamaDate.parse("2026-11-01T20:43:20.085530254-05:00"))
        XCTAssertEqual(date.timeIntervalSince1970, 1_793_583_800.085, accuracy: 0.001)
        XCTAssertNotNil(OllamaDate.parse("2026-11-01T20:43:20Z"))
        XCTAssertNil(OllamaDate.parse("yesterday"))
    }

    func testPullProgressFraction() {
        XCTAssertEqual(PullProgress(status: "pulling", completed: 25, total: 100).fraction, 0.25)
        XCTAssertNil(PullProgress(status: "verifying sha256 digest", completed: nil, total: nil).fraction)
        XCTAssertNil(PullProgress(status: "pulling", completed: 0, total: 0).fraction)
    }

    func testDecodesUsageStats() throws {
        let json = """
        {"sessions": 2, "prompts": 3, "steps": 57,
         "tokens": {"input": 130350, "output": 6189, "reasoning": 0, "cache": {"read": 1011233, "write": 0}},
         "models": [{"model": {"id": "gpt-oss:20b", "providerID": "ollama", "variant": "default"}, "steps": 54,
                     "tokens": {"input": 122429, "output": 6073, "reasoning": 0, "cache": {"read": 995480, "write": 0}}}]}
        """
        let stats = try JSONDecoder().decode(UsageStats.self, from: Data(json.utf8))
        XCTAssertEqual(stats.tokens.cache.read, 1_011_233)
        XCTAssertEqual(stats.models?.first?.id, "ollama/gpt-oss:20b")
    }

    func testDecodesHomebrewFormulaVersions() throws {
        let json = """
        {"formulae": [
          {"name": "ollama", "versions": {"stable": "0.40.16", "head": "HEAD", "bottle": true},
           "linked_keg": "0.40.13", "outdated": true, "revision": 0,
           "installed": [{"version": "0.40.12"}, {"version": "0.40.13"}]},
          {"name": "opencode", "versions": {"stable": "2.2.7", "head": null, "bottle": true},
           "linked_keg": null, "outdated": false, "revision": 0, "installed": []}
        ], "casks": []}
        """
        let formulae = try Homebrew.decodeInfo(Data(json.utf8))
        XCTAssertEqual(formulae.map(\.name), ["ollama", "opencode"])
        XCTAssertEqual(formulae[0].installedVersion, "0.40.13")
        XCTAssertEqual(formulae[0].latestVersion, "0.40.16")
        XCTAssertTrue(formulae[0].isOutdated)
        XCTAssertNil(formulae[1].installedVersion)
        XCTAssertFalse(formulae[1].isOutdated)
    }

    func testCompactCounts() {
        XCTAssertEqual(130_350.compactCount, "130.4K")
        XCTAssertEqual(42.compactCount, "42")
    }
}

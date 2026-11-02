import XCTest
@testable import LlamaBar

final class ServerSettingsTests: XCTestCase {
    private let saved = ServerSettings(defaultModel: "gpt-oss:20b", contextLength: 32768, keepAlive: "30m")

    func testFallsBackToSetupDefaultsWhenEnvIsEmpty() {
        XCTAssertEqual(
            ServerSettings(env: EnvFile(text: "")),
            ServerSettings(defaultModel: "devstral-small-2:24b", contextLength: 32768, keepAlive: "30m")
        )
    }

    func testRoundTripsThroughEnvFile() {
        XCTAssertEqual(ServerSettings(env: saved.applied(to: EnvFile(text: "# comment\n"))), saved)
    }

    func testChangingOnlyTheDefaultModelSkipsServerRestart() {
        var updated = saved
        updated.defaultModel = "devstral-small-2:24b"
        XCTAssertFalse(updated.requiresServerRestart(comparedTo: saved))
    }

    func testChangingServerValuesRequiresRestart() {
        var updated = saved
        updated.keepAlive = "1h"
        XCTAssertTrue(updated.requiresServerRestart(comparedTo: saved))
    }

    func testAcceptsOllamaDurations() {
        for keepAlive in ["30m", "1h", "90s", "0", "-1", "1.5h"] {
            var settings = saved
            settings.keepAlive = keepAlive
            XCTAssertNil(settings.validationError, keepAlive)
        }
    }

    func testRejectsValuesUnsafeForBashOrSed() {
        var badKeepAlive = saved
        badKeepAlive.keepAlive = "30m; rm -rf ~"
        XCTAssertNotNil(badKeepAlive.validationError)

        var badModel = saved
        badModel.defaultModel = "$(whoami)"
        XCTAssertNotNil(badModel.validationError)
    }

    func testRejectsContextBelowMinimum() {
        var settings = saved
        settings.contextLength = ServerSettings.minimumContextLength - 1
        XCTAssertNotNil(settings.validationError)
    }

    func testModelNames() {
        XCTAssertTrue(ModelName.isValid("hf.co/unsloth/Qwen3-8B-GGUF:Q4_K_M"))
        XCTAssertFalse(ModelName.isValid(""))
        XCTAssertFalse(ModelName.isValid("-rm"))
        XCTAssertFalse(ModelName.isValid("qwen 3"))
    }
}

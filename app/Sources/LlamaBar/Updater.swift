import AppKit
import Sparkle

/// Installs new GitHub releases with Sparkle. Only release builds update themselves: bin/build-app
/// gives them an update feed, while a source build runs from its checkout and updates with git.
@MainActor
final class Updater: NSObject {
    private var controller: SPUStandardUpdaterController?

    override init() {
        super.init()
        guard Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") != nil else { return }
        controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: self)
    }

    var isEnabled: Bool { controller != nil }

    func checkForUpdates() {
        controller?.checkForUpdates(nil)
    }
}

extension Updater: @preconcurrency SPUStandardUserDriverDelegate {
    /// A menu bar app is never frontmost, so Sparkle would open a scheduled update's window
    /// behind other apps; this delegate brings it forward instead.
    var supportsGentleScheduledUpdateReminders: Bool { true }

    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
        guard handleShowingUpdate else { return }
        NSApp.activate(ignoringOtherApps: true)
    }
}

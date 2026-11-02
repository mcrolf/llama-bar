import AppKit

/// Hand-offs to other macOS apps.
@MainActor
enum Desktop {
    /// Runs the OpenCode TUI (bin/opencode-ollama).
    static func openOpenCode(project: Project = .current) {
        runInTerminal(project.launcher)
    }

    /// Runs bin/setup, which installs Ollama and OpenCode and downloads the default model.
    static func runSetup(project: Project = .current) {
        runInTerminal(project.setup)
    }

    /// Runs `script` in iTerm when installed, otherwise Terminal, so its output and prompts are visible.
    private static func runInTerminal(_ script: URL) {
        let workspace = NSWorkspace.shared
        let terminal = ["com.googlecode.iterm2", "com.apple.Terminal"]
            .lazy.compactMap(workspace.urlForApplication(withBundleIdentifier:)).first
        guard let terminal else { return }
        workspace.open([script], withApplicationAt: terminal, configuration: NSWorkspace.OpenConfiguration())
    }

    static func showServerLog() {
        NSWorkspace.shared.open(Project.serverLog)
    }

    /// A menu bar app cannot take focus, so its windows open behind other apps. While one is
    /// open the app becomes a regular app (Dock icon, Cmd-Tab) and is activated.
    static func showAsRegularApp(windowID: String) {
        NSApp.setActivationPolicy(.regular)
        bringToFront(windowID: windowID)
    }

    static func returnToMenuBar() {
        NSApp.setActivationPolicy(.accessory)
    }

    /// Activation waits a run-loop pass: activating in the same pass as an activation-policy
    /// change hands focus to another app. Cooperative NSApp.activate() is ignored from the panel.
    static func bringToFront(windowID: String) {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first { $0.identifier?.rawValue.hasPrefix(windowID) == true }?.makeKeyAndOrderFront(nil)
        }
    }
}

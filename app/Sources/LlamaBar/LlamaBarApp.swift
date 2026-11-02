import SwiftUI

@main
struct LlamaBarApp: App {
    private let server: ServerMonitor
    private let usage: UsageMonitor
    private let library: ModelLibrary
    private let configuration: ServerConfiguration
    private let updater: Updater

    init() {
        // Before anything reads .env or runs a script from the runtime.
        do {
            try BundledRuntime.install()
        } catch {
            NSLog("Llama Bar could not install its bundled scripts: \(error)")
        }
        server = ServerMonitor()
        usage = UsageMonitor()
        library = ModelLibrary()
        configuration = ServerConfiguration()
        updater = Updater()
        server.start()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuPanel(server: server, usage: usage, updater: updater)
        } label: {
            MenuBarLabel(server: server)
        }
        .menuBarExtraStyle(.window)

        Window("Configuration Manager", id: ConfigurationWindow.id) {
            ConfigurationWindow(server: server, library: library, configuration: configuration)
        }
        .defaultLaunchBehavior(.suppressed)
        .windowResizability(.contentMinSize)
    }
}

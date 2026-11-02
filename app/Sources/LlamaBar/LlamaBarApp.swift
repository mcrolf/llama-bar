import SwiftUI

@main
struct LlamaBarApp: App {
    private let server: ServerMonitor
    private let usage: UsageMonitor
    private let library: ModelLibrary
    private let configuration: ServerConfiguration

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
        server.start()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuPanel(server: server, usage: usage)
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

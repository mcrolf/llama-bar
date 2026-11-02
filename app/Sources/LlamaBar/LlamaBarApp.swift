import SwiftUI

@main
struct LlamaBarApp: App {
    private let server = ServerMonitor()
    private let usage = UsageMonitor()
    private let library = ModelLibrary()
    private let configuration = ServerConfiguration()

    init() {
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

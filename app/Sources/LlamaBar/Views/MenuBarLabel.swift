import SwiftUI

/// The menu bar icon: hollow when Ollama is down, filled with memory use while a model is loaded.
struct MenuBarLabel: View {
    let server: ServerMonitor

    var body: some View {
        if !server.isReachable {
            Image(systemName: "cube.transparent")
        } else if server.loadedModels.isEmpty {
            Image(systemName: "cube")
        } else {
            Label(server.loadedMemory.byteCount, systemImage: "cube.fill")
                .labelStyle(.titleAndIcon)
        }
    }
}

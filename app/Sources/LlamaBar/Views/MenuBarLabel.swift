import SwiftUI

/// The menu bar llama: dimmed when Ollama is down, with memory use while a model is loaded.
struct MenuBarLabel: View {
    let server: ServerMonitor

    var body: some View {
        if server.loadedModels.isEmpty {
            glyph.opacity(server.isReachable ? 1 : 0.4)
        } else {
            Label { Text(server.loadedMemory.byteCount) } icon: { glyph }
                .labelStyle(.titleAndIcon)
        }
    }

    private var glyph: Image {
        Image(nsImage: LlamaGlyph.image)
    }
}

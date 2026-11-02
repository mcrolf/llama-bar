import SwiftUI

struct InstalledModelsView: View {
    let server: ServerMonitor
    let library: ModelLibrary
    let configuration: ServerConfiguration

    @State private var selection: InstalledModel.ID?
    @State private var modelPendingDeletion: String?
    @State private var failure: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Table(library.installedModels, selection: $selection) {
                TableColumn("Model") { model in
                    HStack(spacing: 6) {
                        Text(model.name)
                        if model.name == configuration.settings.defaultModel { Badge("Default", tint: .accentColor) }
                        if server.isLoaded(model.name) { Badge("Loaded", tint: .green) }
                    }
                }
                .width(min: 220)
                TableColumn("Parameters") { Text($0.details.parameterSize ?? "-") }
                TableColumn("Quantization") { Text($0.details.quantizationLevel ?? "-") }
                TableColumn("Size") { Text($0.size.byteCount).monospacedDigit() }
                TableColumn("Modified") { Text($0.modifiedAt, format: .relative(presentation: .named)) }
            }
            .contextMenu(forSelectionType: InstalledModel.ID.self) { names in
                if let name = names.first { actions(for: name) }
            }

            HStack {
                if let selection { actions(for: selection) }
                Spacer()
                Button("Refresh") { Task { await library.refresh() } }
            }

            if let message = failure ?? library.lastError ?? server.lastError {
                Text(message).foregroundStyle(.red).font(.callout)
            }
        }
        .padding()
        .confirmationDialog(
            "Delete \(modelPendingDeletion ?? "")?",
            isPresented: Binding(get: { modelPendingDeletion != nil }, set: { if !$0 { modelPendingDeletion = nil } })
        ) {
            Button("Delete", role: .destructive) {
                guard let name = modelPendingDeletion else { return }
                Task { await library.delete(name) }
            }
        } message: {
            Text("The model files are removed from disk. You can pull it again later.")
        }
    }

    @ViewBuilder
    private func actions(for name: String) -> some View {
        Button("Set as Default") { setDefaultModel(name) }
            .disabled(name == configuration.settings.defaultModel)
        if server.isLoaded(name) {
            Button("Unload") { Task { await server.unload(name) } }
        } else {
            Button("Load") { Task { await server.load(name) } }
        }
        Button("Delete…", role: .destructive) { modelPendingDeletion = name }
    }

    private func setDefaultModel(_ name: String) {
        Task {
            do {
                try await configuration.setDefaultModel(name)
                failure = nil
            } catch {
                failure = error.localizedDescription
            }
        }
    }
}

private struct Badge: View {
    let title: String
    let tint: Color

    init(_ title: String, tint: Color) {
        self.title = title
        self.tint = tint
    }

    var body: some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .foregroundStyle(tint)
            .background(tint.opacity(0.15), in: Capsule())
    }
}

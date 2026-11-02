import SwiftUI

struct DefaultModelView: View {
    let library: ModelLibrary
    let configuration: ServerConfiguration

    @State private var draft = ServerSettings(env: EnvFile(text: ""))
    @State private var failure: String?
    @State private var isSaving = false

    var body: some View {
        Form {
            Section {
                Picker("Default model", selection: $draft.defaultModel) {
                    ForEach(modelChoices, id: \.self) { name in
                        Text(library.installedNames.contains(name) ? name : "\(name) (not installed)").tag(name)
                    }
                }
            } footer: {
                Text("OpenCode and T3 Code start new sessions with this model. T3 Code picks up a change the next time it starts its OpenCode server.")
                    .foregroundStyle(.secondary)
            }

            Section {
                TextField("Context length (tokens)", value: $draft.contextLength, format: .number.grouping(.never))
                TextField("Keep-alive", text: $draft.keepAlive, prompt: Text("30m"))
            } header: {
                Text("Ollama server")
            } footer: {
                Text("Saving a change here restarts the Ollama server, which unloads loaded models. Keep-alive is how long an idle model stays in memory.")
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    if let failure {
                        Text(failure).foregroundStyle(.red).font(.callout)
                    } else if configuration.isRestartingServer {
                        ProgressView().controlSize(.small)
                        Text("Restarting the Ollama server…").foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Revert") { revert() }
                        .disabled(!hasChanges || isSaving)
                    Button("Save") { save() }
                        .keyboardShortcut(.defaultAction)
                        .disabled(!hasChanges || isSaving)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear(perform: revert)
    }

    private var hasChanges: Bool { draft != configuration.settings }

    private var modelChoices: [String] {
        let installed = library.installedNames
        return installed.contains(draft.defaultModel) ? installed : [draft.defaultModel] + installed
    }

    private func revert() {
        draft = configuration.settings
        failure = nil
    }

    private func save() {
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                try await configuration.save(draft)
                failure = nil
            } catch {
                failure = error.localizedDescription
            }
        }
    }
}

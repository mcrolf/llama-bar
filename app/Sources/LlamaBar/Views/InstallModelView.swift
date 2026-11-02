import SwiftUI

struct InstallModelView: View {
    private static let library = URL(string: "https://ollama.com/library")!

    let library: ModelLibrary

    @State private var modelName = ""

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("Model", text: $modelName, prompt: Text("qwen3-coder:30b"))
                        .onSubmit(pull)
                    Button("Pull", action: pull)
                        .disabled(!ModelName.isValid(requestedModel))
                        .keyboardShortcut(.defaultAction)
                }
                Link("Browse models on ollama.com", destination: Self.library)
            } header: {
                Text("Pull a model from ollama.com")
            } footer: {
                Text("Use name:tag, such as gpt-oss:20b. Without a tag Ollama pulls latest. New models appear in OpenCode and T3 Code the next time the OpenCode server starts.")
                    .foregroundStyle(.secondary)
            }

            if !library.pulls.isEmpty {
                Section("Downloads") {
                    ForEach(library.pulls) { pull in
                        PullRow(pull: pull, library: library)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var requestedModel: String {
        modelName.trimmingCharacters(in: .whitespaces)
    }

    private func pull() {
        guard ModelName.isValid(requestedModel) else { return }
        library.pull(requestedModel)
        modelName = ""
    }
}

private struct PullRow: View {
    let pull: ModelLibrary.Pull
    let library: ModelLibrary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(pull.model).fontWeight(.medium)
                Spacer()
                if pull.failure == nil {
                    Button("Cancel") { library.cancelPull(pull.model) }
                } else {
                    Button("Retry") { library.pull(pull.model) }
                    Button("Dismiss") { library.dismissPull(pull.model) }
                }
            }
            if let failure = pull.failure {
                Text(failure).font(.caption).foregroundStyle(.red)
            } else {
                if let fraction = pull.progress?.fraction {
                    ProgressView(value: fraction)
                } else {
                    ProgressView().progressViewStyle(.linear)
                }
                Text(status).font(.caption).foregroundStyle(.secondary).monospacedDigit()
            }
        }
        .padding(.vertical, 2)
    }

    private var status: String {
        guard let progress = pull.progress else { return "Starting…" }
        guard let completed = progress.completed, let total = progress.total else { return progress.status }
        return "\(progress.status): \(completed.byteCount) of \(total.byteCount)"
    }
}

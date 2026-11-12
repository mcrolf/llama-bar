import SwiftUI

struct DependenciesView: View {
    let updates: DependencyUpdates

    var body: some View {
        Form {
            Section {
                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                    GridRow {
                        Text("")
                        Text("Installed")
                        Text("Latest")
                        Text("")
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    Divider()
                    ForEach(Dependency.allCases) { dependency in
                        DependencyRow(dependency: dependency, updates: updates)
                    }
                }
            } header: {
                Text("Installed with Homebrew")
            } footer: {
                Text("Updating Ollama restarts the server, which unloads loaded models. T3 Code uses a new OpenCode the next time it starts its OpenCode server.")
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    if let failure = updates.failure {
                        Text(failure).foregroundStyle(.red).font(.callout)
                    } else if updates.isChecking {
                        ProgressView().controlSize(.small)
                        Text("Checking for new versions…").foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Check Again") { Task { await updates.check() } }
                        .disabled(updates.isBusy)
                }
            }
        }
        .formStyle(.grouped)
        .task { await updates.check() }
    }
}

private struct DependencyRow: View {
    let dependency: Dependency
    let updates: DependencyUpdates

    var body: some View {
        let formula = updates.formulae[dependency]
        GridRow {
            Text(dependency.title).fontWeight(.medium)
            Text(formula?.installedVersion ?? "-").monospacedDigit()
            Text(formula?.latestVersion ?? "-").monospacedDigit()
            status(formula)
        }
    }

    @ViewBuilder
    private func status(_ formula: Homebrew.Formula?) -> some View {
        if updates.upgrading == dependency {
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Updating…").foregroundStyle(.secondary)
            }
        } else if let formula {
            if formula.installedVersion == nil {
                Text("Not installed with Homebrew").foregroundStyle(.secondary)
            } else if formula.isOutdated {
                Button("Update") { Task { await updates.upgrade(dependency) } }
                    .disabled(updates.isBusy)
            } else {
                Label("Up to date", systemImage: "checkmark.circle").foregroundStyle(.green)
            }
        }
    }
}

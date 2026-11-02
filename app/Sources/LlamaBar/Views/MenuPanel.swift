import SwiftUI

/// The panel shown when the menu bar icon is clicked.
struct MenuPanel: View {
    let server: ServerMonitor
    let usage: UsageMonitor

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismissPanel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ServerHeader(server: server)
            Divider()
            if !server.isSetUp {
                SetupPrompt {
                    dismissPanel()
                    Desktop.runSetup()
                }
                Divider()
            }
            LoadedModelsSection(server: server)
            Divider()
            UsageSection(usage: usage)
            Divider()
            actions
        }
        .padding(14)
        .frame(width: 340)
    }

    private var actions: some View {
        VStack(spacing: 2) {
            PanelAction("Open OpenCode", systemImage: "terminal") {
                dismissPanel()
                Desktop.openOpenCode()
            }
            PanelAction("Configuration Manager…", systemImage: "gearshape") {
                dismissPanel()
                openWindow(id: ConfigurationWindow.id)
                Desktop.bringToFront(windowID: ConfigurationWindow.id)
            }
            PanelAction("Restart Ollama Server", systemImage: "arrow.clockwise") {
                Task { await server.restartServer() }
            }
            PanelAction("Show Server Log", systemImage: "doc.text") {
                dismissPanel()
                Desktop.showServerLog()
            }
            Divider().padding(.vertical, 4)
            PanelAction("Quit Llama Bar", systemImage: "power") { NSApp.terminate(nil) }
        }
    }
}

private struct ServerHeader: View {
    let server: ServerMonitor

    var body: some View {
        HStack {
            Circle()
                .fill(server.isReachable ? Color.green : Color.red)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text("Ollama").font(.headline)
            Spacer()
            Text(status).foregroundStyle(.secondary).font(.callout)
        }
        .accessibilityElement(children: .combine)
    }

    private var status: String {
        server.version.map { "Running v\($0)" } ?? "Not running"
    }
}

/// Shown until bin/setup has installed the Ollama LaunchAgent.
private struct SetupPrompt: View {
    let runSetup: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle("Finish Setup")
            Text("Setup installs Ollama and OpenCode with Homebrew, starts the Ollama server, and downloads the default model (about 15 GB). Quit the Ollama app first if it is running.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Run Setup in Terminal", action: runSetup)
                .buttonStyle(.borderedProminent)
        }
    }
}

private struct LoadedModelsSection: View {
    let server: ServerMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle("Loaded Models")
            if !server.isReachable {
                Text(server.lastError ?? "The Ollama server is not responding.")
                    .font(.callout).foregroundStyle(.secondary)
            } else if server.loadedModels.isEmpty {
                Text("No model loaded. Models load on first use.")
                    .font(.callout).foregroundStyle(.secondary)
            } else {
                ForEach(server.loadedModels) { model in
                    LoadedModelRow(model: model) { Task { await server.unload(model.name) } }
                }
            }
        }
    }
}

private struct LoadedModelRow: View {
    let model: LoadedModel
    let unload: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.name).fontWeight(.medium)
                Text(details).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: unload) { Image(systemName: "eject") }
                .buttonStyle(.borderless)
                .help("Unload from memory")
                .accessibilityLabel("Unload \(model.name)")
        }
    }

    private var details: String {
        var parts = [model.sizeVram.byteCount]
        if let context = model.contextLength { parts.append("\(context / 1024)K context") }
        parts.append("unloads \(model.expiresAt.formatted(.relative(presentation: .named)))")
        return parts.joined(separator: " · ")
    }
}

private struct UsageSection: View {
    @Bindable var usage: UsageMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionTitle("OpenCode Usage")
                Spacer()
                Button { Task { await usage.refresh() } } label: { Image(systemName: "arrow.clockwise") }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Refresh usage")
            }
            Picker("Period", selection: $usage.period) {
                ForEach(UsagePeriod.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if let stats = usage.stats {
                UsageSummary(stats: stats)
            }
            if let failure = usage.failure {
                Text(failure).font(.caption).foregroundStyle(.red)
            }
        }
        .task(id: usage.period) { await usage.refresh() }
    }
}

private struct UsageSummary: View {
    let stats: UsageStats

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
            GridRow {
                Metric("Sessions", stats.sessions)
                Metric("Prompts", stats.prompts)
                Metric("Cache read", stats.tokens.cache.read)
            }
            GridRow {
                Metric("Input tokens", stats.tokens.input)
                Metric("Output tokens", stats.tokens.output)
            }
        }
        let models = stats.models ?? []
        if !models.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                ForEach(models) { usage in
                    HStack {
                        Text(usage.model.id).lineLimit(1)
                        Spacer()
                        Text("\(usage.tokens.input.compactCount) in · \(usage.tokens.output.compactCount) out")
                            .monospacedDigit().foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
            }
        }
    }
}

private struct Metric: View {
    let title: String
    let value: Int

    init(_ title: String, _ value: Int) {
        self.title = title
        self.value = value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value.compactCount).font(.title3.weight(.semibold)).monospacedDigit()
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct SectionTitle: View {
    let title: String

    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title.uppercased()).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
    }
}

/// A full-width, menu-like row that highlights on hover.
private struct PanelAction: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    @State private var isHovered = false

    init(_ title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage).frame(width: 18)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .background(isHovered ? Color.accentColor.opacity(0.18) : .clear, in: RoundedRectangle(cornerRadius: 6))
        .onHover { isHovered = $0 }
    }
}

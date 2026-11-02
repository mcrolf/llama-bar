import SwiftUI

struct ConfigurationWindow: View {
    static let id = "configuration"

    let server: ServerMonitor
    let library: ModelLibrary
    let configuration: ServerConfiguration

    var body: some View {
        TabView {
            Tab("Installed Models", systemImage: "shippingbox") {
                InstalledModelsView(server: server, library: library, configuration: configuration)
            }
            Tab("Install Model", systemImage: "arrow.down.circle") {
                InstallModelView(library: library)
            }
            Tab("Default Model", systemImage: "slider.horizontal.3") {
                DefaultModelView(library: library, configuration: configuration)
            }
        }
        .frame(minWidth: 760, minHeight: 460)
        .task { await library.refresh() }
        .onAppear { Desktop.showAsRegularApp(windowID: Self.id) }
        .onDisappear(perform: Desktop.returnToMenuBar)
    }
}

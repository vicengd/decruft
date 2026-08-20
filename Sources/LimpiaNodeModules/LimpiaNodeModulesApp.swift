import SwiftUI

@main
struct LimpiaNodeModulesApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Limpia node_modules", systemImage: "shippingbox") {
            MenuContentView()
                .environment(appState)
        }
        .menuBarExtraStyle(.window)
    }
}

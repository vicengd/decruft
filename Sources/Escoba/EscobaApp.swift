import SwiftUI

@main
struct EscobaApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Escoba", systemImage: "sparkles") {
            MenuContentView()
                .environment(appState)
        }
        .menuBarExtraStyle(.window)
    }
}

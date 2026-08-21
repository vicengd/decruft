import SwiftUI

@main
struct DecruftApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Decruft", systemImage: "sparkles") {
            MenuContentView()
                .environment(appState)
        }
        .menuBarExtraStyle(.window)
    }
}

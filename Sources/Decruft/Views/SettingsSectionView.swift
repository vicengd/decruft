import SwiftUI

struct SettingsSectionView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Toggle("Dry-run mode (deletes nothing)", isOn: dryRun)
            Toggle("Daily automatic cleanup", isOn: autoClean)

            if state.config.autoCleanEnabled {
                Stepper(
                    "Delete if inactive ≥ \(state.config.inactivityThresholdDays) days",
                    value: threshold,
                    in: 1...90
                )
            }

            Toggle("Launch at login", isOn: launchAtLogin)
        }
        .toggleStyle(.checkbox)
    }

    private var dryRun: Binding<Bool> {
        Binding { state.config.dryRun } set: { state.setDryRun($0) }
    }

    private var autoClean: Binding<Bool> {
        Binding { state.config.autoCleanEnabled } set: { state.setAutoClean($0) }
    }

    private var threshold: Binding<Int> {
        Binding { state.config.inactivityThresholdDays } set: { state.setThreshold($0) }
    }

    private var launchAtLogin: Binding<Bool> {
        Binding { state.launchAtLogin } set: { state.setLaunchAtLogin($0) }
    }
}

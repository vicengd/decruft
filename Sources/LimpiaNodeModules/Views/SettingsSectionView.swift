import SwiftUI

struct SettingsSectionView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Ajustes")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Toggle("Modo solo mostrar (no borra nada)", isOn: dryRun)
            Toggle("Limpieza automática diaria", isOn: autoClean)

            if state.config.autoCleanEnabled {
                Stepper(
                    "Borrar inactivos ≥ \(state.config.inactivityThresholdDays) días",
                    value: threshold,
                    in: 1...90
                )
                .font(.caption)
            }

            Toggle("Abrir al iniciar sesión", isOn: launchAtLogin)
        }
        .toggleStyle(.checkbox)
        .font(.callout)
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

import SwiftUI

struct MenuContentView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            scanControls
            if !state.entries.isEmpty {
                entryList
                deleteButton
            }
            if let message = state.statusMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Divider()
            RootsSectionView()
            SettingsSectionView()
            Divider()
            footer
        }
        .padding(12)
        .frame(width: 380)
        .onAppear {
            if state.entries.isEmpty && !state.isScanning {
                state.scan()
            }
        }
    }

    private var header: some View {
        HStack {
            Label("Limpia node_modules", systemImage: "shippingbox")
                .font(.headline)
            Spacer()
            if state.config.dryRun {
                Text("solo mostrar")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.yellow.opacity(0.25), in: Capsule())
            }
        }
    }

    private var scanControls: some View {
        HStack {
            Button {
                state.scan()
            } label: {
                Label("Escanear", systemImage: "arrow.clockwise")
            }
            .disabled(state.isScanning)

            if state.isScanning {
                ProgressView()
                    .controlSize(.small)
                Text("Escaneando…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if !state.entries.isEmpty {
                Spacer()
                Text("Recuperable: \(AppState.format(state.totalRecoverableBytes))")
                    .font(.callout.weight(.medium))
            }
        }
    }

    private var entryList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(state.entries) { entry in
                    EntryRowView(entry: entry)
                }
            }
        }
        .frame(maxHeight: 260)
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            state.deleteSelected()
        } label: {
            if state.isDeleting {
                Label("Borrando…", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            } else {
                Label(
                    "Borrar seleccionados (\(state.selectedEntries.count) · \(AppState.format(state.selectedBytes)))",
                    systemImage: "trash"
                )
                .frame(maxWidth: .infinity)
            }
        }
        .disabled(state.selectedEntries.isEmpty || state.isDeleting)
    }

    private var footer: some View {
        HStack {
            Text("Total liberado: \(AppState.format(state.config.totalFreedBytes))")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Salir") {
                NSApplication.shared.terminate(nil)
            }
            .font(.caption)
        }
    }
}

import SwiftUI

struct MenuContentView: View {
    @Environment(AppState.self) private var state
    @State private var showArtifactInfo = false

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
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Divider()
            RootsSectionView()
            ExclusionsSectionView()
            SettingsSectionView()
            Divider()
            footer
        }
        .padding(12)
        .frame(width: 380)
        .onAppear {
            // Solo si nunca se ha escaneado: una lista vacía tras borrar todo
            // es el estado normal, no un motivo para reescanear.
            if state.lastScanDate == nil && !state.isScanning {
                state.scan()
            }
        }
    }

    private var header: some View {
        HStack {
            Label("Escoba", systemImage: "sparkles")
                .font(.headline)
            Button("Qué se borra", systemImage: "info.circle") {
                showArtifactInfo.toggle()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Qué tipos de carpetas detecta y borra la app")
            .popover(isPresented: $showArtifactInfo, arrowEdge: .bottom) {
                ArtifactInfoView()
            }
            Spacer()
            if state.config.dryRun {
                Text("solo mostrar")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.yellow.opacity(0.25), in: Capsule())
            }
        }
    }

    private var scanControls: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button {
                    state.scan()
                } label: {
                    Label("Escanear", systemImage: "arrow.clockwise")
                }
                .disabled(state.isScanning)

                if !state.entries.isEmpty {
                    Spacer()
                    Text("Recuperable: \(AppState.format(state.totalRecoverableBytes))")
                        .font(.callout.weight(.medium))
                }
            }
            if state.isScanning {
                if state.scanTotal > 0 {
                    ProgressView(
                        value: Double(state.scanCompleted),
                        total: Double(state.scanTotal)
                    ) {
                        Text("Midiendo \(state.scanCompleted)/\(state.scanTotal) artefactos…")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ProgressView {
                        Text("Buscando artefactos…")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .controlSize(.small)
                }
            } else if let last = state.lastScanDate {
                Text("Último escaneo: \(last.formatted(date: .omitted, time: .shortened))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
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

    @ViewBuilder
    private var deleteButton: some View {
        if state.isDeleting {
            ProgressView(
                value: Double(state.deleteCompleted),
                total: Double(max(1, state.deleteTotal))
            ) {
                Text("Borrando \(state.deleteCompleted)/\(state.deleteTotal) · liberados \(AppState.format(state.deleteFreedBytes))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        } else {
            Button(role: .destructive) {
                state.deleteSelected()
            } label: {
                Label(
                    "Borrar seleccionados (\(state.selectedEntries.count) · \(AppState.format(state.selectedBytes)))",
                    systemImage: "trash"
                )
                .frame(maxWidth: .infinity)
            }
            .disabled(state.selectedEntries.isEmpty || state.isScanning)
        }
    }

    private var footer: some View {
        HStack {
            Text("Total liberado: \(AppState.format(state.config.totalFreedBytes))")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Salir") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

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
            Divider()
            ExclusionsSectionView()
            Divider()
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
            Label("Decruft", systemImage: "sparkles")
                .font(.headline)
            Button("What gets deleted", systemImage: "info.circle") {
                showArtifactInfo.toggle()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Which folder types the app detects and deletes")
            .popover(isPresented: $showArtifactInfo, arrowEdge: .bottom) {
                ArtifactInfoView()
            }
            Spacer()
            if state.config.dryRun {
                Text("dry run")
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
                    Label("Scan", systemImage: "arrow.clockwise")
                }
                .disabled(state.isScanning)

                if !state.isScanning, let last = state.lastScanDate {
                    Text(last.formatted(date: .omitted, time: .shortened))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if !state.entries.isEmpty {
                    Spacer()
                    Text("Recoverable: \(AppState.format(state.totalRecoverableBytes))")
                        .font(.callout.weight(.medium))
                }
            }
            if state.isScanning {
                if state.scanTotal > 0 {
                    ProgressView(
                        value: Double(state.scanCompleted),
                        total: Double(state.scanTotal)
                    ) {
                        Text("Measuring \(state.scanCompleted)/\(state.scanTotal) folders…")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ProgressView {
                        Text("Scanning for regenerable folders…")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .controlSize(.small)
                }
            }
        }
    }

    private let rowHeight: CGFloat = 42

    @ViewBuilder
    private var entryList: some View {
        HStack {
            Text("\(state.selectedEntries.count) of \(state.entries.count) selected")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Button("All") {
                state.selected = Set(state.entries.map(\.id))
            }
            .buttonStyle(.borderless)
            Button("None") {
                state.selected = []
            }
            .buttonStyle(.borderless)
        }
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(state.entries) { entry in
                    EntryRowView(entry: entry)
                }
            }
        }
        // En un popover de MenuBarExtra, un ScrollView sin altura explícita
        // colapsa (el contenido lazy no declara altura ideal): se fija según
        // el número de filas, con tope para que la ventana no crezca sin fin.
        .frame(height: min(260, CGFloat(state.entries.count) * rowHeight))
    }

    @ViewBuilder
    private var deleteButton: some View {
        if state.isDeleting {
            ProgressView(
                value: Double(state.deleteCompleted),
                total: Double(max(1, state.deleteTotal))
            ) {
                Text("Deleting \(state.deleteCompleted)/\(state.deleteTotal) · freed \(AppState.format(state.deleteFreedBytes))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        } else {
            Button(role: .destructive) {
                state.deleteSelected()
            } label: {
                Label(
                    "Delete selected (\(state.selectedEntries.count) · \(AppState.format(state.selectedBytes)))",
                    systemImage: "trash"
                )
                .frame(maxWidth: .infinity)
            }
            .disabled(state.selectedEntries.isEmpty || state.isScanning)
        }
    }

    private var footer: some View {
        HStack {
            Text("Total freed: \(AppState.format(state.config.totalFreedBytes))")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

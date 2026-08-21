import SwiftUI

struct EntryRowView: View {
    @Environment(AppState.self) private var state
    let entry: CleanableEntry

    var body: some View {
        Toggle(isOn: isSelected) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(entry.projectName)
                            .lineLimit(1)
                        Text(entry.kind)
                            .font(.caption.monospaced())
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 3))
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        if !isInactive {
                            Circle()
                                .fill(.green)
                                .frame(width: 6, height: 6)
                        }
                        Text(entry.inactivityLabel)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(AppState.format(entry.sizeBytes))
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
                Button("Excluir proyecto", systemImage: "nosign") {
                    state.excludeProject(entry.projectPath)
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .help("Excluir \(entry.projectName) del escaneo")
            }
        }
        .toggleStyle(.checkbox)
        .padding(.vertical, 3)
        .help(entry.path)
    }

    /// Punto verde = proyecto activo: borrar sus artefactos implica regenerarlos pronto.
    private var isInactive: Bool {
        entry.inactiveDays >= state.config.inactivityThresholdDays
    }

    private var isSelected: Binding<Bool> {
        Binding {
            state.selected.contains(entry.id)
        } set: { selected in
            if selected {
                state.selected.insert(entry.id)
            } else {
                state.selected.remove(entry.id)
            }
        }
    }
}

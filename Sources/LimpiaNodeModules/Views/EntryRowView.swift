import SwiftUI

struct EntryRowView: View {
    @Environment(AppState.self) private var state
    let entry: NodeModulesEntry

    var body: some View {
        Toggle(isOn: isSelected) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.projectName)
                        .font(.callout)
                        .lineLimit(1)
                    Text(entry.inactivityLabel)
                        .font(.caption2)
                        .foregroundStyle(isInactive ? .orange : .secondary)
                }
                Spacer()
                Text(AppState.format(entry.sizeBytes))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .toggleStyle(.checkbox)
        .padding(.vertical, 2)
        .help(entry.nodeModulesPath)
    }

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

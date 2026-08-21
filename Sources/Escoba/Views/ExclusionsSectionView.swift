import SwiftUI

struct ExclusionsSectionView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Excluidos del escaneo")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Excluir…", systemImage: "plus") {
                    state.addExclusion()
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }
            if state.config.excludedPaths.isEmpty {
                Text("Ninguno. Usa ⃠ en una fila o \"Excluir…\" para proteger proyectos en curso.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            ForEach(state.config.excludedPaths, id: \.self) { path in
                HStack {
                    Text(abbreviated(path))
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(path)
                    Spacer()
                    Button("Quitar exclusión", systemImage: "minus.circle") {
                        state.removeExclusion(path)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func abbreviated(_ path: String) -> String {
        let home = NSHomeDirectory()
        return path.hasPrefix(home) ? "~" + path.dropFirst(home.count) : path
    }
}

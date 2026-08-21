import SwiftUI

struct RootsSectionView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Directorios raíz")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Añadir…", systemImage: "plus") {
                    state.addRoot()
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }
            ForEach(state.config.roots, id: \.self) { root in
                HStack {
                    Text(abbreviated(root))
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(root)
                    Spacer()
                    Button("Quitar directorio", systemImage: "minus.circle") {
                        state.removeRoot(root)
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

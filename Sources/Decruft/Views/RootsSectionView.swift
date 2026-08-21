import SwiftUI

struct RootsSectionView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Root folders")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Add…", systemImage: "plus") {
                    state.addRoot()
                }
                .buttonStyle(.borderless)
            }
            ForEach(state.config.roots, id: \.self) { root in
                HStack {
                    Text(abbreviated(root))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(root)
                    Spacer()
                    Button("Remove folder", systemImage: "minus.circle") {
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

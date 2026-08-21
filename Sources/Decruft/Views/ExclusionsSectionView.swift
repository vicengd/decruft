import SwiftUI

struct ExclusionsSectionView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Excluded from scanning")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Exclude…", systemImage: "plus") {
                    state.addExclusion()
                }
                .buttonStyle(.borderless)
            }
            if state.config.excludedPaths.isEmpty {
                Text("None yet. Use ⃠ on a row or \"Exclude…\" to protect projects you are working on.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(state.config.excludedPaths, id: \.self) { path in
                HStack {
                    Text(abbreviated(path))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(path)
                    Spacer()
                    Button("Remove exclusion", systemImage: "minus.circle") {
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

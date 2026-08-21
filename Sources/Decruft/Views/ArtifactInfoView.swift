import SwiftUI

/// Qué borra la app y bajo qué condiciones. Las listas salen de los mismos
/// Set que usa ProjectScanner: si se añade un tipo, esta ayuda se actualiza sola.
struct ArtifactInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What is Decruft")
                .font(.headline)

            Text("Decruft frees disk space by deleting the folders your dev tools regenerate on their own: dependencies, builds, caches and virtual environments. It scans your project folders, shows how much each one takes and how long its project has been inactive, and lets you delete them manually or automatically every day for idle projects. Nothing it deletes is lost: it comes back with npm install or your next build.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Text("What it detects and deletes")
                .font(.subheadline.weight(.semibold))

            section(
                "Always (regenerable by name)",
                names: ProjectScanner.alwaysArtifacts
            )
            section(
                "Only if they are a real virtualenv (contain pyvenv.cfg)",
                names: ProjectScanner.venvNames,
                note: "They regenerate with pip install -r requirements.txt / uv sync."
            )
            section(
                "Only if the parent is a JS or Android project (package.json / Gradle)",
                names: ProjectScanner.buildOutputNames,
                note: "A dist or build in any other context is treated as code and never touched."
            )

            Divider()

            VStack(alignment: .leading, spacing: 3) {
                Text("Never touched")
                    .font(.subheadline.weight(.semibold))
                Text("Inside \(ProjectScanner.vendoredTreeNames.sorted().joined(separator: ", ")) only node_modules is detected: everything else is installed code (WordPress plugins, Composer packages…). .git and .env are never detected: they are not regenerable.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(width: 360)
    }

    private func section(
        _ title: LocalizedStringKey,
        names: Set<String>,
        note: LocalizedStringKey? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(names.sorted().joined(separator: "   "))
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let note {
                Text(note)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

import SwiftUI

/// Qué borra la app y bajo qué condiciones. Las listas salen de los mismos
/// Set que usa ProjectScanner: si se añade un tipo, esta ayuda se actualiza sola.
struct ArtifactInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Qué detecta y borra la app")
                .font(.headline)

            section(
                "Siempre (regenerables por nombre)",
                names: ProjectScanner.alwaysArtifacts
            )
            section(
                "Solo si son un virtualenv real (contienen pyvenv.cfg)",
                names: ProjectScanner.venvNames,
                note: "Se regeneran con pip install -r requirements.txt / uv sync."
            )
            section(
                "Solo si el padre es un proyecto JS o Android (package.json / Gradle)",
                names: ProjectScanner.buildOutputNames,
                note: "Un dist o build en otro contexto se considera código, no artefacto."
            )

            Divider()

            VStack(alignment: .leading, spacing: 3) {
                Text("Nunca se toca")
                    .font(.caption.weight(.semibold))
                Text(
                    "Dentro de \(ProjectScanner.vendoredTreeNames.sorted().joined(separator: ", ")) "
                        + "solo se detecta node_modules: el resto es código instalado "
                        + "(plugins de WordPress, paquetes de Composer…). "
                        + ".git y .env no se detectan nunca: no son regenerables."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(width: 340)
    }

    private func section(_ title: String, names: Set<String>, note: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(.semibold))
            Text(names.sorted().joined(separator: "   "))
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let note {
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

import SwiftUI

/// Qué borra la app y bajo qué condiciones. Las listas salen de los mismos
/// Set que usa ProjectScanner: si se añade un tipo, esta ayuda se actualiza sola.
struct ArtifactInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Qué es Escoba")
                .font(.headline)

            Text(
                "Escoba libera espacio en disco borrando las carpetas que las "
                    + "herramientas de desarrollo regeneran solas: dependencias, "
                    + "builds, cachés y entornos virtuales. Escanea tus directorios "
                    + "de proyectos, muestra cuánto ocupa cada artefacto y cuántos "
                    + "días lleva inactivo su proyecto, y te deja borrarlos a mano "
                    + "o automáticamente cada día en proyectos parados. Nada de lo "
                    + "que borra se pierde: se recupera con npm install o el "
                    + "siguiente build."
            )
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            Divider()

            Text("Qué detecta y borra")
                .font(.subheadline.weight(.semibold))

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
                    .font(.subheadline.weight(.semibold))
                Text(
                    "Dentro de \(ProjectScanner.vendoredTreeNames.sorted().joined(separator: ", ")) "
                        + "solo se detecta node_modules: el resto es código instalado "
                        + "(plugins de WordPress, paquetes de Composer…). "
                        + ".git y .env no se detectan nunca: no son regenerables."
                )
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(width: 360)
    }

    private func section(_ title: String, names: Set<String>, note: String? = nil) -> some View {
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

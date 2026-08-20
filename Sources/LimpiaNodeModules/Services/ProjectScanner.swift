import Foundation

enum ProjectScanner {
    /// Artefactos por nombre inequívoco: siempre regenerables.
    static let alwaysArtifacts: Set<String> = [
        "node_modules", ".next", ".nuxt", ".output", ".svelte-kit",
        ".turbo", ".parcel-cache", ".vite", ".cache", "coverage", ".build",
    ]

    /// Nombres ambiguos: solo son artefactos si el padre es un proyecto
    /// JS (package.json) o Android (gradle). Un "dist" dentro de un plugin
    /// de WordPress o de vendor/ es código instalado, no output de build.
    static let buildOutputNames: Set<String> = ["dist", "build", "out"]

    /// Posibles virtualenvs de Python: solo si contienen pyvenv.cfg.
    static let venvNames: Set<String> = [".venv", "venv", "env"]

    /// Árboles de código vendorizado/instalado: dentro solo se detecta
    /// node_modules (p. ej. un tema de WordPress en desarrollo).
    static let vendoredTreeNames: Set<String> = [
        "vendor", "wp-includes", "wp-admin", "wp-content", "site-packages",
    ]

    /// Directorios que no cuentan como "actividad" del proyecto: artefactos
    /// regenerables y metadatos que se tocan solos (fetch de git, cachés…).
    static let activityExcludedDirs: Set<String> = alwaysArtifacts
        .union(buildOutputNames)
        .union(venvNames)
        .union([".git", "__pycache__", "DerivedData", ".vercel"])

    static func scan(roots: [String]) -> [CleanableEntry] {
        findArtifactPaths(roots: roots)
            .map(measure(artifact:))
            .sorted { $0.sizeBytes > $1.sizeBytes }
    }

    /// Fase rápida: localiza los directorios de artefactos sin descender en ellos.
    static func findArtifactPaths(roots: [String]) -> [URL] {
        var found: [URL] = []
        for root in roots {
            findArtifacts(in: URL(fileURLWithPath: root), isRoot: true, vendored: false, into: &found)
        }
        return found
    }

    private static func findArtifacts(in directory: URL, isRoot: Bool, vendored: Bool, into found: inout [URL]) {
        for child in subdirectories(of: directory) {
            let name = child.lastPathComponent
            // En el nivel raíz un "build" o "dist" sería un proyecto que se llama
            // así, no un artefacto: solo cuenta como artefacto a partir del segundo nivel.
            if !isRoot {
                if name == "node_modules" {
                    found.append(child)
                    continue
                }
                if !vendored {
                    if alwaysArtifacts.contains(name) {
                        found.append(child)
                        continue
                    }
                    if venvNames.contains(name), isVirtualenv(child) {
                        found.append(child)
                        continue
                    }
                    if buildOutputNames.contains(name), isBuildProject(directory) {
                        found.append(child)
                        continue
                    }
                }
            }
            if !name.hasPrefix(".") {
                findArtifacts(
                    in: child,
                    isRoot: false,
                    vendored: vendored || vendoredTreeNames.contains(name),
                    into: &found
                )
            }
        }
    }

    private static func isVirtualenv(_ directory: URL) -> Bool {
        FileManager.default.fileExists(atPath: directory.appendingPathComponent("pyvenv.cfg").path)
    }

    /// El directorio padre delata si dist/build/out es output de build:
    /// proyecto JS (package.json) o Android (gradle).
    private static func isBuildProject(_ parent: URL) -> Bool {
        let markers = ["package.json", "build.gradle", "build.gradle.kts", "settings.gradle"]
        return markers.contains { marker in
            FileManager.default.fileExists(atPath: parent.appendingPathComponent(marker).path)
        }
    }

    /// Fase costosa por entrada: tamaño e inactividad. Paralelizable.
    static func measure(artifact url: URL) -> CleanableEntry {
        let projectURL = url.deletingLastPathComponent()
        return CleanableEntry(
            path: url.path,
            projectPath: projectURL.path,
            sizeBytes: directorySize(url),
            lastActivity: lastActivity(inProject: projectURL)
        )
    }

    /// Modificación más reciente de los ficheros del proyecto, excluyendo
    /// artefactos y metadatos. Es la señal de inactividad.
    static func lastActivity(inProject projectURL: URL) -> Date? {
        var latest: Date?
        walkForActivity(directory: projectURL, latest: &latest)
        return latest
    }

    private static func walkForActivity(directory: URL, latest: inout Date?) {
        let fm = FileManager.default
        let keys: [URLResourceKey] = [.isDirectoryKey, .isSymbolicLinkKey, .contentModificationDateKey]
        guard let children = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys) else { return }
        for child in children {
            guard let values = try? child.resourceValues(forKeys: Set(keys)),
                  values.isSymbolicLink != true
            else { continue }
            if values.isDirectory == true {
                guard !activityExcludedDirs.contains(child.lastPathComponent) else { continue }
                walkForActivity(directory: child, latest: &latest)
            } else if let date = values.contentModificationDate {
                if latest == nil || date > latest! { latest = date }
            }
        }
    }

    static func directorySize(_ url: URL) -> Int64 {
        let keys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey]
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: []
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: Set(keys)) else { continue }
            total += Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
        }
        return total
    }

    private static func subdirectories(of directory: URL) -> [URL] {
        let keys: [URLResourceKey] = [.isDirectoryKey, .isSymbolicLinkKey]
        guard let children = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: keys
        ) else { return [] }
        return children.filter { child in
            guard let values = try? child.resourceValues(forKeys: Set(keys)) else { return false }
            return values.isDirectory == true && values.isSymbolicLink != true
        }
    }
}

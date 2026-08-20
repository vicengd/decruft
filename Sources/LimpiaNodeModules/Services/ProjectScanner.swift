import Foundation

enum ProjectScanner {
    /// Directorios que no cuentan como "actividad" del proyecto: artefactos
    /// regenerables y metadatos que se tocan solos (fetch de git, cachés…).
    static let activityExcludedDirs: Set<String> = [
        "node_modules", ".git", ".next", ".nuxt", ".output", ".svelte-kit",
        "dist", "build", "out", "coverage", ".turbo", ".cache", ".parcel-cache",
        ".venv", "venv", "__pycache__", ".build", "DerivedData", ".vercel",
    ]

    static func scan(roots: [String]) -> [NodeModulesEntry] {
        var found: [URL] = []
        for root in roots {
            findNodeModules(in: URL(fileURLWithPath: root), into: &found)
        }
        return found.map { url in
            let projectURL = url.deletingLastPathComponent()
            return NodeModulesEntry(
                nodeModulesPath: url.path,
                projectPath: projectURL.path,
                sizeBytes: directorySize(url),
                lastActivity: lastActivity(inProject: projectURL)
            )
        }
        .sorted { $0.sizeBytes > $1.sizeBytes }
    }

    /// Busca carpetas node_modules sin descender dentro de ellas (los
    /// node_modules anidados de dependencias quedan cubiertos por el padre).
    private static func findNodeModules(in directory: URL, into found: inout [URL]) {
        for child in subdirectories(of: directory) {
            if child.lastPathComponent == "node_modules" {
                found.append(child)
            } else if !child.lastPathComponent.hasPrefix(".") {
                findNodeModules(in: child, into: &found)
            }
        }
    }

    /// Modificación más reciente de los ficheros del proyecto, excluyendo
    /// node_modules, builds y metadatos. Es la señal de inactividad.
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

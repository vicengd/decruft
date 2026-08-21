import Foundation

/// Un directorio regenerable (node_modules, .next, dist, venv…) candidato a borrado.
struct CleanableEntry: Identifiable, Hashable, Sendable {
    let path: String
    let projectPath: String
    let sizeBytes: Int64
    let lastActivity: Date?

    var id: String { path }

    /// Tipo de artefacto: el nombre del propio directorio ("node_modules", ".next"…).
    var kind: String {
        URL(fileURLWithPath: path).lastPathComponent
    }

    var projectName: String {
        URL(fileURLWithPath: projectPath).lastPathComponent
    }

    var inactiveDays: Int {
        guard let lastActivity else { return Int.max }
        return max(0, Int(Date.now.timeIntervalSince(lastActivity) / 86_400))
    }

    var inactivityLabel: String {
        guard lastActivity != nil else { return "sin datos" }
        let days = inactiveDays
        if days == 0 { return "activo hoy" }
        if days == 1 { return "1 día inactivo" }
        return "\(days) días inactivo"
    }
}

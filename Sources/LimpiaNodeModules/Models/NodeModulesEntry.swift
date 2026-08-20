import Foundation

struct NodeModulesEntry: Identifiable, Hashable, Sendable {
    let nodeModulesPath: String
    let projectPath: String
    let sizeBytes: Int64
    let lastActivity: Date?

    var id: String { nodeModulesPath }

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

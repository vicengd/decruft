import Foundation

struct CleanResult: Sendable {
    var deleted: [NodeModulesEntry] = []
    var errors: [String] = []

    var freedBytes: Int64 { deleted.reduce(0) { $0 + $1.sizeBytes } }
}

enum Cleaner {
    /// Borrado directo (equivalente a rm -rf), sin Papelera: en la Papelera
    /// seguiría ocupando disco y node_modules se regenera con npm install.
    static func delete(entries: [NodeModulesEntry]) -> CleanResult {
        var result = CleanResult()
        for entry in entries {
            do {
                try FileManager.default.removeItem(atPath: entry.nodeModulesPath)
                result.deleted.append(entry)
            } catch {
                result.errors.append("\(entry.projectName): \(error.localizedDescription)")
            }
        }
        return result
    }
}

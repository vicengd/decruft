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
            if let error = deleteOne(entry) {
                result.errors.append(error)
            } else {
                result.deleted.append(entry)
            }
        }
        return result
    }

    /// Borra una sola entrada; devuelve el mensaje de error o nil si fue bien.
    static func deleteOne(_ entry: NodeModulesEntry) -> String? {
        do {
            try FileManager.default.removeItem(atPath: entry.nodeModulesPath)
            return nil
        } catch {
            return "\(entry.projectName): \(error.localizedDescription)"
        }
    }
}

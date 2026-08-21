import Foundation

enum ConfigStore {
    static var directory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Escoba", isDirectory: true)
    }

    static var fileURL: URL {
        directory.appendingPathComponent("config.json")
    }

    /// La app se llamó "Limpia node_modules": si existe el directorio antiguo
    /// y no el nuevo, se mueve para conservar contador y exclusiones.
    static func migrateFromLegacyLocationIfNeeded() {
        let fm = FileManager.default
        let legacy = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LimpiaNodeModules", isDirectory: true)
        guard fm.fileExists(atPath: legacy.path), !fm.fileExists(atPath: directory.path) else { return }
        try? fm.moveItem(at: legacy, to: directory)
    }

    static func load() -> AppConfig {
        migrateFromLegacyLocationIfNeeded()
        guard let data = try? Data(contentsOf: fileURL),
              let config = try? JSONDecoder().decode(AppConfig.self, from: data)
        else { return .default }
        return config
    }

    static func save(_ config: AppConfig) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(config).write(to: fileURL, options: .atomic)
        } catch {
            NSLog("No se pudo guardar config.json: \(error.localizedDescription)")
        }
    }
}

import Foundation

enum ConfigStore {
    static var directory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Decruft", isDirectory: true)
    }

    static var fileURL: URL {
        directory.appendingPathComponent("config.json")
    }

    /// La app se llamó "Limpia node_modules" y luego "Escoba": si existe un
    /// directorio antiguo y no el nuevo, se mueve para conservar contador y exclusiones.
    static func migrateFromLegacyLocationIfNeeded() {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: directory.path) else { return }
        for legacyName in ["Escoba", "LimpiaNodeModules"] {
            let legacy = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(legacyName, isDirectory: true)
            if fm.fileExists(atPath: legacy.path) {
                try? fm.moveItem(at: legacy, to: directory)
                return
            }
        }
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

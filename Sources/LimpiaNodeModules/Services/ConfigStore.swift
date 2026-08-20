import Foundation

enum ConfigStore {
    static var directory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LimpiaNodeModules", isDirectory: true)
    }

    static var fileURL: URL {
        directory.appendingPathComponent("config.json")
    }

    static func load() -> AppConfig {
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

import Foundation
import Observation
import AppKit

@MainActor
@Observable
final class AppState {
    var config: AppConfig
    var entries: [NodeModulesEntry] = []
    var selected: Set<String> = []
    var isScanning = false
    var scanTotal = 0
    var scanCompleted = 0
    var isDeleting = false
    var lastScanDate: Date?
    var statusMessage: String?
    var launchAtLogin: Bool

    init() {
        config = ConfigStore.load()
        launchAtLogin = LoginItemManager.isEnabled
        startAutoCleanLoop()
        // Escaneo al arrancar: los resultados ya están listos al abrir el popover.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            self.scan()
        }
    }

    // MARK: - Derivados

    var totalRecoverableBytes: Int64 {
        entries.reduce(0) { $0 + $1.sizeBytes }
    }

    var selectedEntries: [NodeModulesEntry] {
        entries.filter { selected.contains($0.id) }
    }

    var selectedBytes: Int64 {
        selectedEntries.reduce(0) { $0 + $1.sizeBytes }
    }

    static func format(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    // MARK: - Escaneo

    func scan() {
        guard !isScanning else { return }
        isScanning = true
        statusMessage = nil
        entries = []
        selected = []
        scanTotal = 0
        scanCompleted = 0
        let roots = config.roots
        Task.detached(priority: .userInitiated) {
            let paths = ProjectScanner.findNodeModulesPaths(roots: roots)
            await MainActor.run {
                self.scanTotal = paths.count
            }

            let maxConcurrent = min(8, max(2, ProcessInfo.processInfo.activeProcessorCount))
            await withTaskGroup(of: NodeModulesEntry.self) { group in
                var pending = paths.makeIterator()
                for _ in 0..<maxConcurrent {
                    guard let url = pending.next() else { break }
                    group.addTask { ProjectScanner.measure(nodeModules: url) }
                }
                for await entry in group {
                    if let url = pending.next() {
                        group.addTask { ProjectScanner.measure(nodeModules: url) }
                    }
                    await MainActor.run {
                        self.entries.append(entry)
                        self.selected.insert(entry.id)
                        self.scanCompleted += 1
                    }
                }
            }

            await MainActor.run {
                self.entries.sort { $0.sizeBytes > $1.sizeBytes }
                self.lastScanDate = .now
                self.isScanning = false
                if self.entries.isEmpty {
                    self.statusMessage = "No se ha encontrado ningún node_modules."
                }
            }
        }
    }

    // MARK: - Borrado manual

    func deleteSelected() {
        guard !isDeleting, !selectedEntries.isEmpty else { return }
        let targets = selectedEntries

        if config.dryRun {
            statusMessage = "Solo mostrar: se habrían borrado \(targets.count) node_modules "
                + "(\(Self.format(targets.reduce(0) { $0 + $1.sizeBytes }))). Nada se ha tocado."
            return
        }

        isDeleting = true
        Task.detached(priority: .userInitiated) {
            let result = Cleaner.delete(entries: targets)
            await MainActor.run {
                self.applyCleanResult(result, source: "manual")
            }
        }
    }

    private func applyCleanResult(_ result: CleanResult, source: String) {
        isDeleting = false
        let deletedIDs = Set(result.deleted.map(\.id))
        entries.removeAll { deletedIDs.contains($0.id) }
        selected.subtract(deletedIDs)
        config.totalFreedBytes += result.freedBytes
        ConfigStore.save(config)

        var message = "Liberados \(Self.format(result.freedBytes)) (\(result.deleted.count) node_modules)."
        if !result.errors.isEmpty {
            message += " Errores: \(result.errors.joined(separator: "; "))"
        }
        statusMessage = message
        if source == "auto" {
            Notifier.notify(title: "Limpieza automática", body: message)
        }
    }

    // MARK: - Directorios raíz

    func addRoot() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: AppConfig.defaultRoot)
        panel.prompt = "Añadir"
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let path = url.path
        guard !config.roots.contains(path) else { return }
        config.roots.append(path)
        ConfigStore.save(config)
    }

    func removeRoot(_ path: String) {
        config.roots.removeAll { $0 == path }
        ConfigStore.save(config)
    }

    // MARK: - Ajustes

    func setDryRun(_ enabled: Bool) {
        config.dryRun = enabled
        ConfigStore.save(config)
    }

    func setAutoClean(_ enabled: Bool) {
        config.autoCleanEnabled = enabled
        ConfigStore.save(config)
        if enabled {
            Notifier.requestPermission()
        }
    }

    func setThreshold(_ days: Int) {
        config.inactivityThresholdDays = max(1, days)
        ConfigStore.save(config)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LoginItemManager.setEnabled(enabled)
            launchAtLogin = enabled
        } catch {
            launchAtLogin = LoginItemManager.isEnabled
            statusMessage = "No se pudo cambiar el arranque al iniciar sesión: \(error.localizedDescription)"
        }
    }

    // MARK: - Limpieza automática diaria

    private func startAutoCleanLoop() {
        Task { [weak self] in
            while !Task.isCancelled {
                await self?.autoCleanIfDue()
                try? await Task.sleep(for: .seconds(1800))
            }
        }
    }

    func autoCleanIfDue() async {
        guard config.autoCleanEnabled, !isScanning, !isDeleting else { return }
        let today = Self.dayString(from: .now)
        guard config.lastAutoCleanDay != today else { return }

        let roots = config.roots
        let threshold = config.inactivityThresholdDays
        let dryRun = config.dryRun

        let targets = await Task.detached(priority: .utility) {
            ProjectScanner.scan(roots: roots).filter { $0.inactiveDays >= threshold }
        }.value

        config.lastAutoCleanDay = today
        ConfigStore.save(config)

        guard !targets.isEmpty else { return }
        let totalBytes = targets.reduce(0) { $0 + $1.sizeBytes }

        if dryRun {
            Notifier.notify(
                title: "Limpieza automática (solo mostrar)",
                body: "Se habrían borrado \(targets.count) node_modules inactivos ≥\(threshold) días "
                    + "(\(Self.format(totalBytes))). Desactiva el modo solo mostrar para borrar de verdad."
            )
            return
        }

        let result = await Task.detached(priority: .utility) {
            Cleaner.delete(entries: targets)
        }.value
        applyCleanResult(result, source: "auto")
    }

    static func dayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}

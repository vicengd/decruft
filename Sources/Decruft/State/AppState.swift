import Foundation
import Observation
import AppKit

@MainActor
@Observable
final class AppState {
    var config: AppConfig
    var entries: [CleanableEntry] = []
    var selected: Set<String> = []
    var isScanning = false
    var scanTotal = 0
    var scanCompleted = 0
    var isDeleting = false
    var deleteTotal = 0
    var deleteCompleted = 0
    var deleteFreedBytes: Int64 = 0
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

    var selectedEntries: [CleanableEntry] {
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
        let excluded = Set(config.excludedPaths)
        Task.detached(priority: .userInitiated) {
            let paths = ProjectScanner.findArtifactPaths(roots: roots, excluded: excluded)
            await MainActor.run {
                self.scanTotal = paths.count
            }

            let maxConcurrent = min(8, max(2, ProcessInfo.processInfo.activeProcessorCount))
            await withTaskGroup(of: CleanableEntry.self) { group in
                var pending = paths.makeIterator()
                for _ in 0..<maxConcurrent {
                    guard let url = pending.next() else { break }
                    group.addTask { ProjectScanner.measure(artifact: url) }
                }
                for await entry in group {
                    if let url = pending.next() {
                        group.addTask { ProjectScanner.measure(artifact: url) }
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
                    self.statusMessage = "No se ha encontrado nada que limpiar."
                }
            }
        }
    }

    // MARK: - Borrado manual

    func deleteSelected() {
        guard !isDeleting, !selectedEntries.isEmpty else { return }
        let targets = selectedEntries

        if config.dryRun {
            statusMessage = "Solo mostrar: se habrían borrado \(targets.count) carpetas "
                + "(\(Self.format(targets.reduce(0) { $0 + $1.sizeBytes }))). Nada se ha tocado."
            return
        }

        isDeleting = true
        deleteTotal = targets.count
        deleteCompleted = 0
        deleteFreedBytes = 0

        Task.detached(priority: .userInitiated) {
            var errors: [String] = []
            // Borrar es I/O de metadatos: algo de paralelismo ayuda, mucho satura el disco.
            let maxConcurrent = 4
            await withTaskGroup(of: (CleanableEntry, String?).self) { group in
                var pending = targets.makeIterator()
                for _ in 0..<maxConcurrent {
                    guard let entry = pending.next() else { break }
                    group.addTask { (entry, Cleaner.deleteOne(entry)) }
                }
                for await (entry, error) in group {
                    if let next = pending.next() {
                        group.addTask { (next, Cleaner.deleteOne(next)) }
                    }
                    if let error { errors.append(error) }
                    await MainActor.run {
                        self.deleteCompleted += 1
                        if error == nil {
                            self.entries.removeAll { $0.id == entry.id }
                            self.selected.remove(entry.id)
                            self.deleteFreedBytes += entry.sizeBytes
                        }
                    }
                }
            }
            let finalErrors = errors
            await MainActor.run {
                self.isDeleting = false
                self.config.totalFreedBytes += self.deleteFreedBytes
                ConfigStore.save(self.config)
                var message = "Liberados \(Self.format(self.deleteFreedBytes)) "
                    + "(\(self.deleteTotal - finalErrors.count) carpetas)."
                if !finalErrors.isEmpty {
                    message += " Errores: \(finalErrors.joined(separator: "; "))"
                }
                self.statusMessage = message
            }
        }
    }

    private func applyAutoCleanResult(_ result: CleanResult) {
        isDeleting = false
        let deletedIDs = Set(result.deleted.map(\.id))
        entries.removeAll { deletedIDs.contains($0.id) }
        selected.subtract(deletedIDs)
        config.totalFreedBytes += result.freedBytes
        ConfigStore.save(config)

        var message = "Liberados \(Self.format(result.freedBytes)) (\(result.deleted.count) carpetas)."
        if !result.errors.isEmpty {
            message += " Errores: \(result.errors.joined(separator: "; "))"
        }
        statusMessage = message
        Notifier.notify(title: "Limpieza automática", body: message)
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

    // MARK: - Exclusiones

    /// Excluye un proyecto del escaneo y retira sus artefactos de la lista actual.
    func excludeProject(_ path: String) {
        guard !config.excludedPaths.contains(path) else { return }
        config.excludedPaths.append(path)
        ConfigStore.save(config)
        entries.removeAll { $0.projectPath == path || $0.projectPath.hasPrefix(path + "/") }
        selected = selected.filter { id in entries.contains { $0.id == id } }
    }

    func addExclusion() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: AppConfig.defaultRoot)
        panel.prompt = "Excluir"
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        excludeProject(url.path)
    }

    func removeExclusion(_ path: String) {
        config.excludedPaths.removeAll { $0 == path }
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
        let excluded = Set(config.excludedPaths)
        let threshold = config.inactivityThresholdDays
        let dryRun = config.dryRun

        let targets = await Task.detached(priority: .utility) {
            ProjectScanner.scan(roots: roots, excluded: excluded).filter { $0.inactiveDays >= threshold }
        }.value

        config.lastAutoCleanDay = today
        ConfigStore.save(config)

        guard !targets.isEmpty else { return }
        let totalBytes = targets.reduce(0) { $0 + $1.sizeBytes }

        if dryRun {
            Notifier.notify(
                title: "Limpieza automática (solo mostrar)",
                body: "Se habrían borrado \(targets.count) carpetas de proyectos inactivos ≥\(threshold) días "
                    + "(\(Self.format(totalBytes))). Desactiva el modo solo mostrar para borrar de verdad."
            )
            return
        }

        let result = await Task.detached(priority: .utility) {
            Cleaner.delete(entries: targets)
        }.value
        applyAutoCleanResult(result)
    }

    static func dayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}

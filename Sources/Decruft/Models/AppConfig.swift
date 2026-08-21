import Foundation

struct AppConfig: Codable, Sendable {
    var roots: [String]
    var excludedPaths: [String]
    var autoCleanEnabled: Bool
    var inactivityThresholdDays: Int
    var dryRun: Bool
    var lastAutoCleanDay: String?
    var totalFreedBytes: Int64

    static let defaultRoot = NSHomeDirectory() + "/desarrollo"

    static let `default` = AppConfig(
        roots: [defaultRoot],
        excludedPaths: [],
        autoCleanEnabled: false,
        inactivityThresholdDays: 15,
        dryRun: true,
        lastAutoCleanDay: nil,
        totalFreedBytes: 0
    )

    init(
        roots: [String],
        excludedPaths: [String],
        autoCleanEnabled: Bool,
        inactivityThresholdDays: Int,
        dryRun: Bool,
        lastAutoCleanDay: String?,
        totalFreedBytes: Int64
    ) {
        self.roots = roots
        self.excludedPaths = excludedPaths
        self.autoCleanEnabled = autoCleanEnabled
        self.inactivityThresholdDays = inactivityThresholdDays
        self.dryRun = dryRun
        self.lastAutoCleanDay = lastAutoCleanDay
        self.totalFreedBytes = totalFreedBytes
    }

    // Campos nuevos en versiones futuras no deben invalidar un config.json antiguo.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        roots = try container.decodeIfPresent([String].self, forKey: .roots) ?? [Self.defaultRoot]
        excludedPaths = try container.decodeIfPresent([String].self, forKey: .excludedPaths) ?? []
        autoCleanEnabled = try container.decodeIfPresent(Bool.self, forKey: .autoCleanEnabled) ?? false
        inactivityThresholdDays = try container.decodeIfPresent(Int.self, forKey: .inactivityThresholdDays) ?? 15
        dryRun = try container.decodeIfPresent(Bool.self, forKey: .dryRun) ?? true
        lastAutoCleanDay = try container.decodeIfPresent(String.self, forKey: .lastAutoCleanDay)
        totalFreedBytes = try container.decodeIfPresent(Int64.self, forKey: .totalFreedBytes) ?? 0
    }
}

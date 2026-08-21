import Foundation
import UserNotifications

enum Notifier {
    /// UNUserNotificationCenter exige un bundle real: ejecutando el binario
    /// suelto (swift run) no hay bundle identifier y la API abortaría.
    private static var isAvailable: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    static func requestPermission() {
        guard isAvailable else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func notify(title: String, body: String) {
        guard isAvailable else {
            NSLog("[Notificación] \(title): \(body)")
            return
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}

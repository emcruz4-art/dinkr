import Foundation
import UserNotifications

final class NotificationService: NSObject {
    static let shared = NotificationService()
    private override init() { super.init() }

    var fcmToken: String? = nil

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        do {
            return try await center.requestAuthorization(options: options)
        } catch {
            return false
        }
    }

    func scheduleGameReminder(for session: GameSession) {
        let content = UNMutableNotificationContent()
        content.title = "Game Starting Soon 🏓"
        content.body = "Your game at \(session.courtName) starts in 1 hour!"
        content.sound = .default

        let fireDate = session.dateTime.addingTimeInterval(-3600)
        guard fireDate > Date() else { return }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "game_\(session.id)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleEventReminder(for event: Event) {
        let content = UNMutableNotificationContent()
        content.title = "Event Tomorrow: \(event.title)"
        content.body = "Don't forget: \(event.location)"
        content.sound = .default

        let fireDate = event.dateTime.addingTimeInterval(-86400)
        guard fireDate > Date() else { return }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "event_\(event.id)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // Called from AppDelegate/SwiftUI App after APNs registration
    func didRegisterForRemoteNotifications(deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        fcmToken = token
        // TODO: Messaging.messaging().apnsToken = deviceToken
    }
}

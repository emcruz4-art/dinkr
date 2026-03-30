import UserNotifications
import Observation

@Observable
final class NotificationService {
    static let shared = NotificationService()
    var isAuthorized = false

    private init() {}

    // MARK: - Authorization

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        isAuthorized = granted
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Game Reminders

    /// Schedules a reminder 1 hour before the game session starts.
    func scheduleGameReminder(for session: GameSession) async {
        let fireDate = session.dateTime.addingTimeInterval(-3600)
        guard fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Game time! ⏰"
        content.body = "Your \(session.format.rawValue) game at \(session.courtName) starts in 1 hour"
        content.sound = .default
        content.categoryIdentifier = "GAME_REMINDER"

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "game_\(session.id)",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Daily Challenge Reminder

    /// Schedules a daily challenge reminder at 8:00 AM local time, repeating.
    func scheduleDailyChallengeReminder() async {
        // Remove any existing daily challenge notification before re-scheduling.
        await UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["daily_challenge"])

        let content = UNMutableNotificationContent()
        content.title = "Daily Challenge 🏓"
        content.body = "Your pickleball challenge is ready. Keep your streak going!"
        content.sound = .default

        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_challenge",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancellation

    /// Cancels the pending reminder for a specific game session.
    func cancelGameReminder(for sessionId: String) async {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["game_\(sessionId)"])
    }

    /// Cancels all pending notifications.
    func cancelAll() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Query

    /// Returns true if a reminder is already scheduled for the given session ID.
    func isReminderScheduled(for sessionId: String) async -> Bool {
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return pending.contains { $0.identifier == "game_\(sessionId)" }
    }
}

import UserNotifications
import Observation
import UIKit

// MARK: - LocalNotificationService

/// Manages local UNUserNotification-based game reminders.
/// Use `LocalNotificationService.shared` as the singleton entry point.
@Observable
final class LocalNotificationService {

    // MARK: Singleton

    static let shared = LocalNotificationService()
    private init() {}

    // MARK: Published State

    /// Session IDs that currently have at least one pending reminder.
    var scheduledReminders: [String] = []

    /// Whether the user has granted notification authorization.
    var isAuthorized: Bool = false

    /// Set to true when permission was explicitly denied — callers can show an alert.
    var showDeniedAlert: Bool = false

    // MARK: - Authorization

    /// Requests notification permission. Returns `true` if granted.
    @discardableResult
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            isAuthorized = true
            return true

        case .notDetermined:
            let granted = (try? await center.requestAuthorization(
                options: [.alert, .badge, .sound]
            )) ?? false
            isAuthorized = granted
            if !granted { showDeniedAlert = true }
            return granted

        case .denied:
            isAuthorized = false
            showDeniedAlert = true
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Schedule Game Reminder

    /// Schedules a local notification `minutesBefore` minutes before the session starts.
    /// Also schedules any sub-reminders (paddle bag, leaving, warm-up) if enabled.
    func scheduleGameReminder(
        session: GameSession,
        minutesBefore: Int,
        remindPackBag: Bool = false,
        remindLeave: Bool = false,
        remindWarmUp: Bool = false
    ) async {
        // Require valid fire date in the future
        let fireDate = session.dateTime.addingTimeInterval(-Double(minutesBefore) * 60)
        guard fireDate > Date() else { return }

        let center = UNUserNotificationCenter.current()

        // --- Primary game reminder ---
        let content = UNMutableNotificationContent()
        content.title = "Game starting soon! 🏓"
        content.body = "Your game at \(session.courtName) starts in \(minutesBefore < 60 ? "\(minutesBefore) minutes" : minutesBefore == 60 ? "1 hour" : "\(minutesBefore / 60) hours")"
        content.sound = .default
        content.categoryIdentifier = "GAME_REMINDER"
        content.badge = NSNumber(value: currentBadgeCount().intValue + 1)

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationId(sessionId: session.id, tag: "main"),
            content: content,
            trigger: trigger
        )
        try? await center.add(request)

        // --- Sub-reminders (scheduled 5 min after the primary, if still before game) ---
        let subBaseDate = fireDate.addingTimeInterval(60) // 1 min after main reminder

        if remindPackBag {
            await scheduleSubReminder(
                sessionId: session.id,
                tag: "bag",
                title: "Pack your paddle bag 🎒",
                body: "Don't forget your paddle, balls, and water before heading to \(session.courtName).",
                fireDate: subBaseDate,
                center: center
            )
        }

        if remindLeave {
            await scheduleSubReminder(
                sessionId: session.id,
                tag: "leave",
                title: "Time to head out! 🚗",
                body: "Leave for \(session.courtName) so you arrive on time.",
                fireDate: subBaseDate.addingTimeInterval(60),
                center: center
            )
        }

        if remindWarmUp {
            await scheduleSubReminder(
                sessionId: session.id,
                tag: "warmup",
                title: "Warm-up stretches 🧘",
                body: "Get loose before your game at \(session.courtName).",
                fireDate: subBaseDate.addingTimeInterval(120),
                center: center
            )
        }

        // Update tracked list
        await refreshScheduledReminders()
    }

    // MARK: - Cancel Reminder

    /// Cancels all pending notifications (main + sub-reminders) for a session.
    func cancelReminder(sessionId: String) {
        let ids = [
            notificationId(sessionId: sessionId, tag: "main"),
            notificationId(sessionId: sessionId, tag: "bag"),
            notificationId(sessionId: sessionId, tag: "leave"),
            notificationId(sessionId: sessionId, tag: "warmup"),
        ]
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ids)

        scheduledReminders.removeAll { $0 == sessionId }
    }

    // MARK: - Query

    /// Returns `true` if a main reminder is pending for the given session ID.
    func isReminderScheduled(for sessionId: String) async -> Bool {
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return pending.contains {
            $0.identifier == notificationId(sessionId: sessionId, tag: "main")
        }
    }

    /// Refreshes the `scheduledReminders` list from UNUserNotificationCenter.
    func refreshScheduledReminders() async {
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let sessionIds = pending
            .compactMap { request -> String? in
                // Identifiers have format: "localreminder_<sessionId>_main"
                guard request.identifier.hasPrefix("localreminder_"),
                      request.identifier.hasSuffix("_main") else { return nil }
                let stripped = request.identifier
                    .replacingOccurrences(of: "localreminder_", with: "")
                    .replacingOccurrences(of: "_main", with: "")
                return stripped
            }
        scheduledReminders = sessionIds
    }

    // MARK: - Helpers

    private func notificationId(sessionId: String, tag: String) -> String {
        "localreminder_\(sessionId)_\(tag)"
    }

    private func currentBadgeCount() -> NSNumber {
        // Badge management: read current app badge count
        // On iOS 17+ UIApplication.shared.applicationIconBadgeNumber is deprecated;
        // we use a simple persisted counter via UserDefaults.
        let count = UserDefaults.standard.integer(forKey: "dinkr.badgeCount")
        UserDefaults.standard.set(count + 1, forKey: "dinkr.badgeCount")
        return NSNumber(value: count + 1)
    }

    private func scheduleSubReminder(
        sessionId: String,
        tag: String,
        title: String,
        body: String,
        fireDate: Date,
        center: UNUserNotificationCenter
    ) async {
        guard fireDate > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "GAME_REMINDER"
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationId(sessionId: sessionId, tag: tag),
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }
}

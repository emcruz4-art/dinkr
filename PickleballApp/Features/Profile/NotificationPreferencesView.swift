import SwiftUI
import UserNotifications

// MARK: - Notification Preferences View

struct NotificationPreferencesView: View {

    // MARK: Master Toggle
    @AppStorage("notif.master.pushEnabled") private var pushEnabled = true

    // MARK: Games
    @AppStorage("notif.games.invites")        private var gameInvites = true
    @AppStorage("notif.games.rsvpReminder")   private var rsvpReminder = true
    @AppStorage("notif.games.rsvpHour")       private var rsvpHoursBefore: Double = 1.0
    @AppStorage("notif.games.startingSoon")   private var gameStartingSoon = true
    @AppStorage("notif.games.nearYou")        private var newGameNearYou = false
    @AppStorage("notif.games.waitlist")       private var waitlistSpot = true

    // MARK: Social
    @AppStorage("notif.social.followers")     private var newFollowers = true
    @AppStorage("notif.social.postLikes")     private var postLikes = true
    @AppStorage("notif.social.likesOnlyFollowing") private var likesOnlyFollowing = false
    @AppStorage("notif.social.comments")      private var comments = true
    @AppStorage("notif.social.groupActivity") private var groupActivity = true
    @AppStorage("notif.social.challenges")    private var challengeUpdates = true

    // MARK: Tournaments & Events
    @AppStorage("notif.events.regConfirm")    private var registrationConfirm = true
    @AppStorage("notif.events.bracket")       private var bracketUpdates = true
    @AppStorage("notif.events.reminders")     private var eventReminders = true

    // MARK: System
    @AppStorage("notif.system.tips")          private var tipsUpdates = false
    @AppStorage("notif.system.weeklySummary") private var weeklySummary = false

    // MARK: Local state
    @State private var showRsvpTimePicker = false
    @State private var testNotificationScheduled = false

    // MARK: Computed

    private var enabledCount: Int {
        guard pushEnabled else { return 0 }
        return [
            gameInvites, rsvpReminder, gameStartingSoon, newGameNearYou, waitlistSpot,
            newFollowers, postLikes, comments, groupActivity, challengeUpdates,
            registrationConfirm, bracketUpdates, eventReminders,
            tipsUpdates, weeklySummary
        ].filter { $0 }.count
    }

    private var rsvpReminderLabel: String {
        let hours = Int(rsvpHoursBefore)
        if hours == 1 { return "1 hour before" }
        return "\(hours) hours before"
    }

    // MARK: Body

    var body: some View {
        List {
            masterSection
            if !pushEnabled {
                settingsBannerSection
            }
            if pushEnabled {
                gamesSection
                socialSection
                tournamentsSection
                systemSection
                testSection
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("\(enabledCount) enabled")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }
        }
    }

    // MARK: - Master Section

    private var masterSection: some View {
        Section {
            Toggle(isOn: $pushEnabled) {
                NotifRow(icon: "bell.badge.fill", iconColor: Color.dinkrGreen, title: "Push Notifications")
            }
            .tint(Color.dinkrGreen)
        } footer: {
            Text("Control all push notifications from Dinkr. Individual preferences are only active when push is enabled.")
        }
    }

    // MARK: - Settings Deep Link Banner

    private var settingsBannerSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "bell.slash.fill")
                    .foregroundStyle(Color.dinkrSky)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Notifications are off")
                        .font(.subheadline.weight(.semibold))
                    Text("Enable push notifications in iOS Settings to receive Dinkr alerts.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.dinkrSky)
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
            .listRowBackground(Color.dinkrSky.opacity(0.08))
        }
    }

    // MARK: - Games Section

    private var gamesSection: some View {
        Section("Games") {
            Toggle(isOn: $gameInvites) {
                NotifRow(icon: "envelope.badge", iconColor: Color.dinkrGreen, title: "Game Invites")
            }
            .tint(Color.dinkrGreen)

            Toggle(isOn: $rsvpReminder) {
                NotifRow(icon: "clock.badge", iconColor: Color.dinkrSky, title: "RSVP Reminders")
            }
            .tint(Color.dinkrGreen)

            if rsvpReminder {
                DisclosureGroup(isExpanded: $showRsvpTimePicker) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reminder Time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Hours before", selection: $rsvpHoursBefore) {
                            Text("30 min before").tag(0.5)
                            Text("1 hour before").tag(1.0)
                            Text("2 hours before").tag(2.0)
                            Text("3 hours before").tag(3.0)
                            Text("6 hours before").tag(6.0)
                            Text("12 hours before").tag(12.0)
                            Text("24 hours before").tag(24.0)
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                    .padding(.vertical, 4)
                } label: {
                    HStack {
                        Image(systemName: "timer")
                            .frame(width: 18)
                            .foregroundStyle(.secondary)
                        Text("Reminder timing")
                            .font(.subheadline)
                        Spacer()
                        Text(rsvpReminderLabel)
                            .font(.subheadline)
                            .foregroundStyle(Color.dinkrGreen)
                    }
                    .padding(.leading, 4)
                }
            }

            Toggle(isOn: $gameStartingSoon) {
                NotifRow(icon: "flag.checkered", iconColor: Color.dinkrGreen, title: "Game Starting Soon")
            }
            .tint(Color.dinkrGreen)

            Toggle(isOn: $newGameNearYou) {
                NotifRow(icon: "location.circle", iconColor: Color.dinkrSky, title: "New Game Near You")
            }
            .tint(Color.dinkrGreen)

            Toggle(isOn: $waitlistSpot) {
                NotifRow(icon: "list.number", iconColor: Color.dinkrAmber, title: "Waitlist Spot Available")
            }
            .tint(Color.dinkrGreen)
        }
    }

    // MARK: - Social Section

    private var socialSection: some View {
        Section("Social") {
            Toggle(isOn: $newFollowers) {
                NotifRow(icon: "person.badge.plus", iconColor: Color.dinkrSky, title: "New Followers")
            }
            .tint(Color.dinkrGreen)

            Toggle(isOn: $postLikes) {
                NotifRow(icon: "heart", iconColor: Color.dinkrCoral, title: "Post Likes")
            }
            .tint(Color.dinkrGreen)

            if postLikes {
                Toggle(isOn: $likesOnlyFollowing) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .frame(width: 18)
                            .foregroundStyle(.secondary)
                        Text("Only from people I follow")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 4)
                }
                .tint(Color.dinkrGreen)
            }

            Toggle(isOn: $comments) {
                NotifRow(icon: "bubble.left", iconColor: Color.dinkrSky, title: "Comments on Your Posts")
            }
            .tint(Color.dinkrGreen)

            Toggle(isOn: $groupActivity) {
                NotifRow(icon: "person.3", iconColor: Color.dinkrNavy, title: "DinkrGroup Activity")
            }
            .tint(Color.dinkrGreen)

            Toggle(isOn: $challengeUpdates) {
                NotifRow(icon: "bolt.horizontal", iconColor: Color.dinkrAmber, title: "Challenge Updates")
            }
            .tint(Color.dinkrGreen)
        }
    }

    // MARK: - Tournaments & Events Section

    private var tournamentsSection: some View {
        Section("Tournaments & Events") {
            HStack {
                NotifRow(icon: "checkmark.seal.fill", iconColor: Color.dinkrGreen, title: "Registration Confirmations")
                Spacer()
                Text("Always On")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .opacity(0.6)

            Toggle(isOn: $bracketUpdates) {
                NotifRow(icon: "trophy", iconColor: Color.dinkrAmber, title: "Tournament Bracket Updates")
            }
            .tint(Color.dinkrGreen)

            Toggle(isOn: $eventReminders) {
                NotifRow(icon: "calendar.badge.clock", iconColor: Color.dinkrSky, title: "Event Reminders")
            }
            .tint(Color.dinkrGreen)
        }
    }

    // MARK: - System Section

    private var systemSection: some View {
        Section(
            header: Text("System"),
            footer: Text("Weekly summary is sent every Monday morning with your recent activity, stats, and nearby games.")
        ) {
            Toggle(isOn: $tipsUpdates) {
                NotifRow(icon: "lightbulb", iconColor: .secondary, title: "Dinkr Tips & Updates")
            }
            .tint(Color.dinkrGreen)

            Toggle(isOn: $weeklySummary) {
                NotifRow(icon: "envelope.open", iconColor: Color.dinkrNavy, title: "Weekly Summary Email")
            }
            .tint(Color.dinkrGreen)
        }
    }

    // MARK: - Test Notification Section

    private var testSection: some View {
        Section {
            Button {
                scheduleTestNotification()
            } label: {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.dinkrGreen.opacity(0.15))
                            .frame(width: 30, height: 30)
                        Image(systemName: testNotificationScheduled ? "checkmark.circle.fill" : "bell.and.waves.left.and.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(testNotificationScheduled ? Color.dinkrGreen : Color.dinkrGreen)
                    }
                    Text(testNotificationScheduled ? "Notification Scheduled!" : "Test Notification")
                        .foregroundStyle(testNotificationScheduled ? .secondary : .primary)
                    Spacer()
                    if !testNotificationScheduled {
                        Text("3 sec delay")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(testNotificationScheduled)
        } footer: {
            Text("Sends a sample Dinkr notification after 3 seconds so you can verify your device settings.")
        }
    }

    // MARK: - Test Notification Logic

    private func scheduleTestNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = "Dinkr"
            content.body = "Dink dink! Your notifications are working perfectly. See you on the court!"
            content.sound = .default
            content.badge = 1

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
            let request = UNNotificationRequest(identifier: "dinkr.test.\(UUID().uuidString)", content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { _ in
                DispatchQueue.main.async {
                    withAnimation {
                        testNotificationScheduled = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation {
                            testNotificationScheduled = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - NotifRow Component

private struct NotifRow: View {
    let icon: String
    let iconColor: Color
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            Text(title)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationPreferencesView()
    }
}

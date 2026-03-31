import SwiftUI

// MARK: - Filter Enum

enum NotifFilter: String, CaseIterable {
    case all    = "All"
    case games  = "Games"
    case social = "Social"
    case system = "System"

    func matches(_ notification: DinkrNotification) -> Bool {
        switch self {
        case .all:    return true
        case .games:  return [.gameInvite, .playerRequest, .gameReminder,
                               .attendanceConfirmation, .noShowReported,
                               .challengeReceived, .challengeCompleted,
                               .newChallenger].contains(notification.type)
        case .social: return [.kudos, .newFollower, .groupActivity].contains(notification.type)
        case .system: return [.achievementUnlocked, .tournamentUpdate].contains(notification.type)
        }
    }
}

// MARK: - ViewModel

@MainActor
final class NotificationCenterViewModel: ObservableObject {
    @Published var notifications: [DinkrNotification]
    @Published var selectedFilter: NotifFilter = .all
    @Published var isRefreshing = false

    init() {
        // Extend mock set with extra types required by spec
        var base = DinkrNotification.mockNotifications
        // attendance confirmation
        base.append(DinkrNotification(
            id: "notif_011", type: .attendanceConfirmation,
            fromUserId: "system", fromUserName: "Dinkr",
            title: "Attendance Check", body: "Your game at Mueller ended. Confirm who showed up to keep scores accurate.",
            receivedAt: Date().addingTimeInterval(-5400), isRead: false, actionTarget: "gs2"))
        // no-show reported
        base.append(DinkrNotification(
            id: "notif_012", type: .noShowReported,
            fromUserId: "user_010", fromUserName: "Alex Rivera",
            title: "No-Show Reported", body: "Alex Rivera reported you as a no-show for the 7am game at Dove Springs. Dispute if incorrect.",
            receivedAt: Date().addingTimeInterval(-21600), isRead: false, actionTarget: "gs3"))
        // community spotlight (groupActivity)
        base.append(DinkrNotification(
            id: "notif_013", type: .groupActivity,
            fromUserId: "user_011", fromUserName: "Dinkr Community",
            title: "Community Spotlight 🌟", body: "You've been featured in this week's Community Spotlight for your 12-game win streak!",
            receivedAt: Date().addingTimeInterval(-43200), isRead: true, actionTarget: nil))
        // group challenge
        base.append(DinkrNotification(
            id: "notif_014", type: .challengeReceived,
            fromUserId: "user_012", fromUserName: "S. Austin Crew",
            title: "Group Challenge Incoming 🏆", body: "S. Austin Crew has challenged your group to a weekend showdown. Accept before Friday.",
            receivedAt: Date().addingTimeInterval(-57600), isRead: false, actionTarget: "ch_002"))
        self.notifications = base.sorted { $0.receivedAt > $1.receivedAt }
    }

    var unreadCount: Int { notifications.filter { !$0.isRead }.count }

    var filteredNotifications: [DinkrNotification] {
        notifications.filter { selectedFilter.matches($0) }
    }

    var todayNotifications: [DinkrNotification] {
        filteredNotifications.filter { Calendar.current.isDateInToday($0.receivedAt) }
    }

    var earlierNotifications: [DinkrNotification] {
        filteredNotifications.filter { !Calendar.current.isDateInToday($0.receivedAt) }
    }

    func markAllRead() {
        for i in notifications.indices {
            notifications[i].isRead = true
        }
    }

    func markRead(id: String) {
        if let idx = notifications.firstIndex(where: { $0.id == id }) {
            notifications[idx].isRead = true
        }
    }

    func delete(id: String) {
        notifications.removeAll { $0.id == id }
    }

    func refresh() async {
        isRefreshing = true
        try? await Task.sleep(nanoseconds: 800_000_000)
        isRefreshing = false
    }
}

// MARK: - Main View

struct NotificationCenterView: View {
    @StateObject private var vm = NotificationCenterViewModel()
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                Divider()
                notificationList
            }
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .background(Color.appBackground)
        }
        .onAppear { appeared = true }
    }

    // MARK: Title

    private var titleText: String {
        let count = vm.unreadCount
        return count > 0 ? "Notifications (\(count))" : "Notifications"
    }

    // MARK: Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(NotifFilter.allCases, id: \.self) { filter in
                    filterChip(filter)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func filterChip(_ filter: NotifFilter) -> some View {
        Text(filter.rawValue)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(vm.selectedFilter == filter ? .white : Color.dinkrGreen)
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(vm.selectedFilter == filter ? Color.dinkrGreen : Color.dinkrGreen.opacity(0.12))
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    vm.selectedFilter = filter
                }
            }
    }

    // MARK: Notification List

    @ViewBuilder
    private var notificationList: some View {
        if vm.filteredNotifications.isEmpty {
            emptyState
        } else {
            List {
                if !vm.todayNotifications.isEmpty {
                    Section("Today") {
                        ForEach(Array(vm.todayNotifications.enumerated()), id: \.element.id) { index, notif in
                            notifRow(notif, index: index)
                        }
                    }
                }
                if !vm.earlierNotifications.isEmpty {
                    Section("Earlier") {
                        ForEach(Array(vm.earlierNotifications.enumerated()), id: \.element.id) { index, notif in
                            notifRow(notif, index: index + vm.todayNotifications.count)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable {
                await vm.refresh()
            }
        }
    }

    private func notifRow(_ notif: DinkrNotification, index: Int) -> some View {
        NotificationRow(notification: notif) {
            vm.markRead(id: notif.id)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation {
                    vm.delete(id: notif.id)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : 24)
        .animation(
            .spring(response: 0.45, dampingFraction: 0.82)
                .delay(Double(index) * 0.04),
            value: appeared
        )
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bell.slash")
                .font(.system(size: 52))
                .foregroundStyle(Color.dinkrGreen.opacity(0.4))
            Text("No \(vm.selectedFilter.rawValue) Notifications")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("You're all caught up.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if vm.unreadCount > 0 {
                Button {
                    withAnimation {
                        vm.markAllRead()
                    }
                } label: {
                    Text("Mark All Read")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
    }
}

// MARK: - NotificationRow

struct NotificationRow: View {
    let notification: DinkrNotification
    let onTap: () -> Void

    private var accentColor: Color {
        let name = notification.accentColor
        switch name {
        case "dinkrGreen":  return Color.dinkrGreen
        case "dinkrCoral":  return Color.dinkrCoral
        case "dinkrSky":    return Color.dinkrSky
        case "dinkrAmber":  return Color.dinkrAmber
        case "dinkrNavy":   return Color.dinkrNavy
        default:            return Color.dinkrGreen
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                iconCircle
                textStack
                Spacer(minLength: 8)
                trailingArea
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                notification.isRead
                    ? Color.clear
                    : Color.dinkrGreen.opacity(0.05)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Sub-views

    private var iconCircle: some View {
        ZStack {
            Circle()
                .fill(accentColor.opacity(0.15))
                .frame(width: 46, height: 46)
            Image(systemName: notification.iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(accentColor)
        }
    }

    private var textStack: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(notification.title)
                .font(.subheadline.weight(notification.isRead ? .regular : .bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text(notification.body)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(timestampLabel(for: notification.receivedAt))
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 1)
        }
    }

    private var trailingArea: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 9, height: 9)
            }
            Spacer(minLength: 0)
        }
        .frame(height: 46)
    }

    // MARK: Timestamp helper

    private func timestampLabel(for date: Date) -> String {
        let now = Date()
        let seconds = now.timeIntervalSince(date)
        let minutes = seconds / 60
        let hours   = minutes / 60

        if seconds < 60  { return "Just now" }
        if minutes < 60  { return "\(Int(minutes))m ago" }
        if hours < 24    { return "\(Int(hours))h ago" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    NotificationCenterView()
}

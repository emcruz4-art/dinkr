import SwiftUI

// MARK: - Filter Enum

enum NotifFilter: String, CaseIterable {
    case all    = "All"
    case games  = "Games"
    case social = "Social"
    case system = "System"

    func matches(_ notification: DinkrNotification) -> Bool {
        switch self {
        case .all: return true
        case .games:
            return [
                .gameInvite, .gameReminder, .rsvpConfirmed, .gameResult,
                .playerRequest, .attendanceConfirmation, .noShowReported,
                .matchChallenge, .challengeReceived, .challengeCompleted, .newChallenger
            ].contains(notification.type)
        case .social:
            return [
                .kudos, .newFollower, .friendRequest, .newMessage,
                .groupActivity, .groupInvite
            ].contains(notification.type)
        case .system:
            return [
                .achievementUnlocked, .tournamentUpdate, .newListing
            ].contains(notification.type)
        }
    }
}

// MARK: - Grouped Notification

/// Wraps one or more notifications that share the same groupKey (collapsed group)
/// or a single notification without a groupKey.
struct NotifGroup: Identifiable {
    let id: String          // stable identifier
    var items: [DinkrNotification]
    var isExpanded: Bool = false

    var representative: DinkrNotification { items[0] }
    var isGrouped: Bool { items.count > 1 }
    var hasUnread: Bool { items.contains { !$0.isRead } }

    var collapsedSummary: String {
        let count = items.count
        let senders = Array(Set(items.map { $0.fromUserName })).prefix(2).joined(separator: ", ")
        return "\(count) new messages from \(senders)"
    }
}

// MARK: - ViewModel

@MainActor
final class NotificationCenterViewModel: ObservableObject {
    @Published var notifications: [DinkrNotification]
    @Published var selectedFilter: NotifFilter = .all
    @Published var isRefreshing = false
    @Published var expandedGroups: Set<String> = []

    init() {
        let base = DinkrNotification.mockNotifications
        self.notifications = base.sorted { $0.receivedAt > $1.receivedAt }
    }

    // MARK: Derived

    var unreadCount: Int { notifications.filter { !$0.isRead }.count }

    var filteredNotifications: [DinkrNotification] {
        notifications.filter { selectedFilter.matches($0) }
    }

    /// Build collapsed groups, preserving sort order.
    func buildGroups(from items: [DinkrNotification]) -> [NotifGroup] {
        var grouped: [String: [DinkrNotification]] = [:]
        var order: [String] = []

        for notif in items {
            let key = notif.groupKey ?? notif.id
            if grouped[key] == nil {
                grouped[key] = []
                order.append(key)
            }
            grouped[key]!.append(notif)
        }

        return order.compactMap { key -> NotifGroup? in
            guard let group = grouped[key] else { return nil }
            let expanded = expandedGroups.contains(key)
            return NotifGroup(id: key, items: group, isExpanded: expanded)
        }
    }

    var todayGroups: [NotifGroup] {
        let today = filteredNotifications.filter { Calendar.current.isDateInToday($0.receivedAt) }
        return buildGroups(from: today)
    }

    var earlierGroups: [NotifGroup] {
        let earlier = filteredNotifications.filter { !Calendar.current.isDateInToday($0.receivedAt) }
        return buildGroups(from: earlier)
    }

    // MARK: Actions

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

    func markGroupRead(groupKey: String) {
        for i in notifications.indices {
            let key = notifications[i].groupKey ?? notifications[i].id
            if key == groupKey {
                notifications[i].isRead = true
            }
        }
    }

    func delete(id: String) {
        withAnimation {
            notifications.removeAll { $0.id == id }
        }
    }

    func deleteGroup(groupKey: String) {
        withAnimation {
            notifications.removeAll { ($0.groupKey ?? $0.id) == groupKey }
        }
    }

    func mute(id: String) {
        if let idx = notifications.firstIndex(where: { $0.id == id }) {
            notifications[idx].isMuted = true
            notifications[idx].isRead = true
        }
    }

    func resolveAction(id: String) {
        if let idx = notifications.firstIndex(where: { $0.id == id }) {
            notifications[idx].pendingActionResolved = true
            notifications[idx].isRead = true
        }
    }

    func toggleExpanded(groupId: String) {
        if expandedGroups.contains(groupId) {
            expandedGroups.remove(groupId)
        } else {
            expandedGroups.insert(groupId)
        }
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
    @State private var showPreferences = false

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
            .navigationDestination(isPresented: $showPreferences) {
                NotificationPreferencesView()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                appeared = true
            }
        }
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
                    .fill(vm.selectedFilter == filter
                          ? Color.dinkrGreen
                          : Color.dinkrGreen.opacity(0.12))
            )
            .onTapGesture {
                HapticManager.selection()
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
                if !vm.todayGroups.isEmpty {
                    Section("Today") {
                        ForEach(Array(vm.todayGroups.enumerated()), id: \.element.id) { idx, group in
                            groupRow(group, index: idx)
                        }
                    }
                }
                if !vm.earlierGroups.isEmpty {
                    Section("Earlier") {
                        ForEach(Array(vm.earlierGroups.enumerated()), id: \.element.id) { idx, group in
                            groupRow(group, index: idx + vm.todayGroups.count)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable { await vm.refresh() }
        }
    }

    // MARK: DinkrGroup Row dispatcher

    @ViewBuilder
    private func groupRow(_ group: NotifGroup, index: Int) -> some View {
        if group.isGrouped {
            collapsedGroupRow(group)
                .rowStyle(appeared: appeared, index: index)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    deleteGroupButton(groupId: group.id)
                }
                .swipeActions(edge: .leading) {
                    markGroupReadButton(groupId: group.id)
                }
        } else {
            let notif = group.representative
            NotificationRow(notification: notif, onTap: {
                vm.markRead(id: notif.id)
            }, onResolve: {
                vm.resolveAction(id: notif.id)
            })
            .rowStyle(appeared: appeared, index: index)
            .animation(.easeInOut(duration: 0.3), value: notif.isRead)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                deleteButton(id: notif.id)
                muteButton(id: notif.id)
            }
            .swipeActions(edge: .leading) {
                markReadButton(id: notif.id, isRead: notif.isRead)
            }
        }
    }

    // MARK: Collapsed DinkrGroup Row

    private func collapsedGroupRow(_ group: NotifGroup) -> some View {
        let isExpanded = vm.expandedGroups.contains(group.id)
        return VStack(spacing: 0) {
            // Header tap area
            Button {
                HapticManager.light()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    vm.toggleExpanded(groupId: group.id)
                }
            } label: {
                HStack(alignment: .center, spacing: 14) {
                    groupIconCircle(group.representative)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(group.representative.title)
                            .font(.subheadline.weight(group.hasUnread ? .bold : .regular))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(group.collapsedSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    HStack(spacing: 6) {
                        if group.hasUnread {
                            Circle()
                                .fill(Color.dinkrGreen)
                                .frame(width: 9, height: 9)
                        }
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(group.hasUnread ? Color.dinkrGreen.opacity(0.05) : Color.clear)
            }
            .buttonStyle(.plain)

            // Expanded sub-rows
            if isExpanded {
                Divider().padding(.leading, 76)
                ForEach(group.items) { notif in
                    NotificationRow(
                        notification: notif,
                        onTap: { vm.markRead(id: notif.id) },
                        onResolve: { vm.resolveAction(id: notif.id) },
                        isCompact: true
                    )
                    .padding(.leading, 30)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private func groupIconCircle(_ notif: DinkrNotification) -> some View {
        let color = accentColor(for: notif)
        return ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 46, height: 46)
            Image(systemName: notif.iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(color)
        }
    }

    // MARK: Swipe Action Buttons

    private func deleteButton(id: String) -> some View {
        Button(role: .destructive) {
            HapticManager.heavy()
            vm.delete(id: id)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func muteButton(id: String) -> some View {
        Button {
            HapticManager.medium()
            vm.mute(id: id)
        } label: {
            Label("Mute", systemImage: "bell.slash.fill")
        }
        .tint(Color.dinkrAmber)
    }

    private func markReadButton(id: String, isRead: Bool) -> some View {
        Button {
            HapticManager.light()
            if isRead {
                // no-op — already read, button still shown for consistency
            } else {
                vm.markRead(id: id)
            }
        } label: {
            Label(isRead ? "Read" : "Mark Read", systemImage: isRead ? "envelope.open" : "envelope.badge")
        }
        .tint(Color.dinkrSky)
        .disabled(isRead)
    }

    private func deleteGroupButton(groupId: String) -> some View {
        Button(role: .destructive) {
            HapticManager.heavy()
            vm.deleteGroup(groupKey: groupId)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func markGroupReadButton(groupId: String) -> some View {
        Button {
            HapticManager.light()
            vm.markGroupRead(groupKey: groupId)
        } label: {
            Label("Mark Read", systemImage: "envelope.badge")
        }
        .tint(Color.dinkrSky)
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
                    HapticManager.success()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        vm.markAllRead()
                    }
                } label: {
                    Text("Mark All Read")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                HapticManager.light()
                showPreferences = true
            } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(Color.dinkrGreen)
            }
        }
    }

    // MARK: Accent color helper

    private func accentColor(for notif: DinkrNotification) -> Color {
        switch notif.accentColor {
        case "dinkrGreen":  return Color.dinkrGreen
        case "dinkrCoral":  return Color.dinkrCoral
        case "dinkrSky":    return Color.dinkrSky
        case "dinkrAmber":  return Color.dinkrAmber
        case "dinkrNavy":   return Color.dinkrNavy
        default:            return Color.dinkrGreen
        }
    }
}

// MARK: - Row Style Modifier

private extension View {
    func rowStyle(appeared: Bool, index: Int) -> some View {
        self
            .listRowInsets(EdgeInsets())
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
}

// MARK: - NotificationRow

struct NotificationRow: View {
    let notification: DinkrNotification
    let onTap: () -> Void
    let onResolve: () -> Void
    var isCompact: Bool = false

    private var accentColor: Color {
        switch notification.accentColor {
        case "dinkrGreen":  return Color.dinkrGreen
        case "dinkrCoral":  return Color.dinkrCoral
        case "dinkrSky":    return Color.dinkrSky
        case "dinkrAmber":  return Color.dinkrAmber
        case "dinkrNavy":   return Color.dinkrNavy
        default:            return Color.dinkrGreen
        }
    }

    private var showActionButtons: Bool {
        notification.actionKind != .none && !notification.pendingActionResolved
    }

    var body: some View {
        Button(action: { onTap() }) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 14) {
                    iconArea
                    contentStack
                    Spacer(minLength: 8)
                    trailingDot
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, showActionButtons ? 8 : 12)

                if showActionButtons {
                    actionButtonRow
                        .padding(.leading, isCompact ? 46 : 76)
                        .padding(.trailing, 16)
                        .padding(.bottom, 12)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .background(
                notification.isRead
                    ? Color.clear
                    : Color.dinkrGreen.opacity(0.05)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Icon area — avatar initials for social, icon circle for system

    @ViewBuilder
    private var iconArea: some View {
        let circleSize: CGFloat = isCompact ? 36 : 46
        let fontSize: CGFloat = isCompact ? 14 : 18

        if notification.type == .newMessage ||
           notification.type == .friendRequest ||
           notification.type == .groupInvite ||
           notification.type == .matchChallenge ||
           notification.type == .playerRequest ||
           notification.type == .kudos ||
           notification.type == .newFollower {
            // Avatar circle with initials
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.18))
                    .frame(width: circleSize, height: circleSize)
                Text(notification.avatarInitials)
                    .font(.system(size: fontSize * 0.65, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
            }
        } else {
            // System icon circle
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: circleSize, height: circleSize)
                Image(systemName: notification.iconName)
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundStyle(accentColor)
            }
        }
    }

    // MARK: Content stack

    private var contentStack: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(notification.title)
                .font(.subheadline.weight(notification.isRead ? .regular : .bold))
                .foregroundStyle(.primary)
                .lineLimit(isCompact ? 1 : 2)
                .fixedSize(horizontal: false, vertical: true)

            Text(notification.body)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Court chip for game reminders
            if let court = notification.courtName, notification.type == .gameReminder {
                courtChip(court)
                    .padding(.top, 4)
            }

            Text(relativeTimestamp(for: notification.receivedAt))
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
    }

    private func courtChip(_ name: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "mappin.circle.fill")
                .font(.caption2)
                .foregroundStyle(Color.dinkrAmber)
            Text(name)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.dinkrAmber)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.dinkrAmber.opacity(0.12), in: Capsule())
    }

    // MARK: Trailing unread dot

    private var trailingDot: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if !notification.isRead {
                Circle()
                    .fill(Color.dinkrGreen)
                    .frame(width: 9, height: 9)
            }
            Spacer(minLength: 0)
        }
        .frame(height: isCompact ? 36 : 46)
    }

    // MARK: Inline action buttons

    @ViewBuilder
    private var actionButtonRow: some View {
        switch notification.actionKind {
        case .acceptDecline:
            actionPair(
                primary: ("checkmark", "Accept", Color.dinkrGreen),
                secondary: ("xmark", "Decline", Color.dinkrCoral)
            )
        case .acceptView:
            actionPair(
                primary: ("bolt.fill", "Accept", Color.dinkrGreen),
                secondary: ("eye", "View", Color.dinkrSky)
            )
        case .viewBadge:
            singleAction(icon: "trophy.fill", label: "View Badge", color: Color.dinkrAmber)
        case .viewResult:
            singleAction(icon: "chart.line.uptrend.xyaxis", label: "View Result", color: Color.dinkrSky)
        case .viewCourt:
            singleAction(icon: "mappin.circle.fill", label: "Get Directions", color: Color.dinkrAmber)
        case .none:
            EmptyView()
        }
    }

    private func actionPair(
        primary: (String, String, Color),
        secondary: (String, String, Color)
    ) -> some View {
        HStack(spacing: 10) {
            actionButton(icon: primary.0, label: primary.1, color: primary.2, filled: true)
            actionButton(icon: secondary.0, label: secondary.1, color: secondary.2, filled: false)
            Spacer()
        }
    }

    private func singleAction(icon: String, label: String, color: Color) -> some View {
        HStack {
            actionButton(icon: icon, label: label, color: color, filled: false)
            Spacer()
        }
    }

    private func actionButton(icon: String, label: String, color: Color, filled: Bool) -> some View {
        Button {
            HapticManager.medium()
            onResolve()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                Text(label)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(filled ? .white : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(filled ? color : color.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Relative timestamp

    private func relativeTimestamp(for date: Date) -> String {
        let now = Date()
        let seconds = now.timeIntervalSince(date)
        let minutes = seconds / 60
        let hours   = minutes / 60

        if seconds < 60  { return "Just now" }
        if minutes < 60  { return "\(Int(minutes))m ago" }
        if hours   < 24  { return "\(Int(hours))h ago" }
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

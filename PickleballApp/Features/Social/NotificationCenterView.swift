import SwiftUI

struct NotificationCenterView: View {
    @State private var notifications = DinkrNotification.mockNotifications
    @State private var selectedFilter: NotifFilter = .all

    enum NotifFilter: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
        case invites = "Invites"
        case social = "Social"
    }

    var filteredNotifs: [DinkrNotification] {
        switch selectedFilter {
        case .all: return notifications
        case .unread: return notifications.filter { !$0.isRead }
        case .invites: return notifications.filter { $0.type == .gameInvite || $0.type == .playerRequest }
        case .social: return notifications.filter { $0.type == .kudos || $0.type == .newFollower || $0.type == .groupActivity }
        }
    }

    var unreadCount: Int { notifications.filter { !$0.isRead }.count }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(NotifFilter.allCases, id: \.self) { filter in
                            HStack(spacing: 4) {
                                Text(filter.rawValue)
                                    .font(.caption.weight(.semibold))
                                if filter == .unread && unreadCount > 0 {
                                    Text("\(unreadCount)")
                                        .font(.system(size: 9, weight: .heavy))
                                        .foregroundStyle(.white)
                                        .frame(width: 16, height: 16)
                                        .background(Color.dinkrCoral)
                                        .clipShape(Circle())
                                }
                            }
                            .foregroundStyle(selectedFilter == filter ? .white : Color.dinkrGreen)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(selectedFilter == filter ? Color.dinkrGreen : Color.dinkrGreen.opacity(0.12))
                            .clipShape(Capsule())
                            .onTapGesture { selectedFilter = filter }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                Divider()

                // Mark all read button
                if unreadCount > 0 {
                    HStack {
                        Spacer()
                        Button("Mark all read") {
                            for i in notifications.indices {
                                notifications[i].isRead = true
                            }
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                    }
                    Divider()
                }

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredNotifs) { notif in
                            NotificationRow(notification: notif, onTap: {
                                if let idx = notifications.firstIndex(where: { $0.id == notif.id }) {
                                    notifications[idx].isRead = true
                                }
                            })
                            Divider().padding(.leading, 68)
                        }
                    }
                }
                .refreshable {}
            }
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: DinkrNotification
    let onTap: () -> Void

    var accentColor: Color {
        switch notification.type {
        case .gameInvite, .groupActivity: return Color.dinkrGreen
        case .kudos, .newChallenger, .tournamentUpdate: return Color.dinkrCoral
        case .newFollower, .playerRequest: return Color.dinkrSky
        case .gameReminder, .achievementUnlocked: return Color.dinkrAmber
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon with accent circle
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: notification.iconName)
                        .foregroundStyle(accentColor)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(notification.title)
                        .font(.subheadline.weight(notification.isRead ? .regular : .bold))
                        .lineLimit(1)
                    Text(notification.body)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Text(notification.receivedAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                if !notification.isRead {
                    Circle()
                        .fill(Color.dinkrGreen)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(notification.isRead ? Color.clear : Color.dinkrGreen.opacity(0.04))
        }
        .buttonStyle(.plain)
    }
}

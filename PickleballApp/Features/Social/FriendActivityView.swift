import SwiftUI

// MARK: - Models

struct ActiveFriend: Identifiable {
    let id: String
    let user: User
    let courtName: String
    let minutesAgo: Int
    let gameSessionId: String
}

struct RecentActivityItem: Identifiable {
    let id: String
    let user: User
    let activityType: FriendActivityType
    let timestamp: Date
    var highFiveCount: Int
    var hasHighFived: Bool

    var timeAgoText: String {
        let mins = Int(-timestamp.timeIntervalSinceNow / 60)
        if mins < 60 { return "\(mins)m ago" }
        let hrs = mins / 60
        if hrs < 24 { return "\(hrs)h ago" }
        return "\(hrs / 24)d ago"
    }

    var descriptionText: String {
        switch activityType {
        case .joinedGame(let courtName):
            return "\(user.displayName) joined a game at \(courtName)"
        case .wonMatch(let score):
            return "\(user.displayName) won a match \(score)"
        case .postedHighlight(let title):
            return "\(user.displayName) posted a highlight: \"\(title)\""
        }
    }

    var actionIcon: String {
        switch activityType {
        case .joinedGame:   return "figure.pickleball"
        case .wonMatch:     return "trophy.fill"
        case .postedHighlight: return "bolt.fill"
        }
    }

    var accentColor: Color {
        switch activityType {
        case .joinedGame:      return Color.dinkrGreen
        case .wonMatch:        return Color.dinkrAmber
        case .postedHighlight: return Color.dinkrCoral
        }
    }
}

enum FriendActivityType {
    case joinedGame(courtName: String)
    case wonMatch(score: String)
    case postedHighlight(title: String)
}

// MARK: - Mock Data

extension ActiveFriend {
    static let mockActive: [ActiveFriend] = [
        ActiveFriend(
            id: "af_001",
            user: User.mockPlayers[0],  // Maria Chen
            courtName: "Westside Pickleball",
            minutesAgo: 45,
            gameSessionId: "session_001"
        ),
        ActiveFriend(
            id: "af_002",
            user: User.mockPlayers[2],  // Sarah Johnson
            courtName: "Mueller Park Courts",
            minutesAgo: 12,
            gameSessionId: "session_002"
        ),
        ActiveFriend(
            id: "af_003",
            user: User.mockPlayers[4],  // Taylor Kim
            courtName: "Brushy Creek Sports",
            minutesAgo: 67,
            gameSessionId: "session_003"
        ),
    ]
}

extension RecentActivityItem {
    static let mockRecent: [RecentActivityItem] = [
        RecentActivityItem(
            id: "ra_001",
            user: User.mockPlayers[1],  // Jordan Smith
            activityType: .joinedGame(courtName: "Westside Pickleball"),
            timestamp: Date(timeIntervalSinceNow: -3600),
            highFiveCount: 4,
            hasHighFived: false
        ),
        RecentActivityItem(
            id: "ra_002",
            user: User.mockPlayers[0],  // Maria Chen
            activityType: .wonMatch(score: "11–7, 11–5"),
            timestamp: Date(timeIntervalSinceNow: -7200),
            highFiveCount: 11,
            hasHighFived: false
        ),
        RecentActivityItem(
            id: "ra_003",
            user: User.mockPlayers[6],  // Jamie Lee
            activityType: .postedHighlight(title: "That ATP though 🔥"),
            timestamp: Date(timeIntervalSinceNow: -10800),
            highFiveCount: 23,
            hasHighFived: true
        ),
        RecentActivityItem(
            id: "ra_004",
            user: User.mockPlayers[3],  // Chris Park
            activityType: .joinedGame(courtName: "Round Rock Sports Center"),
            timestamp: Date(timeIntervalSinceNow: -14400),
            highFiveCount: 2,
            hasHighFived: false
        ),
        RecentActivityItem(
            id: "ra_005",
            user: User.mockPlayers[7],  // Morgan Davis
            activityType: .wonMatch(score: "11–9, 8–11, 11–8"),
            timestamp: Date(timeIntervalSinceNow: -18000),
            highFiveCount: 7,
            hasHighFived: false
        ),
    ]
}

// MARK: - FriendActivityView

struct FriendActivityView: View {
    @State private var selectedTab = 0
    @State private var activeFriends = ActiveFriend.mockActive
    @State private var recentItems = RecentActivityItem.mockRecent
    @State private var isRefreshing = false
    @State private var showRSVP = false
    @State private var selectedSessionId: String? = nil

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Segmented control
                Picker("Activity", selection: $selectedTab) {
                    Text("Playing Now").tag(0)
                    Text("Recent").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        if selectedTab == 0 {
                            playingNowSection
                        } else {
                            recentSection
                        }
                    }
                    .padding(.bottom, 36)
                }
                .refreshable {
                    await refreshData()
                }
            }
        }
        .navigationTitle("Friend Activity")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRSVP) {
            if let sessionId = selectedSessionId,
               let session = GameSession.mockSessions.first(where: { $0.id == sessionId }) {
                QuickRSVPView(session: session, viewModel: PlayViewModel())
            }
        }
    }

    // MARK: - Playing Now

    @ViewBuilder
    private var playingNowSection: some View {
        if activeFriends.isEmpty {
            playingNowEmptyState
        } else {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader(
                    "\(activeFriends.count) friend\(activeFriends.count == 1 ? "" : "s") on court",
                    icon: "figure.pickleball"
                )
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 12)

                VStack(spacing: 10) {
                    ForEach(activeFriends) { friend in
                        ActiveFriendRow(
                            friend: friend,
                            onJoin: {
                                selectedSessionId = friend.gameSessionId
                                showRSVP = true
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var playingNowEmptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "figure.pickleball")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Color.dinkrGreen)
            }

            VStack(spacing: 8) {
                Text("No one's on court yet")
                    .font(.headline.weight(.bold))
                Text("None of your friends are playing right now. Be the first!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 72)
    }

    // MARK: - Recent

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Last 24 hours", icon: "clock.arrow.circlepath")
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                ForEach(Array(recentItems.enumerated()), id: \.element.id) { idx, item in
                    RecentActivityRow(
                        item: item,
                        onHighFive: { toggleHighFive(id: item.id) },
                        onComment: { /* navigate to post */ }
                    )

                    if idx < recentItems.count - 1 {
                        Divider()
                            .padding(.leading, 76)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.dinkrGreen)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
    }

    private func toggleHighFive(id: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if let idx = recentItems.firstIndex(where: { $0.id == id }) {
                recentItems[idx].hasHighFived.toggle()
                recentItems[idx].highFiveCount += recentItems[idx].hasHighFived ? 1 : -1
                if recentItems[idx].hasHighFived {
                    HapticManager.selection()
                }
            }
        }
    }

    private func refreshData() async {
        try? await Task.sleep(nanoseconds: 800_000_000)
        // In production: re-fetch from Firestore
    }
}

// MARK: - ActiveFriendRow

private struct ActiveFriendRow: View {
    let friend: ActiveFriend
    let onJoin: () -> Void

    @State private var pulse = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    urlString: friend.user.avatarURL,
                    displayName: friend.user.displayName,
                    size: 50
                )

                // Pulsing green dot
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen.opacity(pulse ? 0.35 : 0.0))
                        .frame(width: 18, height: 18)
                        .animation(
                            .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                            value: pulse
                        )
                    Circle()
                        .fill(Color.dinkrGreen)
                        .frame(width: 11, height: 11)
                        .overlay(
                            Circle().stroke(Color.appBackground, lineWidth: 2)
                        )
                }
                .offset(x: 2, y: 2)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(friend.user.displayName)
                    .font(.subheadline.weight(.semibold))

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.dinkrGreen)
                    Text("at \(friend.courtName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text("Started \(friend.minutesAgo)m ago")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onJoin) {
                HStack(spacing: 4) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Join them")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.dinkrGreen, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.dinkrGreen.opacity(0.2), lineWidth: 1)
        )
        .onAppear { pulse = true }
    }
}

// MARK: - RecentActivityRow

private struct RecentActivityRow: View {
    let item: RecentActivityItem
    let onHighFive: () -> Void
    let onComment: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar with activity type icon badge
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    urlString: item.user.avatarURL,
                    displayName: item.user.displayName,
                    size: 46
                )

                ZStack {
                    Circle()
                        .fill(item.accentColor)
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(Color.cardBackground, lineWidth: 1.5))
                    Image(systemName: item.actionIcon)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                }
                .offset(x: 2, y: 2)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(item.descriptionText)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.timeAgoText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                // Action buttons
                HStack(spacing: 10) {
                    // High Five reaction
                    Button(action: onHighFive) {
                        HStack(spacing: 4) {
                            Text("🙌")
                                .font(.system(size: 13))
                            Text("High Five")
                                .font(.caption.weight(.semibold))
                            if item.highFiveCount > 0 {
                                Text("\(item.highFiveCount)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(item.hasHighFived ? Color.dinkrAmber : .secondary)
                            }
                        }
                        .foregroundStyle(item.hasHighFived ? Color.dinkrAmber : .secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            item.hasHighFived
                                ? Color.dinkrAmber.opacity(0.12)
                                : Color.secondary.opacity(0.08),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    item.hasHighFived ? Color.dinkrAmber.opacity(0.4) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(item.hasHighFived ? 1.05 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: item.hasHighFived)

                    // Comment button
                    Button(action: onComment) {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 11))
                            Text("Comment")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.secondary.opacity(0.08), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FriendActivityView()
    }
}

import SwiftUI

// MARK: - UserProfileView
// Displayed when tapping on any player that is not the current user.
// Navigation entry points:
//   • FindPlayersView player cards
//   • CourtDetailView → Regulars section
//   • GameSessionDetailView → host name tap

struct UserProfileView: View {
    let user: User
    let currentUserId: String

    @State private var isFriend = false
    @State private var isLoading = true
    @State private var showMessage = false
    @State private var showChallenge = false
    @State private var showHeadToHead = false
    @State private var showComparison = false
    @State private var showMutuals = false
    @Environment(AuthService.self) private var authService

    /// Deterministic mock mutual count derived from userId hash
    private var mutualCount: Int { max(1, abs(user.id.hashValue) % 9 + 1) }

    private var isOwnProfile: Bool { currentUserId == user.id }
    private var showPrivateGate: Bool {
        user.isPrivate && !isFriend && !isOwnProfile
    }

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .tint(Color.dinkrGreen)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if showPrivateGate {
                PrivateProfileScreen(user: user, currentUserId: currentUserId) { newState in
                    isFriend = newState
                }
            } else {
                fullProfileBody
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showMessage) {
            DirectMessageView(
                conversationId: "dm_\(user.id)",
                otherUserName: user.displayName,
                otherUserInitial: String(user.displayName.prefix(1)),
                isOnline: false
            )
        }
        .sheet(isPresented: $showChallenge) {
            MatchRequestView(opponent: user)
        }
        .sheet(isPresented: $showHeadToHead) {
            if let currentUser = authService.currentUser {
                HeadToHeadView(playerA: currentUser, playerB: user)
            }
        }
        .sheet(isPresented: $showComparison) {
            if let currentUser = authService.currentUser {
                PlayerComparisonView(currentUser: currentUser, opponent: user)
            }
        }
        .navigationDestination(isPresented: $showMutuals) {
            MutualFriendsView(userId: user.id, userName: user.displayName)
        }
        .task {
            if user.isPrivate && !isOwnProfile {
                isFriend = await FollowService.shared.isMutualFollow(
                    currentUserId: currentUserId,
                    targetUserId: user.id
                )
            } else {
                isFriend = true
            }
            isLoading = false
        }
    }

    // MARK: - Full profile scroll body

    private var fullProfileBody: some View {
        ScrollView {
            VStack(spacing: 0) {
                UserProfileHeaderView(
                    user: user,
                    currentUserId: currentUserId,
                    onMessage: { showMessage = true },
                    onChallenge: { showChallenge = true },
                    onCompare: { showComparison = true }
                )

                VStack(spacing: 16) {
                    statsRow
                    if !isOwnProfile { mutualFriendsLink }
                    if !isOwnProfile { compareButton }
                    if !user.badges.isEmpty { badgesRow }
                    recentGamesSection
                    commonGroupsSection
                    activeChallengesSection
                    if !user.bio.isEmpty { bioSection }
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            userStatCol("\(user.gamesPlayed)", "Games", "figure.pickleball", Color.dinkrGreen)
            Divider().frame(height: 44)
            userStatCol("\(user.wins)", "Wins", "trophy.fill", Color.dinkrAmber)
            Divider().frame(height: 44)
            userStatCol("\(Int(user.winRate * 100))%", "Win Rate", "percent", Color.dinkrSky)
            Divider().frame(height: 44)
            userStatCol("\(winStreak)", "Streak", "flame.fill", Color.dinkrCoral)
        }
        .padding(.vertical, 14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.secondary.opacity(0.1), lineWidth: 1))
    }

    private func userStatCol(_ value: String, _ label: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.title3.weight(.bold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.3)
        }
        .frame(maxWidth: .infinity)
    }

    /// Approximated win-streak from games played (deterministic mock)
    private var winStreak: Int {
        guard user.gamesPlayed > 0 else { return 0 }
        return max(1, (user.wins * 3) % 7 + 1)
    }

    // MARK: - Mutual Friends Link

    private var mutualFriendsLink: some View {
        Button {
            HapticManager.selection()
            showMutuals = true
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen.opacity(0.12))
                        .frame(width: 32, height: 32)
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.dinkrGreen)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(mutualCount) mutual connection\(mutualCount == 1 ? "" : "s")")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                    Text("Tap to see who you both know")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.dinkrGreen.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color.dinkrGreen.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.dinkrGreen.opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Badges Row

    private var badgesRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Badges", icon: "medal.fill")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(user.badges.prefix(4)) { badge in
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(badgeAccentColor(badge).opacity(0.15))
                                    .frame(width: 52, height: 52)
                                Circle()
                                    .stroke(badgeAccentColor(badge).opacity(0.3), lineWidth: 1.5)
                                    .frame(width: 52, height: 52)
                                Image(systemName: badge.icon)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(badgeAccentColor(badge))
                            }
                            Text(badge.label)
                                .font(.caption2)
                                .multilineTextAlignment(.center)
                                .frame(width: 68)
                                .lineLimit(2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    private func badgeAccentColor(_ badge: Badge) -> Color {
        switch badge.color {
        case "yellow":  return Color.dinkrAmber
        case "orange":  return Color.dinkrAmber
        case "red":     return Color.dinkrCoral
        case "purple":  return Color.purple
        case "green":   return Color.dinkrGreen
        case "pink":    return Color.pink
        case "blue":    return Color.dinkrSky
        default:        return Color.dinkrAmber
        }
    }

    // MARK: - Recent Games Section

    private var recentGamesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Recent Games", icon: "clock.arrow.circlepath")
            VStack(spacing: 8) {
                ForEach(mockResultsForUser.prefix(3)) { result in
                    GameResultRow(result: result, player: user)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    /// Generate deterministic mock results tied to this player
    private var mockResultsForUser: [GameResult] {
        GameResult.mockResults
    }

    // MARK: - Common Groups Section

    private var commonGroupsSection: some View {
        let sharedClubIds = Set(user.clubIds).intersection(
            Set(authService.currentUser?.clubIds ?? [])
        )
        let clubs = Club.mockClubs.filter { sharedClubIds.contains($0.id) }

        return ZStack {
            if !clubs.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader("Groups in Common", icon: "person.3.fill")
                    VStack(spacing: 8) {
                        ForEach(clubs) { club in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.dinkrGreen.opacity(0.12))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "person.3.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Color.dinkrGreen)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(club.name)
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(club.memberCount) members")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if club.isWomenOnly {
                                    Image(systemName: "figure.stand")
                                        .font(.caption)
                                        .foregroundStyle(Color.pink)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(14)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
            }
        }
    }

    // MARK: - Active Challenges Section

    private var activeChallengesSection: some View {
        let active = Challenge.mockChallenges.filter {
            $0.status == .active && $0.participants.contains { $0.id == user.id }
        }

        return ZStack {
            if !active.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader("Active Challenges", icon: "bolt.fill")
                    VStack(spacing: 8) {
                        ForEach(active) { challenge in
                            activeChallengeRow(challenge)
                        }
                    }
                }
                .padding(14)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
            }
        }
    }

    private func activeChallengeRow(_ challenge: Challenge) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(challenge.type.brandColor.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: challenge.type.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(challenge.type.brandColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(challenge.title)
                    .font(.subheadline.weight(.semibold))
                Text("\(challenge.daysRemaining)d left · \(challenge.goalUnit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            // Progress pill
            if let me = challenge.participants.first(where: { $0.id == user.id }) {
                Text("\(Int(me.currentValue))")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(challenge.type.brandColor, in: Capsule())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Compare Button (inline card)

    private var compareButton: some View {
        Button {
            HapticManager.light()
            showComparison = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.xaxis.ascending.badge.clock")
                    .font(.system(size: 14, weight: .semibold))
                Text("Compare Stats")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(Color.dinkrGreen)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.dinkrGreen.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.dinkrGreen.opacity(0.28), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bio / About Section

    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("About", icon: "person.text.rectangle.fill")
            Text(user.bio)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Section Header Helper

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.dinkrGreen)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.4)
        }
    }
}

// MARK: - UserProfileHeaderView

struct UserProfileHeaderView: View {
    let user: User
    let currentUserId: String
    var onMessage: (() -> Void)? = nil
    var onChallenge: (() -> Void)? = nil
    var onCompare: (() -> Void)? = nil

    @State private var glowPulse = false
    @State private var drawProgress: Double = 0

    private var isOwnProfile: Bool { currentUserId == user.id }

    private var coverGradientColors: [Color] {
        guard let style = user.playStyle else {
            return [Color.dinkrNavy, Color.dinkrNavy.opacity(0.75)]
        }
        switch style {
        case .competitive:  return [Color.dinkrCoral.opacity(0.9), Color.dinkrNavy]
        case .recreational: return [Color.dinkrGreen.opacity(0.85), Color.dinkrNavy]
        case .drillFocused: return [Color.dinkrSky.opacity(0.9), Color.dinkrNavy]
        case .dinkCulture:  return [Color.dinkrAmber.opacity(0.85), Color.dinkrNavy]
        case .allAround:    return [Color.dinkrNavy, Color.dinkrSky.opacity(0.75)]
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Cover gradient
            LinearGradient(
                colors: coverGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 240)

            // Subtle court line decoration
            Canvas { ctx, size in
                let path = userProfileCourtPath(size: size, progress: drawProgress)
                ctx.stroke(path, with: .color(.white.opacity(0.05)), lineWidth: 1.5)
            }
            .frame(height: 240)
            .allowsHitTesting(false)

            // Fade to background
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [Color.clear, Color(UIColor.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 52)
            }
            .frame(height: 240)

            // Content
            VStack(spacing: 0) {
                Color.clear.frame(height: 52)

                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen.opacity(glowPulse ? 0.28 : 0.12))
                        .frame(width: 108, height: 108)
                        .blur(radius: 8)
                        .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: glowPulse)

                    Circle()
                        .stroke(Color.dinkrGreen, lineWidth: 2.5)
                        .frame(width: 96, height: 96)

                    AvatarView(urlString: user.avatarURL, displayName: user.displayName, size: 90)
                        .shadow(color: Color.dinkrNavy.opacity(0.5), radius: 8, x: 0, y: 4)
                }
                .padding(.bottom, 10)

                // Name + username
                Text(user.displayName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.top, 1)

                // Chips row: skill + DUPR + play style
                HStack(spacing: 8) {
                    SkillBadge(level: user.skillLevel)

                    if let dupr = user.duprRating {
                        HStack(spacing: 4) {
                            Text("DUPR")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(Color.dinkrAmber)
                            Text(String(format: "%.2f", dupr))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color.dinkrAmber.opacity(0.18))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.dinkrAmber.opacity(0.5), lineWidth: 1))
                    }

                    if let style = user.playStyle {
                        PlayStyleBadge(style: style)
                    }
                }
                .padding(.top, 6)

                // Action buttons — only for other users
                if !isOwnProfile {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            // Follow button
                            FollowButton(
                                currentUserId: currentUserId,
                                targetUserId: user.id,
                                size: .regular
                            )

                            // Message button
                            Button(action: { onMessage?() }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "bubble.left.fill")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Message")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .foregroundStyle(Color.dinkrNavy)
                                .frame(height: 38)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.dinkrNavy.opacity(0.35), lineWidth: 1.5)
                                        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                                )
                            }
                            .buttonStyle(.plain)

                            // Challenge button
                            Button(action: { onChallenge?() }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Challenge")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .foregroundStyle(Color.dinkrAmber)
                                .frame(height: 38)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.dinkrAmber.opacity(0.4), lineWidth: 1.5)
                                        .background(Color.dinkrAmber.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                                )
                            }
                            .buttonStyle(.plain)

                            // Compare button
                            Button(action: { onCompare?() }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "chart.bar.xaxis.ascending")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Compare")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .foregroundStyle(Color.dinkrSky)
                                .frame(height: 38)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.dinkrSky.opacity(0.4), lineWidth: 1.5)
                                        .background(Color.dinkrSky.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 10)
                }

                // Followers / Following row
                HStack(spacing: 0) {
                    profileStatCol("\(user.followersCount)", "Followers")
                    Rectangle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 1, height: 28)
                    profileStatCol("\(user.followingCount)", "Following")
                    Rectangle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 1, height: 28)
                    profileStatCol(user.city.isEmpty ? "—" : user.city, "Location")
                }
                .padding(.horizontal, 32)
                .padding(.top, 12)
                .padding(.bottom, 18)
            }
        }
        .onAppear {
            glowPulse = true
            withAnimation(.easeInOut(duration: 1.8)) {
                drawProgress = 1.0
            }
        }
    }

    private func profileStatCol(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(0.4)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Court line path for header

private func userProfileCourtPath(size: CGSize, progress: Double) -> Path {
    var path = Path()
    let w = size.width
    let h = size.height

    let horizontals: [CGFloat] = [0.25, 0.50, 0.72]
    for ratio in horizontals {
        let y = h * ratio
        let endX = 20 + (w - 40) * progress
        path.move(to: CGPoint(x: 20, y: y))
        path.addLine(to: CGPoint(x: endX, y: y))
    }

    let sideEndY = h * 0.25 + (h * 0.72 - h * 0.25) * progress
    path.move(to: CGPoint(x: 20, y: h * 0.25))
    path.addLine(to: CGPoint(x: 20, y: sideEndY))
    path.move(to: CGPoint(x: w - 20, y: h * 0.25))
    path.addLine(to: CGPoint(x: w - 20, y: sideEndY))

    let centerEndY = h * 0.25 + (h * 0.72 - h * 0.25) * progress
    path.move(to: CGPoint(x: w / 2, y: h * 0.25))
    path.addLine(to: CGPoint(x: w / 2, y: centerEndY))

    return path
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UserProfileView(user: User.mockPlayers[0], currentUserId: "user_001")
            .environment(AuthService())
    }
}

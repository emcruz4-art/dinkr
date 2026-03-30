import SwiftUI

struct FindPlayersView: View {
    let players: [User]
    let currentUserId: String

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if players.isEmpty {
                    EmptyStateView(
                        icon: "person.2",
                        title: "No Players Found",
                        message: "Players in your area will appear here."
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(players) { player in
                        NavigationLink(destination: UserProfileView(user: player, currentUserId: currentUserId)) {
                            PlayerCardView(player: player, currentUserId: currentUserId)
                                .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Player Card View

struct PlayerCardView: View {
    let player: User
    let currentUserId: String

    @State private var isFriend = false
    @State private var checked = false

    private var showPrivateGate: Bool {
        player.isPrivate && !isFriend && currentUserId != player.id
    }

    var body: some View {
        PickleballCard {
            HStack(spacing: 14) {
                ZStack(alignment: .bottomTrailing) {
                    AvatarView(urlString: player.avatarURL, displayName: player.displayName, size: 52)
                    if player.isPrivate {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(Color.dinkrNavy)
                            .clipShape(Circle())
                            .offset(x: 4, y: 4)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(player.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.primary)
                        SkillBadge(level: player.skillLevel, compact: true)
                    }

                    if showPrivateGate {
                        // Private — only show city
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("Private account · \(player.city)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(player.city)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 12) {
                            Label("\(player.gamesPlayed) games", systemImage: "figure.pickleball")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Label(String(format: "%.0f%%", player.winRate * 100) + " wins", systemImage: "trophy")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                if currentUserId != player.id {
                    FollowButton(
                        currentUserId: currentUserId,
                        targetUserId: player.id,
                        isPrivateAccount: player.isPrivate && !isFriend,
                        size: .compact
                    )
                }
            }
            .padding(14)
        }
        .task {
            guard !checked else { return }
            checked = true
            if player.isPrivate && currentUserId != player.id {
                isFriend = await FollowService.shared.isMutualFollow(
                    currentUserId: currentUserId,
                    targetUserId: player.id
                )
            } else {
                isFriend = true
            }
        }
    }
}

// MARK: - User Profile View

struct UserProfileView: View {
    let user: User
    let currentUserId: String

    @State private var isFriend = false
    @State private var isLoading = true
    @Environment(AuthService.self) private var authService

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
                PrivateProfileScreen(user: user, currentUserId: currentUserId) { newFriendState in
                    isFriend = newFriendState
                }
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        PremiumProfileHeaderView(user: user, currentUserId: currentUserId)
                        PublicProfileBody(user: user)
                    }
                    .padding(.bottom, 32)
                }
                .ignoresSafeArea(edges: .top)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
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
}

// MARK: - Private Profile Screen

struct PrivateProfileScreen: View {
    let user: User
    let currentUserId: String
    var onFriendStatusChange: ((Bool) -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Mini header (name + avatar only)
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [Color.dinkrNavy, Color.dinkrNavy.opacity(0.7)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 200)

                VStack(spacing: 10) {
                    AvatarView(urlString: user.avatarURL, displayName: user.displayName, size: 72)
                        .overlay(Circle().stroke(Color.dinkrGreen, lineWidth: 2))
                        .padding(.top, 56)

                    Text(user.displayName)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    Text("@\(user.username)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))

                    // Follower count only
                    Text("\(user.followersCount) followers")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.bottom, 16)
                }
            }

            // Lock body
            VStack(spacing: 20) {
                Spacer().frame(height: 32)

                ZStack {
                    Circle()
                        .fill(Color.dinkrNavy.opacity(0.08))
                        .frame(width: 80, height: 80)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(Color.dinkrNavy.opacity(0.5))
                }

                VStack(spacing: 8) {
                    Text("This account is private")
                        .font(.title3.weight(.bold))
                    Text("Follow \(user.displayName.components(separatedBy: " ").first ?? user.displayName) to see their games, stats, and posts.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Request to follow button
                FollowButton(
                    currentUserId: currentUserId,
                    targetUserId: user.id,
                    isPrivateAccount: true,
                    size: .regular
                )

                Text("Dinkr · Private Account")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Public Profile Body (stats + bio for other users)

struct PublicProfileBody: View {
    let user: User

    var body: some View {
        VStack(spacing: 16) {
            // Stats row
            HStack(spacing: 0) {
                statCol("\(user.gamesPlayed)", "Games")
                Divider().frame(height: 32)
                statCol("\(user.followersCount)", "Followers")
                Divider().frame(height: 32)
                statCol("\(user.followingCount)", "Following")
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            if !user.bio.isEmpty {
                Text(user.bio)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
            }
        }
    }

    @ViewBuilder
    private func statCol(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.weight(.bold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    FindPlayersView(players: User.mockPlayers, currentUserId: "user_001")
        .environment(AuthService())
}

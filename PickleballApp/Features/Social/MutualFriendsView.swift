import SwiftUI

// MARK: - MutualConnection

struct MutualConnection: Identifiable {
    let id: String
    let user: User
    let connectionNote: String  // e.g. "Plays at Westside Pickleball"
}

// MARK: - Mock Data

extension MutualConnection {
    static func mockMutuals(for userId: String) -> [MutualConnection] {
        [
            MutualConnection(id: "mc_001", user: User.mockPlayers[0], connectionNote: "Plays at Westside Pickleball"),
            MutualConnection(id: "mc_002", user: User.mockPlayers[1], connectionNote: "Mueller Park regular"),
            MutualConnection(id: "mc_003", user: User.mockPlayers[2], connectionNote: "Austin Open 2024"),
            MutualConnection(id: "mc_004", user: User.mockPlayers[3], connectionNote: "Round Rock Sports Center"),
            MutualConnection(id: "mc_005", user: User.mockPlayers[4], connectionNote: "Cedar Park Pickleball Club"),
            MutualConnection(id: "mc_006", user: User.mockPlayers[5], connectionNote: "Friday Open Play crew"),
            MutualConnection(id: "mc_007", user: User.mockPlayers[6], connectionNote: "Dink Culture group"),
        ]
    }

    static func mockSuggestions(for userId: String) -> [User] {
        Array(User.mockPlayers.dropFirst(4).prefix(4))
    }
}

// MARK: - MutualFriendsView

struct MutualFriendsView: View {
    let userId: String
    let userName: String

    @State private var searchText = ""
    @State private var followingIds: Set<String> = []
    @State private var mutuals: [MutualConnection] = []
    @State private var suggestions: [User] = []

    private var filteredMutuals: [MutualConnection] {
        guard !searchText.isEmpty else { return mutuals }
        return mutuals.filter {
            $0.user.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.user.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredSuggestions: [User] {
        guard !searchText.isEmpty else { return suggestions }
        return suggestions.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            Group {
                if mutuals.isEmpty && suggestions.isEmpty {
                    emptyState
                } else {
                    contentList
                }
            }
        }
        .navigationTitle("Mutual Connections")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search connections")
        .onAppear {
            mutuals = MutualConnection.mockMutuals(for: userId)
            suggestions = MutualConnection.mockSuggestions(for: userId)
        }
    }

    // MARK: - Content List

    private var contentList: some View {
        List {
            // ── Header section ──────────────────────────────────────
            Section {
                mutualCountHeader
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            // ── Mutual connections ──────────────────────────────────
            if !filteredMutuals.isEmpty {
                Section {
                    ForEach(filteredMutuals) { mutual in
                        MutualConnectionRow(
                            user: mutual.user,
                            connectionNote: mutual.connectionNote,
                            isFollowing: followingIds.contains(mutual.user.id),
                            onFollowToggle: { toggleFollow(mutual.user.id) }
                        )
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .listRowBackground(Color.cardBackground)
                    }
                } header: {
                    sectionLabel("Mutual Connections", icon: "person.2.fill", color: Color.dinkrGreen)
                }
            }

            // ── People you may know ──────────────────────────────────
            if !filteredSuggestions.isEmpty {
                Section {
                    ForEach(filteredSuggestions) { user in
                        MutualConnectionRow(
                            user: user,
                            connectionNote: "May know through \(userName)",
                            isFollowing: followingIds.contains(user.id),
                            onFollowToggle: { toggleFollow(user.id) }
                        )
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .listRowBackground(Color.cardBackground)
                    }
                } header: {
                    sectionLabel("People You May Know", icon: "sparkles", color: Color.dinkrAmber)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Header Card

    private var mutualCountHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.dinkrGreen.opacity(0.18), Color.dinkrSky.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                Text("\(mutuals.count)")
                    .font(.title2.weight(.black))
                    .foregroundStyle(Color.dinkrGreen)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("You and \(userName)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("have \(mutuals.count) mutual connection\(mutuals.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.dinkrSky.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.2.slash")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Color.dinkrSky)
            }

            VStack(spacing: 8) {
                Text("No mutual connections yet")
                    .font(.headline.weight(.bold))
                Text("Play more games and join groups to grow your network with \(userName).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(.top, 4)
    }

    private func toggleFollow(_ id: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
            if followingIds.contains(id) {
                followingIds.remove(id)
            } else {
                followingIds.insert(id)
                HapticManager.selection()
            }
        }
    }
}

// MARK: - MutualConnectionRow

private struct MutualConnectionRow: View {
    let user: User
    let connectionNote: String
    let isFollowing: Bool
    let onFollowToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(
                urlString: user.avatarURL,
                displayName: user.displayName,
                size: 46
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(user.displayName)
                        .font(.subheadline.weight(.semibold))
                    SkillBadge(level: user.skillLevel, compact: true)
                }

                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.dinkrGreen)
                    Text(connectionNote)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button(action: onFollowToggle) {
                HStack(spacing: 4) {
                    Image(systemName: isFollowing ? "checkmark" : "person.badge.plus")
                        .font(.system(size: 11, weight: .semibold))
                    Text(isFollowing ? "Following" : "Follow")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(isFollowing ? Color.dinkrGreen : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    isFollowing ? Color.clear : Color.dinkrGreen,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(Color.dinkrGreen, lineWidth: isFollowing ? 1.5 : 0)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MutualFriendsView(userId: "user_002", userName: "Maria Chen")
    }
}

import SwiftUI

// MARK: - Follow List Mode

enum FollowListMode {
    case followers
    case following

    var title: String {
        switch self {
        case .followers: return "Followers"
        case .following: return "Following"
        }
    }
}

// MARK: - Follow List View

struct FollowListView: View {
    let mode: FollowListMode
    let user: User

    @State private var searchText = ""
    @State private var followingSet: Set<String> = ["user_002", "user_004", "user_007"]

    private var players: [User] { User.mockPlayers }

    private var followerIds: Set<String> { Set(["user_002", "user_003", "user_005", "user_007"]) }
    private var followingIds: Set<String> { Set(["user_002", "user_004", "user_006", "user_007"]) }

    private var displayList: [User] {
        let sourceIds = mode == .followers ? followerIds : followingIds
        let base = players.filter { sourceIds.contains($0.id) }
        guard !searchText.isEmpty else { return base }
        let query = searchText.lowercased()
        return base.filter {
            $0.displayName.lowercased().contains(query) ||
            $0.username.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if displayList.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.dinkrGreen.opacity(0.5))
                        Text(searchText.isEmpty ? "No \(mode.title) yet" : "No results for \"\(searchText)\"")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List(displayList) { player in
                        FollowRow(
                            player: player,
                            isMutual: followerIds.contains(player.id) && followingIds.contains(player.id),
                            isFollowing: followingSet.contains(player.id)
                        ) {
                            toggleFollow(player.id)
                        }
                        .listRowBackground(Color.cardBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search \(mode.title.lowercased())")
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func toggleFollow(_ id: String) {
        if followingSet.contains(id) {
            followingSet.remove(id)
        } else {
            followingSet.insert(id)
        }
    }
}

// MARK: - Follow Row

private struct FollowRow: View {
    let player: User
    let isMutual: Bool
    let isFollowing: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.18))
                    .frame(width: 48, height: 48)
                Text(String(player.displayName.prefix(1)))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.dinkrGreen)
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(player.displayName)
                        .font(.subheadline.weight(.semibold))
                    if isMutual {
                        Text("Mutual")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.dinkrSky, in: Capsule())
                    }
                }
                HStack(spacing: 6) {
                    Text("@\(player.username)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SkillBadge(level: player.skillLevel)
                }
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(player.city)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Follow Button
            Button(action: onToggle) {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isFollowing ? Color.dinkrGreen : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        isFollowing
                            ? Color.dinkrGreen.opacity(0.12)
                            : Color.dinkrGreen,
                        in: Capsule()
                    )
                    .overlay(
                        Capsule()
                            .stroke(isFollowing ? Color.dinkrGreen.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Preview

#Preview("Followers") {
    FollowListView(mode: .followers, user: User.mockCurrentUser)
}

#Preview("Following") {
    FollowListView(mode: .following, user: User.mockCurrentUser)
}

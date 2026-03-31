import SwiftUI

// MARK: - FollowersListView

struct FollowersListView: View {
    @State private var selectedSegment = 0
    @State private var searchText = ""
    @State private var followingIds: Set<String> = Set(User.mockPlayers.map { $0.id })
    @State private var unfollowTarget: User? = nil
    @State private var showUnfollowAlert = false

    private let segments = ["Followers", "Following"]

    private var followers: [User] { User.mockPlayers }
    private var following: [User] { Array(User.mockPlayers.reversed()) }

    private var activeList: [User] {
        selectedSegment == 0 ? followers : following
    }

    private var filteredList: [User] {
        if searchText.isEmpty { return activeList }
        let q = searchText.lowercased()
        return activeList.filter {
            $0.displayName.lowercased().contains(q) ||
            $0.username.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented control
                Picker("", selection: $selectedSegment) {
                    ForEach(segments.indices, id: \.self) { i in
                        Text(segments[i]).tag(i)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search players…", text: $searchText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                Divider()

                // List
                if filteredList.isEmpty {
                    FollowersEmptyState(segment: selectedSegment, hasSearch: !searchText.isEmpty)
                } else {
                    List(filteredList) { user in
                        FollowerRowView(
                            user: user,
                            isFollowing: followingIds.contains(user.id),
                            onFollowTap: { handleFollowTap(user) }
                        )
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .animation(.default, value: filteredList.map { $0.id })
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Unfollow \(unfollowTarget?.displayName ?? "")?", isPresented: $showUnfollowAlert) {
                Button("Unfollow", role: .destructive) {
                    if let target = unfollowTarget {
                        followingIds.remove(target.id)
                    }
                    unfollowTarget = nil
                }
                Button("Cancel", role: .cancel) {
                    unfollowTarget = nil
                }
            } message: {
                Text("They won't be notified.")
            }
        }
    }

    private func handleFollowTap(_ user: User) {
        if followingIds.contains(user.id) {
            unfollowTarget = user
            showUnfollowAlert = true
        } else {
            withAnimation { followingIds.insert(user.id) }
        }
    }
}

// MARK: - Follower Row

private struct FollowerRowView: View {
    let user: User
    let isFollowing: Bool
    let onFollowTap: () -> Void

    // Deterministic mock mutual count based on user id hash
    private var mutualCount: Int {
        abs(user.id.hashValue) % 6
    }

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(urlString: user.avatarURL, displayName: user.displayName, size: 48)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(user.displayName)
                        .font(.subheadline.weight(.semibold))
                    SkillBadge(level: user.skillLevel, compact: true)
                }
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if mutualCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Text("\(mutualCount) mutual")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color(.tertiarySystemBackground), in: Capsule())
                }
            }

            Spacer()

            Button(action: onFollowTap) {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isFollowing ? Color.dinkrGreen : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        isFollowing
                        ? Color.clear
                        : Color.dinkrGreen,
                        in: Capsule()
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.dinkrGreen, lineWidth: isFollowing ? 1.5 : 0)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty State

private struct FollowersEmptyState: View {
    let segment: Int
    let hasSearch: Bool

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: hasSearch ? "magnifyingglass" : (segment == 0 ? "person.3" : "person.badge.plus"))
                .font(.system(size: 44))
                .foregroundStyle(Color.dinkrGreen.opacity(0.6))

            Text(hasSearch
                 ? "No players match your search"
                 : (segment == 0 ? "No followers yet" : "Not following anyone yet"))
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(hasSearch
                 ? "Try a different name or username."
                 : (segment == 0
                    ? "Play more games and connect with players to build your audience."
                    : "Explore players and follow people you want to play with."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    FollowersListView()
}

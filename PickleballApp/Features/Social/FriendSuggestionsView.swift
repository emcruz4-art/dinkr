import SwiftUI

// MARK: - FriendSuggestionsView

struct FriendSuggestionsView: View {
    // Mock: shuffled with a fixed seed-like arrangement via array manipulation
    private var allSuggestions: [User] {
        let players = User.mockPlayers
        // Deterministic "shuffle" — reverse then interleave
        let reversed = Array(players.reversed())
        var result: [User] = []
        for i in players.indices {
            result.append(i % 2 == 0 ? reversed[i] : players[i])
        }
        return result
    }

    private var featuredSuggestions: [User] { Array(allSuggestions.prefix(3)) }

    private var groupsSuggestions: [User] {
        allSuggestions.filter { !$0.clubIds.isEmpty }.prefix(3).map { $0 }
    }

    private var nearCourtsSuggestions: [User] {
        allSuggestions.filter { $0.city.contains("Austin") || $0.city.contains("Round Rock") || $0.city.contains("Cedar Park") }.prefix(4).map { $0 }
    }

    @State private var addedIds: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: Featured horizontal scroll
                VStack(alignment: .leading, spacing: 12) {
                    Text("People You May Know")
                        .font(.title2.weight(.bold))
                        .padding(.horizontal, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(featuredSuggestions) { user in
                                FeaturedSuggestionCard(
                                    user: user,
                                    isAdded: addedIds.contains(user.id),
                                    onAdd: { toggleAdd(user) }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                    }
                }

                // MARK: Based on your groups
                SuggestionSection(
                    title: "Based on your groups",
                    icon: "person.3.fill",
                    users: groupsSuggestions,
                    addedIds: addedIds,
                    onAdd: toggleAdd
                )

                // MARK: Near your courts
                SuggestionSection(
                    title: "Near your courts",
                    icon: "mappin.circle.fill",
                    users: nearCourtsSuggestions,
                    addedIds: addedIds,
                    onAdd: toggleAdd
                )
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
    }

    private func toggleAdd(_ user: User) {
        withAnimation {
            if addedIds.contains(user.id) {
                addedIds.remove(user.id)
            } else {
                addedIds.insert(user.id)
                HapticManager.selection()
            }
        }
    }
}

// MARK: - Featured Card

private struct FeaturedSuggestionCard: View {
    let user: User
    let isAdded: Bool
    let onAdd: () -> Void

    private var mutualCount: Int { abs(user.id.hashValue) % 8 + 1 }

    var body: some View {
        VStack(spacing: 10) {
            AvatarView(urlString: user.avatarURL, displayName: user.displayName, size: 72)
                .shadow(color: Color.dinkrGreen.opacity(0.18), radius: 8, x: 0, y: 4)

            VStack(spacing: 4) {
                Text(user.displayName)
                    .font(.subheadline.weight(.bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 130)

                SkillBadge(level: user.skillLevel, compact: true)

                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text("\(mutualCount) mutual")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Button(action: onAdd) {
                HStack(spacing: 5) {
                    Image(systemName: isAdded ? "checkmark" : "person.badge.plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text(isAdded ? "Added" : "Add Friend")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(isAdded ? Color.dinkrGreen : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(width: 130)
                .background(
                    isAdded ? Color.clear : Color.dinkrGreen,
                    in: RoundedRectangle(cornerRadius: 20)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.dinkrGreen, lineWidth: isAdded ? 1.5 : 0)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Suggestion Section

private struct SuggestionSection: View {
    let title: String
    let icon: String
    let users: [User]
    let addedIds: Set<String>
    let onAdd: (User) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrGreen)
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.4)
            }
            .padding(.horizontal, 16)

            VStack(spacing: 0) {
                ForEach(Array(users.enumerated()), id: \.element.id) { idx, user in
                    SuggestionRow(
                        user: user,
                        isAdded: addedIds.contains(user.id),
                        onAdd: { onAdd(user) }
                    )

                    if idx < users.count - 1 {
                        Divider().padding(.leading, 76)
                    }
                }
            }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Suggestion Row

private struct SuggestionRow: View {
    let user: User
    let isAdded: Bool
    let onAdd: () -> Void

    private var mutualCount: Int { abs(user.id.hashValue) % 7 + 1 }

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

                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text("\(mutualCount) mutual friend\(mutualCount == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onAdd) {
                HStack(spacing: 4) {
                    Image(systemName: isAdded ? "checkmark" : "person.badge.plus")
                        .font(.system(size: 11, weight: .semibold))
                    Text(isAdded ? "Added" : "Add")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(isAdded ? Color.dinkrGreen : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    isAdded ? Color.clear : Color.dinkrGreen,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(Color.dinkrGreen, lineWidth: isAdded ? 1.5 : 0)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Preview

#Preview {
    FriendSuggestionsView()
}

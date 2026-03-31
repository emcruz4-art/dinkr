import SwiftUI

// MARK: - PostReaction

struct PostReaction: Identifiable, Hashable {
    var id: String { emoji }
    var emoji: String
    var count: Int
    var userHasReacted: Bool
}

// MARK: - ReactionType

enum ReactionType: CaseIterable {
    case heart
    case fire
    case trophy
    case target
    case clap
    case pickleball

    var emoji: String {
        switch self {
        case .heart:      return "❤️"
        case .fire:       return "🔥"
        case .trophy:     return "🏆"
        case .target:     return "🎯"
        case .clap:       return "👏"
        case .pickleball: return "🥒"
        }
    }

    var label: String {
        switch self {
        case .heart:      return "Heart"
        case .fire:       return "Fire"
        case .trophy:     return "Trophy"
        case .target:     return "Target"
        case .clap:       return "Clap"
        case .pickleball: return "Pickle"
        }
    }
}

// MARK: - ReactionChip

private struct ReactionChip: View {
    let reaction: PostReaction
    let onTap: () -> Void

    @State private var bouncing = false

    var body: some View {
        Button(action: {
            onTap()
            withAnimation(.interpolatingSpring(stiffness: 600, damping: 12)) {
                bouncing = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                bouncing = false
            }
        }) {
            HStack(spacing: 4) {
                Text(reaction.emoji)
                    .font(.caption)
                    .scaleEffect(bouncing ? 1.4 : 1.0)
                Text("\(reaction.count)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(reaction.userHasReacted ? Color.dinkrGreen : .secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                reaction.userHasReacted
                    ? Color.dinkrGreen.opacity(0.12)
                    : Color.secondary.opacity(0.08)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        reaction.userHasReacted ? Color.dinkrGreen.opacity(0.4) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ReactionPicker

struct ReactionPicker: View {
    @Binding var reactions: [PostReaction]
    let onDismiss: () -> Void

    @State private var appeared: [Bool] = Array(repeating: false, count: ReactionType.allCases.count)

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(ReactionType.allCases.enumerated()), id: \.element) { index, type in
                let alreadyReacted = reactions.first(where: { $0.emoji == type.emoji })?.userHasReacted == true

                Button {
                    HapticManager.medium()
                    toggleReaction(type: type)
                    onDismiss()
                } label: {
                    Text(type.emoji)
                        .font(.title2)
                        .padding(10)
                        .background(
                            alreadyReacted
                                ? Color.dinkrGreen.opacity(0.15)
                                : Color(uiColor: .systemBackground).opacity(0.92)
                        )
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    alreadyReacted ? Color.dinkrGreen.opacity(0.5) : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                        .scaleEffect(appeared[index] ? 1 : 0.4)
                        .offset(y: appeared[index] ? 0 : 12)
                }
                .buttonStyle(.plain)
                .onAppear {
                    withAnimation(
                        .interpolatingSpring(stiffness: 400, damping: 18)
                            .delay(Double(index) * 0.045)
                    ) {
                        appeared[index] = true
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.16), radius: 12, y: 4)
    }

    private func toggleReaction(type: ReactionType) {
        let emoji = type.emoji
        if let idx = reactions.firstIndex(where: { $0.emoji == emoji }) {
            let current = reactions[idx]
            reactions[idx] = PostReaction(
                emoji: current.emoji,
                count: current.userHasReacted ? max(0, current.count - 1) : current.count + 1,
                userHasReacted: !current.userHasReacted
            )
            // Remove if count drops to zero and was not originally seeded
            if reactions[idx].count == 0 {
                reactions.remove(at: idx)
            }
        } else {
            reactions.append(PostReaction(emoji: emoji, count: 1, userHasReacted: true))
        }
    }
}

// MARK: - ReactionBar

struct ReactionBar: View {
    @Binding var reactions: [PostReaction]
    var onShowDetails: () -> Void

    @State private var showPicker = false

    /// Top 3 reactions by count
    private var topReactions: [PostReaction] {
        Array(reactions.sorted { $0.count > $1.count }.prefix(3))
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            HStack(spacing: 6) {
                ForEach(topReactions) { reaction in
                    ReactionChip(reaction: reaction) {
                        HapticManager.medium()
                        toggleExisting(emoji: reaction.emoji)
                    }
                }

                // Add reaction button (long-press hint visible as "+" chip)
                Button {
                    // tap also shows picker
                    withAnimation(.interpolatingSpring(stiffness: 350, damping: 20)) {
                        showPicker.toggle()
                    }
                } label: {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .background(Color.secondary.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.35).onEnded { _ in
                        HapticManager.soft()
                        withAnimation(.interpolatingSpring(stiffness: 350, damping: 20)) {
                            showPicker = true
                        }
                    }
                )

                Spacer()

                // Tappable total to show full sheet
                if !reactions.isEmpty {
                    Button(action: onShowDetails) {
                        Text("View all")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            // Picker floats above the bar
            if showPicker {
                ReactionPicker(reactions: $reactions) {
                    withAnimation(.easeOut(duration: 0.18)) {
                        showPicker = false
                    }
                }
                .offset(y: -56)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.7, anchor: .bottomLeading).combined(with: .opacity),
                    removal: .scale(scale: 0.7, anchor: .bottomLeading).combined(with: .opacity)
                ))
                .zIndex(10)
            }
        }
        // Dismiss picker on tap outside
        .contentShape(Rectangle())
        .onTapGesture {
            if showPicker {
                withAnimation(.easeOut(duration: 0.18)) {
                    showPicker = false
                }
            }
        }
    }

    private func toggleExisting(emoji: String) {
        guard let idx = reactions.firstIndex(where: { $0.emoji == emoji }) else { return }
        let current = reactions[idx]
        reactions[idx] = PostReaction(
            emoji: current.emoji,
            count: current.userHasReacted ? max(0, current.count - 1) : current.count + 1,
            userHasReacted: !current.userHasReacted
        )
    }
}

// MARK: - ReactionUserRow

private struct ReactionUserRow: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(urlString: user.avatarURL, displayName: user.displayName, size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.subheadline.weight(.semibold))
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Skill badge
            Text(user.skillLevel.label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.dinkrGreen, in: Capsule())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - PostReactionsView (Sheet)

struct PostReactionsView: View {
    let reactions: [PostReaction]

    @State private var selectedEmoji: String

    init(reactions: [PostReaction]) {
        self.reactions = reactions
        let first = reactions.sorted { $0.count > $1.count }.first?.emoji ?? ""
        _selectedEmoji = State(initialValue: first)
    }

    private var totalCount: Int {
        reactions.reduce(0) { $0 + $1.count }
    }

    /// Reactions with at least 1 reaction, sorted by count descending
    private var activeReactions: [PostReaction] {
        reactions.filter { $0.count > 0 }.sorted { $0.count > $1.count }
    }

    /// Users mapped to each emoji for mock display
    private func users(for emoji: String) -> [User] {
        // Distribute mock players by cycling through based on reaction position
        let allUsers = [User.mockCurrentUser] + User.mockPlayers
        let reactionIndex = activeReactions.firstIndex(where: { $0.emoji == emoji }) ?? 0
        let reaction = activeReactions.first(where: { $0.emoji == emoji })
        let count = min(reaction?.count ?? 0, allUsers.count)
        // Offset the slice per reaction so each type shows different users
        let offset = (reactionIndex * 3) % max(allUsers.count - count, 1)
        let start = min(offset, allUsers.count - 1)
        let end = min(start + count, allUsers.count)
        return Array(allUsers[start..<end])
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Reaction tab chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(activeReactions) { reaction in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedEmoji = reaction.emoji
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(reaction.emoji)
                                        .font(.subheadline)
                                    Text("\(reaction.count)")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(
                                            selectedEmoji == reaction.emoji ? Color.dinkrGreen : .primary
                                        )
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    selectedEmoji == reaction.emoji
                                        ? Color.dinkrGreen.opacity(0.12)
                                        : Color.secondary.opacity(0.08)
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            selectedEmoji == reaction.emoji
                                                ? Color.dinkrGreen.opacity(0.45)
                                                : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.2), value: selectedEmoji)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                Divider()

                // User list for selected reaction
                if activeReactions.isEmpty {
                    ContentUnavailableView(
                        "No reactions yet",
                        systemImage: "face.smiling",
                        description: Text("Be the first to react to this post.")
                    )
                } else {
                    List {
                        ForEach(users(for: selectedEmoji)) { user in
                            ReactionUserRow(user: user)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Reactions  \(totalCount > 0 ? "· \(totalCount)" : "")")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

#Preview("ReactionBar") {
    @Previewable @State var reactions = Post.mockPosts[0].mockReactions
    VStack {
        Spacer()
        ReactionBar(reactions: $reactions, onShowDetails: {})
            .padding()
        Spacer()
    }
}

#Preview("PostReactionsView") {
    PostReactionsView(reactions: Post.mockPosts[0].mockReactions)
}

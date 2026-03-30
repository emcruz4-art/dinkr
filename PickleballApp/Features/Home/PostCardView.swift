import SwiftUI

struct PostCardView: View {
    let post: Post
    let onLike: () -> Void
    let onComment: () -> Void

    var body: some View {
        PickleballCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 10) {
                    AvatarView(urlString: post.authorAvatarURL, displayName: post.authorName, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.authorName)
                            .font(.subheadline.weight(.semibold))
                        Text(post.createdAt.relativeString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    PostTypeBadge(type: post.postType)
                }

                // Content
                Text(post.content)
                    .font(.subheadline)
                    .lineLimit(5)

                // Tags
                if !post.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(post.tags, id: \.self) { tag in
                                PillTag(text: "#\(tag)")
                            }
                        }
                    }
                }

                // Tagged users
                if !post.taggedUserIds.isEmpty {
                    TaggedUsersRow(taggedIds: post.taggedUserIds)
                        .padding(.horizontal, 12)
                }

                Divider()

                // Actions
                HStack(spacing: 20) {
                    Button(action: onLike) {
                        Label("\(post.likes)", systemImage: post.isLiked ? "heart.fill" : "heart")
                            .font(.subheadline)
                            .foregroundStyle(post.isLiked ? Color.dinkrCoral : .secondary)
                    }
                    .buttonStyle(.plain)

                    Button {
                        onComment()
                    } label: {
                        Label("\(post.commentCount)", systemImage: "bubble.left")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        // share
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                PostReactionRow()
            }
            .padding(16)
        }
    }
}

struct PostReactionRow: View {
    @State private var selectedReaction: String? = nil
    let reactions: [(emoji: String, label: String, count: Int)] = [
        ("👏", "Nice", 14),
        ("🔥", "Fire", 8),
        ("💪", "Letsgoo", 6),
        ("🏓", "Dink", 3),
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(reactions, id: \.emoji) { reaction in
                Button {
                    selectedReaction = selectedReaction == reaction.emoji ? nil : reaction.emoji
                } label: {
                    HStack(spacing: 4) {
                        Text(reaction.emoji)
                            .font(.caption)
                        Text("\(reaction.count + (selectedReaction == reaction.emoji ? 1 : 0))")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(selectedReaction == reaction.emoji ? Color.dinkrGreen : .secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(selectedReaction == reaction.emoji ? Color.dinkrGreen.opacity(0.12) : Color.secondary.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(selectedReaction == reaction.emoji ? Color.dinkrGreen.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }
}

struct PostTypeBadge: View {
    let type: PostType

    var body: some View {
        Text(label)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12), in: Capsule())
    }

    var label: String {
        switch type {
        case .general: return "Post"
        case .highlight: return "Highlight"
        case .question: return "Tip"
        case .winCelebration: return "Win"
        case .courtReview: return "Court"
        case .lookingForGame: return "LFG"
        }
    }

    var color: Color {
        switch type {
        case .general: return .secondary
        case .highlight: return .courtOrange
        case .question: return .courtBlue
        case .winCelebration: return Color.pickleballGreen
        case .courtReview: return .purple
        case .lookingForGame: return .red
        }
    }
}

#Preview {
    PostCardView(post: Post.mockPosts[0], onLike: {}, onComment: {})
        .padding()
}

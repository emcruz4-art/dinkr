import SwiftUI

// MARK: - PostCardView

struct PostCardView: View {
    let post: Post
    let onLike: () -> Void
    let onComment: () -> Void

    @State private var showReportSheet = false
    @State private var showCommentThread = false
    @State private var showSaveSheet = false
    @State private var showShareSheet = false
    @State private var reactions: [PostReaction]
    @State private var showReactionsSheet = false
    @State private var heartScale: CGFloat = 1.0
    @State private var heartBounce = false

    init(post: Post, onLike: @escaping () -> Void, onComment: @escaping () -> Void) {
        self.post = post
        self.onLike = onLike
        self.onComment = onComment
        _reactions = State(initialValue: post.mockReactions)
    }

    private var totalReactionCount: Int {
        reactions.reduce(0) { $0 + $1.count }
    }

    // Group name is stored on the post for display
    private var groupName: String? {
        post.groupName ?? (post.groupId != nil ? "Group" : nil)
    }

    // Derive a mock star rating from post id for court reviews
    private var mockStarRating: Int {
        let hash = post.id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return max(3, (hash % 3) + 3) // 3–5 stars
    }

    // Mock court name for courtReview posts
    private var mockCourtName: String {
        let courts = ["Westside Pickleball Complex", "Mueller Recreation Center", "Zilker Park Courts", "South Lamar Sports Club"]
        let idx = post.id.unicodeScalars.reduce(0) { $0 + Int($1.value) } % courts.count
        return courts[idx]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                headerRow
                if post.mediaURLs.isEmpty == false || post.postType == .highlight || post.postType == .winCelebration {
                    photoPlaceholder
                }
                contentBody
                typeSpecificContent
                if !post.tags.isEmpty { tagsRow }
                Divider().padding(.top, 2)
                engagementRow
                ReactionBar(reactions: $reactions) { showReactionsSheet = true }
            }
            .padding(16)
        }
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showReportSheet) {
            ReportContentView(
                reportType: .post,
                contentPreview: post.content,
                reportedUserName: post.authorName
            )
        }
        .sheet(isPresented: $showCommentThread) {
            CommentThreadView(post: post)
        }
        .sheet(isPresented: $showSaveSheet) {
            PostCollectionsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: ["https://dinkr.app/post/\(post.id)"])
        }
        .sheet(isPresented: $showReactionsSheet) {
            PostReactionsView(reactions: reactions)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 10) {
            AvatarView(urlString: post.authorAvatarURL, displayName: post.authorName, size: 42)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(post.authorName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)

                    // Verified badge — show for users with many likes (mock criteria)
                    if post.likes > 100 {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.dinkrSky)
                    }
                }

                HStack(spacing: 4) {
                    Text(post.createdAt.relativeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let name = groupName {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 3) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(Color.dinkrGreen)
                            Text("in \(name)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.dinkrGreen)
                        }
                    }
                }
            }

            Spacer()

            PostTypeBadge(type: post.postType)
            moreMenu
        }
    }

    // MARK: - Photo Placeholder

    private var photoPlaceholder: some View {
        LinearGradient(
            colors: gradientColors(for: post.postType),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            Image(systemName: photoIcon(for: post.postType))
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.white.opacity(0.7))
        )
    }

    private func gradientColors(for type: PostType) -> [Color] {
        switch type {
        case .winCelebration:
            return [Color.dinkrAmber.opacity(0.7), Color.dinkrCoral.opacity(0.85)]
        case .highlight:
            return [Color.dinkrGreen.opacity(0.55), Color.dinkrSky.opacity(0.65)]
        case .courtReview:
            return [Color.dinkrNavy.opacity(0.6), Color.dinkrSky.opacity(0.5)]
        default:
            return [Color.dinkrSky.opacity(0.4), Color.dinkrGreen.opacity(0.4)]
        }
    }

    private func photoIcon(for type: PostType) -> String {
        switch type {
        case .winCelebration:    return "trophy.fill"
        case .highlight:         return "star.fill"
        case .courtReview:       return "mappin.circle.fill"
        default:                 return "photo"
        }
    }

    // MARK: - Content Body

    private var contentBody: some View {
        Text(post.content)
            .font(.subheadline)
            .foregroundStyle(Color.primary)
            .lineLimit(6)
    }

    // MARK: - Type-specific Content

    @ViewBuilder
    private var typeSpecificContent: some View {
        switch post.postType {
        case .courtReview:
            courtReviewCard
        case .winCelebration:
            winCelebrationCard
        case .lookingForGame:
            lookingForGameCard
        default:
            EmptyView()
        }
    }

    // Court Review: star rating + court name chip
    private var courtReviewCard: some View {
        HStack(spacing: 10) {
            // Stars
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= mockStarRating ? "star.fill" : "star")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(star <= mockStarRating ? Color.dinkrAmber : Color.secondary.opacity(0.35))
                }
            }

            Text("\(mockStarRating).0")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.dinkrAmber)

            Spacer()

            // Court chip
            HStack(spacing: 4) {
                Image(systemName: "mappin.fill")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.dinkrNavy)
                Text(mockCourtName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrNavy)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.dinkrNavy.opacity(0.08), in: Capsule())
            .overlay(Capsule().stroke(Color.dinkrNavy.opacity(0.15), lineWidth: 1))
        }
        .padding(12)
        .background(Color.dinkrAmber.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.dinkrAmber.opacity(0.18), lineWidth: 1)
        )
    }

    // Win Celebration: trophy + score
    private var winCelebrationCard: some View {
        HStack(spacing: 12) {
            Text("🏆")
                .font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text("Match Result")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dinkrGreen)
                Text("11–7 · 11–9")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dinkrNavy)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color.dinkrGreen)
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [Color.dinkrGreen.opacity(0.07), Color.dinkrAmber.opacity(0.05)],
                startPoint: .leading, endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.dinkrGreen.opacity(0.2), lineWidth: 1)
        )
    }

    // Looking for Game: compact detail card
    private var lookingForGameCard: some View {
        HStack(spacing: 0) {
            lfgDetail(icon: "figure.pickleball", label: "Doubles", color: Color.dinkrGreen)
            Divider().frame(height: 32).padding(.horizontal, 10)
            lfgDetail(icon: "chart.bar.fill", label: "3.5+", color: Color.dinkrSky)
            Divider().frame(height: 32).padding(.horizontal, 10)
            lfgDetail(icon: "calendar", label: "Sat 9am", color: Color.dinkrAmber)
            Spacer()
            Text("Join")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.dinkrGreen, in: Capsule())
                .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 4, y: 2)
        }
        .padding(12)
        .background(Color.dinkrAmber.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.dinkrAmber.opacity(0.18), lineWidth: 1)
        )
    }

    private func lfgDetail(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.primary)
        }
    }

    // MARK: - Tags Row

    private var tagsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(post.tags.prefix(5), id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.dinkrSky)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.dinkrSky.opacity(0.08), in: Capsule())
                        .overlay(Capsule().stroke(Color.dinkrSky.opacity(0.2), lineWidth: 1))
                }
            }
        }
    }

    // MARK: - Engagement Row

    private var engagementRow: some View {
        HStack(spacing: 6) {
            // Like button with animated heart
            Button {
                withAnimation(.interpolatingSpring(stiffness: 500, damping: 15)) {
                    heartScale = 1.35
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                        heartScale = 1.0
                    }
                }
                HapticManager.medium()
                onLike()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(post.isLiked ? Color.dinkrCoral : Color.secondary)
                        .scaleEffect(heartScale)
                    Text(post.likes > 0 ? "\(post.likes)" : "Like")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(post.isLiked ? Color.dinkrCoral : Color.secondary)
                }
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: post.isLiked)

            Divider().frame(height: 16).padding(.horizontal, 4)

            // Comment button
            Button {
                showCommentThread = true
                onComment()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                    Text(post.commentCount > 0 ? "\(post.commentCount)" : "Reply")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.secondary)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Share button
            Button {
                showShareSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - More Menu

    private var moreMenu: some View {
        Menu {
            Button {
                HapticManager.selection()
                showSaveSheet = true
            } label: {
                Label("Save to Collection", systemImage: "bookmark")
            }

            Button {
                UIPasteboard.general.string = "https://dinkr.app/post/\(post.id)"
                HapticManager.selection()
            } label: {
                Label("Copy Link", systemImage: "link")
            }

            Button {
                showShareSheet = true
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            Divider()

            Button(role: .destructive) {
                HapticManager.medium()
                showReportSheet = true
            } label: {
                Label("Report Post", systemImage: "flag")
            }

            Button(role: .destructive) {
                HapticManager.medium()
                // Block user — handled by moderation service in production
            } label: {
                Label("Block User", systemImage: "hand.raised")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
                .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ShareSheet (UIActivityViewController wrapper)

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}

// MARK: - PostTypeBadge

struct PostTypeBadge: View {
    let type: PostType

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.filterIcon)
                .font(.system(size: 9, weight: .bold))
            Text(type.filterLabel)
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(type.filterColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(type.filterColor.opacity(0.10), in: Capsule())
        .overlay(Capsule().stroke(type.filterColor.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            PostCardView(post: Post.mockPosts[0], onLike: {}, onComment: {})
            PostCardView(post: Post.mockPosts[1], onLike: {}, onComment: {})
            PostCardView(post: Post.mockPosts[3], onLike: {}, onComment: {})
            PostCardView(post: Post.mockPosts[4], onLike: {}, onComment: {})
        }
        .padding()
    }
    .background(Color.appBackground)
}

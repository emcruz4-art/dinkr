import SwiftUI

// MARK: - TrendingPost

/// A lightweight wrapper that pairs a Post with a view count for trending display.
struct TrendingPost: Identifiable {
    var id: String { post.id }
    let post: Post
    let viewCount: Int
}

extension TrendingPost {
    /// Five trending posts derived from the mock data — highest view counts win.
    static let mockTrending: [TrendingPost] = [
        TrendingPost(post: Post.mockPosts[8],  viewCount: 14_200),   // Austin Open champion
        TrendingPost(post: Post.mockPosts[6],  viewCount: 9_800),    // Morgan wins first round robin
        TrendingPost(post: Post.mockPosts[5],  viewCount: 7_300),    // Tennis pro humbled
        TrendingPost(post: Post.mockPosts[2],  viewCount: 5_600),    // Poaching tip
        TrendingPost(post: Post.mockPosts[11], viewCount: 4_100),    // Mueller free play
    ]
}

// MARK: - HomeFeedView

struct HomeFeedView: View {
    var viewModel: HomeViewModel
    @State private var commentPost: Post? = nil
    @State private var showCollections = false
    @State private var showFriendActivity = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else if viewModel.posts.isEmpty {
                    // Trending still shows even when the main feed is empty
                    TrendingSection()
                    EmptyStateView(
                        icon: "bubble.left.and.bubble.right",
                        title: "Nothing Here Yet",
                        message: "Follow players and join groups to see their posts.",
                        actionLabel: "Find Players",
                        action: {}
                    )
                    .padding(.top, 40)
                } else {
                    // ── Trending section ────────────────────────────────────
                    TrendingSection()

                    // ── Main feed ───────────────────────────────────────────
                    ForEach(viewModel.posts) { post in
                        PostCardView(
                            post: post,
                            onLike: {
                                viewModel.likePost(post, userId: viewModel.currentUserId ?? "")
                            },
                            onComment: {
                                commentPost = post
                            }
                        )
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .refreshable { await viewModel.loadFeed() }
        .sheet(item: $commentPost) { post in
            CommentSheet(
                post: post,
                currentUserId: viewModel.currentUserId ?? "",
                currentUserName: viewModel.currentUserName ?? "You",
                currentUserAvatarURL: nil
            )
        }
        .sheet(isPresented: $showCollections) {
            PostCollectionsView()
        }
        .sheet(isPresented: $showFriendActivity) {
            NavigationStack {
                FriendActivityView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFriendActivity = true
                } label: {
                    Image(systemName: "person.2.wave.2")
                        .foregroundStyle(Color.dinkrGreen)
                }
                .accessibilityLabel("Friend Activity")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCollections = true
                } label: {
                    Image(systemName: "rectangle.stack")
                        .foregroundStyle(Color.dinkrGreen)
                }
                .accessibilityLabel("Collections")
            }
        }
    }
}

// MARK: - TrendingSection

private struct TrendingSection: View {
    private let trendingPosts = TrendingPost.mockTrending

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack(alignment: .center) {
                Text("🔥 Trending in Your Area")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.dinkrNavy)
                Spacer()
                Button("See all") {}
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.dinkrGreen)
            }
            .padding(.horizontal, 16)

            // Horizontal card scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(trendingPosts) { trending in
                        TrendingCard(trending: trending)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - TrendingCard

private struct TrendingCard: View {
    let trending: TrendingPost

    private var gradientColors: [Color] {
        switch trending.post.postType {
        case .winCelebration:  return [Color.dinkrGreen, Color.dinkrSky]
        case .highlight:       return [Color.dinkrCoral, Color.dinkrAmber]
        case .question:        return [Color.dinkrSky, Color.dinkrNavy]
        case .courtReview:     return [Color(red: 0.55, green: 0.25, blue: 0.80), Color.dinkrSky]
        case .lookingForGame:  return [Color.dinkrAmber, Color.dinkrCoral]
        case .general:         return [Color.dinkrNavy, Color.dinkrSky]
        }
    }

    private var typeIcon: String {
        switch trending.post.postType {
        case .winCelebration:  return "trophy.fill"
        case .highlight:       return "bolt.fill"
        case .question:        return "lightbulb.fill"
        case .courtReview:     return "mappin.circle.fill"
        case .lookingForGame:  return "person.2.fill"
        case .general:         return "text.bubble.fill"
        }
    }

    private var formattedViews: String {
        trending.viewCount >= 1000
            ? String(format: "%.1fk", Double(trending.viewCount) / 1_000.0)
            : "\(trending.viewCount)"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background gradient
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Content overlay
            VStack(alignment: .leading, spacing: 0) {
                // Post type icon centred in upper region
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: typeIcon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                    Spacer()
                }
                Spacer()

                // Bottom info strip
                VStack(alignment: .leading, spacing: 3) {
                    // Trending badge
                    Text("🔥 Trending")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.dinkrAmber)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.black.opacity(0.35), in: Capsule())

                    // Like count
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9))
                        Text("\(trending.post.likes)")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.9))
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [.black.opacity(0.55), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
        }
        .frame(width: 80, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 3)
        .accessibilityLabel("\(trending.post.authorName): \(trending.post.content.prefix(40))")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HomeFeedView(viewModel: {
            let vm = HomeViewModel()
            vm.posts = Post.mockPosts
            return vm
        }())
    }
}

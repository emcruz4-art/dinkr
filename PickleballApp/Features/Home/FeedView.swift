import SwiftUI

struct FeedView: View {
    var viewModel: HomeViewModel
    @State private var commentPost: Post? = nil

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else if viewModel.posts.isEmpty {
                    EmptyStateView(
                        icon: "bubble.left.and.bubble.right",
                        title: "Nothing Here Yet",
                        message: "Follow players and join groups to see their posts.",
                        actionLabel: "Find Players",
                        action: {}
                    )
                    .padding(.top, 40)
                } else {
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
    }
}

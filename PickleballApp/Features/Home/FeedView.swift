import SwiftUI

struct FeedView: View {
    var viewModel: HomeViewModel

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
                        PostCardView(post: post) {
                            viewModel.likePost(post)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .refreshable { await viewModel.loadFeed() }
    }
}

import SwiftUI

struct GroupFeedView: View {
    let group: Group
    @State private var posts: [Post] = []

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if posts.isEmpty {
                    EmptyStateView(
                        icon: "bubble.left.and.bubble.right",
                        title: "No Posts Yet",
                        message: "Be the first to post in \(group.name)!"
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(posts) { post in
                        PostCardView(post: post, onLike: {})
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .onAppear {
            posts = Post.mockPosts.filter { $0.groupId == group.id }
        }
    }
}

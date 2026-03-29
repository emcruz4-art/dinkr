import SwiftUI

// MARK: - Comment Model

struct Comment: Identifiable {
    var id: String
    var authorName: String
    var authorInitial: Character
    var text: String
    var timestamp: Date
    var likesCount: Int
    var isLiked: Bool
}

extension Comment {
    static let mockComments: [Comment] = [
        Comment(
            id: "c1",
            authorName: "Maria Chen",
            authorInitial: "M",
            text: "Great shot! That backhand drive at the end was insane 🔥",
            timestamp: Date().addingTimeInterval(-120),
            likesCount: 12,
            isLiked: false
        ),
        Comment(
            id: "c2",
            authorName: "Jordan Smith",
            authorInitial: "J",
            text: "Which paddle are you using? Looks like a Selkirk but I can't tell.",
            timestamp: Date().addingTimeInterval(-300),
            likesCount: 5,
            isLiked: true
        ),
        Comment(
            id: "c3",
            authorName: "Sarah Johnson",
            authorInitial: "S",
            text: "We should play sometime! I'm at Mueller every Saturday morning.",
            timestamp: Date().addingTimeInterval(-600),
            likesCount: 8,
            isLiked: false
        ),
        Comment(
            id: "c4",
            authorName: "Chris Park",
            authorInitial: "C",
            text: "That kitchen game is elite. No wonder you're climbing the ladder 💪",
            timestamp: Date().addingTimeInterval(-900),
            likesCount: 19,
            isLiked: false
        ),
        Comment(
            id: "c5",
            authorName: "Taylor Kim",
            authorInitial: "T",
            text: "As a beginner this is so inspiring to watch! Goals right here.",
            timestamp: Date().addingTimeInterval(-1800),
            likesCount: 3,
            isLiked: false
        ),
        Comment(
            id: "c6",
            authorName: "Jamie Lee",
            authorInitial: "J",
            text: "Former tennis pro here — the dink patience in this clip is real. You've got serious touch.",
            timestamp: Date().addingTimeInterval(-3600),
            likesCount: 27,
            isLiked: true
        ),
        Comment(
            id: "c7",
            authorName: "Morgan Davis",
            authorInitial: "M",
            text: "I was at this game! The crowd was going nuts on that last point 🎉",
            timestamp: Date().addingTimeInterval(-7200),
            likesCount: 9,
            isLiked: false
        ),
        Comment(
            id: "c8",
            authorName: "Riley Torres",
            authorInitial: "R",
            text: "Stack formation locked in — this is how you do it. Tag me when you want to run drills!",
            timestamp: Date().addingTimeInterval(-10800),
            likesCount: 14,
            isLiked: false
        ),
    ]
}

// MARK: - Post Detail View

struct PostDetailView: View {
    let post: Post

    @State private var comments: [Comment] = Comment.mockComments
    @State private var commentText = ""
    @State private var replyPrefix = ""
    @FocusState private var inputFocused: Bool
    @State private var newCommentIds: Set<String> = []

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Original Post
                        postHeader
                        Divider().padding(.vertical, 8)
                        // Comment Count Header
                        Text("\(comments.count) Comments")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)

                        // Comments
                        LazyVStack(spacing: 0) {
                            ForEach($comments) { $comment in
                                CommentRow(
                                    comment: $comment,
                                    isNew: newCommentIds.contains(comment.id)
                                ) { name in
                                    replyPrefix = "@\(name) "
                                    commentText = replyPrefix
                                    inputFocused = true
                                }
                                .id(comment.id)
                                Divider().padding(.leading, 60)
                            }
                        }

                        // Spacer for pinned input bar
                        Color.clear.frame(height: 72)
                    }
                }
                .onChange(of: comments.count) { _, _ in
                    if let last = comments.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Pinned Comment Input Bar
            commentInputBar
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.appBackground.ignoresSafeArea())
    }

    // MARK: - Original Post Header

    private var postHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.dinkrNavy.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text(String(post.authorName.prefix(1)))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.dinkrNavy)
                }

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

            Text(post.content)
                .font(.subheadline)

            if !post.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(post.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.dinkrSky)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.dinkrSky.opacity(0.10), in: Capsule())
                        }
                    }
                }
            }

            HStack(spacing: 20) {
                Label("\(post.likes)", systemImage: post.isLiked ? "heart.fill" : "heart")
                    .font(.subheadline)
                    .foregroundStyle(post.isLiked ? .red : .secondary)

                Label("\(post.commentCount)", systemImage: "bubble.left")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    // share stub
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
    }

    // MARK: - Comment Input Bar

    private var commentInputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen.opacity(0.18))
                        .frame(width: 32, height: 32)
                    Text(String(User.mockCurrentUser.displayName.prefix(1)))
                        .font(.callout.weight(.bold))
                        .foregroundStyle(Color.dinkrGreen)
                }

                TextField("Add a comment...", text: $commentText, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(4)
                    .focused($inputFocused)
                    .onChange(of: commentText) { _, newValue in
                        // If user clears back past the reply prefix, clear the prefix
                        if !newValue.hasPrefix(replyPrefix) {
                            replyPrefix = ""
                        }
                    }

                Button {
                    submitComment()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(commentText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color.secondary.opacity(0.4)
                            : Color.dinkrGreen)
                }
                .buttonStyle(.plain)
                .disabled(commentText.trimmingCharacters(in: .whitespaces).isEmpty)
                .animation(.easeInOut(duration: 0.2), value: commentText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.cardBackground)
        }
    }

    // MARK: - Submit Comment

    private func submitComment() {
        let trimmed = commentText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let newId = UUID().uuidString
        let newComment = Comment(
            id: newId,
            authorName: User.mockCurrentUser.displayName,
            authorInitial: User.mockCurrentUser.displayName.first ?? "A",
            text: trimmed,
            timestamp: Date(),
            likesCount: 0,
            isLiked: false
        )

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            comments.append(newComment)
            newCommentIds.insert(newId)
        }

        commentText = ""
        replyPrefix = ""
        inputFocused = false

        // Remove the "new" highlight after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            newCommentIds.remove(newId)
        }
    }
}

// MARK: - Comment Row

private struct CommentRow: View {
    @Binding var comment: Comment
    let isNew: Bool
    let onReply: (String) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.18))
                    .frame(width: 36, height: 36)
                Text(String(comment.authorInitial))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.dinkrGreen)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Name + Comment inline
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(comment.authorName)
                        .font(.subheadline.weight(.semibold))
                    Text(comment.text)
                        .font(.subheadline)
                }

                // Timestamp + Like + Reply
                HStack(spacing: 14) {
                    Text(comment.timestamp.relativeString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            comment.isLiked.toggle()
                            comment.likesCount += comment.isLiked ? 1 : -1
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                                .font(.caption)
                                .foregroundStyle(comment.isLiked ? .red : .secondary)
                            if comment.likesCount > 0 {
                                Text("\(comment.likesCount)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        onReply(comment.authorName)
                    } label: {
                        Text("Reply")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isNew ? Color.dinkrGreen.opacity(0.07) : Color.clear)
        .animation(.easeOut(duration: 0.4), value: isNew)
        .contextMenu {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    comment.isLiked.toggle()
                    comment.likesCount += comment.isLiked ? 1 : -1
                }
            } label: {
                Label(comment.isLiked ? "Unlike" : "Like", systemImage: comment.isLiked ? "heart.fill" : "heart")
            }

            Button {
                onReply(comment.authorName)
            } label: {
                Label("Reply", systemImage: "arrowshape.turn.up.left")
            }

            Button {
                UIPasteboard.general.string = comment.text
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }

            Divider()

            Button(role: .destructive) {
                // report stub
            } label: {
                Label("Report", systemImage: "flag")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PostDetailView(post: Post.mockPosts[0])
    }
}

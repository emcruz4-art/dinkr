import SwiftUI

// MARK: - CommentThreadView

struct CommentThreadView: View {
    let post: Post

    @Environment(AuthService.self) private var authService
    @State private var comments: [CommentThreadItem] = []
    @State private var commentText: String = ""
    @State private var replyingToId: String? = nil
    @State private var replyDraft: [String: String] = [:]
    @FocusState private var inputFocused: Bool

    private var currentUserInitial: String {
        String((authService.currentUser?.displayName ?? "?").prefix(1))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if comments.isEmpty {
                    emptyState
                } else {
                    commentList
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Text("Comments")
                            .font(.headline)
                        if !comments.isEmpty {
                            Text("\(comments.count)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.dinkrGreen)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.dinkrGreen.opacity(0.12), in: Capsule())
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomInputBar
            }
        }
        .onAppear {
            comments = CommentThreadItem.from(Comment.mockComments(for: post.id))
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.dinkrGreen.opacity(0.5))
            Text("No comments yet. Be the first!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Comment List

    private var commentList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach($comments) { $item in
                    CommentThreadRow(item: $item, replyingToId: $replyingToId, replyDraft: $replyDraft)
                    Divider()
                        .padding(.leading, 56)
                }
            }
            .padding(.bottom, 16)
        }
    }

    // MARK: - Bottom Input Bar

    private var bottomInputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen.opacity(0.18))
                        .frame(width: 34, height: 34)
                    Text(currentUserInitial)
                        .font(.callout.weight(.bold))
                        .foregroundStyle(Color.dinkrGreen)
                }

                TextField("Add a comment…", text: $commentText, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(1...4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20))
                    .focused($inputFocused)

                Button {
                    submitTopLevelComment()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color.secondary.opacity(0.35)
                            : Color.dinkrGreen)
                }
                .buttonStyle(.plain)
                .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .animation(.easeInOut(duration: 0.15), value: commentText.isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.appBackground)
        }
    }

    // MARK: - Submit

    private func submitTopLevelComment() {
        let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newComment = Comment(
            id: UUID().uuidString,
            postId: post.id,
            userId: authService.currentUser?.id ?? "",
            userName: authService.currentUser?.displayName ?? "You",
            body: trimmed,
            date: Date(),
            likeCount: 0,
            replies: []
        )
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            comments.insert(CommentThreadItem(comment: newComment), at: 0)
        }
        commentText = ""
        inputFocused = false
    }
}

// MARK: - CommentThreadItem (UI state wrapper)

struct CommentThreadItem: Identifiable {
    var id: String { comment.id }
    var comment: Comment
    var isLiked: Bool = false
    var likeCount: Int
    var replyItems: [ReplyThreadItem]

    init(comment: Comment) {
        self.comment = comment
        self.likeCount = comment.likeCount
        self.replyItems = comment.replies.map { ReplyThreadItem(comment: $0) }
    }

    static func from(_ comments: [Comment]) -> [CommentThreadItem] {
        comments.map { CommentThreadItem(comment: $0) }
    }
}

struct ReplyThreadItem: Identifiable {
    var id: String { comment.id }
    var comment: Comment
    var isLiked: Bool = false
    var likeCount: Int

    init(comment: Comment) {
        self.comment = comment
        self.likeCount = comment.likeCount
    }
}

// MARK: - CommentThreadRow

private struct CommentThreadRow: View {
    @Binding var item: CommentThreadItem
    @Binding var replyingToId: String?
    @Binding var replyDraft: [String: String]
    @Environment(AuthService.self) private var authService

    var isShowingReplyComposer: Bool { replyingToId == item.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main comment
            HStack(alignment: .top, spacing: 10) {
                avatarCircle(initial: String(item.comment.userName.prefix(1)), size: 36, color: Color.dinkrGreen)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(item.comment.userName)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        timestampChip(item.comment.date)
                    }

                    Text(item.comment.body)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 16) {
                        likeButton(isLiked: $item.isLiked, count: $item.likeCount)

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                replyingToId = isShowingReplyComposer ? nil : item.id
                                if replyDraft[item.id] == nil {
                                    replyDraft[item.id] = ""
                                }
                            }
                        } label: {
                            Text("Reply")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(isShowingReplyComposer ? Color.dinkrGreen : Color.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Replies
            if !item.replyItems.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach($item.replyItems) { $reply in
                        ReplyRow(reply: $reply)
                    }
                }
                .padding(.leading, 52)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color.dinkrGreen.opacity(0.3))
                        .frame(width: 2)
                        .padding(.leading, 52)
                        .padding(.vertical, 4)
                }
            }

            // Inline reply composer
            if isShowingReplyComposer {
                replyComposer(for: item.id)
                    .padding(.leading, 52)
                    .padding(.trailing, 16)
                    .padding(.bottom, 10)
                    .transition(.asymmetric(
                        insertion: .push(from: .top).combined(with: .opacity),
                        removal: .push(from: .bottom).combined(with: .opacity)
                    ))
            }
        }
    }

    @ViewBuilder
    private func replyComposer(for commentId: String) -> some View {
        HStack(spacing: 8) {
            TextField("Reply…", text: Binding(
                get: { replyDraft[commentId] ?? "" },
                set: { replyDraft[commentId] = $0 }
            ))
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))

            Button {
                submitReply(for: commentId)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title3)
                    .foregroundStyle((replyDraft[commentId] ?? "").trimmingCharacters(in: .whitespaces).isEmpty
                        ? Color.secondary.opacity(0.35)
                        : Color.dinkrGreen)
            }
            .buttonStyle(.plain)
            .disabled((replyDraft[commentId] ?? "").trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func submitReply(for commentId: String) {
        let trimmed = (replyDraft[commentId] ?? "").trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let newReplyComment = Comment(
            id: UUID().uuidString,
            postId: item.comment.postId,
            userId: authService.currentUser?.id ?? "",
            userName: authService.currentUser?.displayName ?? "You",
            body: trimmed,
            date: Date(),
            likeCount: 0,
            replies: []
        )
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            item.replyItems.append(ReplyThreadItem(comment: newReplyComment))
        }
        replyDraft[commentId] = ""
        replyingToId = nil
    }
}

// MARK: - ReplyRow

private struct ReplyRow: View {
    @Binding var reply: ReplyThreadItem

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            avatarCircle(initial: String(reply.comment.userName.prefix(1)), size: 28, color: Color.dinkrGreen.opacity(0.8))

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(reply.comment.userName)
                        .font(.caption.weight(.semibold))
                    Spacer()
                    timestampChip(reply.comment.date)
                }
                Text(reply.comment.body)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)

                likeButton(isLiked: $reply.isLiked, count: $reply.likeCount)
            }
        }
        .padding(.vertical, 8)
        .padding(.trailing, 16)
    }
}

// MARK: - Shared helpers (file-level free functions)

private func avatarCircle(initial: String, size: CGFloat, color: Color) -> some View {
    ZStack {
        Circle()
            .fill(color.opacity(0.18))
            .frame(width: size, height: size)
        Text(initial)
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundStyle(color)
    }
}

private func timestampChip(_ date: Date) -> some View {
    Text(date.relativeString)
        .font(.caption2)
        .foregroundStyle(.white.opacity(0.7))
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color.secondary.opacity(0.25), in: Capsule())
}

private func likeButton(isLiked: Binding<Bool>, count: Binding<Int>) -> some View {
    Button {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
            isLiked.wrappedValue.toggle()
            count.wrappedValue += isLiked.wrappedValue ? 1 : -1
        }
    } label: {
        HStack(spacing: 4) {
            Image(systemName: isLiked.wrappedValue ? "heart.fill" : "heart")
                .font(.caption)
                .foregroundStyle(isLiked.wrappedValue ? .red : .secondary)
                .scaleEffect(isLiked.wrappedValue ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.55), value: isLiked.wrappedValue)
            if count.wrappedValue > 0 {
                Text("\(count.wrappedValue)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    .buttonStyle(.plain)
}

// MARK: - Preview

#Preview {
    CommentThreadView(post: Post.mockPosts[0])
}

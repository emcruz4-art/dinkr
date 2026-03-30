import SwiftUI
import FirebaseFirestore

struct CommentSheet: View {
    let post: Post
    let currentUserId: String
    let currentUserName: String
    let currentUserAvatarURL: String?

    @Environment(\.dismiss) private var dismiss
    @State private var comments: [Comment] = []
    @State private var isLoading = false
    @State private var commentText = ""
    @State private var isPosting = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    if isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if comments.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 36))
                                .foregroundStyle(Color.dinkrGreen.opacity(0.6))
                            Text("No comments yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Be the first to comment!")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    } else {
                        List(comments) { comment in
                            CommentRow(comment: comment)
                                .listRowBackground(Color.cardBackground)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }

                    // Spacer to push content above the composer
                    Color.clear.frame(height: 72)
                }

                // Sticky bottom composer
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 10) {
                        AvatarView(
                            urlString: currentUserAvatarURL,
                            displayName: currentUserName,
                            size: 32
                        )

                        TextField("Add a comment…", text: $commentText, axis: .vertical)
                            .font(.subheadline)
                            .lineLimit(1...4)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20))

                        if isPosting {
                            ProgressView()
                                .frame(width: 32, height: 32)
                        } else {
                            Button {
                                Task { await submitComment() }
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundStyle(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? Color.secondary.opacity(0.4)
                                        : Color.dinkrGreen)
                            }
                            .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.appBackground)
                }
            }
            .navigationTitle("\(post.commentCount) Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .task { await fetchComments() }
    }

    // MARK: - Actions

    private func fetchComments() async {
        isLoading = true
        defer { isLoading = false }
        do {
            comments = try await FirestoreService.shared.queryCollectionOrdered(
                collection: "posts/\(post.id)/comments",
                orderBy: "createdAt",
                descending: false
            )
        } catch {
            print("[CommentSheet] fetchComments error: \(error)")
        }
    }

    private func submitComment() async {
        let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isPosting = true
        defer { isPosting = false }
        do {
            let commentId = UUID().uuidString
            let comment = Comment(
                id: commentId,
                postId: post.id,
                authorId: currentUserId,
                authorName: currentUserName,
                authorAvatarURL: currentUserAvatarURL,
                content: trimmed,
                createdAt: Date()
            )
            try await FirestoreService.shared.setDocument(
                comment,
                collection: "posts/\(post.id)/comments",
                documentId: commentId
            )
            try await FirestoreService.shared.updateDocument(
                collection: FirestoreCollections.posts,
                documentId: post.id,
                data: ["commentCount": FieldValue.increment(Int64(1))]
            )
            await MainActor.run {
                comments.append(comment)
                commentText = ""
            }
        } catch {
            print("[CommentSheet] submitComment error: \(error)")
        }
    }
}

// MARK: - CommentRow

private struct CommentRow: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            AvatarView(
                urlString: comment.authorAvatarURL,
                displayName: comment.authorName,
                size: 34
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(comment.authorName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)
                    Text(comment.createdAt.relativeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(comment.content)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

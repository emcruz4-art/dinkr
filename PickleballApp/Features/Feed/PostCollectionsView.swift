import SwiftUI

// MARK: - Models

struct PostCollection: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var posts: [Post]

    var postCount: Int { posts.count }

    /// Returns gradient colors for the thumbnail placeholder.
    var gradientColors: [Color] {
        switch name {
        case "Saved":          return [Color.dinkrNavy, Color.dinkrSky]
        case "Techniques":     return [Color.dinkrGreen, Color.dinkrSky]
        case "Wins":           return [Color.dinkrAmber, Color.dinkrCoral]
        case "Courts to Visit": return [Color.dinkrSky, Color.dinkrGreen]
        default:
            // Deterministic color pair from the collection name's hash
            let colors: [[Color]] = [
                [Color.dinkrGreen, Color.dinkrNavy],
                [Color.dinkrCoral, Color.dinkrAmber],
                [Color.dinkrSky, Color.dinkrCoral],
                [Color.dinkrAmber, Color.dinkrGreen],
            ]
            let index = abs(name.hashValue) % colors.count
            return colors[index]
        }
    }

    /// SF Symbol icon for the collection thumbnail.
    var iconName: String {
        switch name {
        case "Saved":          return "bookmark.fill"
        case "Techniques":     return "graduationcap.fill"
        case "Wins":           return "trophy.fill"
        case "Courts to Visit": return "mappin.circle.fill"
        default:               return "folder.fill"
        }
    }
}

// MARK: - PostCollectionsView

struct PostCollectionsView: View {
    @State private var collections: [PostCollection] = PostCollection.defaults
    @State private var showNewCollectionAlert = false
    @State private var newCollectionName = ""
    @State private var selectedCollection: PostCollection? = nil
    @State private var collectionToRename: PostCollection? = nil
    @State private var renameText = ""
    @State private var showRenameAlert = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if collections.isEmpty {
                    emptyState
                        .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(collections) { collection in
                            CollectionCard(collection: collection)
                                .onTapGesture {
                                    selectedCollection = collection
                                }
                                .contextMenu {
                                    Button {
                                        collectionToRename = collection
                                        renameText = collection.name
                                        showRenameAlert = true
                                    } label: {
                                        Label("Rename", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        withAnimation {
                                            collections.removeAll { $0.id == collection.id }
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(Color.appBackground)
            .navigationTitle("My Collections")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newCollectionName = ""
                        showNewCollectionAlert = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.dinkrGreen)
                    }
                }
            }
            // New collection alert
            .alert("New Collection", isPresented: $showNewCollectionAlert) {
                TextField("Collection name", text: $newCollectionName)
                Button("Create") {
                    let trimmed = newCollectionName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    let newCollection = PostCollection(name: trimmed, posts: [])
                    withAnimation { collections.append(newCollection) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Give your collection a name.")
            }
            // Rename alert
            .alert("Rename Collection", isPresented: $showRenameAlert) {
                TextField("Collection name", text: $renameText)
                Button("Save") {
                    let trimmed = renameText.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty,
                          let target = collectionToRename,
                          let index = collections.firstIndex(where: { $0.id == target.id })
                    else { return }
                    collections[index].name = trimmed
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter a new name for this collection.")
            }
            // Push to collection detail
            .navigationDestination(item: $selectedCollection) { collection in
                CollectionDetailView(collection: collection)
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 52))
                .foregroundStyle(Color.dinkrGreen.opacity(0.6))
            Text("No Collections Yet")
                .font(.headline)
                .foregroundStyle(Color.dinkrNavy)
            Text("Tap + to create your first collection.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - CollectionCard

private struct CollectionCard: View {
    let collection: PostCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Gradient thumbnail
            ZStack {
                LinearGradient(
                    colors: collection.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if collection.posts.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: collection.iconName)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                        Text("No posts saved yet")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                } else {
                    // Preview thumbnails: up to 4 mini-squares
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
                        ForEach(Array(collection.posts.prefix(4).enumerated()), id: \.offset) { _, post in
                            PostThumbnailSwatch(post: post)
                        }
                        // Fill remaining slots with dimmed squares
                        ForEach(collection.posts.count..<min(4, 4), id: \.self) { _ in
                            Color.white.opacity(0.15)
                        }
                    }
                    .padding(4)
                }
            }
            .frame(height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Info strip
            VStack(alignment: .leading, spacing: 2) {
                Text(collection.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dinkrNavy)
                    .lineLimit(1)
                Text("\(collection.postCount) post\(collection.postCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
            .padding(.horizontal, 2)
            .padding(.bottom, 4)
        }
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - PostThumbnailSwatch

private struct PostThumbnailSwatch: View {
    let post: Post

    var swatchColor: Color {
        switch post.postType {
        case .winCelebration:  return Color.dinkrGreen
        case .highlight:       return Color.dinkrCoral
        case .question:        return Color.dinkrSky
        case .courtReview:     return .purple
        case .lookingForGame:  return Color.dinkrAmber
        case .general:         return Color.dinkrNavy
        }
    }

    var body: some View {
        swatchColor.opacity(0.75)
            .frame(height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - CollectionDetailView

struct CollectionDetailView: View {
    let collection: PostCollection

    var body: some View {
        Group {
            if collection.posts.isEmpty {
                emptyState
            } else {
                List(collection.posts) { post in
                    PostMiniRow(post: post)
                        .listRowBackground(Color.cardBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
                .listStyle(.plain)
                .background(Color.appBackground)
            }
        }
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundStyle(Color.dinkrGreen.opacity(0.55))
            Text("No posts saved yet")
                .font(.headline)
                .foregroundStyle(Color.dinkrNavy)
            Text("Save posts to this collection and they'll appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

// MARK: - PostMiniRow

struct PostMiniRow: View {
    let post: Post

    private var typeColor: Color {
        switch post.postType {
        case .general:         return .secondary
        case .highlight:       return Color.dinkrCoral
        case .question:        return Color.dinkrSky
        case .winCelebration:  return Color.dinkrGreen
        case .courtReview:     return .purple
        case .lookingForGame:  return Color.dinkrAmber
        }
    }

    private var typeLabel: String {
        switch post.postType {
        case .general:         return "Post"
        case .highlight:       return "Highlight"
        case .question:        return "Tip"
        case .winCelebration:  return "Win"
        case .courtReview:     return "Court"
        case .lookingForGame:  return "LFG"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Type color swatch
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(typeColor.opacity(0.85))
                .frame(width: 4)
                .frame(minHeight: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(post.authorName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)
                    Spacer()
                    Text(typeLabel)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(typeColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(typeColor.opacity(0.12), in: Capsule())
                }
                Text(post.content)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                HStack(spacing: 12) {
                    Label("\(post.likes)", systemImage: "heart")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label("\(post.commentCount)", systemImage: "bubble.left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(post.createdAt.relativeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Default collections

extension PostCollection {
    static let defaults: [PostCollection] = [
        PostCollection(name: "Saved",           posts: [Post.mockPosts[3], Post.mockPosts[6]]),
        PostCollection(name: "Techniques",      posts: [Post.mockPosts[2], Post.mockPosts[7]]),
        PostCollection(name: "Wins",            posts: [Post.mockPosts[6], Post.mockPosts[8]]),
        PostCollection(name: "Courts to Visit", posts: []),
    ]
}

// MARK: - Preview

#Preview {
    PostCollectionsView()
}

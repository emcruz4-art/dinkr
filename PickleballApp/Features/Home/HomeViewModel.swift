import Foundation
import Observation
import FirebaseFirestore

struct PlayerSpotlightData {
    var userId: String
    var displayName: String
    var username: String
    var achievement: String
    var eventName: String
    var tags: [String]
}

@Observable
final class HomeViewModel {
    var posts: [Post] = []
    var featuredPosts: [Post] = []
    var newsArticles: [NewsArticle] = []
    var spotlight: PlayerSpotlightData? = nil
    var isLoading = false
    var showCreatePost = false
    var upcomingGameCount = 2
    var nearbyGameCount = 3
    var nearestDistance = "0.8 mi"
    var nearbyPlayerCount = 12
    var newPlayersThisWeek = 3

    // MARK: - Pagination state

    var lastPostDocument: DocumentSnapshot? = nil
    var hasMorePosts: Bool = true
    var isLoadingMore: Bool = false

    private let firestoreService = FirestoreService.shared
    private var postListener: ListenerRegistration?
    private var lastLoadTime: Date = Date()

    // MARK: - Real-time feed listener

    /// Attaches a listener that only picks up posts created after `lastLoadTime`,
    /// prepending them to the front of the existing paginated array.
    func startFeedListener() {
        postListener?.remove()
        let threshold = lastLoadTime
        postListener = firestoreService.listenToCollectionWhere(
            collection: FirestoreCollections.posts,
            whereField: "createdAt",
            isGreaterThanOrEqualTo: threshold,
            orderBy: "createdAt"
        ) { [weak self] (newPosts: [Post]) in
            guard let self else { return }
            DispatchQueue.main.async {
                // Prepend genuinely new posts that aren't already in the array
                let existingIDs = Set(self.posts.map(\.id))
                let fresh = newPosts.filter { !existingIDs.contains($0.id) }
                if !fresh.isEmpty {
                    self.posts.insert(contentsOf: fresh, at: 0)
                    self.featuredPosts = Array(self.posts.prefix(3))
                }
            }
        }
    }

    func stopFeedListener() {
        postListener?.remove()
        postListener = nil
    }

    // MARK: - Load (first page)

    func loadFeed() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result: (items: [Post], lastDocument: DocumentSnapshot?) = try await firestoreService.getFirstPage(
                collection: FirestoreCollections.posts,
                orderBy: "createdAt",
                descending: true,
                pageSize: 20
            )
            await MainActor.run {
                posts = result.items
                featuredPosts = Array(result.items.prefix(3))
                lastPostDocument = result.lastDocument
                hasMorePosts = result.items.count >= 20
                lastLoadTime = Date()
            }
        } catch {
            print("[HomeViewModel] loadFeed error: \(error)")
        }

        // Attach the live listener for posts arriving after this load
        startFeedListener()

        // Static data that doesn't need a live feed
        newsArticles = NewsArticle.mockArticles
    }

    // MARK: - Load more (subsequent pages)

    func loadMorePosts() async {
        guard hasMorePosts, !isLoadingMore else { return }
        await MainActor.run { isLoadingMore = true }
        defer { Task { @MainActor in isLoadingMore = false } }

        do {
            let result: (items: [Post], lastDocument: DocumentSnapshot?) = try await firestoreService.getPage(
                collection: FirestoreCollections.posts,
                orderBy: "createdAt",
                descending: true,
                pageSize: 20,
                after: lastPostDocument
            )
            await MainActor.run {
                posts.append(contentsOf: result.items)
                lastPostDocument = result.lastDocument
                hasMorePosts = result.items.count >= 20
            }
        } catch {
            print("[HomeViewModel] loadMorePosts error: \(error)")
        }
    }

    // MARK: - Post actions

    func likePost(_ post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].isLiked.toggle()
        let newLikes = posts[index].likes + (posts[index].isLiked ? 1 : -1)
        posts[index].likes = newLikes
        // Mirror change into featuredPosts if present
        if let fi = featuredPosts.firstIndex(where: { $0.id == post.id }) {
            featuredPosts[fi].isLiked = posts[index].isLiked
            featuredPosts[fi].likes = newLikes
        }
        Task {
            try? await firestoreService.updateDocument(
                collection: FirestoreCollections.posts,
                documentId: post.id,
                data: ["likes": newLikes]
            )
        }
    }

    func deletePost(_ post: Post) {
        posts.removeAll { $0.id == post.id }
        featuredPosts.removeAll { $0.id == post.id }
        Task {
            try? await firestoreService.deleteDocument(
                collection: FirestoreCollections.posts,
                documentId: post.id
            )
        }
    }

    // MARK: - Derived

    var featuredEvent: Event { Event.mockEvents[0] }
    var myGroups: [String] { ["S. Austin Crew", "4.0+ Pool", "Mueller Regulars"] }

    var greetingText: String {
        let first = currentUserName?.components(separatedBy: " ").first ?? "there"
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning, \(first)! ☀️"
        case 12..<17: return "Good afternoon, \(first)! 🌤️"
        case 17..<21: return "Good evening, \(first)! 🌅"
        default:      return "Hey \(first)! 🌙"
        }
    }

    var currentUserName: String? = nil
}


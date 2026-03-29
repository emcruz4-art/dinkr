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
    var newsArticles: [NewsArticle] = []
    var spotlight: PlayerSpotlightData? = nil
    var isLoading = false
    var showCreatePost = false
    var upcomingGameCount = 2
    var nearbyGameCount = 3
    var nearestDistance = "0.8 mi"
    var nearbyPlayerCount = 12
    var newPlayersThisWeek = 3

    private let firestoreService = FirestoreService.shared

    func loadFeed() async {
        isLoading = true
        defer { isLoading = false }
        do {
            posts = try await firestoreService.queryCollectionOrdered(
                collection: FirestoreCollections.posts,
                orderBy: "createdAt",
                descending: true,
                limit: 20
            )
            newsArticles = NewsArticle.mockArticles
        } catch {
            print("[HomeViewModel] loadFeed error: \(error)")
        }
    }

    func likePost(_ post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].isLiked.toggle()
        let newLikes = posts[index].likes + (posts[index].isLiked ? 1 : -1)
        posts[index].likes = newLikes
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
        Task {
            try? await firestoreService.deleteDocument(
                collection: FirestoreCollections.posts,
                documentId: post.id
            )
        }
    }

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

import Foundation
import Observation
import FirebaseFirestore

// MARK: - VideoCategory

enum VideoCategory: String, CaseIterable, Identifiable {
    case all         = "All"
    case highlights  = "Highlights"
    case tutorials   = "Tutorials"
    case tournaments = "Tournaments"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all:         return "play.rectangle.fill"
        case .highlights:  return "flame.fill"
        case .tutorials:   return "graduationcap.fill"
        case .tournaments: return "trophy.fill"
        }
    }
}

// MARK: - VideoHighlight

struct VideoHighlight: Identifiable {
    var id: String
    var title: String
    var playerName: String
    var courtName: String
    var duration: String       // e.g. "0:28"
    var viewCount: Int
    var likes: Int
    var category: VideoCategory

    static let mockHighlights: [VideoHighlight] = [
        VideoHighlight(
            id: "vh1",
            title: "Best Point of the Week 🔥",
            playerName: "Jamie Lee",
            courtName: "Mueller Courts",
            duration: "0:15",
            viewCount: 14_200,
            likes: 2871,
            category: .highlights
        ),
        VideoHighlight(
            id: "vh2",
            title: "Third-Shot Drop Master Class",
            playerName: "Maria Chen",
            courtName: "Zilker Park",
            duration: "3:42",
            viewCount: 8_430,
            likes: 1432,
            category: .tutorials
        ),
        VideoHighlight(
            id: "vh3",
            title: "Erne Winner at Open Play 😱",
            playerName: "Riley Torres",
            courtName: "Bartholomew Pool",
            duration: "0:10",
            viewCount: 21_300,
            likes: 3204,
            category: .highlights
        ),
        VideoHighlight(
            id: "vh4",
            title: "Austin Open — Finals Recap",
            playerName: "Jordan Smith",
            courtName: "Austin Tennis Center",
            duration: "4:55",
            viewCount: 31_800,
            likes: 5120,
            category: .tournaments
        ),
        VideoHighlight(
            id: "vh5",
            title: "Serve + Return Blueprint 🎯",
            playerName: "Sarah Johnson",
            courtName: "Northwest Rec Center",
            duration: "2:20",
            viewCount: 6_100,
            likes: 645,
            category: .tutorials
        ),
        VideoHighlight(
            id: "vh6",
            title: "Lob Recovery Comeback 🌟",
            playerName: "Chris Park",
            courtName: "Onion Creek Club",
            duration: "0:18",
            viewCount: 9_870,
            likes: 1876,
            category: .highlights
        ),
    ]
}

// MARK: - WeekendDay
/// Enriched weekend day with pickleball-specific game count,
/// used by WeekendForecastWidget alongside DayForecast.
struct WeekendDay: Identifiable {
    var id: String { dateString }
    var dateString: String   // "2026-03-30" — must match DayForecast.dateString
    var date: Date
    var weatherEmoji: String
    var temp: Double         // high temp °F
    var gameCount: Int

    static var mockWeekend: [WeekendDay] {
        let cal = Calendar.current
        let today = Date()
        // Find the upcoming Saturday
        let weekday = cal.component(.weekday, from: today) // 1=Sun … 7=Sat
        let daysUntilSat = (7 - weekday + 7) % 7
        guard
            let sat = cal.date(byAdding: .day, value: daysUntilSat == 0 ? 0 : daysUntilSat, to: today),
            let sun = cal.date(byAdding: .day, value: 1, to: sat),
            let mon = cal.date(byAdding: .day, value: 2, to: sat)
        else { return [] }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return [
            WeekendDay(dateString: fmt.string(from: sat), date: sat,  weatherEmoji: "☀️", temp: 78, gameCount: 3),
            WeekendDay(dateString: fmt.string(from: sun), date: sun,  weatherEmoji: "⛅️", temp: 72, gameCount: 2),
            WeekendDay(dateString: fmt.string(from: mon), date: mon,  weatherEmoji: "🌤️", temp: 75, gameCount: 1),
        ]
    }
}

// MARK: - SpotlightGameResult

struct SpotlightGameResult: Identifiable {
    enum GameResult { case win, loss }
    let id = UUID()
    var opponent: String
    var score: String
    var result: GameResult
    var date: String
}

// MARK: - NomineeData

struct NomineeData: Identifiable {
    let id = UUID()
    var displayName: String
    var username: String
}

// MARK: - PreviousSpotlight

struct PreviousSpotlight: Identifiable {
    let id = UUID()
    var displayName: String
    var username: String
    var weekLabel: String
}

// MARK: - PlayerSpotlightData

struct PlayerSpotlightData {
    var userId: String
    var displayName: String
    var username: String
    var achievement: String
    var eventName: String
    var tags: [String]
    // Extended detail fields
    var skillLevel: String
    var location: String
    var quote: String
    var winRate: String
    var dupr: String
    var gamesThisMonth: Int
    var streak: Int
    var recentGames: [SpotlightGameResult]
    var weekLabel: String

    static let mock = PlayerSpotlightData(
        userId: "player_001",
        displayName: "Marcus Webb",
        username: "marcuswebb",
        achievement: "Won Austin Open Singles Championship",
        eventName: "Austin Open 2026",
        tags: ["Singles Champion", "4.5+ Rated", "Tournament Ace"],
        skillLevel: "4.5",
        location: "Austin, TX",
        quote: "Pickleball saved my life. I'm here every morning at 6am!",
        winRate: "78%",
        dupr: "4.52",
        gamesThisMonth: 24,
        streak: 7,
        recentGames: [
            SpotlightGameResult(opponent: "D. Torres", score: "11-7, 11-5",      result: .win,  date: "Mar 29"),
            SpotlightGameResult(opponent: "K. Okafor", score: "11-9, 8-11, 11-6", result: .win,  date: "Mar 27"),
            SpotlightGameResult(opponent: "L. Park",   score: "7-11, 9-11",       result: .loss, date: "Mar 25")
        ],
        weekLabel: "Player of the Week"
    )

    static let previousSpotlights: [PreviousSpotlight] = [
        PreviousSpotlight(displayName: "Priya Sharma", username: "priyasharma", weekLabel: "Mar 22 Spotlight"),
        PreviousSpotlight(displayName: "Jamal Osei",   username: "jamalosei",   weekLabel: "Mar 15 Spotlight"),
        PreviousSpotlight(displayName: "Tina Nguyen",  username: "tinanguyen",  weekLabel: "Mar 8 Spotlight")
    ]

    static let nominees: [NomineeData] = [
        NomineeData(displayName: "Sofia Reyes", username: "sofiareyes"),
        NomineeData(displayName: "Ben Tran",    username: "bentran"),
        NomineeData(displayName: "Aisha Malik", username: "aishamalik")
    ]
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
    var weather: CurrentWeather? = nil
    var weekendForecast: [DayForecast] = []
    var weekendDays: [WeekendDay] = WeekendDay.mockWeekend
    var videoHighlights: [VideoHighlight] = VideoHighlight.mockHighlights
    var currentStreak: Int = 7

    // MARK: - Header computed properties

    /// Number of mock unread notifications shown on the bell badge.
    var unreadNotificationCount: Int = 3

    /// Number of currently live games shown in the header chip.
    var liveGameCount: Int {
        GameSession.mockSessions.filter { $0.liveScore != nil }.count
    }

    /// Weather summary string for the hero widget, e.g. "☀️ 78°F".
    var weatherSummary: String? {
        guard let w = weather else { return nil }
        return "\(w.emoji) \(Int(w.temperatureF))°F"
    }
    /// Each tuple is (day, gameCount) for the current Mon–Sun week
    var weekGames: [(Date, Int)] = {
        let cal = Calendar.current
        var comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        comps.weekday = 2 // Monday
        guard let monday = cal.date(from: comps) else { return [] }
        // Mock: Tue (index 1) = 1 game, Thu (index 3) = 1 game
        return (0..<7).compactMap { offset -> (Date, Int)? in
            guard let day = cal.date(byAdding: .day, value: offset, to: monday) else { return nil }
            let count = (offset == 1 || offset == 3) ? 1 : 0
            return (day, count)
        }
    }()

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
                var loadedPosts = result.items.isEmpty ? Post.mockPosts : result.items
                let uid = currentUserId ?? ""
                for i in loadedPosts.indices {
                    loadedPosts[i].isLiked = loadedPosts[i].likedBy.contains(uid)
                }
                posts = loadedPosts
                featuredPosts = Array(loadedPosts.prefix(3))
                lastPostDocument = result.lastDocument
                hasMorePosts = result.items.count >= 20
                lastLoadTime = Date()
            }
        } catch {
            print("[HomeViewModel] loadFeed error: \(error) — falling back to mock posts")
            await MainActor.run {
                let uid = currentUserId ?? ""
                var fallback = Post.mockPosts
                for i in fallback.indices {
                    fallback[i].isLiked = fallback[i].likedBy.contains(uid)
                }
                posts = fallback
                featuredPosts = Array(fallback.prefix(3))
                hasMorePosts = false
                lastLoadTime = Date()
            }
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

    func likePost(_ post: Post, userId: String) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        let isJoining = !posts[index].likedBy.contains(userId)
        if isJoining {
            posts[index].likedBy.append(userId)
        } else {
            posts[index].likedBy.removeAll { $0 == userId }
        }
        posts[index].isLiked = isJoining
        let newLikes = posts[index].likes + (isJoining ? 1 : -1)
        posts[index].likes = newLikes
        // Mirror change into featuredPosts if present
        if let fi = featuredPosts.firstIndex(where: { $0.id == post.id }) {
            featuredPosts[fi].isLiked = isJoining
            featuredPosts[fi].likedBy = posts[index].likedBy
            featuredPosts[fi].likes = newLikes
        }
        Task {
            try? await firestoreService.updateDocument(
                collection: FirestoreCollections.posts,
                documentId: post.id,
                data: [
                    "likedBy": isJoining
                        ? FieldValue.arrayUnion([userId])
                        : FieldValue.arrayRemove([userId]),
                    "likes": FieldValue.increment(isJoining ? Int64(1) : Int64(-1))
                ]
            )
        }
    }

    func loadComments(for postId: String) async throws -> [Comment] {
        try await firestoreService.queryCollectionOrdered(
            collection: "posts/\(postId)/comments",
            orderBy: "createdAt",
            descending: false
        )
    }

    func addComment(to postId: String, content: String, authorId: String, authorName: String, authorAvatarURL: String?) async throws {
        let commentId = UUID().uuidString
        let comment = Comment(
            id: commentId,
            postId: postId,
            userId: authorId,
            userName: authorName,
            body: content,
            date: Date(),
            likeCount: 0,
            replies: []
        )
        try await firestoreService.setDocument(
            comment,
            collection: "posts/\(postId)/comments",
            documentId: commentId
        )
        try await firestoreService.updateDocument(
            collection: FirestoreCollections.posts,
            documentId: postId,
            data: ["commentCount": FieldValue.increment(Int64(1))]
        )
        await MainActor.run {
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index].commentCount += 1
            }
            if let fi = featuredPosts.firstIndex(where: { $0.id == postId }) {
                featuredPosts[fi].commentCount += 1
            }
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
    var trendingGames: [GameSession] { Array(GameSession.mockSessions.prefix(3)) }
    var liveSession: GameSession? { GameSession.mockSessions.first { $0.liveScore != nil } }

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
    var currentUserId: String? = nil

    // MARK: - Weather

    func fetchWeather(latitude: Double, longitude: Double) async {
        await WeatherService.shared.fetch(latitude: latitude, longitude: longitude)
        weather = WeatherService.shared.current
        weekendForecast = WeatherService.shared.weekendForecast
    }

    func loadVideoHighlights() async {
        // VideoHighlight is a local model — mock data is pre-populated.
        // Future: swap for a Firestore fetch and map to VideoHighlight.
        videoHighlights = VideoHighlight.mockHighlights
    }
}


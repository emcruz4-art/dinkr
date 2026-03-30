import Foundation
import FirebaseFirestore

/// Seeds Firestore with mock data on first launch (DEBUG only).
/// Safe to call repeatedly — checks if data exists before writing.
final class SeedService {
    static let shared = SeedService()
    private let db = Firestore.firestore()
    private init() {}

    func seedIfNeeded() async {
        #if DEBUG
        do {
            let snapshot = try await db.collection(FirestoreCollections.users).limit(to: 1).getDocuments()
            guard snapshot.isEmpty else {
                print("[SeedService] Data already exists — skipping seed.")
                return
            }
            print("[SeedService] Seeding Firestore with mock data...")
            try await seedAll()
            print("[SeedService] ✅ Seed complete.")
        } catch {
            print("[SeedService] ❌ Seed error: \(error)")
        }
        #endif
    }

    private func seedAll() async throws {
        async let u: Void = seedCollection(FirestoreCollections.users, docs: User.mockPlayers + [User.mockCurrentUser])
        async let e: Void = seedCollection(FirestoreCollections.events, docs: Event.mockEvents)
        async let g: Void = seedCollection(FirestoreCollections.gameSessions, docs: GameSession.mockSessions)
        async let c: Void = seedCollection(FirestoreCollections.courtVenues, docs: CourtVenue.mockVenues)
        async let p: Void = seedPostsCollection()
        async let m: Void = seedCollection(FirestoreCollections.marketListings, docs: MarketListing.mockListings)
        async let gr: Void = seedCollection(FirestoreCollections.groups, docs: Group.mockGroups)
        _ = try await (u, e, g, c, p, m, gr)
    }

    // Generic helper — writes each doc using its id field
    private func seedCollection<T: Encodable & Identifiable>(_ collection: String, docs: [T]) async throws where T.ID == String {
        for doc in docs {
            try db.collection(collection).document(doc.id).setData(from: doc)
        }
    }

    // Posts need special handling because Post.id is a String
    private func seedPostsCollection() async throws {
        for post in Post.mockPosts {
            try db.collection(FirestoreCollections.posts).document(post.id).setData(from: post)
        }
    }
}

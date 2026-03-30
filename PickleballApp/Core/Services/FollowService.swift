import Foundation
import FirebaseFirestore
import Observation

@Observable
final class FollowService {
    static let shared = FollowService()
    private let db = Firestore.firestore()
    private init() {}

    // key: followeeId, value: isFollowing
    var followingCache: [String: Bool] = [:]

    // MARK: - Follow

    func follow(currentUserId: String, targetUserId: String) async throws {
        let docId = "\(currentUserId)_\(targetUserId)"
        let followDoc = db.collection(FirestoreCollections.follows).document(docId)

        let data: [String: Any] = [
            "followerId": currentUserId,
            "followeeId": targetUserId,
            "createdAt": FieldValue.serverTimestamp()
        ]

        let batch = db.batch()
        batch.setData(data, forDocument: followDoc)

        let targetUserRef = db.collection(FirestoreCollections.users).document(targetUserId)
        batch.updateData(["followersCount": FieldValue.increment(Int64(1))], forDocument: targetUserRef)

        let currentUserRef = db.collection(FirestoreCollections.users).document(currentUserId)
        batch.updateData(["followingCount": FieldValue.increment(Int64(1))], forDocument: currentUserRef)

        try await batch.commit()
        followingCache[targetUserId] = true
    }

    // MARK: - Unfollow

    func unfollow(currentUserId: String, targetUserId: String) async throws {
        let docId = "\(currentUserId)_\(targetUserId)"
        let followDoc = db.collection(FirestoreCollections.follows).document(docId)

        let batch = db.batch()
        batch.deleteDocument(followDoc)

        let targetUserRef = db.collection(FirestoreCollections.users).document(targetUserId)
        batch.updateData(["followersCount": FieldValue.increment(Int64(-1))], forDocument: targetUserRef)

        let currentUserRef = db.collection(FirestoreCollections.users).document(currentUserId)
        batch.updateData(["followingCount": FieldValue.increment(Int64(-1))], forDocument: currentUserRef)

        try await batch.commit()
        followingCache[targetUserId] = false
    }

    // MARK: - Is Following

    func isFollowing(currentUserId: String, targetUserId: String) async -> Bool {
        if let cached = followingCache[targetUserId] {
            return cached
        }
        let docId = "\(currentUserId)_\(targetUserId)"
        do {
            let doc = try await db.collection(FirestoreCollections.follows).document(docId).getDocument()
            let result = doc.exists
            followingCache[targetUserId] = result
            return result
        } catch {
            return false
        }
    }

    // MARK: - Load Following IDs

    func loadFollowingIds(for userId: String) async -> [String] {
        do {
            let snapshot = try await db.collection(FirestoreCollections.follows)
                .whereField("followerId", isEqualTo: userId)
                .getDocuments()
            return snapshot.documents.compactMap { $0.data()["followeeId"] as? String }
        } catch {
            return []
        }
    }
}

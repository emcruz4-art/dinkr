import Foundation
import FirebaseFirestore
import Observation

@Observable
final class GameResultService {
    static let shared = GameResultService()
    private init() {}

    // Save a game result to the top-level gameResults collection
    func saveResult(_ result: GameResult) async {
        try? await FirestoreService.shared.setDocument(
            result,
            collection: FirestoreCollections.gameResults,
            documentId: result.id
        )
    }

    // Load all results for a user from their subcollection: users/{userId}/gameResults
    func loadResults(for userId: String) async -> [GameResult] {
        let db = Firestore.firestore()
        guard let snapshot = try? await db
            .collection("users")
            .document(userId)
            .collection("gameResults")
            .order(by: "playedAt", descending: true)
            .limit(to: 50)
            .getDocuments()
        else {
            return GameResult.mockResults
        }

        let results = snapshot.documents.compactMap { try? $0.data(as: GameResult.self) }
        return results.isEmpty ? GameResult.mockResults : results
    }

    // Save a game result to a user's subcollection: users/{userId}/gameResults
    func saveResult(_ result: GameResult, forUserId userId: String) async {
        let db = Firestore.firestore()
        guard let encoded = try? Firestore.Encoder().encode(result) else { return }
        try? await db
            .collection("users")
            .document(userId)
            .collection("gameResults")
            .document(result.id)
            .setData(encoded)
    }
}

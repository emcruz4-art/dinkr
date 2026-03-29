import Foundation
import Observation
import FirebaseFirestore

@Observable
final class PlayViewModel {
    var nearbySessions: [GameSession] = []
    var nearbyVenues: [CourtVenue] = []
    var nearbyPlayers: [User] = []
    var isLoading = false
    var selectedSegment: PlaySegment = .games
    var showHostGame = false
    var selectedFormat: GameFormat? = nil
    var todayOnly: Bool = false

    enum PlaySegment: String, CaseIterable {
        case games = "Games"
        case live = "Live 🔴"
        case courts = "Courts"
        case players = "Players"
        case match = "Match ♟️"
        case leaderboard = "Rankings"
    }

    private let firestoreService = FirestoreService.shared

    func load() async {
        isLoading = true
        defer { isLoading = false }
        async let sessions: [GameSession] = (try? firestoreService.queryCollectionWhere(
            collection: FirestoreCollections.gameSessions,
            whereField: "dateTime",
            isGreaterThanOrEqualTo: Timestamp(date: Date()),
            orderBy: "dateTime",
            descending: false
        )) ?? []
        async let venues: [CourtVenue] = (try? firestoreService.queryCollectionOrdered(
            collection: FirestoreCollections.courtVenues,
            orderBy: "name"
        )) ?? []
        async let players: [User] = (try? firestoreService.queryCollectionOrdered(
            collection: FirestoreCollections.users,
            orderBy: "displayName",
            limit: 20
        )) ?? []
        (nearbySessions, nearbyVenues, nearbyPlayers) = await (sessions, venues, players)
    }

    func rsvp(to session: GameSession, currentUserId: String) async {
        guard let index = nearbySessions.firstIndex(where: { $0.id == session.id }) else { return }
        let isJoining = !nearbySessions[index].rsvps.contains(currentUserId)

        if isJoining && !nearbySessions[index].isFull {
            nearbySessions[index].rsvps.append(currentUserId)
        } else if !isJoining {
            nearbySessions[index].rsvps.removeAll { $0 == currentUserId }
        } else {
            return
        }

        let fieldValue: Any = isJoining
            ? FieldValue.arrayUnion([currentUserId])
            : FieldValue.arrayRemove([currentUserId])

        try? await firestoreService.updateDocument(
            collection: FirestoreCollections.gameSessions,
            documentId: session.id,
            data: ["rsvps": fieldValue]
        )
    }

    // Legacy overload retained for call sites that don't yet pass currentUserId
    func rsvp(to session: GameSession) {
        guard let index = nearbySessions.firstIndex(where: { $0.id == session.id }) else { return }
        let userId = "user_001"
        if nearbySessions[index].rsvps.contains(userId) {
            nearbySessions[index].rsvps.removeAll { $0 == userId }
        } else if !nearbySessions[index].isFull {
            nearbySessions[index].rsvps.append(userId)
        }
    }
}

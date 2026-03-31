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
    var joinToast: String? = nil

    /// Controls the game list sort mode. Defaults to skill match.
    var sortMode: GameSortMode = .skillMatch

    enum GameSortMode: String, CaseIterable {
        case skillMatch = "Best Match"
        case soonest    = "Starting Soon"
        case spotsLeft  = "Spots Available"

        var icon: String {
            switch self {
            case .skillMatch: return "person.crop.circle.badge.checkmark"
            case .soonest:    return "clock.fill"
            case .spotsLeft:  return "person.3.fill"
            }
        }
    }

    enum PlaySegment: String, CaseIterable {
        case games = "Games"
        case live = "Live 🔴"
        case courts = "Courts"
        case players = "Players"
        case match = "Match ♟️"
        case leaderboard = "Rankings"
    }

    // MARK: - Skill match scoring

    /// Returns a 0–1 score: 1.0 = perfect match (player is inside the range),
    /// then degrades by distance (in skill steps) outside the range.
    func matchScore(session: GameSession, playerSkill: SkillLevel) -> Double {
        let lo = session.skillRange.lowerBound.sortIndex
        let hi = session.skillRange.upperBound.sortIndex
        let p  = playerSkill.sortIndex
        if p >= lo && p <= hi { return 1.0 }
        let distance = p < lo ? Double(lo - p) : Double(p - hi)
        return max(0, 1.0 - distance * 0.25)
    }

    // MARK: - Filtered & sorted sessions (used by NearbyGamesView)

    func sortedSessions(playerSkill: SkillLevel) -> [GameSession] {
        var sessions = nearbySessions

        // Format filter
        if let fmt = selectedFormat {
            sessions = sessions.filter { $0.format == fmt }
        }

        // Today-only filter
        if todayOnly {
            let cal = Calendar.current
            sessions = sessions.filter { cal.isDateInToday($0.dateTime) }
        }

        // Sort
        switch sortMode {
        case .skillMatch:
            sessions.sort {
                matchScore(session: $0, playerSkill: playerSkill) >
                matchScore(session: $1, playerSkill: playerSkill)
            }
        case .soonest:
            sessions.sort { $0.dateTime < $1.dateTime }
        case .spotsLeft:
            sessions.sort { $0.spotsRemaining > $1.spotsRemaining }
        }

        return sessions
    }

    private let firestoreService = FirestoreService.shared
    private var sessionListener: ListenerRegistration?

    // Tracks rsvp counts from the previous snapshot so we can detect joins
    private var previousRsvpCounts: [String: Int] = [:]

    // MARK: - Real-time session listener

    func startListening() {
        sessionListener?.remove()
        sessionListener = firestoreService.listenToCollectionWhere(
            collection: FirestoreCollections.gameSessions,
            whereField: "dateTime",
            isGreaterThanOrEqualTo: Timestamp(date: Date()),
            orderBy: "dateTime"
        ) { [weak self] (sessions: [GameSession]) in
            guard let self else { return }
            DispatchQueue.main.async {
                self.handleSessionUpdate(sessions)
            }
        }
    }

    func stopListening() {
        sessionListener?.remove()
        sessionListener = nil
    }

    private func handleSessionUpdate(_ sessions: [GameSession]) {
        // Detect any session where the rsvp count grew since last snapshot
        for session in sessions {
            let previousCount = previousRsvpCounts[session.id] ?? -1
            let currentCount = session.rsvps.count
            // Only fire the toast if we had a prior reading (not on first load)
            // and the count genuinely increased
            if previousCount >= 0 && currentCount > previousCount {
                // Use the most-recently-joined rsvp id as a display name stub,
                // since we only have the id array; real apps would resolve the name.
                let joinerDisplay = session.rsvps.last.map { id in
                    // Strip the "user_" prefix and capitalise for a readable label
                    let trimmed = id.replacingOccurrences(of: "user_", with: "")
                    return "Player \(trimmed)"
                } ?? "Someone"
                joinToast = "\(joinerDisplay) just joined · \(session.courtName)"
                break   // one toast at a time
            }
        }

        // Commit new rsvp counts for the next diff
        for session in sessions {
            previousRsvpCounts[session.id] = session.rsvps.count
        }

        nearbySessions = sessions
    }

    // MARK: - Load (one-shot + kicks off live listener)

    func load() async {
        isLoading = true
        defer { isLoading = false }

        // Kick off the real-time sessions listener
        startListening()

        // One-shot fetches for venues and players (these don't need live updates)
        async let venues: [CourtVenue] = (try? firestoreService.queryCollectionOrdered(
            collection: FirestoreCollections.courtVenues,
            orderBy: "name"
        )) ?? []
        async let players: [User] = (try? firestoreService.queryCollectionOrdered(
            collection: FirestoreCollections.users,
            orderBy: "displayName",
            limit: 20
        )) ?? []
        (nearbyVenues, nearbyPlayers) = await (venues, players)
    }

    // MARK: - RSVP

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

    // MARK: - Live Score

    /// Creates or updates the liveScore snapshot on a session, persisting it locally.
    func startLiveScore(session: GameSession, snapshot: GameSession.LiveScoreSnapshot?) {
        guard let index = nearbySessions.firstIndex(where: { $0.id == session.id }) else { return }
        nearbySessions[index].liveScore = snapshot
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

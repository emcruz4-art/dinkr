import Foundation

enum BracketFormat: String, Codable, CaseIterable {
    case singleElimination = "Single Elimination"
    case doubleElimination = "Double Elimination"
    case roundRobin        = "Round Robin"

    var icon: String {
        switch self {
        case .singleElimination: return "arrow.right"
        case .doubleElimination: return "arrow.2.squarepath"
        case .roundRobin:        return "circle.grid.3x3.fill"
        }
    }

    var description: String {
        switch self {
        case .singleElimination: return "One loss and you're out. Classic knockout format."
        case .doubleElimination: return "Two losses to eliminate. Second-chance bracket."
        case .roundRobin:        return "Everyone plays everyone. Best record wins."
        }
    }
}

struct BracketParticipant: Identifiable, Codable, Hashable {
    var id: String
    var displayName: String
    var skillLevel: SkillLevel
    var seed: Int
    var duprRating: Double?
}

struct NewBracketMatch: Identifiable, Codable {
    var id: String
    var round: Int               // 1 = first round, higher = later rounds
    var matchNumber: Int         // position within the round
    var participantAId: String?
    var participantBId: String?
    var participantAName: String?
    var participantBName: String?
    var scoreA: String           // e.g. "11" or "11-9" for full set
    var scoreB: String
    var winnerId: String?
    var isComplete: Bool
    var scheduledTime: Date?
    var courtName: String?

    var winnerName: String? {
        guard let wId = winnerId, isComplete else { return nil }
        return wId == participantAId ? participantAName : participantBName
    }
}

struct Bracket: Identifiable, Codable {
    var id: String
    var eventId: String
    var eventName: String
    var format: BracketFormat
    var participants: [BracketParticipant]
    var matches: [NewBracketMatch]
    var createdAt: Date
    var isPublished: Bool

    // Rounds computed from matches
    var rounds: [[NewBracketMatch]] {
        let maxRound = matches.map { $0.round }.max() ?? 0
        return (1...max(1, maxRound)).map { round in
            matches.filter { $0.round == round }.sorted { $0.matchNumber < $1.matchNumber }
        }
    }

    var champion: BracketParticipant? {
        let maxRound = matches.map { $0.round }.max() ?? 0
        guard let finalMatch = matches.filter({ $0.round == maxRound }).first,
              finalMatch.isComplete, let winnerId = finalMatch.winnerId else { return nil }
        return participants.first { $0.id == winnerId }
    }

    // Round label helpers
    func roundLabel(for roundNum: Int) -> String {
        let total = rounds.count
        let fromEnd = total - roundNum
        switch fromEnd {
        case 0: return "Final"
        case 1: return "Semifinals"
        case 2: return "Quarterfinals"
        default: return "Round \(roundNum)"
        }
    }

    // Generate a single-elimination bracket from participant list
    static func generateSingleElimination(
        eventId: String,
        eventName: String,
        participants: [BracketParticipant]
    ) -> Bracket {
        var bracketMatches: [NewBracketMatch] = []
        let seeded = participants.sorted { $0.seed < $1.seed }
        let count = seeded.count
        let slots = Int(pow(2.0, ceil(log2(Double(max(count, 2))))))
        var matchId = 0

        // Round 1 — pair top seed vs bottom seed (1 vs N, 2 vs N-1, etc.)
        let pairs = stride(from: 0, to: slots / 2, by: 1).map { i -> (BracketParticipant?, BracketParticipant?) in
            let a = i < seeded.count ? seeded[i] : nil
            let b = (slots - 1 - i) < seeded.count ? seeded[slots - 1 - i] : nil
            return (a, b)
        }

        for (idx, pair) in pairs.enumerated() {
            matchId += 1
            let isBye = pair.1 == nil
            bracketMatches.append(NewBracketMatch(
                id: "m\(matchId)",
                round: 1,
                matchNumber: idx + 1,
                participantAId: pair.0?.id,
                participantBId: pair.1?.id,
                participantAName: pair.0?.displayName ?? "TBD",
                participantBName: pair.1?.displayName ?? "TBD",
                scoreA: "", scoreB: "",
                winnerId: isBye ? pair.0?.id : nil,
                isComplete: isBye,
                scheduledTime: nil, courtName: nil
            ))
        }

        // Subsequent rounds (empty placeholders)
        var roundSize = slots / 4
        var roundNum = 2
        while roundSize >= 1 {
            for matchIdx in 0..<roundSize {
                matchId += 1
                bracketMatches.append(NewBracketMatch(
                    id: "m\(matchId)", round: roundNum, matchNumber: matchIdx + 1,
                    participantAId: nil, participantBId: nil,
                    participantAName: "TBD", participantBName: "TBD",
                    scoreA: "", scoreB: "", winnerId: nil, isComplete: false,
                    scheduledTime: nil, courtName: nil
                ))
            }
            roundSize /= 2
            roundNum += 1
        }

        return Bracket(
            id: UUID().uuidString,
            eventId: eventId,
            eventName: eventName,
            format: .singleElimination,
            participants: seeded,
            matches: bracketMatches,
            createdAt: Date(),
            isPublished: true
        )
    }
}

// MARK: - Mock Data

extension Bracket {
    static let mock: Bracket = {
        let players = User.mockPlayers
        let bracketParticipants = players.enumerated().map { index, user in
            BracketParticipant(
                id: user.id,
                displayName: user.displayName,
                skillLevel: user.skillLevel,
                seed: index + 1,
                duprRating: user.duprRating
            )
        }
        var bracket = Bracket.generateSingleElimination(
            eventId: "evt_001",
            eventName: "Austin Open Pickleball Tournament",
            participants: bracketParticipants
        )
        // Inject some completed first-round results for realism
        if bracket.matches.count >= 4 {
            bracket.matches[0].scoreA = "11"; bracket.matches[0].scoreB = "7"
            bracket.matches[0].winnerId = bracketParticipants[0].id
            bracket.matches[0].isComplete = true

            bracket.matches[1].scoreA = "9"; bracket.matches[1].scoreB = "11"
            bracket.matches[1].winnerId = bracketParticipants[6].id
            bracket.matches[1].isComplete = true

            bracket.matches[2].scoreA = "11"; bracket.matches[2].scoreB = "5"
            bracket.matches[2].winnerId = bracketParticipants[2].id
            bracket.matches[2].isComplete = true
        }
        return bracket
    }()
}

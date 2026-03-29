import Foundation

struct GameResult: Identifiable, Codable, Hashable {
    var id: String
    var sessionId: String
    var opponentId: String
    var opponentName: String
    var opponentSkill: SkillLevel
    var myScore: Int
    var opponentScore: Int
    var format: GameFormat
    var courtName: String
    var playedAt: Date
    var isWin: Bool { myScore > opponentScore }
    var scoreDisplay: String { "\(myScore)–\(opponentScore)" }
}

extension GameResult {
    static let mockResults: [GameResult] = [
        GameResult(id: "gr1", sessionId: "gs1", opponentId: "user_002", opponentName: "Maria Chen",
                   opponentSkill: .intermediate35, myScore: 11, opponentScore: 7,
                   format: .doubles, courtName: "Westside Pickleball Complex",
                   playedAt: Date().addingTimeInterval(-86400)),
        GameResult(id: "gr2", sessionId: "gs2", opponentId: "user_003", opponentName: "Jordan Smith",
                   opponentSkill: .advanced40, myScore: 9, opponentScore: 11,
                   format: .singles, courtName: "Mueller Recreation Center",
                   playedAt: Date().addingTimeInterval(-172800)),
        GameResult(id: "gr3", sessionId: "gs3", opponentId: "user_004", opponentName: "Sarah Johnson",
                   opponentSkill: .intermediate35, myScore: 11, opponentScore: 4,
                   format: .mixed, courtName: "South Lamar Sports Club",
                   playedAt: Date().addingTimeInterval(-259200)),
        GameResult(id: "gr4", sessionId: "gs4", opponentId: "user_005", opponentName: "Chris Park",
                   opponentSkill: .advanced40, myScore: 11, opponentScore: 9,
                   format: .doubles, courtName: "Westside Pickleball Complex",
                   playedAt: Date().addingTimeInterval(-345600)),
        GameResult(id: "gr5", sessionId: "gs5", opponentId: "user_006", opponentName: "Taylor Kim",
                   opponentSkill: .intermediate30, myScore: 11, opponentScore: 2,
                   format: .singles, courtName: "Barton Springs Tennis Center",
                   playedAt: Date().addingTimeInterval(-432000)),
        GameResult(id: "gr6", sessionId: "gs6", opponentId: "user_007", opponentName: "Jamie Lee",
                   opponentSkill: .intermediate35, myScore: 8, opponentScore: 11,
                   format: .doubles, courtName: "Mueller Recreation Center",
                   playedAt: Date().addingTimeInterval(-518400)),
        GameResult(id: "gr7", sessionId: "gs7", opponentId: "user_008", opponentName: "Morgan Davis",
                   opponentSkill: .advanced40, myScore: 11, opponentScore: 10,
                   format: .mixed, courtName: "South Lamar Sports Club",
                   playedAt: Date().addingTimeInterval(-604800)),
        GameResult(id: "gr8", sessionId: "gs8", opponentId: "user_002", opponentName: "Maria Chen",
                   opponentSkill: .intermediate35, myScore: 7, opponentScore: 11,
                   format: .singles, courtName: "Westside Pickleball Complex",
                   playedAt: Date().addingTimeInterval(-691200)),
        GameResult(id: "gr9", sessionId: "gs9", opponentId: "user_003", opponentName: "Jordan Smith",
                   opponentSkill: .advanced40, myScore: 11, opponentScore: 6,
                   format: .doubles, courtName: "Barton Springs Tennis Center",
                   playedAt: Date().addingTimeInterval(-777600)),
        GameResult(id: "gr10", sessionId: "gs10", opponentId: "user_004", opponentName: "Sarah Johnson",
                   opponentSkill: .intermediate35, myScore: 11, opponentScore: 8,
                   format: .openPlay, courtName: "Mueller Recreation Center",
                   playedAt: Date().addingTimeInterval(-864000)),
    ]
}

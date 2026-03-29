import Foundation

struct DailyChallenge: Identifiable, Hashable {
    var id: String
    var title: String
    var description: String
    var xpReward: Int
    var icon: String
    var isCompleted: Bool
    var progress: Int
    var total: Int
    var category: ChallengeCategory

    enum ChallengeCategory: String, Hashable {
        case play = "Play"
        case social = "Social"
        case streak = "Streak"
        case skill = "Skill"
    }

    var progressFraction: Double {
        guard total > 0 else { return 0 }
        return min(Double(progress) / Double(total), 1.0)
    }
}

extension DailyChallenge {
    static let mockChallenges: [DailyChallenge] = [
        DailyChallenge(id: "dc1", title: "Play a Game Today",
                       description: "Join or host any game session today.",
                       xpReward: 100, icon: "figure.pickleball",
                       isCompleted: false, progress: 0, total: 1, category: .play),
        DailyChallenge(id: "dc2", title: "Like 3 Posts",
                       description: "Show some love in the community.",
                       xpReward: 25, icon: "heart.fill",
                       isCompleted: true, progress: 3, total: 3, category: .social),
        DailyChallenge(id: "dc3", title: "Check In at a Court",
                       description: "Let your crew know you're on the courts!",
                       xpReward: 50, icon: "mappin.circle.fill",
                       isCompleted: false, progress: 0, total: 1, category: .play),
        DailyChallenge(id: "dc4", title: "Win a Game",
                       description: "Take the W in any format today.",
                       xpReward: 150, icon: "trophy.fill",
                       isCompleted: false, progress: 0, total: 1, category: .skill),
        DailyChallenge(id: "dc5", title: "Post a Match Update",
                       description: "Share a game result or highlight with the community.",
                       xpReward: 75, icon: "square.and.pencil",
                       isCompleted: false, progress: 0, total: 1, category: .social),
    ]

    static var weeklyXP: Int { 725 }
    static var currentStreak: Int { 7 }
    static var longestStreak: Int { 23 }
}

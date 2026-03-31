import Foundation

struct Achievement: Identifiable {
    var id: String
    var badgeType: BadgeType
    var title: String
    var description: String
    var icon: String        // SF Symbol name
    var color: String       // brand color key (e.g. "dinkrAmber")
    var requirement: String // human-readable unlock criteria
    var progress: Int       // current progress toward goal
    var goal: Int           // total needed to unlock
    var isUnlocked: Bool
    var unlockedDate: Date?
    var xpReward: Int

    /// Clamped 0…1 fraction for progress bar rendering
    var progressFraction: Double {
        guard goal > 0 else { return isUnlocked ? 1 : 0 }
        return min(1.0, Double(progress) / Double(goal))
    }
}

// MARK: - Static catalogue

extension Achievement {
    static let all: [Achievement] = {
        let user = User.mockCurrentUser
        let now = Date()
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now

        return [
            // --- UNLOCKED (4) ---
            Achievement(
                id: "a1",
                badgeType: .firstGame,
                title: "First Dink",
                description: "Play your very first game on Dinkr and join the community.",
                icon: "figure.pickleball",
                color: "dinkrGreen",
                requirement: "Play 1 game",
                progress: min(user.gamesPlayed, 1),
                goal: 1,
                isUnlocked: user.gamesPlayed >= 1,
                unlockedDate: user.gamesPlayed >= 1 ? oneYearAgo : nil,
                xpReward: 50
            ),
            Achievement(
                id: "a2",
                badgeType: .reliablePro,
                title: "Reliable Pro",
                description: "Maintain a 4.8+ reliability score across at least 50 games.",
                icon: "checkmark.seal.fill",
                color: "dinkrSky",
                requirement: "Reliability ≥ 4.8 over 50 games",
                progress: min(user.gamesPlayed, 50),
                goal: 50,
                isUnlocked: user.reliabilityScore >= 4.8 && user.gamesPlayed >= 50,
                unlockedDate: user.reliabilityScore >= 4.8 && user.gamesPlayed >= 50 ? oneYearAgo : nil,
                xpReward: 200
            ),
            Achievement(
                id: "a3",
                badgeType: .communityChampion,
                title: "Community Pillar",
                description: "Join 2 or more groups and help grow the local scene.",
                icon: "person.3.fill",
                color: "dinkrAmber",
                requirement: "Join 2 groups",
                progress: min(user.clubIds.count, 2),
                goal: 2,
                isUnlocked: user.clubIds.count >= 2,
                unlockedDate: user.clubIds.count >= 2 ? oneYearAgo : nil,
                xpReward: 100
            ),
            Achievement(
                id: "a4",
                badgeType: .centennial,
                title: "Centurion",
                description: "Log 100 games on Dinkr — a true court veteran.",
                icon: "100.circle.fill",
                color: "dinkrCoral",
                requirement: "Play 100 games",
                progress: min(user.gamesPlayed, 100),
                goal: 100,
                isUnlocked: user.gamesPlayed >= 100,
                unlockedDate: user.gamesPlayed >= 100 ? Calendar.current.date(byAdding: .month, value: -3, to: now) : nil,
                xpReward: 300
            ),

            // --- LOCKED (8) ---
            Achievement(
                id: "a5",
                badgeType: .tournamentWinner,
                title: "Tournament Victor",
                description: "Win a sanctioned tournament event on Dinkr.",
                icon: "trophy.fill",
                color: "dinkrAmber",
                requirement: "Win 1 tournament",
                progress: user.badges.contains(where: { $0.type == .tournamentWinner }) ? 1 : 0,
                goal: 1,
                isUnlocked: user.badges.contains(where: { $0.type == .tournamentWinner }),
                unlockedDate: nil,
                xpReward: 500
            ),
            Achievement(
                id: "a6",
                badgeType: .firstGame,
                title: "On Fire",
                description: "Win 5 games in a row without a single loss.",
                icon: "flame.fill",
                color: "dinkrCoral",
                requirement: "Win 5 consecutive games",
                progress: 3,   // illustrative mock progress
                goal: 5,
                isUnlocked: false,
                unlockedDate: nil,
                xpReward: 150
            ),
            Achievement(
                id: "a7",
                badgeType: .firstGame,
                title: "Level Master",
                description: "Reach Level 10 by accumulating XP across all activity.",
                icon: "graduationcap.fill",
                color: "dinkrNavy",
                requirement: "Reach Level 10",
                progress: 7,   // illustrative mock progress
                goal: 10,
                isUnlocked: false,
                unlockedDate: nil,
                xpReward: 400
            ),
            Achievement(
                id: "a8",
                badgeType: .courtBuilder,
                title: "Court Regular",
                description: "Play at 10 different courts to explore the local scene.",
                icon: "mappin.and.ellipse",
                color: "dinkrSky",
                requirement: "Play at 10 courts",
                progress: 4,   // illustrative mock progress
                goal: 10,
                isUnlocked: false,
                unlockedDate: nil,
                xpReward: 200
            ),
            Achievement(
                id: "a9",
                badgeType: .communityChampion,
                title: "Social Butterfly",
                description: "Follow 20 players and expand your Dinkr network.",
                icon: "globe",
                color: "dinkrGreen",
                requirement: "Follow 20 players",
                progress: min(user.followingCount, 20),
                goal: 20,
                isUnlocked: user.followingCount >= 20,
                unlockedDate: nil,
                xpReward: 100
            ),
            Achievement(
                id: "a10",
                badgeType: .firstGame,
                title: "Consistent Player",
                description: "Show up every week — play at least once per week for 4 weeks.",
                icon: "calendar.badge.checkmark",
                color: "dinkrSky",
                requirement: "Play 1× per week for 4 weeks",
                progress: 2,   // illustrative mock progress
                goal: 4,
                isUnlocked: false,
                unlockedDate: nil,
                xpReward: 125
            ),
            Achievement(
                id: "a11",
                badgeType: .communityChampion,
                title: "Dinkr Champion",
                description: "Reach #1 on your local leaderboard.",
                icon: "crown.fill",
                color: "dinkrAmber",
                requirement: "Rank #1 locally",
                progress: 0,
                goal: 1,
                isUnlocked: false,
                unlockedDate: nil,
                xpReward: 750
            ),
            Achievement(
                id: "a12",
                badgeType: .centennial,
                title: "Legend",
                description: "Play 500 games on Dinkr — an all-time great.",
                icon: "sparkles",
                color: "dinkrCoral",
                requirement: "Play 500 games",
                progress: min(user.gamesPlayed, 500),
                goal: 500,
                isUnlocked: user.gamesPlayed >= 500,
                unlockedDate: nil,
                xpReward: 1000
            ),
        ]
    }()
}

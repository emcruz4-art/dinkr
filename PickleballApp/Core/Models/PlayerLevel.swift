import SwiftUI

struct PlayerLevel: Equatable {
    let level: Int
    let title: String
    let xpRequired: Int
    let badgeColor: String
    let icon: String

    // MARK: - All Levels

    static let all: [PlayerLevel] = [
        PlayerLevel(level: 1,  title: "Beginner",        xpRequired: 0,     badgeColor: "dinkrSky",   icon: "figure.walk"),
        PlayerLevel(level: 2,  title: "Rallyer",         xpRequired: 500,   badgeColor: "dinkrSky",   icon: "figure.run"),
        PlayerLevel(level: 3,  title: "Dinker",          xpRequired: 1_200, badgeColor: "dinkrGreen", icon: "sportscourt"),
        PlayerLevel(level: 4,  title: "Court Regular",   xpRequired: 2_500, badgeColor: "dinkrGreen", icon: "figure.pickleball"),
        PlayerLevel(level: 5,  title: "Competitor",      xpRequired: 4_500, badgeColor: "dinkrGreen", icon: "trophy"),
        PlayerLevel(level: 6,  title: "Veteran",         xpRequired: 7_500, badgeColor: "dinkrAmber", icon: "shield"),
        PlayerLevel(level: 7,  title: "Dinkmaster",      xpRequired: 12_000, badgeColor: "dinkrAmber", icon: "crown"),
        PlayerLevel(level: 8,  title: "Court Commander", xpRequired: 18_000, badgeColor: "dinkrAmber", icon: "crown.fill"),
        PlayerLevel(level: 9,  title: "Ace",             xpRequired: 26_000, badgeColor: "dinkrCoral", icon: "star"),
        PlayerLevel(level: 10, title: "Legend",          xpRequired: 36_000, badgeColor: "dinkrCoral", icon: "star.fill"),
    ]

    // MARK: - Lookup

    static func level(for xp: Int) -> PlayerLevel {
        // Walk backwards to find the highest level whose threshold is met
        for playerLevel in all.reversed() {
            if xp >= playerLevel.xpRequired {
                return playerLevel
            }
        }
        return all[0]
    }

    // MARK: - Brand Color

    var color: Color {
        switch badgeColor {
        case "dinkrGreen": return Color.dinkrGreen
        case "dinkrAmber": return Color.dinkrAmber
        case "dinkrCoral": return Color.dinkrCoral
        case "dinkrSky":   return Color.dinkrSky
        case "dinkrNavy":  return Color.dinkrNavy
        default:           return Color.dinkrGreen
        }
    }

    // MARK: - Next Level

    var next: PlayerLevel? {
        guard level < PlayerLevel.all.count else { return nil }
        return PlayerLevel.all[level] // levels are 1-indexed, array is 0-indexed
    }
}

// MARK: - User XP Extensions

extension User {
    var xp: Int {
        (gamesPlayed * 100) + (wins * 50)
    }

    var playerLevel: PlayerLevel {
        PlayerLevel.level(for: xp)
    }

    var xpToNextLevel: Int {
        guard let next = playerLevel.next else { return 0 }
        return max(next.xpRequired - xp, 0)
    }

    var levelProgress: Double {
        let current = playerLevel
        guard let next = current.next else { return 1.0 }
        let rangeStart = Double(current.xpRequired)
        let rangeEnd   = Double(next.xpRequired)
        guard rangeEnd > rangeStart else { return 1.0 }
        let progress = (Double(xp) - rangeStart) / (rangeEnd - rangeStart)
        return min(max(progress, 0.0), 1.0)
    }
}

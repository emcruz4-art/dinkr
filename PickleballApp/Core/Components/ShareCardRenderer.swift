import SwiftUI
import UIKit

// MARK: - MonthlyStats

/// Flat stats bag used by ShareCardRenderer and MonthlyRecapView.
struct MonthlyStats {
    var playerName: String
    var month: String           // e.g. "March"
    var year: Int               // e.g. 2026
    var gamesPlayed: Int
    var wins: Int
    var losses: Int
    var topCourtName: String
    var topCourtVisits: Int
    var bestWinOpponent: String
    var bestWinScore: String    // e.g. "11–7"
    var duprBefore: Double
    var duprAfter: Double
    var streakDays: Int
    var isStreakPersonalBest: Bool
    var percentileBeat: Int     // e.g. 87  → "more than 87% of Dinkr players"

    var winRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(wins) / Double(gamesPlayed)
    }

    var duprDelta: Double { duprAfter - duprBefore }
    var monthYear: String { "\(month) \(year)" }

    static func mock(for user: User) -> MonthlyStats {
        MonthlyStats(
            playerName: user.displayName,
            month: "March",
            year: 2026,
            gamesPlayed: 14,
            wins: 9,
            losses: 5,
            topCourtName: "Westside Complex",
            topCourtVisits: 6,
            bestWinOpponent: "Jordan Smith",
            bestWinScore: "11–6",
            duprBefore: 3.65,
            duprAfter: 3.88,
            streakDays: 7,
            isStreakPersonalBest: true,
            percentileBeat: 87
        )
    }
}

// MARK: - ShareCardRenderer

/// Renders Dinkr share cards to UIImage via ImageRenderer.
/// All methods run on the main actor (ImageRenderer requirement).
@MainActor
enum ShareCardRenderer {

    // MARK: Match Card

    /// Renders a MatchShareCard for the given result and player.
    /// - Returns: A 3× scale UIImage, or nil on failure.
    static func renderMatchCard(result: GameResult, player: User) -> UIImage? {
        let view = MatchShareCard(result: result, player: player)
            .environment(\.colorScheme, .dark)
        return render(view)
    }

    // MARK: Achievement Card

    /// Renders an AchievementShareCard for the given achievement and user.
    /// - Returns: A 3× scale UIImage, or nil on failure.
    static func renderAchievementCard(achievement: Achievement, user: User) -> UIImage? {
        let badgeColor: Color = {
            switch achievement.color {
            case "dinkrGreen":  return Color.dinkrGreen
            case "dinkrNavy":   return Color.dinkrNavy
            case "dinkrCoral":  return Color.dinkrCoral
            case "dinkrSky":    return Color.dinkrSky
            default:            return Color.dinkrAmber
            }
        }()
        let badgeEmoji: String = {
            switch achievement.badgeType {
            case .tournamentWinner:   return "🏆"
            case .reliablePro:        return "⭐️"
            case .communityChampion:  return "🤝"
            case .centennial:         return "💯"
            case .firstGame:          return "🎉"
            case .womensPioneer:      return "💪"
            case .courtBuilder:       return "🏗️"
            }
        }()
        let view = AchievementShareCard(
            achievement: achievement,
            user: user,
            badgeEmoji: badgeEmoji,
            badgeColor: badgeColor
        )
        .environment(\.colorScheme, .dark)
        return render(view)
    }

    // MARK: Profile Card

    /// Renders a compact profile card (360×460) for the given user.
    /// - Returns: A 3× scale UIImage, or nil on failure.
    static func renderProfileCard(user: User) -> UIImage? {
        let view = ProfileShareCard(user: user)
            .environment(\.colorScheme, .dark)
        return render(view)
    }

    // MARK: Recap Card

    /// Renders a MonthlyRecapCard for the given stats.
    /// - Returns: A 3× scale UIImage, or nil on failure.
    static func renderRecapCard(stats: MonthlyStats) -> UIImage? {
        let data = MonthlyRecapData(
            playerName: stats.playerName,
            monthYear: stats.monthYear,
            gamesPlayed: stats.gamesPlayed,
            wins: stats.wins,
            losses: stats.losses,
            courtsVisited: stats.topCourtVisits,
            topPartner: stats.bestWinOpponent,
            topCourt: stats.topCourtName,
            challengesWon: 0,
            reliabilityScore: 4.8,
            duprChange: stats.duprDelta,
            winStreak: stats.streakDays
        )
        let view = MonthlyRecapCard(data: data)
            .environment(\.colorScheme, .dark)
        return render(view)
    }

    // MARK: Private

    private static func render<V: View>(_ view: V) -> UIImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        return renderer.uiImage
    }
}


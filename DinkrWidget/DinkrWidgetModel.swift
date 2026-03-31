// DinkrWidgetModel.swift
// DinkrWidget — Timeline entry model, supporting types, and mock data

import WidgetKit
import Foundation

// MARK: - AppGroup shared suite

let dinkrWidgetDefaults = UserDefaults(suiteName: "group.com.dinkr.ios")

// MARK: - Widget Configuration Kind

/// All widget kinds registered in the bundle.
enum DinkrWidgetKind {
    static let nextGame   = "DinkrNextGameWidget"
    static let streak     = "DinkrStreakWidget"
    static let todayGames = "DinkrTodayGamesWidget"
    static let myStats    = "DinkrMyStatsWidget"
    static let dashboard  = "DinkrDashboardWidget"
    static let lockCircle = "DinkrLockCircleWidget"
    static let lockRect   = "DinkrLockRectWidget"
    static let lockInline = "DinkrLockInlineWidget"
}

// MARK: - Small Widget Stat Choice (AppIntentConfiguration)

enum SmallWidgetStat: String, CaseIterable {
    case nextGame = "Next Game"
    case streak   = "Streak"
}

// MARK: - Supporting Types

struct NextGameInfo {
    let courtName: String
    let format: String          // "Singles" | "Doubles" | "MXD"
    let timeString: String      // human-readable "Today 6:00 PM"
    let spotsLeft: Int
    let dateTime: Date          // for countdown and timeline reload
}

struct ActiveChallengeInfo {
    let type: String
    let opponentName: String
    let myProgress: Double
    let theirProgress: Double
    let daysLeft: Int
}

struct GameSummary {
    let courtName: String
    let format: String
    let timeString: String
    let spotsLeft: Int
}

struct WeeklyStatsInfo {
    let wins: Int
    let losses: Int
}

struct WeatherSnippet {
    let emoji: String
    let temperatureF: Int
    let label: String
    let isGoodForPlay: Bool
}

// MARK: - Timeline Entry

struct DinkrWidgetEntry: TimelineEntry {
    // Required by TimelineEntry
    let date: Date
    // TimelineEntryRelevance for smart stacking
    var relevance: TimelineEntryRelevance?

    // Player
    let playerName: String
    let duprRating: Double
    let reliabilityScore: Double

    // Games
    let upcomingGameCount: Int
    let nextGame: NextGameInfo?
    let todayGames: [GameSummary]   // up to 2 for medium widget

    // Streak
    let currentStreak: Int
    let lastPlayedDate: Date?

    // Stats
    let weeklyStats: WeeklyStatsInfo?

    // Challenge (legacy medium panel)
    let activeChallenge: ActiveChallengeInfo?

    // Courts
    let openCourtsNearby: Int

    // Leaderboard
    let leaderboardRank: Int?       // nil = unranked

    // Weather
    let weather: WeatherSnippet?

    // Small widget config
    let smallStat: SmallWidgetStat
}

// MARK: - Convenience

extension DinkrWidgetEntry {

    /// Countdown string from now to next game, e.g. "2h 30m"
    var nextGameCountdown: String {
        guard let game = nextGame else { return "—" }
        let diff = game.dateTime.timeIntervalSince(date)
        guard diff > 0 else { return "Now" }
        let hours   = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    /// Formatted last-played date, e.g. "Mar 29"
    var lastPlayedFormatted: String {
        guard let d = lastPlayedDate else { return "—" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: d)
    }

    /// W/L this week, e.g. "3W · 1L"
    var weeklyRecord: String {
        guard let s = weeklyStats else { return "—" }
        return "\(s.wins)W · \(s.losses)L"
    }
}

// MARK: - Mock Data

extension DinkrWidgetEntry {

    static let mock = DinkrWidgetEntry(
        date: Date(),
        relevance: nil,
        playerName: "Alex Rivera",
        duprRating: 4.69,
        reliabilityScore: 4.8,
        upcomingGameCount: 3,
        nextGame: NextGameInfo(
            courtName: "Garrison Park Courts",
            format: "Doubles",
            timeString: "Today 6:00 PM",
            spotsLeft: 2,
            dateTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
        ),
        todayGames: [
            GameSummary(courtName: "Garrison Park", format: "Doubles", timeString: "6:00 PM", spotsLeft: 2),
            GameSummary(courtName: "Westside Rec",  format: "Singles", timeString: "8:00 PM", spotsLeft: 4),
        ],
        currentStreak: 7,
        lastPlayedDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
        weeklyStats: WeeklyStatsInfo(wins: 4, losses: 1),
        activeChallenge: ActiveChallengeInfo(
            type: "Win Race",
            opponentName: "Maria Chen",
            myProgress: 0.6,
            theirProgress: 0.4,
            daysLeft: 3
        ),
        openCourtsNearby: 3,
        leaderboardRank: 12,
        weather: WeatherSnippet(emoji: "☀️", temperatureF: 74, label: "Clear", isGoodForPlay: true),
        smallStat: .nextGame
    )

    static let mockStreak = DinkrWidgetEntry(
        date: Date(),
        relevance: nil,
        playerName: "Alex Rivera",
        duprRating: 4.69,
        reliabilityScore: 4.8,
        upcomingGameCount: 3,
        nextGame: NextGameInfo(
            courtName: "Garrison Park Courts",
            format: "Doubles",
            timeString: "Today 6:00 PM",
            spotsLeft: 2,
            dateTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
        ),
        todayGames: [
            GameSummary(courtName: "Garrison Park", format: "Doubles", timeString: "6:00 PM", spotsLeft: 2),
            GameSummary(courtName: "Westside Rec",  format: "Singles", timeString: "8:00 PM", spotsLeft: 4),
        ],
        currentStreak: 7,
        lastPlayedDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
        weeklyStats: WeeklyStatsInfo(wins: 4, losses: 1),
        activeChallenge: nil,
        openCourtsNearby: 3,
        leaderboardRank: 12,
        weather: WeatherSnippet(emoji: "☀️", temperatureF: 74, label: "Clear", isGoodForPlay: true),
        smallStat: .streak
    )

    static let placeholder = DinkrWidgetEntry(
        date: Date(),
        relevance: nil,
        playerName: "Player",
        duprRating: 0.0,
        reliabilityScore: 0.0,
        upcomingGameCount: 0,
        nextGame: nil,
        todayGames: [],
        currentStreak: 0,
        lastPlayedDate: nil,
        weeklyStats: nil,
        activeChallenge: nil,
        openCourtsNearby: 0,
        leaderboardRank: nil,
        weather: nil,
        smallStat: .nextGame
    )
}

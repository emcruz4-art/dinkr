// DinkrWidget.swift
// DinkrWidget — Widget configurations and unified timeline provider

import WidgetKit
import SwiftUI

// MARK: - Double helper

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}

// MARK: - Unified Timeline Provider
//
// Shared across all widget kinds. Produces entries for the next 24 hours so
// iOS can pick the most relevant snapshot without another fetch. Relevance
// scoring gives next-game proximity the highest weight.

struct DinkrProvider: TimelineProvider {

    // MARK: - TimelineProvider

    func placeholder(in context: Context) -> DinkrWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (DinkrWidgetEntry) -> Void) {
        completion(context.isPreview ? .mock : buildEntry(date: Date(), smallStat: loadSmallStat()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DinkrWidgetEntry>) -> Void) {
        let now       = Date()
        let stat      = loadSmallStat()
        let nextGame  = loadNextGame()

        // Produce entries at: now, +15m, +30m, +1h, +2h, …, +24h
        // Finer granularity when a game is within 3 hours.
        var dates: [Date] = []
        let calendar = Calendar.current

        if let gameDate = nextGame?.dateTime, gameDate.timeIntervalSince(now) < 3 * 3600 {
            // Every 15 minutes up to game time
            var cursor = now
            while cursor <= gameDate {
                dates.append(cursor)
                cursor = calendar.date(byAdding: .minute, value: 15, to: cursor) ?? cursor.addingTimeInterval(900)
            }
        } else {
            // Hourly for 24 hours
            dates = (0..<24).compactMap {
                calendar.date(byAdding: .hour, value: $0, to: now)
            }
        }

        let entries = dates.map { buildEntry(date: $0, smallStat: stat) }

        // Reload policy: if we know the next game time, reload right after it
        let reloadDate: Date
        if let gameDate = nextGame?.dateTime, gameDate > now {
            reloadDate = gameDate.addingTimeInterval(60)   // 1 minute after game starts
        } else {
            reloadDate = calendar.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        }

        let timeline = Timeline(entries: entries, policy: .after(reloadDate))
        completion(timeline)
    }

    // MARK: - Build Entry

    private func buildEntry(date: Date, smallStat: SmallWidgetStat) -> DinkrWidgetEntry {
        let nextGame = loadNextGame()

        // Relevance: max relevance (1.0) when game is within 30 min, scales down to 0 at 6h+
        var relevance: TimelineEntryRelevance? = nil
        if let gameDate = nextGame?.dateTime {
            let diff = max(0, gameDate.timeIntervalSince(date))
            if diff < 6 * 3600 {
                let score = Float(max(0, 1.0 - diff / (6 * 3600)))
                let duration = min(diff, 1800)    // relevance lasts until game or 30 min
                relevance = TimelineEntryRelevance(score: score, duration: duration)
            }
        }

        return DinkrWidgetEntry(
            date: date,
            relevance: relevance,
            playerName: loadPlayerName(),
            duprRating: loadDUPR(),
            reliabilityScore: loadReliability(),
            upcomingGameCount: loadGameCount(),
            nextGame: nextGame,
            todayGames: loadTodayGames(),
            currentStreak: loadStreak(),
            lastPlayedDate: loadLastPlayedDate(),
            weeklyStats: loadWeeklyStats(),
            activeChallenge: loadChallenge(),
            openCourtsNearby: loadOpenCourts(),
            leaderboardRank: loadLeaderboardRank(),
            weather: loadWeather(),
            smallStat: smallStat
        )
    }

    // MARK: - Data Loaders (AppGroup UserDefaults; fallback to mock)

    private let defaults = dinkrWidgetDefaults

    private func loadPlayerName() -> String {
        defaults?.string(forKey: "widget_playerName") ?? "Alex Rivera"
    }

    private func loadDUPR() -> Double {
        defaults?.double(forKey: "widget_duprRating").nonZero ?? 4.69
    }

    private func loadReliability() -> Double {
        defaults?.double(forKey: "widget_reliabilityScore").nonZero ?? 4.8
    }

    private func loadGameCount() -> Int {
        let v = defaults?.integer(forKey: "widget_upcomingGameCount") ?? 0
        return v > 0 ? v : 3
    }

    private func loadOpenCourts() -> Int {
        let v = defaults?.integer(forKey: "widget_openCourtsNearby") ?? 0
        return v > 0 ? v : 3
    }

    private func loadStreak() -> Int {
        let v = defaults?.integer(forKey: "widget_currentStreak") ?? 0
        return v > 0 ? v : 7
    }

    private func loadLastPlayedDate() -> Date? {
        if let interval = defaults?.double(forKey: "widget_lastPlayedTimestamp"), interval > 0 {
            return Date(timeIntervalSince1970: interval)
        }
        return Calendar.current.date(byAdding: .day, value: -1, to: Date())
    }

    private func loadWeeklyStats() -> WeeklyStatsInfo {
        let wins   = defaults?.integer(forKey: "widget_weeklyWins") ?? 0
        let losses = defaults?.integer(forKey: "widget_weeklyLosses") ?? 0
        if wins + losses > 0 {
            return WeeklyStatsInfo(wins: wins, losses: losses)
        }
        return WeeklyStatsInfo(wins: 4, losses: 1)
    }

    private func loadLeaderboardRank() -> Int? {
        let v = defaults?.integer(forKey: "widget_leaderboardRank") ?? 0
        return v > 0 ? v : 12
    }

    private func loadNextGame() -> NextGameInfo? {
        // Prefer a stored Date timestamp so we can do real countdown
        var gameDate: Date
        if let interval = defaults?.double(forKey: "widget_nextGame_timestamp"), interval > 0 {
            gameDate = Date(timeIntervalSince1970: interval)
        } else {
            gameDate = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
        }

        let court  = defaults?.string(forKey: "widget_nextGame_court")  ?? "Garrison Park Courts"
        let format = defaults?.string(forKey: "widget_nextGame_format") ?? "Doubles"
        let time   = defaults?.string(forKey: "widget_nextGame_time")   ?? "Today 6:00 PM"
        let spots  = defaults?.integer(forKey: "widget_nextGame_spots") ?? 2

        return NextGameInfo(
            courtName: court,
            format: format,
            timeString: time,
            spotsLeft: spots,
            dateTime: gameDate
        )
    }

    private func loadTodayGames() -> [GameSummary] {
        // Decode up to 2 today's games stored as JSON array in defaults
        if let data = defaults?.data(forKey: "widget_todayGames"),
           let decoded = try? JSONDecoder().decode([TodayGameCodable].self, from: data) {
            return decoded.map { GameSummary(courtName: $0.court, format: $0.format, timeString: $0.time, spotsLeft: $0.spots) }
        }
        // Fallback mock
        return [
            GameSummary(courtName: "Garrison Park",  format: "Doubles", timeString: "6:00 PM", spotsLeft: 2),
            GameSummary(courtName: "Westside Rec",   format: "Singles", timeString: "8:00 PM", spotsLeft: 4),
        ]
    }

    private func loadChallenge() -> ActiveChallengeInfo? {
        guard let opp = defaults?.string(forKey: "widget_challenge_opponent") else {
            return ActiveChallengeInfo(
                type: "Win Race",
                opponentName: "Maria Chen",
                myProgress: 0.6,
                theirProgress: 0.4,
                daysLeft: 3
            )
        }
        return ActiveChallengeInfo(
            type: defaults?.string(forKey: "widget_challenge_type") ?? "Win Race",
            opponentName: opp,
            myProgress: defaults?.double(forKey: "widget_challenge_myProgress") ?? 0.6,
            theirProgress: defaults?.double(forKey: "widget_challenge_theirProgress") ?? 0.4,
            daysLeft: defaults?.integer(forKey: "widget_challenge_daysLeft") ?? 3
        )
    }

    private func loadWeather() -> WeatherSnippet? {
        guard let emoji = defaults?.string(forKey: "widget_weather_emoji") else {
            return WeatherSnippet(emoji: "☀️", temperatureF: 74, label: "Clear", isGoodForPlay: true)
        }
        return WeatherSnippet(
            emoji: emoji,
            temperatureF: defaults?.integer(forKey: "widget_weather_tempF") ?? 72,
            label: defaults?.string(forKey: "widget_weather_label") ?? "Clear",
            isGoodForPlay: defaults?.bool(forKey: "widget_weather_good") ?? true
        )
    }

    private func loadSmallStat() -> SmallWidgetStat {
        let raw = defaults?.string(forKey: "widget_smallStat") ?? SmallWidgetStat.nextGame.rawValue
        return SmallWidgetStat(rawValue: raw) ?? .nextGame
    }
}

// MARK: - Codable helper for todayGames UserDefaults

private struct TodayGameCodable: Codable {
    let court: String
    let format: String
    let time: String
    let spots: Int
}

// MARK: - Widget Declarations

/// Small (2×2) — user chooses "Next Game" or "Streak" via widget edit
struct DinkrNextGameWidget: Widget {
    let kind = DinkrWidgetKind.nextGame

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DinkrProvider()) { entry in
            DinkrWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "dinkr://games"))
        }
        .configurationDisplayName("Next Game")
        .description("Countdown to your next game, format badge, and court name.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct DinkrStreakWidget: Widget {
    let kind = DinkrWidgetKind.streak

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DinkrProvider()) { entry in
            DinkrWidgetEntryView(entry: DinkrWidgetEntry(
                date: entry.date,
                relevance: entry.relevance,
                playerName: entry.playerName,
                duprRating: entry.duprRating,
                reliabilityScore: entry.reliabilityScore,
                upcomingGameCount: entry.upcomingGameCount,
                nextGame: entry.nextGame,
                todayGames: entry.todayGames,
                currentStreak: entry.currentStreak,
                lastPlayedDate: entry.lastPlayedDate,
                weeklyStats: entry.weeklyStats,
                activeChallenge: entry.activeChallenge,
                openCourtsNearby: entry.openCourtsNearby,
                leaderboardRank: entry.leaderboardRank,
                weather: entry.weather,
                smallStat: .streak
            ))
            .widgetURL(URL(string: "dinkr://profile/streak"))
        }
        .configurationDisplayName("Streak")
        .description("Your current play streak, fire count, and last played date.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

/// Medium (2×4) — Today's Games list
struct DinkrTodayGamesWidget: Widget {
    let kind = DinkrWidgetKind.todayGames

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DinkrProvider()) { entry in
            DinkrWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "dinkr://games"))
        }
        .configurationDisplayName("Today's Games")
        .description("Up to 2 upcoming games with format, time, and open spots.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

/// Medium (2×4) — My Stats
struct DinkrMyStatsWidget: Widget {
    let kind = DinkrWidgetKind.myStats

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DinkrProvider()) { entry in
            // Inject .streak flag so DinkrWidgetEntryView routes to MediumMyStatsView
            DinkrWidgetEntryView(entry: DinkrWidgetEntry(
                date: entry.date,
                relevance: entry.relevance,
                playerName: entry.playerName,
                duprRating: entry.duprRating,
                reliabilityScore: entry.reliabilityScore,
                upcomingGameCount: entry.upcomingGameCount,
                nextGame: entry.nextGame,
                todayGames: entry.todayGames,
                currentStreak: entry.currentStreak,
                lastPlayedDate: entry.lastPlayedDate,
                weeklyStats: entry.weeklyStats,
                activeChallenge: entry.activeChallenge,
                openCourtsNearby: entry.openCourtsNearby,
                leaderboardRank: entry.leaderboardRank,
                weather: entry.weather,
                smallStat: .streak      // routes medium view to MediumMyStatsView
            ))
            .widgetURL(URL(string: "dinkr://profile/stats"))
        }
        .configurationDisplayName("My Stats")
        .description("DUPR rating, weekly W/L record, and next game countdown.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

/// Large (4×4) — Full Dinkr Dashboard
struct DinkrDashboardWidget: Widget {
    let kind = DinkrWidgetKind.dashboard

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DinkrProvider()) { entry in
            DinkrWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "dinkr://dashboard"))
        }
        .configurationDisplayName("Dinkr Dashboard")
        .description("Next game, streak, leaderboard position, and local weather.")
        .supportedFamilies([.systemLarge])
        .contentMarginsDisabled()
    }
}

/// Lock Screen — Circular: streak fire count
struct DinkrLockCircleWidget: Widget {
    let kind = DinkrWidgetKind.lockCircle

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DinkrProvider()) { entry in
            DinkrWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "dinkr://profile/streak"))
        }
        .configurationDisplayName("Streak")
        .description("Your current play streak on the lock screen.")
        .supportedFamilies([.accessoryCircular])
        .contentMarginsDisabled()
    }
}

/// Lock Screen — Rectangular: "Next game: 2h 30m · Westside"
struct DinkrLockRectWidget: Widget {
    let kind = DinkrWidgetKind.lockRect

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DinkrProvider()) { entry in
            DinkrWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "dinkr://games"))
        }
        .configurationDisplayName("Next Game")
        .description("Next game countdown and court name on your lock screen.")
        .supportedFamilies([.accessoryRectangular])
        .contentMarginsDisabled()
    }
}

/// Lock Screen — Inline: "3 games this week · 🏓"
struct DinkrLockInlineWidget: Widget {
    let kind = DinkrWidgetKind.lockInline

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DinkrProvider()) { entry in
            DinkrWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "dinkr://games"))
        }
        .configurationDisplayName("Games This Week")
        .description("Inline lock screen summary of your week.")
        .supportedFamilies([.accessoryInline])
        .contentMarginsDisabled()
    }
}

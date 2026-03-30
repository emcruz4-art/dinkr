// DinkrWidget.swift
// DinkrWidget — Widget configuration and timeline provider

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct DinkrWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> DinkrWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (DinkrWidgetEntry) -> Void) {
        completion(.mock)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DinkrWidgetEntry>) -> Void) {
        let entry = DinkrWidgetEntry(
            date: Date(),
            playerName: loadPlayerName(),
            duprRating: loadDUPR(),
            reliabilityScore: loadReliability(),
            upcomingGameCount: loadGameCount(),
            nextGame: loadNextGame(),
            activeChallenge: loadChallenge(),
            openCourtsNearby: loadOpenCourts()
        )

        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }

    // MARK: - Data loaders (AppGroup UserDefaults; fallback to mock)

    private let defaults = UserDefaults(suiteName: "group.com.dinkr.ios")

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
        return v > 0 ? v : 2
    }
    private func loadOpenCourts() -> Int {
        let v = defaults?.integer(forKey: "widget_openCourtsNearby") ?? 0
        return v > 0 ? v : 3
    }
    private func loadNextGame() -> NextGameInfo? {
        guard let court = defaults?.string(forKey: "widget_nextGame_court") else {
            return NextGameInfo(
                courtName: "Garrison Park Courts",
                format: "Doubles",
                timeString: "Today 6:00 PM",
                spotsLeft: 2
            )
        }
        return NextGameInfo(
            courtName: court,
            format: defaults?.string(forKey: "widget_nextGame_format") ?? "Doubles",
            timeString: defaults?.string(forKey: "widget_nextGame_time") ?? "Today 6:00 PM",
            spotsLeft: defaults?.integer(forKey: "widget_nextGame_spots") ?? 2
        )
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
}

// MARK: - Double helper

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}

// MARK: - Widget Declaration

struct DinkrWidget: Widget {
    let kind: String = "DinkrWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DinkrWidgetProvider()) { entry in
            DinkrWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Dinkr Dashboard")
        .description("Upcoming games, active challenges, and your DUPR rating.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// DinkrWidgetModel.swift
// DinkrWidget — Timeline entry model and mock data

import WidgetKit
import Foundation

// MARK: - Supporting Types

struct NextGameInfo {
    let courtName: String
    let format: String
    let timeString: String
    let spotsLeft: Int
}

struct ActiveChallengeInfo {
    let type: String
    let opponentName: String
    let myProgress: Double
    let theirProgress: Double
    let daysLeft: Int
}

// MARK: - Timeline Entry

struct DinkrWidgetEntry: TimelineEntry {
    let date: Date
    let playerName: String
    let duprRating: Double
    let reliabilityScore: Double
    let upcomingGameCount: Int
    let nextGame: NextGameInfo?
    let activeChallenge: ActiveChallengeInfo?
    let openCourtsNearby: Int
}

// MARK: - Mock Data

extension DinkrWidgetEntry {
    static let mock = DinkrWidgetEntry(
        date: Date(),
        playerName: "Alex Rivera",
        duprRating: 4.69,
        reliabilityScore: 4.8,
        upcomingGameCount: 2,
        nextGame: NextGameInfo(
            courtName: "Garrison Park Courts",
            format: "Doubles",
            timeString: "Today 6:00 PM",
            spotsLeft: 2
        ),
        activeChallenge: ActiveChallengeInfo(
            type: "Win Race",
            opponentName: "Maria Chen",
            myProgress: 0.6,
            theirProgress: 0.4,
            daysLeft: 3
        ),
        openCourtsNearby: 3
    )

    static let placeholder = DinkrWidgetEntry(
        date: Date(),
        playerName: "Player",
        duprRating: 0.0,
        reliabilityScore: 0.0,
        upcomingGameCount: 0,
        nextGame: nil,
        activeChallenge: nil,
        openCourtsNearby: 0
    )
}

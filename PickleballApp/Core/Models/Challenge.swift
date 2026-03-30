import Foundation

enum ChallengeType: String, Codable, CaseIterable {
    case drillBattle    = "Drill Battle"      // Who completes a drill faster / better
    case gameChallenge  = "Game Challenge"    // Challenge to a head-to-head game
    case fitnessRace    = "Fitness Race"      // Steps, active minutes, calories over a period
    case streakWar      = "Streak War"        // Who keeps a longer daily play streak
    case winRace        = "Win Race"          // Who racks up more wins this week/month
    case courtHours     = "Court Hours"       // Who logs the most court time
    case rallyContest   = "Rally Contest"     // Longest rally (self-reported or video proof)
    case improvementChallenge = "Improvement" // Biggest DUPR rating jump in X days

    var icon: String {
        switch self {
        case .drillBattle:         return "figure.strengthtraining.functional"
        case .gameChallenge:       return "figure.pickleball"
        case .fitnessRace:         return "flame.fill"
        case .streakWar:           return "calendar.badge.checkmark"
        case .winRace:             return "trophy.fill"
        case .courtHours:          return "clock.fill"
        case .rallyContest:        return "arrow.left.arrow.right"
        case .improvementChallenge: return "chart.line.uptrend.xyaxis"
        }
    }

    var color: String { // maps to dinkr colors
        switch self {
        case .drillBattle:         return "coral"
        case .gameChallenge:       return "green"
        case .fitnessRace:         return "amber"
        case .streakWar:           return "amber"
        case .winRace:             return "amber"
        case .courtHours:          return "sky"
        case .rallyContest:        return "green"
        case .improvementChallenge: return "sky"
        }
    }

    var brandColor: Color {
        switch color {
        case "coral": return Color.dinkrCoral
        case "green": return Color.dinkrGreen
        case "amber": return Color.dinkrAmber
        case "sky":   return Color.dinkrSky
        default:      return Color.dinkrGreen
        }
    }

    var description: String {
        switch self {
        case .drillBattle:         return "Who completes a drill faster or better?"
        case .gameChallenge:       return "Head-to-head game — best of 3"
        case .fitnessRace:         return "Most active minutes over a set period"
        case .streakWar:           return "Who keeps a longer daily play streak?"
        case .winRace:             return "Who racks up the most wins?"
        case .courtHours:          return "Who logs the most court time?"
        case .rallyContest:        return "Longest rally — self-reported or video proof"
        case .improvementChallenge: return "Biggest DUPR rating jump in X days"
        }
    }
}

enum ChallengeStatus: String, Codable {
    case pending   = "Pending"    // Sent, waiting for acceptance
    case active    = "Active"     // Accepted, in progress
    case completed = "Completed"  // Time expired or goal reached
    case declined  = "Declined"
    case cancelled = "Cancelled"
}

struct ChallengeParticipant: Identifiable, Codable {
    var id: String   // = userId
    var displayName: String
    var username: String
    var avatarURL: String?
    var progress: Double   // 0.0–1.0 toward the goal
    var currentValue: Double  // raw value (wins, hours, etc.)
    var isWinner: Bool
}

struct Challenge: Identifiable, Codable {
    var id: String
    var type: ChallengeType
    var title: String           // e.g. "7-Day Win Race"
    var description: String     // What they're competing on
    var challengerId: String
    var challengerName: String
    var participants: [ChallengeParticipant]
    var goalValue: Double       // Target: 10 wins, 5 hours, etc.
    var goalUnit: String        // "wins", "hours", "day streak", etc.
    var status: ChallengeStatus
    var startDate: Date
    var endDate: Date
    var createdAt: Date
    var winnerMessage: String?  // Message from winner
    var proofVideoURL: String?  // Optional video proof (rally contests etc.)
    var isPublic: Bool          // Show in activity feed

    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0)
    }

    var isExpired: Bool { Date() > endDate }

    var leadingParticipant: ChallengeParticipant? {
        participants.max(by: { $0.currentValue < $1.currentValue })
    }
}

// MARK: - GroupChallengeMetric

enum GroupChallengeMetric: String, Codable, CaseIterable {
    case gamesPlayed    = "Games Played"
    case totalWins      = "Total Wins"
    case wellnessPoints = "Wellness Points"
    case avgImprovement = "Avg DUPR Improvement"
    case courtHours     = "Court Hours"

    var icon: String {
        switch self {
        case .gamesPlayed:    return "figure.pickleball"
        case .totalWins:      return "trophy.fill"
        case .wellnessPoints: return "heart.fill"
        case .avgImprovement: return "chart.line.uptrend.xyaxis"
        case .courtHours:     return "clock.fill"
        }
    }
}

// MARK: - GroupChallenge

struct GroupChallenge: Identifiable, Codable {
    var id: String
    var title: String
    var challengerGroupId: String
    var challengerGroupName: String
    var challengedGroupId: String
    var challengedGroupName: String
    var metric: GroupChallengeMetric
    var startDate: Date
    var endDate: Date
    var status: ChallengeStatus
    var challengerScore: Int
    var challengedScore: Int
    var challengerPlayerCount: Int
    var challengedPlayerCount: Int
    var stakes: String
    var createdByUserId: String

    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0)
    }
    var isExpired: Bool { Date() > endDate }
    var leadingGroupName: String? {
        if challengerScore > challengedScore { return challengerGroupName }
        if challengedScore > challengerScore { return challengedGroupName }
        return nil
    }
}

import SwiftUI

extension Challenge {
    static let mockChallenges: [Challenge] = [
        Challenge(
            id: "ch_001", type: .winRace,
            title: "7-Day Win Race",
            description: "Who can rack up the most wins in 7 days?",
            challengerId: "user_003",
            challengerName: "Jordan Smith",
            participants: [
                ChallengeParticipant(id: "user_001", displayName: "Alex Rivera", username: "pickleking", avatarURL: nil, progress: 0.7, currentValue: 7, isWinner: false),
                ChallengeParticipant(id: "user_003", displayName: "Jordan Smith", username: "jordan_4point0", avatarURL: nil, progress: 0.5, currentValue: 5, isWinner: false)
            ],
            goalValue: 10, goalUnit: "wins",
            status: .active,
            startDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: 4, to: Date())!,
            createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            winnerMessage: nil, proofVideoURL: nil, isPublic: true
        ),
        Challenge(
            id: "ch_002", type: .streakWar,
            title: "Streak War",
            description: "Keep your daily play streak alive longer than your opponent",
            challengerId: "user_002",
            challengerName: "Maria Chen",
            participants: [
                ChallengeParticipant(id: "user_001", displayName: "Alex Rivera", username: "pickleking", avatarURL: nil, progress: 0.8, currentValue: 8, isWinner: false),
                ChallengeParticipant(id: "user_002", displayName: "Maria Chen", username: "maria_plays", avatarURL: nil, progress: 1.0, currentValue: 10, isWinner: false)
            ],
            goalValue: 10, goalUnit: "day streak",
            status: .active,
            startDate: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: 20, to: Date())!,
            createdAt: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
            winnerMessage: nil, proofVideoURL: nil, isPublic: true
        ),
        Challenge(
            id: "ch_003", type: .drillBattle,
            title: "Dink Drill Battle",
            description: "Complete 100 crosscourt dinks with the fewest errors",
            challengerId: "user_001",
            challengerName: "Alex Rivera",
            participants: [
                ChallengeParticipant(id: "user_001", displayName: "Alex Rivera", username: "pickleking", avatarURL: nil, progress: 0.6, currentValue: 60, isWinner: false),
                ChallengeParticipant(id: "user_009", displayName: "Riley Torres", username: "riley_dinkmaster", avatarURL: nil, progress: 0.45, currentValue: 45, isWinner: false)
            ],
            goalValue: 100, goalUnit: "clean dinks",
            status: .active,
            startDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: 6, to: Date())!,
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            winnerMessage: nil, proofVideoURL: nil, isPublic: false
        ),
        Challenge(
            id: "ch_004", type: .gameChallenge,
            title: "Game Challenge",
            description: "Best of 3 games — challenge accepted!",
            challengerId: "user_007",
            challengerName: "Jamie Lee",
            participants: [
                ChallengeParticipant(id: "user_001", displayName: "Alex Rivera", username: "pickleking", avatarURL: nil, progress: 0, currentValue: 0, isWinner: false),
                ChallengeParticipant(id: "user_007", displayName: "Jamie Lee", username: "jamiepb", avatarURL: nil, progress: 0, currentValue: 0, isWinner: false)
            ],
            goalValue: 2, goalUnit: "games won",
            status: .pending,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            createdAt: Date(),
            winnerMessage: nil, proofVideoURL: nil, isPublic: false
        ),
        Challenge(
            id: "ch_005", type: .improvementChallenge,
            title: "DUPR Climb",
            description: "Who improves their DUPR rating the most in 30 days?",
            challengerId: "user_004",
            challengerName: "Sarah Johnson",
            participants: [
                ChallengeParticipant(id: "user_001", displayName: "Alex Rivera", username: "pickleking", avatarURL: nil, progress: 0.4, currentValue: 0.08, isWinner: true),
                ChallengeParticipant(id: "user_004", displayName: "Sarah Johnson", username: "sarahj_pb", avatarURL: nil, progress: 0.25, currentValue: 0.05, isWinner: false)
            ],
            goalValue: 0.2, goalUnit: "DUPR points",
            status: .completed,
            startDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
            winnerMessage: "GG! You've been putting in the work", proofVideoURL: nil, isPublic: true
        ),
    ]
}

extension GroupChallenge {
    static let mockGroupChallenges: [GroupChallenge] = [
        GroupChallenge(
            id: "gc_001",
            title: "South Austin vs Mueller: Win Race",
            challengerGroupId: "grp_001",
            challengerGroupName: "South Austin Dinkers",
            challengedGroupId: "grp_003",
            challengedGroupName: "Mueller Morning Crew",
            metric: .totalWins,
            startDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: 9, to: Date())!,
            status: .active,
            challengerScore: 38,
            challengedScore: 29,
            challengerPlayerCount: 54,
            challengedPlayerCount: 19,
            stakes: "Winning group gets bragging rights 🏆",
            createdByUserId: "user_003"
        ),
        GroupChallenge(
            id: "gc_002",
            title: "4.0+ Competitive vs South Austin: Court Hours",
            challengerGroupId: "grp_002",
            challengerGroupName: "4.0+ Competitive Pool",
            challengedGroupId: "grp_001",
            challengedGroupName: "South Austin Dinkers",
            metric: .courtHours,
            startDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())!,
            status: .pending,
            challengerScore: 0,
            challengedScore: 0,
            challengerPlayerCount: 28,
            challengedPlayerCount: 54,
            stakes: "Losers buy coffee at next Sunday round robin ☕",
            createdByUserId: "user_002"
        ),
    ]
}

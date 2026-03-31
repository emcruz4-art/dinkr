import SwiftUI

// MARK: - TrainingPlan

struct TrainingPlan: Identifiable {
    var id: String
    var name: String
    var level: String        // "Beginner", "Intermediate", "Advanced", "All Levels"
    var durationWeeks: Int
    var sessionsPerWeek: Int
    var totalDrills: Int
    var description: String
    var drillIds: [String]
    var colorGradient: [Color]   // two dinkr colors
    var badge: String            // SF symbol name
}


// MARK: - Mock Training Plans

extension TrainingPlan {
    static let mockPlans: [TrainingPlan] = [
        TrainingPlan(
            id: "plan_001",
            name: "Foundation Series",
            level: "Beginner",
            durationWeeks: 4,
            sessionsPerWeek: 3,
            totalDrills: 5,
            description: "Build the fundamentals that every strong pickleball game is built on. Covers service mechanics, dinking, basic footwork, and kitchen line positioning over four structured weeks.",
            drillIds: ["drill_001", "drill_004", "drill_006", "drill_010", "drill_012"],
            colorGradient: [Color.dinkrGreen, Color.dinkrSky],
            badge: "figure.pickleball"
        ),
        TrainingPlan(
            id: "plan_002",
            name: "Dink Master",
            level: "Intermediate",
            durationWeeks: 6,
            sessionsPerWeek: 4,
            totalDrills: 7,
            description: "Elevate your soft game to a weapon. Six weeks dedicated to cross-court consistency, speed-control, Erne threats, and the net-play exchanges that decide close matches.",
            drillIds: ["drill_001", "drill_002", "drill_003", "drill_007", "drill_008", "drill_011", "drill_013"],
            colorGradient: [Color.dinkrNavy, Color.dinkrGreen],
            badge: "trophy.fill"
        ),
        TrainingPlan(
            id: "plan_003",
            name: "Tournament Prep",
            level: "Advanced",
            durationWeeks: 8,
            sessionsPerWeek: 5,
            totalDrills: 10,
            description: "Eight weeks of high-intensity preparation for competitive play. Combines every skill zone — third-shot decision-making, speed-up defense, advanced footwork, and peak-performance conditioning.",
            drillIds: ["drill_002", "drill_003", "drill_005", "drill_007", "drill_009", "drill_011", "drill_013", "drill_014", "drill_015", "drill_001"],
            colorGradient: [Color.dinkrCoral, Color.dinkrAmber],
            badge: "medal.fill"
        ),
        TrainingPlan(
            id: "plan_004",
            name: "Quick Wins",
            level: "All Levels",
            durationWeeks: 2,
            sessionsPerWeek: 3,
            totalDrills: 4,
            description: "A compact two-week program designed to sharpen three or four high-impact skills fast. Great for players returning after a break or prepping for a casual tournament weekend.",
            drillIds: ["drill_004", "drill_006", "drill_008", "drill_012"],
            colorGradient: [Color.dinkrAmber, Color.dinkrSky],
            badge: "bolt.fill"
        )
    ]
}

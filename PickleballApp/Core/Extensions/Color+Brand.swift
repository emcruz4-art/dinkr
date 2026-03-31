import SwiftUI

extension Color {
    // MARK: - Dinkr brand palette
    static let dinkrGreen = Color(red: 0.18, green: 0.74, blue: 0.38)   // vibrant sporty green — primary
    static let dinkrNavy  = Color(red: 0.10, green: 0.18, blue: 0.29)   // deep navy — headers/contrast
    static let dinkrCoral = Color(red: 0.95, green: 0.36, blue: 0.23)   // energetic coral — CTAs/alerts
    static let dinkrAmber = Color(red: 0.96, green: 0.65, blue: 0.14)   // warm amber — badges/ratings
    static let dinkrSky   = Color(red: 0.29, green: 0.66, blue: 0.83)   // sky blue — info/secondary

    // MARK: - Legacy aliases (backward compat)
    static let pickleballGreen = Color.dinkrGreen
    static let courtBlue       = Color.dinkrSky
    static let courtOrange     = Color.dinkrCoral

    // MARK: - Semantic surface colors
    static let appBackground   = Color(UIColor.systemBackground)
    static let cardBackground  = Color(UIColor.secondarySystemBackground)
    static let primaryText     = Color.primary
    static let secondaryText   = Color.secondary
    static let divider         = Color(UIColor.separator)
}

// MARK: - Gradient helpers

extension LinearGradient {
    /// Green → Navy: primary brand gradient for hero surfaces and CTAs
    static var dinkrPrimaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color.dinkrGreen, Color.dinkrNavy],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Amber → Coral: warm energy gradient for ratings, streaks, highlights
    static var dinkrWarmGradient: LinearGradient {
        LinearGradient(
            colors: [Color.dinkrAmber, Color.dinkrCoral],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Sky → Navy: cool info gradient for courts, weather, stats panels
    static var dinkrCoolGradient: LinearGradient {
        LinearGradient(
            colors: [Color.dinkrSky, Color.dinkrNavy],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Green → Amber: celebration gradient for wins, achievements, confetti
    static var dinkrCelebrationGradient: LinearGradient {
        LinearGradient(
            colors: [Color.dinkrGreen, Color.dinkrAmber],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

import SwiftUI

extension Color {
    // Dinkr brand palette
    static let dinkrGreen = Color(red: 0.18, green: 0.74, blue: 0.38)   // vibrant sporty green — primary
    static let dinkrNavy  = Color(red: 0.10, green: 0.18, blue: 0.29)   // deep navy — headers/contrast
    static let dinkrCoral = Color(red: 0.95, green: 0.36, blue: 0.23)   // energetic coral — CTAs/alerts
    static let dinkrAmber = Color(red: 0.96, green: 0.65, blue: 0.14)   // warm amber — badges/ratings
    static let dinkrSky   = Color(red: 0.29, green: 0.66, blue: 0.83)   // sky blue — info/secondary

    // Legacy aliases kept for backward compat
    static let pickleballGreen = Color.dinkrGreen
    static let courtBlue       = Color.dinkrSky
    static let courtOrange     = Color.dinkrCoral

    // Semantic
    static let cardBackground = Color(UIColor.secondarySystemBackground)
    static let appBackground  = Color(UIColor.systemBackground)
}

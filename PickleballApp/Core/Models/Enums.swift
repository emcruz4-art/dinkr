import Foundation

enum SkillLevel: String, Codable, CaseIterable, Hashable {
    case beginner20 = "2.0"
    case beginner25 = "2.5"
    case intermediate30 = "3.0"
    case intermediate35 = "3.5"
    case advanced40 = "4.0"
    case advanced45 = "4.5"
    case pro50 = "5.0+"

    var label: String { rawValue }

    var color: String {
        switch self {
        case .beginner20, .beginner25: return "green"
        case .intermediate30, .intermediate35: return "blue"
        case .advanced40, .advanced45: return "orange"
        case .pro50: return "red"
        }
    }
}

enum PostType: String, Codable, CaseIterable {
    case general, highlight, question, winCelebration, courtReview, lookingForGame
}

enum GameFormat: String, Codable, CaseIterable {
    case singles, doubles, mixed, openPlay, round_robin = "Round Robin"
}

enum EventType: String, Codable, CaseIterable {
    case tournament, clinic, openPlay, social, womenOnly, fundraiser
}

enum MarketCategory: String, Codable, CaseIterable {
    case paddles, balls, bags, apparel, shoes, accessories, courts, other
}

enum ListingCondition: String, Codable, CaseIterable {
    case brandNew = "Brand New"
    case likeNew = "Like New"
    case good = "Good"
    case fair = "Fair"
    case forParts = "For Parts"
}

enum ListingStatus: String, Codable {
    case active, sold, reserved, expired
}

enum BadgeType: String, Codable {
    case reliablePro, tournamentWinner, communityChampion, centennial, firstGame, womensPioneer, courtBuilder
}

enum GroupType: String, Codable, CaseIterable {
    case publicClub = "Public Club"
    case privateClub = "Private Club"
    case womenOnly = "Women Only"
    case ageGroup = "Age Group"
    case recreational = "Recreational"
    case competitive = "Competitive"
    case neighborhood = "Neighborhood"
}

enum CourtSurface: String, Codable, CaseIterable {
    case hardcourt, concrete, asphalt, indoor, clay
}

enum MessageType: String, Codable {
    case text, image, gameInvite, systemNote
}

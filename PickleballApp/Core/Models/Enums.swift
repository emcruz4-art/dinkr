import Foundation

enum SkillLevel: String, Codable, CaseIterable, Hashable, Comparable {
    case beginner20 = "2.0"
    case beginner25 = "2.5"
    case intermediate30 = "3.0"
    case intermediate35 = "3.5"
    case advanced40 = "4.0"
    case advanced45 = "4.5"
    case pro50 = "5.0+"

    var label: String { rawValue }

    /// Numeric position used for sort scoring and match-quality calculation.
    var sortIndex: Int {
        switch self {
        case .beginner20: return 0
        case .beginner25: return 1
        case .intermediate30: return 2
        case .intermediate35: return 3
        case .advanced40: return 4
        case .advanced45: return 5
        case .pro50: return 6
        }
    }

    static func < (lhs: SkillLevel, rhs: SkillLevel) -> Bool {
        lhs.sortIndex < rhs.sortIndex
    }

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
    case corporate = "Corporate"
    case internalLeague = "Internal League"
}

enum PlayStyle: String, Codable, CaseIterable {
    case competitive    = "Competitive"
    case recreational   = "Recreational"
    case drillFocused   = "Drill-Focused"
    case dinkCulture    = "Dink Culture"
    case allAround      = "All-Around"

    var icon: String {
        switch self {
        case .competitive:  return "flame.fill"
        case .recreational: return "face.smiling.fill"
        case .drillFocused: return "target"
        case .dinkCulture:  return "figure.mind.and.body"
        case .allAround:    return "star.fill"
        }
    }

    var color: String {
        switch self {
        case .competitive:  return "dinkrCoral"
        case .recreational: return "dinkrGreen"
        case .drillFocused: return "dinkrSky"
        case .dinkCulture:  return "dinkrAmber"
        case .allAround:    return "dinkrNavy"
        }
    }
}

enum CourtSurface: String, Codable, CaseIterable {
    case hardcourt, concrete, asphalt, indoor, clay
}

enum MessageType: String, Codable {
    case text, image, gameInvite, systemNote
}

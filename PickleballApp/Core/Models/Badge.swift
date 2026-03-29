import Foundation

struct Badge: Identifiable, Codable, Hashable {
    var id: String
    var type: BadgeType
    var earnedAt: Date
    var label: String

    var icon: String {
        switch type {
        case .reliablePro: return "star.fill"
        case .tournamentWinner: return "trophy.fill"
        case .communityChampion: return "heart.fill"
        case .centennial: return "100.circle.fill"
        case .firstGame: return "play.circle.fill"
        case .womensPioneer: return "figure.stand"
        case .courtBuilder: return "hammer.fill"
        }
    }

    var color: String {
        switch type {
        case .reliablePro: return "yellow"
        case .tournamentWinner: return "orange"
        case .communityChampion: return "red"
        case .centennial: return "purple"
        case .firstGame: return "green"
        case .womensPioneer: return "pink"
        case .courtBuilder: return "blue"
        }
    }
}

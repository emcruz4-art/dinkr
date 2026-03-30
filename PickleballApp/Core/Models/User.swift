import Foundation
import CoreLocation

struct SocialLinks: Codable, Hashable {
    var instagram: String = ""
    var tiktok: String = ""
    var youtube: String = ""
    var linkedin: String = ""
    var twitter: String = ""
    var website: String = ""

    var isEmpty: Bool {
        instagram.isEmpty && tiktok.isEmpty && youtube.isEmpty
            && linkedin.isEmpty && twitter.isEmpty && website.isEmpty
    }
}

struct User: Identifiable, Codable, Hashable {
    var id: String
    var displayName: String
    var username: String
    var avatarURL: String?
    var bio: String
    var skillLevel: SkillLevel
    var city: String
    var location: GeoPoint?
    var clubIds: [String]
    var badges: [Badge]
    var reliabilityScore: Double
    var gamesPlayed: Int
    var wins: Int
    var joinedDate: Date
    var isWomenOnly: Bool
    var followersCount: Int
    var followingCount: Int
    var duprRating: Double?
    var isPrivate: Bool
    var socialLinks: SocialLinks
    var playStyle: PlayStyle?
    var department: String?

    var winRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(wins) / Double(gamesPlayed)
    }
}

struct GeoPoint: Codable, Hashable {
    var latitude: Double
    var longitude: Double

    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension User {
    static let mockCurrentUser = User(
        id: "user_001",
        displayName: "Alex Rivera",
        username: "pickleking",
        avatarURL: nil,
        bio: "3.5 player | Austin TX | always looking for a game 🥒",
        skillLevel: .intermediate35,
        city: "Austin, TX",
        location: GeoPoint(latitude: 30.2672, longitude: -97.7431),
        clubIds: ["club_001", "club_002"],
        badges: [.init(id: "b1", type: .reliablePro, earnedAt: Date(), label: "Reliable Pro")],
        reliabilityScore: 4.8,
        gamesPlayed: 142,
        wins: 89,
        joinedDate: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date(),
        isWomenOnly: false,
        followersCount: 234,
        followingCount: 178,
        duprRating: 4.69,
        isPrivate: false,
        socialLinks: SocialLinks(
            instagram: "pickleking",
            tiktok: "pickleking",
            youtube: "pickleking",
            linkedin: "alexrivera",
            twitter: "pickleking",
            website: "https://dinkr.app"
        ),
        playStyle: .dinkCulture,
        department: "Engineering"
    )

    static let mockPlayers: [User] = [
        User(id: "user_002", displayName: "Maria Chen", username: "maria_plays",
             avatarURL: nil, bio: "Women's 3.5 singles champion. Austin Open 2024 🏆",
             skillLevel: .intermediate35, city: "Austin, TX",
             location: GeoPoint(latitude: 30.2700, longitude: -97.7440),
             clubIds: ["club_002"], badges: [.init(id: "b2", type: .tournamentWinner, earnedAt: Date(), label: "Tournament Winner")],
             reliabilityScore: 4.9, gamesPlayed: 203, wins: 148,
             joinedDate: Calendar.current.date(byAdding: .month, value: -18, to: Date()) ?? Date(),
             isWomenOnly: true, followersCount: 412, followingCount: 205, duprRating: nil, isPrivate: false, socialLinks: SocialLinks(), playStyle: .competitive, department: "Engineering"),
        User(id: "user_003", displayName: "Jordan Smith", username: "jordan_4point0",
             avatarURL: nil, bio: "4.0 aggressive baseliner. Let's play!",
             skillLevel: .advanced40, city: "Austin, TX",
             location: GeoPoint(latitude: 30.3042, longitude: -97.7024),
             clubIds: ["club_001"], badges: [],
             reliabilityScore: 4.5, gamesPlayed: 87, wins: 51,
             joinedDate: Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date(),
             isWomenOnly: false, followersCount: 98, followingCount: 134, duprRating: nil, isPrivate: false, socialLinks: SocialLinks(), playStyle: .allAround, department: "Sales"),
        User(id: "user_004", displayName: "Sarah Johnson", username: "sarahj_pb",
             avatarURL: nil, bio: "Community builder. 100+ women's league members 💪",
             skillLevel: .intermediate35, city: "Austin, TX",
             location: GeoPoint(latitude: 30.2473, longitude: -97.7528),
             clubIds: ["club_002", "club_003"], badges: [.init(id: "b3", type: .communityChampion, earnedAt: Date(), label: "Community Champion")],
             reliabilityScore: 5.0, gamesPlayed: 176, wins: 102,
             joinedDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date(),
             isWomenOnly: false, followersCount: 567, followingCount: 89, duprRating: nil, isPrivate: false, socialLinks: SocialLinks(), playStyle: .recreational, department: "Marketing"),
        User(id: "user_005", displayName: "Chris Park", username: "chrisp_dink",
             avatarURL: nil, bio: "4.0+ doubles specialist. Kitchen magician.",
             skillLevel: .advanced40, city: "Round Rock, TX",
             location: GeoPoint(latitude: 30.5085, longitude: -97.6789),
             clubIds: ["club_001"], badges: [],
             reliabilityScore: 4.7, gamesPlayed: 312, wins: 198,
             joinedDate: Calendar.current.date(byAdding: .year, value: -3, to: Date()) ?? Date(),
             isWomenOnly: false, followersCount: 289, followingCount: 211, duprRating: nil, isPrivate: true, socialLinks: SocialLinks(), playStyle: nil, department: nil),
        User(id: "user_006", displayName: "Taylor Kim", username: "tkim_pickles",
             avatarURL: nil, bio: "Beginner turned 3.0. Still learning every day!",
             skillLevel: .intermediate30, city: "Cedar Park, TX",
             location: GeoPoint(latitude: 30.5049, longitude: -97.8202),
             clubIds: [], badges: [],
             reliabilityScore: 4.3, gamesPlayed: 34, wins: 18,
             joinedDate: Calendar.current.date(byAdding: .month, value: -4, to: Date()) ?? Date(),
             isWomenOnly: false, followersCount: 45, followingCount: 67, duprRating: nil, isPrivate: false, socialLinks: SocialLinks(), playStyle: nil, department: nil),
        User(id: "user_007", displayName: "Jamie Lee", username: "jamiepb",
             avatarURL: nil, bio: "4.5 bandit. Former tennis pro. Loves the dink battle.",
             skillLevel: .advanced45, city: "Austin, TX",
             location: GeoPoint(latitude: 30.2889, longitude: -97.7681),
             clubIds: ["club_001"], badges: [.init(id: "b4", type: .reliablePro, earnedAt: Date(), label: "Reliable Pro")],
             reliabilityScore: 4.6, gamesPlayed: 445, wins: 301,
             joinedDate: Calendar.current.date(byAdding: .year, value: -4, to: Date()) ?? Date(),
             isWomenOnly: false, followersCount: 734, followingCount: 156, duprRating: nil, isPrivate: true, socialLinks: SocialLinks(), playStyle: nil, department: nil),
        User(id: "user_008", displayName: "Morgan Davis", username: "morganplays",
             avatarURL: nil, bio: "3.0 and climbing. Mueller Park regular.",
             skillLevel: .intermediate30, city: "Austin, TX",
             location: GeoPoint(latitude: 30.3042, longitude: -97.7024),
             clubIds: [], badges: [],
             reliabilityScore: 4.4, gamesPlayed: 56, wins: 28,
             joinedDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
             isWomenOnly: false, followersCount: 67, followingCount: 89, duprRating: nil, isPrivate: false, socialLinks: SocialLinks(), playStyle: nil, department: nil),
        User(id: "user_009", displayName: "Riley Torres", username: "riley_dinkmaster",
             avatarURL: nil, bio: "Dinkmaster Level 9. Weekend warrior, weekday dreamer.",
             skillLevel: .intermediate35, city: "Austin, TX",
             location: GeoPoint(latitude: 30.2672, longitude: -97.7531),
             clubIds: ["club_003"], badges: [],
             reliabilityScore: 4.8, gamesPlayed: 121, wins: 73,
             joinedDate: Calendar.current.date(byAdding: .month, value: -10, to: Date()) ?? Date(),
             isWomenOnly: false, followersCount: 189, followingCount: 145, duprRating: nil, isPrivate: false, socialLinks: SocialLinks(), playStyle: nil, department: nil),
    ]
}

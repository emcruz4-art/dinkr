import Foundation
import CoreLocation

struct SocialLinks: Codable, Hashable {
    var instagram: String = ""
    var tiktok: String = ""
    var youtube: String = ""
    var linkedin: String = ""
    var twitter: String = ""
    var website: String = ""
    var pickleheads: String = ""

    var isEmpty: Bool {
        instagram.isEmpty && tiktok.isEmpty && youtube.isEmpty
            && linkedin.isEmpty && twitter.isEmpty && website.isEmpty && pickleheads.isEmpty
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
    var playStyles: [PlayStyle]? = nil
    var dominantHand: DominantHand? = nil
    var yearsPlaying: Int? = nil
    var availabilityDays: [Weekday]? = nil
    var availableTimes: [TimeOfDay]? = nil
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
        User(id: "user_010", displayName: "Tyler Brooks", username: "tylerbrooks_pb",
             avatarURL: nil, bio: "2.5 and loving every second of it. Just found pickleball 6 months ago — hooked for life.",
             skillLevel: .beginner25, city: "San Marcos, TX",
             location: GeoPoint(latitude: 29.8833, longitude: -97.9414),
             clubIds: [], badges: [],
             reliabilityScore: 4.2, gamesPlayed: 22, wins: 9,
             joinedDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
             isWomenOnly: false, followersCount: 28, followingCount: 52, duprRating: nil, isPrivate: false,
             socialLinks: SocialLinks(instagram: "tylerbrooks_pb"),
             playStyle: .recreational, department: nil),
        User(id: "user_011", displayName: "Priya Patel", username: "priyapatel_dinks",
             avatarURL: nil, bio: "4.0 singles grinder | former tennis D1 | Austin by way of Houston | obsessed with the erne.",
             skillLevel: .advanced40, city: "Austin, TX",
             location: GeoPoint(latitude: 30.2453, longitude: -97.7610),
             clubIds: ["club_001", "club_002"], badges: [.init(id: "b5", type: .reliablePro, earnedAt: Date(), label: "Reliable Pro")],
             reliabilityScore: 4.9, gamesPlayed: 267, wins: 174,
             joinedDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date(),
             isWomenOnly: false, followersCount: 381, followingCount: 142, duprRating: 4.31, isPrivate: false,
             socialLinks: SocialLinks(instagram: "priyapatel_dinks", twitter: "priyapb"),
             playStyle: .drillFocused, department: "Product"),
        User(id: "user_012", displayName: "Marcus Williams", username: "marcusw_kitchen",
             avatarURL: nil, bio: "Kitchen king. 4.5 doubles specialist. Retired basketball coach who traded hardwood for hardcourt.",
             skillLevel: .advanced45, city: "Pflugerville, TX",
             location: GeoPoint(latitude: 30.4393, longitude: -97.6200),
             clubIds: ["club_001"], badges: [.init(id: "b6", type: .tournamentWinner, earnedAt: Date(), label: "Tournament Winner")],
             reliabilityScore: 4.7, gamesPlayed: 398, wins: 263,
             joinedDate: Calendar.current.date(byAdding: .year, value: -3, to: Date()) ?? Date(),
             isWomenOnly: false, followersCount: 612, followingCount: 95, duprRating: 4.72, isPrivate: false,
             socialLinks: SocialLinks(instagram: "marcusw_kitchen", youtube: "marcuswilliamspb"),
             playStyle: .competitive, department: nil),
        User(id: "user_013", displayName: "Sophie Chen", username: "sophie_serves",
             avatarURL: nil, bio: "3.0 recreational player and community organizer. Sundays at Mueller are my church.",
             skillLevel: .intermediate30, city: "Austin, TX",
             location: GeoPoint(latitude: 30.3100, longitude: -97.7050),
             clubIds: ["club_002", "club_003"], badges: [.init(id: "b7", type: .communityChampion, earnedAt: Date(), label: "Community Champion")],
             reliabilityScore: 5.0, gamesPlayed: 88, wins: 47,
             joinedDate: Calendar.current.date(byAdding: .month, value: -14, to: Date()) ?? Date(),
             isWomenOnly: true, followersCount: 204, followingCount: 178, duprRating: nil, isPrivate: false,
             socialLinks: SocialLinks(instagram: "sophie_serves"),
             playStyle: .recreational, department: "Design"),
        User(id: "user_014", displayName: "Derek Martinez", username: "derekmartinez_5pt0",
             avatarURL: nil, bio: "5.0+ pro. PPA Tour participant. Coaching available. DMs open for clinics.",
             skillLevel: .pro50, city: "Austin, TX",
             location: GeoPoint(latitude: 30.2672, longitude: -97.7431),
             clubIds: ["club_001"],
             badges: [
                .init(id: "b8", type: .reliablePro, earnedAt: Date(), label: "Reliable Pro"),
                .init(id: "b9", type: .tournamentWinner, earnedAt: Date(), label: "Tournament Winner")
             ],
             reliabilityScore: 5.0, gamesPlayed: 892, wins: 671,
             joinedDate: Calendar.current.date(byAdding: .year, value: -5, to: Date()) ?? Date(),
             isWomenOnly: false, followersCount: 4821, followingCount: 312, duprRating: 5.47, isPrivate: false,
             socialLinks: SocialLinks(instagram: "derekmartinez_pb", tiktok: "derekmartinez_5pt0", youtube: "DerekMartinezPickleball", twitter: "derekmartinezpb"),
             playStyle: .competitive, department: nil),
        User(id: "user_015", displayName: "Aisha Johnson", username: "aishaj_bangerz",
             avatarURL: nil, bio: "3.5 banger with a backhand that doesn't quit. ATX Women's League co-captain. Always down for open play.",
             skillLevel: .intermediate35, city: "Austin, TX",
             location: GeoPoint(latitude: 30.2550, longitude: -97.7600),
             clubIds: ["club_002"], badges: [],
             reliabilityScore: 4.6, gamesPlayed: 145, wins: 82,
             joinedDate: Calendar.current.date(byAdding: .month, value: -20, to: Date()) ?? Date(),
             isWomenOnly: true, followersCount: 276, followingCount: 231, duprRating: nil, isPrivate: false,
             socialLinks: SocialLinks(instagram: "aishaj_bangerz"),
             playStyle: .allAround, department: "Legal"),
        User(id: "user_016", displayName: "Kevin Park", username: "kevinpark_spin",
             avatarURL: nil, bio: "Topspin obsessed. 4.0 singles. Former table tennis player — brings an unusual spin game to the court.",
             skillLevel: .advanced40, city: "Georgetown, TX",
             location: GeoPoint(latitude: 30.6330, longitude: -97.6779),
             clubIds: ["club_001"], badges: [],
             reliabilityScore: 4.5, gamesPlayed: 193, wins: 118,
             joinedDate: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date(),
             isWomenOnly: false, followersCount: 143, followingCount: 167, duprRating: 4.15, isPrivate: false,
             socialLinks: SocialLinks(tiktok: "kevinpark_spin"),
             playStyle: .drillFocused, department: "Finance"),
        User(id: "user_017", displayName: "Olivia Turner", username: "oliviaturner_pb",
             avatarURL: nil, bio: "2.0 beginner — started 3 months ago. Scared of the erne but working on it. This community is the best!",
             skillLevel: .beginner20, city: "Buda, TX",
             location: GeoPoint(latitude: 30.0854, longitude: -97.8403),
             clubIds: [], badges: [.init(id: "b10", type: .firstGame, earnedAt: Date(), label: "First Game")],
             reliabilityScore: 4.0, gamesPlayed: 11, wins: 3,
             joinedDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
             isWomenOnly: false, followersCount: 14, followingCount: 43, duprRating: nil, isPrivate: false,
             socialLinks: SocialLinks(),
             playStyle: .recreational, department: nil),
    ]

    /// All mock users including the current signed-in user.
    static var mockUsers: [User] {
        [mockCurrentUser] + mockPlayers
    }

    /// All mock users excluding the current signed-in user — useful for player search / discovery screens.
    static var otherPlayers: [User] {
        mockPlayers
    }
}

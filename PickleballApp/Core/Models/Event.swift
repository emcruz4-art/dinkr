import Foundation

struct Event: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var type: EventType
    var description: String
    var location: String
    var coordinates: GeoPoint?
    var dateTime: Date
    var endDateTime: Date?
    var registrationURL: String?
    var registrationDeadline: Date?
    var isPro: Bool
    var isWomenOnly: Bool
    var organizer: String
    var organizerId: String
    var maxParticipants: Int?
    var currentParticipants: Int
    var entryFee: Double?
    var prizePool: String?
    var bannerURL: String?
    var tags: [String]
}

extension Event {
    static let mockEvents: [Event] = [
        Event(id: "evt_001", title: "Austin Open Pickleball Tournament",
              type: .tournament, description: "Annual open tournament featuring singles, doubles, and mixed doubles brackets for all skill levels 3.0–5.0+.",
              location: "Westside Pickleball Complex, Austin TX",
              coordinates: GeoPoint(latitude: 30.2889, longitude: -97.7681),
              dateTime: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
              endDateTime: Calendar.current.date(byAdding: .day, value: 15, to: Date()),
              registrationURL: "https://example.com/austin-open",
              registrationDeadline: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
              isPro: false, isWomenOnly: false, organizer: "Austin Pickleball Alliance",
              organizerId: "club_001", maxParticipants: 256, currentParticipants: 178,
              entryFee: 45.00, prizePool: "$5,000", bannerURL: nil,
              tags: ["tournament", "austin", "allskills"]),
        Event(id: "evt_002", title: "Women's Beginner Clinic",
              type: .clinic, description: "A supportive 3-hour clinic designed specifically for women new to pickleball. Certified instructor. Equipment provided.",
              location: "Mueller Recreation Center, Austin TX",
              coordinates: GeoPoint(latitude: 30.3042, longitude: -97.7024),
              dateTime: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
              endDateTime: nil, registrationURL: nil, registrationDeadline: nil,
              isPro: false, isWomenOnly: true, organizer: "ATX Women's Pickleball",
              organizerId: "club_002", maxParticipants: 20, currentParticipants: 14,
              entryFee: 25.00, prizePool: nil, bannerURL: nil,
              tags: ["clinic", "womens", "beginner"]),
        Event(id: "evt_003", title: "Friday Night Social Mixer",
              type: .social, description: "Casual open play social every Friday evening. Food trucks on site. All skill levels welcome.",
              location: "South Lamar Sports Club, Austin TX",
              coordinates: GeoPoint(latitude: 30.2473, longitude: -97.7528),
              dateTime: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
              endDateTime: nil, registrationURL: nil, registrationDeadline: nil,
              isPro: false, isWomenOnly: false, organizer: "South Lamar Sports Club",
              organizerId: "club_003", maxParticipants: 80, currentParticipants: 52,
              entryFee: 10.00, prizePool: nil, bannerURL: nil,
              tags: ["social", "openplay", "friday"]),
        Event(id: "evt_004", title: "4.0+ Competitive Ladder",
              type: .tournament, description: "Weekly competitive ladder play for serious 4.0+ players. Rotating partners, ELO-style ranking system. Shows up in your Dinkr ranking.",
              location: "Westside Pickleball Complex, Austin TX",
              coordinates: GeoPoint(latitude: 30.2889, longitude: -97.7681),
              dateTime: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
              endDateTime: nil, registrationURL: nil, registrationDeadline: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
              isPro: false, isWomenOnly: false, organizer: "Austin Competitive Pickleball",
              organizerId: "club_001", maxParticipants: 32, currentParticipants: 21,
              entryFee: 15.00, prizePool: nil, bannerURL: nil,
              tags: ["competitive", "ladder", "4point0"]),
        Event(id: "evt_005", title: "Sunday Morning Open Play Social",
              type: .social, description: "Casual open play every Sunday morning at Mueller. Food trucks, good vibes, all skill levels. Doors open at 7:30am.",
              location: "Mueller Recreation Center, Austin TX",
              coordinates: GeoPoint(latitude: 30.3042, longitude: -97.7024),
              dateTime: Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date(),
              endDateTime: nil, registrationURL: nil, registrationDeadline: nil,
              isPro: false, isWomenOnly: false, organizer: "Mueller Park Community",
              organizerId: "club_003", maxParticipants: 60, currentParticipants: 38,
              entryFee: 0.00, prizePool: nil, bannerURL: nil,
              tags: ["social", "openplay", "sunday"]),
        Event(id: "evt_006", title: "Pickleball 101 — Beginner Workshop",
              type: .clinic, description: "A friendly 2-hour intro workshop. No equipment needed — paddles and balls provided. Perfect for absolute beginners.",
              location: "South Lamar Sports Club, Austin TX",
              coordinates: GeoPoint(latitude: 30.2473, longitude: -97.7528),
              dateTime: Calendar.current.date(byAdding: .day, value: 8, to: Date()) ?? Date(),
              endDateTime: nil, registrationURL: nil, registrationDeadline: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
              isPro: false, isWomenOnly: false, organizer: "South Lamar Sports Club",
              organizerId: "club_003", maxParticipants: 15, currentParticipants: 6,
              entryFee: 20.00, prizePool: nil, bannerURL: nil,
              tags: ["beginner", "clinic", "intro"]),
        Event(id: "evt_007", title: "ATX Charity Pickleball Fundraiser",
              type: .fundraiser, description: "Annual charity tournament supporting Austin youth sports programs. Round robin format, prizes for top teams, silent auction on site.",
              location: "Zilker Park Courts, Austin TX",
              coordinates: GeoPoint(latitude: 30.2672, longitude: -97.7731),
              dateTime: Calendar.current.date(byAdding: .day, value: 21, to: Date()) ?? Date(),
              endDateTime: Calendar.current.date(byAdding: .day, value: 21, to: Date()),
              registrationURL: "https://example.com/charity",
              registrationDeadline: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
              isPro: false, isWomenOnly: false, organizer: "Austin Community Foundation",
              organizerId: "club_001", maxParticipants: 128, currentParticipants: 84,
              entryFee: 50.00, prizePool: "Charity Prizes", bannerURL: nil,
              tags: ["charity", "fundraiser", "community"]),
        Event(id: "evt_008", title: "Women's 3.5 Round Robin",
              type: .womenOnly, description: "Competitive round robin exclusively for women's 3.5 players. Excellent for DUPR tracking and finding regular partners.",
              location: "Barton Springs Tennis Center, Austin TX",
              coordinates: GeoPoint(latitude: 30.2502, longitude: -97.7720),
              dateTime: Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date(),
              endDateTime: nil, registrationURL: nil,
              registrationDeadline: Calendar.current.date(byAdding: .day, value: 8, to: Date()),
              isPro: false, isWomenOnly: true, organizer: "ATX Women's Pickleball",
              organizerId: "club_002", maxParticipants: 24, currentParticipants: 18,
              entryFee: 20.00, prizePool: nil, bannerURL: nil,
              tags: ["womens", "roundrobin", "3.5"]),
    ]
}

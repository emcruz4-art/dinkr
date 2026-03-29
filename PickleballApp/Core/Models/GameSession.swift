import Foundation

struct GameSession: Identifiable, Codable, Hashable {
    var id: String
    var hostId: String
    var hostName: String
    var courtId: String
    var courtName: String
    var dateTime: Date
    var format: GameFormat
    var skillRange: ClosedRange<SkillLevel>
    var totalSpots: Int
    var rsvps: [String]
    var waitlist: [String]
    var isPublic: Bool
    var notes: String
    var fee: Double?

    var spotsRemaining: Int { max(0, totalSpots - rsvps.count) }
    var isFull: Bool { spotsRemaining == 0 }

    // Custom Codable for ClosedRange
    private enum CodingKeys: String, CodingKey {
        case id, hostId, hostName, courtId, courtName, dateTime, format
        case skillMin, skillMax, totalSpots, rsvps, waitlist, isPublic, notes, fee
    }

    init(id: String, hostId: String, hostName: String, courtId: String, courtName: String,
         dateTime: Date, format: GameFormat, skillRange: ClosedRange<SkillLevel>,
         totalSpots: Int, rsvps: [String], waitlist: [String], isPublic: Bool, notes: String, fee: Double? = nil) {
        self.id = id; self.hostId = hostId; self.hostName = hostName
        self.courtId = courtId; self.courtName = courtName; self.dateTime = dateTime
        self.format = format; self.skillRange = skillRange; self.totalSpots = totalSpots
        self.rsvps = rsvps; self.waitlist = waitlist; self.isPublic = isPublic
        self.notes = notes; self.fee = fee
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        hostId = try c.decode(String.self, forKey: .hostId)
        hostName = try c.decode(String.self, forKey: .hostName)
        courtId = try c.decode(String.self, forKey: .courtId)
        courtName = try c.decode(String.self, forKey: .courtName)
        dateTime = try c.decode(Date.self, forKey: .dateTime)
        format = try c.decode(GameFormat.self, forKey: .format)
        let min = try c.decode(SkillLevel.self, forKey: .skillMin)
        let max = try c.decode(SkillLevel.self, forKey: .skillMax)
        skillRange = min...max
        totalSpots = try c.decode(Int.self, forKey: .totalSpots)
        rsvps = try c.decode([String].self, forKey: .rsvps)
        waitlist = try c.decode([String].self, forKey: .waitlist)
        isPublic = try c.decode(Bool.self, forKey: .isPublic)
        notes = try c.decode(String.self, forKey: .notes)
        fee = try c.decodeIfPresent(Double.self, forKey: .fee)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(hostId, forKey: .hostId)
        try c.encode(hostName, forKey: .hostName); try c.encode(courtId, forKey: .courtId)
        try c.encode(courtName, forKey: .courtName); try c.encode(dateTime, forKey: .dateTime)
        try c.encode(format, forKey: .format); try c.encode(skillRange.lowerBound, forKey: .skillMin)
        try c.encode(skillRange.upperBound, forKey: .skillMax); try c.encode(totalSpots, forKey: .totalSpots)
        try c.encode(rsvps, forKey: .rsvps); try c.encode(waitlist, forKey: .waitlist)
        try c.encode(isPublic, forKey: .isPublic); try c.encode(notes, forKey: .notes)
        try c.encodeIfPresent(fee, forKey: .fee)
    }
}

extension GameSession {
    static let mockSessions: [GameSession] = [
        GameSession(id: "gs1", hostId: "user_002", hostName: "Maria Chen",
                    courtId: "court_001", courtName: "Westside Pickleball Complex",
                    dateTime: Date().addingTimeInterval(7200),
                    format: .doubles, skillRange: .intermediate30 ... .intermediate35,
                    totalSpots: 4, rsvps: ["user_001", "user_002"], waitlist: [],
                    isPublic: true, notes: "Bring water! Courts can get hot."),
        GameSession(id: "gs2", hostId: "user_003", hostName: "Jordan Smith",
                    courtId: "court_002", courtName: "Mueller Recreation Center",
                    dateTime: Date().addingTimeInterval(86400),
                    format: .openPlay, skillRange: .beginner25 ... .advanced40,
                    totalSpots: 12, rsvps: ["user_003", "user_004", "user_005"], waitlist: [],
                    isPublic: true, notes: "Open play — all welcome!"),
        GameSession(id: "gs3", hostId: "user_004", hostName: "Sarah Johnson",
                    courtId: "court_003", courtName: "South Lamar Sports Club",
                    dateTime: Date().addingTimeInterval(172800),
                    format: .mixed, skillRange: .intermediate35 ... .advanced45,
                    totalSpots: 8, rsvps: Array(repeating: "u", count: 7), waitlist: ["user_006"],
                    isPublic: false, notes: "Members only. Bring your DUPR rating."),
        GameSession(id: "gs4", hostId: "user_005", hostName: "Chris Park",
                    courtId: "court_001", courtName: "Westside Pickleball Complex",
                    dateTime: Date().addingTimeInterval(10800),
                    format: .singles, skillRange: .advanced40 ... .advanced45,
                    totalSpots: 2, rsvps: ["user_005"], waitlist: [],
                    isPublic: true, notes: "Competitive singles match. Bring your A game.", fee: nil),
        GameSession(id: "gs5", hostId: "user_007", hostName: "Jamie Lee",
                    courtId: "court_004", courtName: "Barton Springs Tennis Center",
                    dateTime: Date().addingTimeInterval(18000),
                    format: .round_robin, skillRange: .intermediate35 ... .advanced45,
                    totalSpots: 8, rsvps: ["user_007", "user_003", "user_009"], waitlist: [],
                    isPublic: true, notes: "Rotating partners round robin. Great for practice!", fee: 5.00),
        GameSession(id: "gs6", hostId: "user_009", hostName: "Riley Torres",
                    courtId: "court_002", courtName: "Mueller Recreation Center",
                    dateTime: Date().addingTimeInterval(3600),
                    format: .doubles, skillRange: .intermediate30 ... .intermediate35,
                    totalSpots: 4, rsvps: ["user_009", "user_008", "user_006"], waitlist: [],
                    isPublic: true, notes: "3.0–3.5 only. Super chill, learning focused.", fee: nil),
        GameSession(id: "gs7", hostId: "user_004", hostName: "Sarah Johnson",
                    courtId: "court_003", courtName: "South Lamar Sports Club",
                    dateTime: Date().addingTimeInterval(14400),
                    format: .mixed, skillRange: .intermediate35 ... .advanced40,
                    totalSpots: 6, rsvps: ["user_004", "user_002"], waitlist: [],
                    isPublic: false, notes: "Women's group mixed session. Members only.", fee: nil),
        GameSession(id: "gs8", hostId: "user_002", hostName: "Maria Chen",
                    courtId: "court_005", courtName: "Zilker Park Courts",
                    dateTime: Date().addingTimeInterval(28800),
                    format: .openPlay, skillRange: .beginner25 ... .advanced45,
                    totalSpots: 16, rsvps: Array(repeating: "u", count: 9), waitlist: [],
                    isPublic: true, notes: "Outdoor sunset open play! All welcome. Food trucks nearby!", fee: 0.00),
    ]
}

extension SkillLevel: Comparable {
    public static func < (lhs: SkillLevel, rhs: SkillLevel) -> Bool {
        let order: [SkillLevel] = [.beginner20, .beginner25, .intermediate30, .intermediate35, .advanced40, .advanced45, .pro50]
        return (order.firstIndex(of: lhs) ?? 0) < (order.firstIndex(of: rhs) ?? 0)
    }
}

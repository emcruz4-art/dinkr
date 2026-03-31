import Foundation

struct DinkrGroup: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var type: GroupType
    var description: String
    var memberIds: [String]
    var adminIds: [String]
    var chatThreadId: String?
    var eventIds: [String]
    var isPrivate: Bool
    var bannerURL: String?
    var memberCount: Int
}

extension DinkrGroup {
    static let mockGroups: [DinkrGroup] = [
        DinkrGroup(id: "grp_001", name: "South Austin Dinkers", type: .neighborhood,
              description: "Casual rec play for South Austin folks. We meet Tue/Thu/Sat.",
              memberIds: [], adminIds: ["user_003"], chatThreadId: "chat_001",
              eventIds: [], isPrivate: false, bannerURL: nil, memberCount: 54),
        DinkrGroup(id: "grp_002", name: "4.0+ Competitive Pool", type: .competitive,
              description: "Organized competitive play for 4.0 and above. Round robins every other Sunday.",
              memberIds: [], adminIds: ["user_002"], chatThreadId: "chat_002",
              eventIds: [], isPrivate: true, bannerURL: nil, memberCount: 28),
        DinkrGroup(id: "grp_003", name: "Mueller Morning Crew", type: .recreational,
              description: "Early birds at Mueller. 6:30am sharp, M/W/F.",
              memberIds: [], adminIds: ["user_005"], chatThreadId: "chat_003",
              eventIds: [], isPrivate: false, bannerURL: nil, memberCount: 19),
        DinkrGroup(id: "grp_004", name: "Westlake Weekend Warriors", type: .recreational,
              description: "Saturday/Sunday doubles at Westlake courts. All skill levels.",
              memberIds: [], adminIds: ["user_007"], chatThreadId: "chat_004",
              eventIds: [], isPrivate: false, bannerURL: nil, memberCount: 41),
        DinkrGroup(id: "grp_005", name: "ATX Pro Dev Squad", type: .competitive,
              description: "High-level training group. DUPR 4.5+ only. Drill-heavy sessions.",
              memberIds: [], adminIds: ["user_009"], chatThreadId: "chat_005",
              eventIds: [], isPrivate: true, bannerURL: nil, memberCount: 12),
        DinkrGroup(id: "grp_006", name: "Austin Women's Pickleball", type: .womenOnly,
              description: "A welcoming space for women of all levels. Weekly clinics and social play.",
              memberIds: [], adminIds: ["user_011"], chatThreadId: "chat_006",
              eventIds: [], isPrivate: false, bannerURL: nil, memberCount: 67),
        DinkrGroup(id: "grp_007", name: "Dell Technologies Smashers", type: .corporate,
              description: "Official Dell Austin campus group. Lunch and evening sessions in the parking lot courts.",
              memberIds: [], adminIds: ["user_013"], chatThreadId: "chat_007",
              eventIds: [], isPrivate: false, bannerURL: nil, memberCount: 33),
        DinkrGroup(id: "grp_008", name: "Barton Hills Neighbors", type: .neighborhood,
              description: "Friendly neighborhood games at Barton Hills Elementary. Families welcome.",
              memberIds: [], adminIds: ["user_015"], chatThreadId: "chat_008",
              eventIds: [], isPrivate: false, bannerURL: nil, memberCount: 22),
    ]
}

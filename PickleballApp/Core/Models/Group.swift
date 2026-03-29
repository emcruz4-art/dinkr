import Foundation

struct Group: Identifiable, Codable, Hashable {
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

extension Group {
    static let mockGroups: [Group] = [
        Group(id: "grp_001", name: "South Austin Dinkers", type: .neighborhood,
              description: "Casual rec play for South Austin folks. We meet Tue/Thu/Sat.",
              memberIds: [], adminIds: ["user_003"], chatThreadId: "chat_001",
              eventIds: [], isPrivate: false, bannerURL: nil, memberCount: 54),
        Group(id: "grp_002", name: "4.0+ Competitive Pool", type: .competitive,
              description: "Organized competitive play for 4.0 and above. Round robins every other Sunday.",
              memberIds: [], adminIds: ["user_002"], chatThreadId: "chat_002",
              eventIds: [], isPrivate: true, bannerURL: nil, memberCount: 28),
        Group(id: "grp_003", name: "Mueller Morning Crew", type: .recreational,
              description: "Early birds at Mueller. 6:30am sharp, M/W/F.",
              memberIds: [], adminIds: ["user_005"], chatThreadId: "chat_003",
              eventIds: [], isPrivate: false, bannerURL: nil, memberCount: 19),
    ]
}

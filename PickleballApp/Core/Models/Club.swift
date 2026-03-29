import Foundation

struct Club: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var description: String
    var memberIds: [String]
    var adminIds: [String]
    var location: GeoPoint?
    var city: String
    var isWomenOnly: Bool
    var bannerURL: String?
    var logoURL: String?
    var memberCount: Int
    var foundedYear: Int
}

extension Club {
    static let mockClubs: [Club] = [
        Club(id: "club_001", name: "Austin Pickleball Alliance",
             description: "Austin's largest community pickleball organization with open play, leagues, and tournaments for all skill levels.",
             memberIds: [], adminIds: ["user_001"], location: GeoPoint(latitude: 30.2672, longitude: -97.7431),
             city: "Austin, TX", isWomenOnly: false, bannerURL: nil, logoURL: nil,
             memberCount: 847, foundedYear: 2019),
        Club(id: "club_002", name: "ATX Women's Pickleball",
             description: "A safe, welcoming space for women of all skill levels to play, learn, and build community through pickleball.",
             memberIds: [], adminIds: ["user_004"], location: GeoPoint(latitude: 30.2672, longitude: -97.7431),
             city: "Austin, TX", isWomenOnly: true, bannerURL: nil, logoURL: nil,
             memberCount: 312, foundedYear: 2021),
    ]
}



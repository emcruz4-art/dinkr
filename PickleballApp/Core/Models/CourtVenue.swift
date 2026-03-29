import Foundation
import CoreLocation

struct CourtVenue: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var address: String
    var coordinates: GeoPoint
    var courtCount: Int
    var surface: CourtSurface
    var hasLighting: Bool
    var isIndoor: Bool
    var openPlaySchedule: String
    var amenities: [String]
    var rating: Double
    var reviewCount: Int
    var websiteURL: String?
    var phoneNumber: String?
}

extension CourtVenue {
    static let mockVenues: [CourtVenue] = [
        CourtVenue(id: "court_001", name: "Westside Pickleball Complex",
                   address: "4501 W 35th St, Austin, TX 78703",
                   coordinates: GeoPoint(latitude: 30.2889, longitude: -97.7681),
                   courtCount: 12, surface: .hardcourt, hasLighting: true, isIndoor: false,
                   openPlaySchedule: "Mon–Fri 6am–9pm, Sat–Sun 7am–8pm",
                   amenities: ["Restrooms", "Water Fountains", "Pro Shop", "Lessons"],
                   rating: 4.7, reviewCount: 234, websiteURL: nil, phoneNumber: "512-555-0101"),
        CourtVenue(id: "court_002", name: "Mueller Recreation Center",
                   address: "4730 Mueller Blvd, Austin, TX 78723",
                   coordinates: GeoPoint(latitude: 30.3042, longitude: -97.7024),
                   courtCount: 6, surface: .hardcourt, hasLighting: true, isIndoor: false,
                   openPlaySchedule: "Daily 6am–10pm",
                   amenities: ["Restrooms", "Parking", "Water Fountains"],
                   rating: 4.4, reviewCount: 178, websiteURL: nil, phoneNumber: nil),
        CourtVenue(id: "court_003", name: "South Lamar Sports Club",
                   address: "1600 S Lamar Blvd, Austin, TX 78704",
                   coordinates: GeoPoint(latitude: 30.2473, longitude: -97.7528),
                   courtCount: 4, surface: .indoor, hasLighting: true, isIndoor: true,
                   openPlaySchedule: "Members only — 24/7 access",
                   amenities: ["Locker Rooms", "Pro Shop", "Coaching", "Gym"],
                   rating: 4.9, reviewCount: 89, websiteURL: nil, phoneNumber: "512-555-0303"),
    ]
}

import Foundation

struct CourtReview: Identifiable, Codable, Hashable {
    var id: String
    var courtId: String
    var authorId: String
    var authorName: String
    var authorUsername: String
    var overallRating: Double        // 1.0–5.0
    var surfaceRating: Double        // Court surface quality
    var lightingRating: Double       // Lighting (1 = poor, 5 = excellent)
    var facilityRating: Double       // Bathrooms, parking, amenities
    var crowdsRating: Double         // How crowded / wait times
    var atmosphereRating: Double     // Community vibe
    var body: String                 // Written review text
    var typicalPlayTimes: [String]   // e.g. ["Weekday mornings", "Weekend afternoons"]
    var tags: [CourtTag]             // Quick descriptor tags
    var isVerifiedPlayer: Bool       // Has logged games here
    var helpfulCount: Int
    var createdAt: Date
    var isFeatured: Bool
}

// MARK: - CourtTag

enum CourtTag: String, Codable, CaseIterable, Hashable {
    case greatSurface = "Great Surface"
    case wellLit = "Well Lit"
    case goodParking = "Good Parking"
    case friendly = "Friendly Community"
    case competitive = "Competitive Play"
    case beginnerFriendly = "Beginner Friendly"
    case windProtected = "Wind Protected"
    case shaded = "Shaded Courts"
    case cleanFacilities = "Clean Facilities"
    case easyToBook = "Easy to Book"
    case crowded = "Gets Crowded"
    case waitTimes = "Long Wait Times"
    case poorLighting = "Poor Lighting"
    case roughSurface = "Rough Surface"
}

// MARK: - Mock Data

extension CourtReview {

    static let mockReviews: [CourtReview] = [

        // MARK: court_001 — Westside Pickleball Complex

        CourtReview(
            id: "rev_001", courtId: "court_001",
            authorId: "user_002", authorName: "Maria Chen", authorUsername: "maria_plays",
            overallRating: 4.5, surfaceRating: 5.0, lightingRating: 4.0,
            facilityRating: 4.5, crowdsRating: 3.5, atmosphereRating: 5.0,
            body: "Best outdoor courts in Austin! The surface was just resurfaced last spring and it's silky smooth. The pickleball community here is super welcoming — I've made so many friends. Gets busy on weekend mornings but worth showing up early.",
            typicalPlayTimes: ["Weekday mornings 7–10am", "Weekend 7–9am"],
            tags: [.greatSurface, .friendly, .shaded, .crowded],
            isVerifiedPlayer: true, helpfulCount: 34,
            createdAt: Calendar.current.date(byAdding: .day, value: -12, to: Date()) ?? Date(),
            isFeatured: true
        ),

        CourtReview(
            id: "rev_002", courtId: "court_001",
            authorId: "user_003", authorName: "Jordan Smith", authorUsername: "jordan_4point0",
            overallRating: 3.5, surfaceRating: 3.0, lightingRating: 2.5,
            facilityRating: 3.5, crowdsRating: 2.0, atmosphereRating: 4.0,
            body: "Great community but the courts get absolutely packed on weekends. No lighting so you can't play after dark. Courts 5 and 6 have some cracks that will trip you up. Still my go-to for casual games though.",
            typicalPlayTimes: ["Weekday evenings 5–8pm"],
            tags: [.friendly, .crowded, .waitTimes, .poorLighting],
            isVerifiedPlayer: true, helpfulCount: 18,
            createdAt: Calendar.current.date(byAdding: .day, value: -28, to: Date()) ?? Date(),
            isFeatured: false
        ),

        CourtReview(
            id: "rev_005", courtId: "court_001",
            authorId: "user_005", authorName: "Marcus Webb", authorUsername: "mwebb_pb",
            overallRating: 5.0, surfaceRating: 5.0, lightingRating: 5.0,
            facilityRating: 4.5, crowdsRating: 4.0, atmosphereRating: 5.0,
            body: "Twelve courts means you almost never wait, even on weekend mornings. The surface is freshly resurfaced and the lines are crisp. Lighting is excellent for evening play — no dead zones at all. Highly recommend.",
            typicalPlayTimes: ["Weekday evenings 5–8pm", "Weekend mornings 7–10am"],
            tags: [.greatSurface, .wellLit, .friendly],
            isVerifiedPlayer: true, helpfulCount: 21,
            createdAt: Calendar.current.date(byAdding: .day, value: -55, to: Date()) ?? Date(),
            isFeatured: false
        ),

        // MARK: court_002 — Mueller Recreation Center

        CourtReview(
            id: "rev_003", courtId: "court_002",
            authorId: "user_004", authorName: "Sarah Johnson", authorUsername: "sarahj_pb",
            overallRating: 5.0, surfaceRating: 5.0, lightingRating: 5.0,
            facilityRating: 5.0, crowdsRating: 4.0, atmosphereRating: 5.0,
            body: "Mueller is the real deal. Courts with Laykold surface, full lighting for night play, clean facilities and easy parking. A little pricier than some outdoor spots but absolutely worth it for the guaranteed court time.",
            typicalPlayTimes: ["Open 6am–11pm daily", "Open play 10am–2pm weekdays"],
            tags: [.greatSurface, .wellLit, .cleanFacilities, .easyToBook],
            isVerifiedPlayer: true, helpfulCount: 52,
            createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            isFeatured: true
        ),

        CourtReview(
            id: "rev_004", courtId: "court_002",
            authorId: "user_007", authorName: "Jamie Lee", authorUsername: "jamiepb",
            overallRating: 4.0, surfaceRating: 5.0, lightingRating: 5.0,
            facilityRating: 4.5, crowdsRating: 3.0, atmosphereRating: 3.5,
            body: "Courts are immaculate. Can feel a bit cliquey if you're new. Parking can be rough on evenings. Overall a top-tier facility.",
            typicalPlayTimes: ["Competitive open play 6–9pm weekdays", "Weekend mornings 8–11am"],
            tags: [.greatSurface, .wellLit, .competitive, .goodParking],
            isVerifiedPlayer: true, helpfulCount: 27,
            createdAt: Calendar.current.date(byAdding: .day, value: -45, to: Date()) ?? Date(),
            isFeatured: false
        ),

        CourtReview(
            id: "rev_006", courtId: "court_002",
            authorId: "user_008", authorName: "Gina Park", authorUsername: "gina_smash",
            overallRating: 3.5, surfaceRating: 4.0, lightingRating: 4.5,
            facilityRating: 3.0, crowdsRating: 2.5, atmosphereRating: 3.0,
            body: "The courts are fine — nothing wrong with the surface or equipment. The problem is the parking situation and it gets busy fast. Great October through April, but plan accordingly in peak summer.",
            typicalPlayTimes: ["Weekday mornings 6–9am"],
            tags: [.crowded, .goodParking, .roughSurface],
            isVerifiedPlayer: false, helpfulCount: 12,
            createdAt: Calendar.current.date(byAdding: .day, value: -70, to: Date()) ?? Date(),
            isFeatured: false
        ),

        // MARK: court_003 — South Lamar Sports Club

        CourtReview(
            id: "rev_007", courtId: "court_003",
            authorId: "user_009", authorName: "Derek Sousa", authorUsername: "derek_dink",
            overallRating: 4.8, surfaceRating: 5.0, lightingRating: 5.0,
            facilityRating: 5.0, crowdsRating: 4.5, atmosphereRating: 4.5,
            body: "Worth every penny of the membership. Indoor courts with climate control, pristine locker rooms, a real pro shop, and coaches who actually know pickleball. The regular players are competitive but welcoming.",
            typicalPlayTimes: ["Members only 24/7", "Open play 8am–12pm weekdays"],
            tags: [.greatSurface, .wellLit, .cleanFacilities, .competitive, .beginnerFriendly],
            isVerifiedPlayer: true, helpfulCount: 41,
            createdAt: Calendar.current.date(byAdding: .day, value: -8, to: Date()) ?? Date(),
            isFeatured: true
        ),
    ]
}

import Foundation

struct CourtReview: Identifiable, Codable, Hashable {
    var id: String
    var courtId: String
    var authorId: String
    var authorName: String
    var rating: Int          // 1–5
    var title: String
    var body: String
    var tags: [String]       // "Well lit", "Good nets", "Shade available", "Crowded", "Great surface"
    var createdAt: Date
    var helpfulCount: Int
}

// MARK: - Mock Data

extension CourtReview {

    static let allTags: [String] = [
        "Well lit", "Good nets", "Shade available", "Crowded", "Great surface"
    ]

    static let mockReviews: [CourtReview] = [

        // MARK: court_001 — Westside Pickleball Complex (5 reviews)

        CourtReview(
            id: "cr_001",
            courtId: "court_001",
            authorId: "user_101",
            authorName: "Marcus Webb",
            rating: 5,
            title: "Best outdoor courts in Austin",
            body: "Twelve courts means you almost never wait, even on weekend mornings. The surface is freshly resurfaced and the lines are crisp. Lighting is excellent for evening play — no dead zones at all. Highly recommend.",
            tags: ["Well lit", "Great surface", "Good nets"],
            createdAt: date(year: 2025, month: 11, day: 3),
            helpfulCount: 18
        ),

        CourtReview(
            id: "cr_002",
            courtId: "court_001",
            authorId: "user_102",
            authorName: "Priya Nair",
            rating: 4,
            title: "Great facility, can get crowded on weekends",
            body: "The courts themselves are in fantastic shape and the nets are always properly tensioned. My only complaint is that Saturday afternoons attract huge crowds and wait times can stretch 45 minutes. Come early or on a weekday and it's perfect.",
            tags: ["Crowded", "Good nets", "Great surface"],
            createdAt: date(year: 2025, month: 10, day: 19),
            helpfulCount: 11
        ),

        CourtReview(
            id: "cr_003",
            courtId: "court_001",
            authorId: "user_103",
            authorName: "Derek Sousa",
            rating: 5,
            title: "Pro shop and lessons make this a full package",
            body: "Beyond the courts, the on-site pro shop is well-stocked and the instructors offer group clinics on Tuesday and Thursday evenings. Great community vibe here. The water fountains are cold and plentiful too.",
            tags: ["Well lit", "Great surface"],
            createdAt: date(year: 2025, month: 9, day: 28),
            helpfulCount: 7
        ),

        CourtReview(
            id: "cr_004",
            courtId: "court_001",
            authorId: "user_104",
            authorName: "Tamara Flynn",
            rating: 3,
            title: "Good courts, parking situation is rough",
            body: "Surface quality is solid and the lighting works well for night games. The courts themselves earn a five, but parking is genuinely terrible during peak hours. I've circled the lot for 20 minutes more than once. Fix the parking and this becomes a 5-star spot.",
            tags: ["Well lit", "Great surface", "Crowded"],
            createdAt: date(year: 2025, month: 8, day: 14),
            helpfulCount: 22
        ),

        CourtReview(
            id: "cr_005",
            courtId: "court_001",
            authorId: "user_105",
            authorName: "Leon Okafor",
            rating: 4,
            title: "Reliable, well-maintained, solid community",
            body: "I play here three mornings a week. The staff sweeps the courts regularly and I've never had a net issue. The regular crowd is welcoming to newcomers and skill levels mix well during open play. Great place to level up.",
            tags: ["Good nets", "Great surface", "Shade available"],
            createdAt: date(year: 2025, month: 7, day: 30),
            helpfulCount: 14
        ),

        // MARK: court_002 — Mueller Recreation Center (3 reviews)

        CourtReview(
            id: "cr_006",
            courtId: "court_002",
            authorId: "user_201",
            authorName: "Sofia Reyes",
            rating: 4,
            title: "Perfect for morning open play",
            body: "Mueller is my go-to for early morning sessions. Six courts, usually available, and the surrounding park keeps the air cool in the mornings. The surface is standard hard court — nothing fancy but well maintained. Wish there were more shade structures.",
            tags: ["Good nets", "Great surface"],
            createdAt: date(year: 2025, month: 11, day: 10),
            helpfulCount: 9
        ),

        CourtReview(
            id: "cr_007",
            courtId: "court_002",
            authorId: "user_202",
            authorName: "Brendan Chu",
            rating: 5,
            title: "Underrated gem in the Mueller neighborhood",
            body: "People sleep on Mueller. Six courts, daily open play from 6am, and the city keeps them in genuinely good shape. The nets were recently replaced and the tension is exactly right. Bring your own sunscreen — shade is limited — but otherwise this place is fantastic.",
            tags: ["Good nets", "Well lit"],
            createdAt: date(year: 2025, month: 10, day: 5),
            helpfulCount: 16
        ),

        CourtReview(
            id: "cr_008",
            courtId: "court_002",
            authorId: "user_203",
            authorName: "Gina Park",
            rating: 3,
            title: "Courts are decent but heat is brutal in summer",
            body: "The courts are fine — nothing wrong with the surface or equipment. The problem is there is almost zero shade and afternoon summer sessions in Austin are nearly unplayable. Great October through April, but plan accordingly if you're coming in peak summer.",
            tags: ["Crowded", "Great surface"],
            createdAt: date(year: 2025, month: 8, day: 22),
            helpfulCount: 19
        ),
    ]

    // MARK: - Private date helper

    private static func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }
}

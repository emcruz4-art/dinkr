import Foundation

struct Post: Identifiable, Codable, Hashable {
    var id: String
    var authorId: String
    var authorName: String
    var authorAvatarURL: String?
    var content: String
    var mediaURLs: [String]
    var postType: PostType
    var likes: Int
    var commentCount: Int
    var createdAt: Date
    var likedBy: [String] = []
    var isLiked: Bool = false   // client-side only — derived from likedBy, excluded from Firestore encoding
    var tags: [String]
    var groupId: String?

    // isLiked is client-side only — exclude from Firestore encoding
    private enum CodingKeys: String, CodingKey {
        case id, authorId, authorName, authorAvatarURL, content, mediaURLs,
             postType, likes, commentCount, createdAt, likedBy, tags, groupId
    }
}

extension Post {
    static let mockPosts: [Post] = [
        Post(id: "p1", authorId: "user_001", authorName: "Alex Rivera",
             authorAvatarURL: nil, content: "Just had the most epic game at Westside Courts! 4 games to 11, went to a tiebreak. Nothing beats a Sunday morning dink battle 🏓",
             mediaURLs: [], postType: .highlight, likes: 47, commentCount: 12,
             createdAt: Date().addingTimeInterval(-3600), isLiked: false, tags: ["austintx", "pickleball"], groupId: nil),
        Post(id: "p2", authorId: "user_002", authorName: "Maria Chen",
             authorAvatarURL: nil, content: "Looking for a 4th for doubles this Saturday around 9am near Mueller Park. 3.5+ skill level preferred. DM me! 🎉",
             mediaURLs: [], postType: .lookingForGame, likes: 23, commentCount: 8,
             createdAt: Date().addingTimeInterval(-7200), isLiked: true, tags: ["lfg", "austin"], groupId: "grp_001"),
        Post(id: "p3", authorId: "user_003", authorName: "Jordan Smith",
             authorAvatarURL: nil, content: "Quick tip: If your opponent is poaching, stop telegraphing your cross-court shots. Keep them guessing with a down-the-line drive first. Works every time 💡",
             mediaURLs: [], postType: .question, likes: 89, commentCount: 34,
             createdAt: Date().addingTimeInterval(-14400), isLiked: false, tags: ["tips", "strategy"], groupId: nil),
        Post(id: "p4", authorId: "user_004", authorName: "Sarah Johnson",
             authorAvatarURL: nil, content: "Our women's league just hit 100 members! So proud of this community we've built together. Looking forward to our first invitational next month 💪",
             mediaURLs: [], postType: .winCelebration, likes: 156, commentCount: 41,
             createdAt: Date().addingTimeInterval(-86400), isLiked: true, tags: ["womenspickleball", "milestone"], groupId: "grp_001"),
        Post(id: "p5", authorId: "user_005", authorName: "Chris Park",
             authorAvatarURL: nil, content: "Anyone else notice Westside Courts added two new dedicated pickleball courts? Played there today — fantastic surface, perfect lighting. Highly recommend 🌟",
             mediaURLs: [], postType: .courtReview, likes: 64, commentCount: 19,
             createdAt: Date().addingTimeInterval(-108000), isLiked: false, tags: ["courtsreview", "westside"], groupId: nil),
        Post(id: "p6", authorId: "user_007", authorName: "Jamie Lee",
             authorAvatarURL: nil, content: "Former tennis pro take: the transition to pickleball is HUMBLING. Spent 20 years playing tennis at a high level and still getting schooled at the kitchen line 😂",
             mediaURLs: [], postType: .general, likes: 234, commentCount: 67,
             createdAt: Date().addingTimeInterval(-172800), isLiked: true, tags: ["tennistopicleball", "humbled"], groupId: nil),
        Post(id: "p7", authorId: "user_008", authorName: "Morgan Davis",
             authorAvatarURL: nil, content: "3 months ago I didn't know what a dink was. Today I won my first 3.0 round robin 🎊 Progress feels incredible. Don't give up beginners!",
             mediaURLs: [], postType: .winCelebration, likes: 312, commentCount: 88,
             createdAt: Date().addingTimeInterval(-259200), isLiked: false, tags: ["beginners", "milestone"], groupId: "grp_001"),
        Post(id: "p8", authorId: "user_009", authorName: "Riley Torres",
             authorAvatarURL: nil, content: "Is anyone else using the stack formation in 4.0+ doubles? Changed my game completely. Partner coordination is key though — need to be on the same page.",
             mediaURLs: [], postType: .question, likes: 45, commentCount: 22,
             createdAt: Date().addingTimeInterval(-345600), isLiked: false, tags: ["strategy", "doubles"], groupId: nil),
        Post(id: "p9", authorId: "user_002", authorName: "Maria Chen",
             authorAvatarURL: nil, content: "Austin Open Women's Singles 3.5 — WINNER 🏆 Two years of work paid off today. Huge thanks to my doubles partner and coach. See you all at the 2025 edition!",
             mediaURLs: [], postType: .winCelebration, likes: 487, commentCount: 134,
             createdAt: Date().addingTimeInterval(-432000), isLiked: true, tags: ["austinopen", "champion"], groupId: "grp_001"),
        Post(id: "p10", authorId: "user_006", authorName: "Taylor Kim",
             authorAvatarURL: nil, content: "Bought my first real paddle — a Selkirk SLK Halo. Huge upgrade from the wooden paddle I started with. Night and day difference 🎾",
             mediaURLs: [], postType: .general, likes: 28, commentCount: 11,
             createdAt: Date().addingTimeInterval(-518400), isLiked: false, tags: ["gear", "firstpaddle"], groupId: nil),
        Post(id: "p11", authorId: "user_003", authorName: "Jordan Smith",
             authorAvatarURL: nil, content: "Drilled for 90 minutes this morning before anyone else showed up. There's something magical about an empty court at 6am. Peace. Focus. Sweat. Love this sport.",
             mediaURLs: [], postType: .highlight, likes: 102, commentCount: 31,
             createdAt: Date().addingTimeInterval(-604800), isLiked: true, tags: ["earlybird", "drills"], groupId: "grp_001"),
        Post(id: "p12", authorId: "user_004", authorName: "Sarah Johnson",
             authorAvatarURL: nil, content: "PSA: Mueller Park is hosting free open play every Sunday 8am–12pm starting next week. Bring your paddle, bring a friend, all levels welcome! Spread the word 📢",
             mediaURLs: [], postType: .general, likes: 201, commentCount: 56,
             createdAt: Date().addingTimeInterval(-691200), isLiked: false, tags: ["freeplay", "mueller", "austin"], groupId: nil),
    ]
}

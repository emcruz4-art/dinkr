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
    var taggedUserIds: [String] = []
    var groupId: String?

    // isLiked is client-side only — exclude from Firestore encoding
    private enum CodingKeys: String, CodingKey {
        case id, authorId, authorName, authorAvatarURL, content, mediaURLs,
             postType, likes, commentCount, createdAt, likedBy, tags, taggedUserIds, groupId
    }
}

extension Post {
    /// Computed mock reactions seeded from the post's like count.
    /// Distributes across 6 reaction types so higher-engagement posts feel richer.
    var mockReactions: [PostReaction] {
        guard likes > 0 else { return [] }
        // Seed distribution percentages per reaction type (must sum <= 1.0)
        let distribution: [(emoji: String, fraction: Double)] = [
            ("❤️", 0.35),
            ("🔥", 0.25),
            ("🏆", 0.15),
            ("🎯", 0.12),
            ("👏", 0.08),
            ("🥒", 0.05),
        ]
        return distribution.compactMap { item in
            let count = max(0, Int((Double(likes) * item.fraction).rounded()))
            guard count > 0 else { return nil }
            return PostReaction(emoji: item.emoji, count: count, userHasReacted: false)
        }
    }

    static let mockPosts: [Post] = [
        Post(id: "p1", authorId: "user_001", authorName: "Alex Rivera",
             authorAvatarURL: nil, content: "Just had the most epic game at Westside Courts! 4 games to 11, went to a tiebreak. Nothing beats a Sunday morning dink battle 🏓",
             mediaURLs: [], postType: .highlight, likes: 47, commentCount: 12,
             createdAt: Date().addingTimeInterval(-3600), isLiked: false, tags: ["austintx", "pickleball"],
             taggedUserIds: ["user_002", "user_003"], groupId: "grp_001"),
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
             createdAt: Date().addingTimeInterval(-432000), isLiked: true, tags: ["austinopen", "champion"],
             taggedUserIds: ["user_004", "user_007"], groupId: "grp_001"),
        Post(id: "p10", authorId: "user_006", authorName: "Taylor Kim",
             authorAvatarURL: nil, content: "Bought my first real paddle — a Selkirk SLK Halo. Huge upgrade from the wooden paddle I started with. Night and day difference 🎾",
             mediaURLs: [], postType: .general, likes: 28, commentCount: 11,
             createdAt: Date().addingTimeInterval(-518400), isLiked: false, tags: ["gear", "firstpaddle"], groupId: nil),
        Post(id: "p11", authorId: "user_003", authorName: "Jordan Smith",
             authorAvatarURL: nil, content: "Drilled for 90 minutes this morning before anyone else showed up. There's something magical about an empty court at 6am. Peace. Focus. Sweat. Love this sport.",
             mediaURLs: [], postType: .highlight, likes: 102, commentCount: 31,
             createdAt: Date().addingTimeInterval(-604800), isLiked: true, tags: ["earlybird", "drills"],
             taggedUserIds: ["user_005"], groupId: "grp_001"),
        Post(id: "p12", authorId: "user_004", authorName: "Sarah Johnson",
             authorAvatarURL: nil, content: "PSA: Mueller Park is hosting free open play every Sunday 8am–12pm starting next week. Bring your paddle, bring a friend, all levels welcome! Spread the word 📢",
             mediaURLs: [], postType: .general, likes: 201, commentCount: 56,
             createdAt: Date().addingTimeInterval(-691200), isLiked: false, tags: ["freeplay", "mueller", "austin"], groupId: nil),
        Post(id: "p13", authorId: "user_011", authorName: "Priya Patel",
             authorAvatarURL: nil, content: "Finally nailed the erne today after weeks of drilling it. The look on my opponent's face was worth every rep. Drill it until it's automatic, people 🎯",
             mediaURLs: [], postType: .highlight, likes: 178, commentCount: 43,
             createdAt: Date().addingTimeInterval(-777600), isLiked: true, tags: ["erne", "drills", "advanced"],
             taggedUserIds: ["user_012"], groupId: "grp_001"),
        Post(id: "p14", authorId: "user_012", authorName: "Marcus Williams",
             authorAvatarURL: nil, content: "Coaching tip: Stop trying to win the point from the baseline. Get to the kitchen line ASAP. Every extra step closer to the net is a percentage point in your favor. #KitchenOrDie",
             mediaURLs: [], postType: .question, likes: 312, commentCount: 91,
             createdAt: Date().addingTimeInterval(-864000), isLiked: false, tags: ["coaching", "strategy", "kitchen"], groupId: nil),
        Post(id: "p15", authorId: "user_013", authorName: "Sophie Chen",
             authorAvatarURL: nil, content: "Looking for 3.0-ish players for a casual mixed doubles session this Thursday evening at South Lamar. Totally low-key — just good vibes and good dinks. Drop a comment if you're in!",
             mediaURLs: [], postType: .lookingForGame, likes: 34, commentCount: 17,
             createdAt: Date().addingTimeInterval(-950400), isLiked: false, tags: ["lfg", "mixeddoubles", "casual"],
             taggedUserIds: [], groupId: "grp_001"),
        Post(id: "p16", authorId: "user_014", authorName: "Derek Martinez",
             authorAvatarURL: nil, content: "Just got back from the PPA Cincinnati Open. 4th place in men's singles. Learned so much playing against the top pros. The level at 5.0+ is just a different game entirely. Blessed to be competing at this level 🏆",
             mediaURLs: [], postType: .winCelebration, likes: 1204, commentCount: 287,
             createdAt: Date().addingTimeInterval(-1036800), isLiked: true, tags: ["ppa", "pro", "cincinnati"],
             taggedUserIds: [], groupId: nil),
        Post(id: "p17", authorId: "user_015", authorName: "Aisha Johnson",
             authorAvatarURL: nil, content: "Honest review of Westside Courts after visiting yesterday: Pros — great surface, good lighting, clean restrooms, plenty of courts. Cons — parking is rough on weekends and the wind tunnel between courts 3 and 4 is brutal. Overall 8/10, would recommend.",
             mediaURLs: [], postType: .courtReview, likes: 67, commentCount: 28,
             createdAt: Date().addingTimeInterval(-1123200), isLiked: false, tags: ["courtsreview", "westside", "austin"], groupId: nil),
        Post(id: "p18", authorId: "user_016", authorName: "Kevin Park",
             authorAvatarURL: nil, content: "Hot take: topspin on the third shot drop is underrated. Everyone drills a flat drop but adding a little topspin lets you attack the transition zone more aggressively afterward. Fight me in the comments 😂",
             mediaURLs: [], postType: .question, likes: 143, commentCount: 61,
             createdAt: Date().addingTimeInterval(-1209600), isLiked: false, tags: ["strategy", "thirdshotdrop", "topspin"],
             taggedUserIds: ["user_012"], groupId: "grp_001"),
        Post(id: "p19", authorId: "user_010", authorName: "Tyler Brooks",
             authorAvatarURL: nil, content: "First time playing in an actual rec league tonight instead of just open play. Terrifying. Wonderful. We lost every game but I got my first ace serve and literally screamed 😂 Best night. 10/10 would recommend getting out of your comfort zone.",
             mediaURLs: [], postType: .general, likes: 89, commentCount: 36,
             createdAt: Date().addingTimeInterval(-1296000), isLiked: true, tags: ["beginners", "recleague", "firsttime"], groupId: nil),
        Post(id: "p20", authorId: "user_017", authorName: "Olivia Turner",
             authorAvatarURL: nil, content: "Question for experienced players: how do you stop popping the ball up when you're rushed at the kitchen? I keep giving my opponents easy put-aways. Any drills or cues that helped you?",
             mediaURLs: [], postType: .question, likes: 56, commentCount: 42,
             createdAt: Date().addingTimeInterval(-1382400), isLiked: false, tags: ["beginners", "tips", "kitchen"],
             taggedUserIds: ["user_012", "user_011"], groupId: "grp_001"),

        // grp_002 — 4.0+ Competitive Pool
        Post(id: "p21", authorId: "user_002", authorName: "Maria Chen",
             authorAvatarURL: nil, content: "Sunday round robin results are in — great competitive matches today. Special shoutout to the new members who came in and immediately raised the level. 4.0+ is not a joke 💪",
             mediaURLs: [], postType: .winCelebration, likes: 72, commentCount: 19,
             createdAt: Date().addingTimeInterval(-5400), isLiked: false, tags: ["competitive", "roundrobin"],
             taggedUserIds: [], groupId: "grp_002"),
        Post(id: "p22", authorId: "user_009", authorName: "Riley Torres",
             authorAvatarURL: nil, content: "Reminder: drills start 30 min before open play on Sundays. If you haven't been joining drills you're leaving points on the table. The serve-and-third combo we worked on last week? Total game changer.",
             mediaURLs: [], postType: .general, likes: 44, commentCount: 11,
             createdAt: Date().addingTimeInterval(-90000), isLiked: true, tags: ["drills", "competitive"], groupId: "grp_002"),
        Post(id: "p23", authorId: "user_014", authorName: "Derek Martinez",
             authorAvatarURL: nil, content: "Heads up to the 4.0+ Pool — we're entering a team in the Austin Summer Classic in July. 6 spots, tryout format. More details coming in the Events tab. Start your prep 🏆",
             mediaURLs: [], postType: .general, likes: 118, commentCount: 33,
             createdAt: Date().addingTimeInterval(-172800), isLiked: false, tags: ["tournament", "austinsummerclassic"], groupId: "grp_002"),

        // grp_003 — Mueller Morning Crew
        Post(id: "p24", authorId: "user_005", authorName: "Chris Park",
             authorAvatarURL: nil, content: "Courts were empty at 6:30 today so we basically had the place to ourselves for an hour. Early bird privilege is real. See you all Wednesday! ☀️",
             mediaURLs: [], postType: .general, likes: 29, commentCount: 8,
             createdAt: Date().addingTimeInterval(-10800), isLiked: true, tags: ["mueller", "earlybird"], groupId: "grp_003"),
        Post(id: "p25", authorId: "user_010", authorName: "Tyler Brooks",
             authorAvatarURL: nil, content: "New to the Mueller Morning Crew — just moved to the Mueller neighborhood. First session was so welcoming. Looking forward to improving alongside you all 🙌",
             mediaURLs: [], postType: .general, likes: 53, commentCount: 15,
             createdAt: Date().addingTimeInterval(-216000), isLiked: false, tags: ["newmember", "mueller"], groupId: "grp_003"),
    ]
}

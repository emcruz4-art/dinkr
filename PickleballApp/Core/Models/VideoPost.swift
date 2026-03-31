import Foundation

enum VideoPostCategory: String, Codable, CaseIterable, Identifiable {
    case all       = "All"
    case drills    = "Drills"
    case highlights = "Highlights"
    var id: String { rawValue }
}

struct VideoPost: Identifiable, Codable {
    var id: String
    var title: String
    var description: String
    var creatorId: String
    var creatorName: String
    var creatorUsername: String
    var videoURL: String
    var thumbnailURL: String?
    var likes: Int
    var commentCount: Int
    var shareCount: Int
    var category: VideoPostCategory
    var hashtags: [String]
    var durationSeconds: Int
    var createdAt: Date
    var isLiked: Bool = false
    var isFeatured: Bool

    // not stored in Firestore
    enum CodingKeys: String, CodingKey {
        case id, title, description, creatorId, creatorName, creatorUsername
        case videoURL, thumbnailURL, likes, commentCount, shareCount
        case category, hashtags, durationSeconds, createdAt, isFeatured
    }
}

extension VideoPost {
    // Use Apple's reliable HLS test streams for demo
    private static let testStream1 = "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"
    private static let testStream2 = "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"

    static let mockVideos: [VideoPost] = [
        VideoPost(id: "v1", title: "Week 12 Drill Challenge 🏓",
                  description: "Third-shot drop to reset — practice this 100x and your game will transform",
                  creatorId: "user_002", creatorName: "Maria Chen", creatorUsername: "maria_plays",
                  videoURL: testStream1, thumbnailURL: nil,
                  likes: 1432, commentCount: 87, shareCount: 203,
                  category: .drills, hashtags: ["drillchallenge", "thirdshot", "dinkr"],
                  durationSeconds: 28, createdAt: Date().addingTimeInterval(-3600),
                  isLiked: false, isFeatured: true),
        VideoPost(id: "v2", title: "Best Point of the Week 🔥",
                  description: "This cross-court ATP at match point — couldn't believe it went in",
                  creatorId: "user_007", creatorName: "Jamie Lee", creatorUsername: "jamiepb",
                  videoURL: testStream2, thumbnailURL: nil,
                  likes: 2871, commentCount: 134, shareCount: 445,
                  category: .highlights, hashtags: ["ATP", "matchpoint", "pickleball", "highlight"],
                  durationSeconds: 15, createdAt: Date().addingTimeInterval(-7200),
                  isLiked: true, isFeatured: true),
        VideoPost(id: "v3", title: "Kitchen Battle Drill 💪",
                  description: "Dink-dink-dink until one of you cracks. This is how you win at the net",
                  creatorId: "user_005", creatorName: "Chris Park", creatorUsername: "chrisp_dink",
                  videoURL: testStream1, thumbnailURL: nil,
                  likes: 987, commentCount: 56, shareCount: 112,
                  category: .drills, hashtags: ["kitchen", "NVZ", "drills", "4point0"],
                  durationSeconds: 32, createdAt: Date().addingTimeInterval(-14400),
                  isLiked: false, isFeatured: false),
        VideoPost(id: "v4", title: "Erne Winner at Open Play 😱",
                  description: "Ran the line perfectly — give it a watch in slo-mo",
                  creatorId: "user_009", creatorName: "Riley Torres", creatorUsername: "riley_dinkmaster",
                  videoURL: testStream2, thumbnailURL: nil,
                  likes: 3204, commentCount: 198, shareCount: 678,
                  category: .highlights, hashtags: ["erne", "openplay", "winner"],
                  durationSeconds: 10, createdAt: Date().addingTimeInterval(-21600),
                  isLiked: false, isFeatured: true),
        VideoPost(id: "v5", title: "Serve + Return Drill 🎯",
                  description: "Deep serve, aggressive return — do this every warmup",
                  creatorId: "user_004", creatorName: "Sarah Johnson", creatorUsername: "sarahj_pb",
                  videoURL: testStream1, thumbnailURL: nil,
                  likes: 645, commentCount: 31, shareCount: 89,
                  category: .drills, hashtags: ["serve", "return", "warmup", "drilling"],
                  durationSeconds: 45, createdAt: Date().addingTimeInterval(-28800),
                  isLiked: false, isFeatured: false),
        VideoPost(id: "v6", title: "Lob Recovery Point 🌟",
                  description: "Down 9-10, lobbed over both players and somehow converted",
                  creatorId: "user_003", creatorName: "Jordan Smith", creatorUsername: "jordan_4point0",
                  videoURL: testStream2, thumbnailURL: nil,
                  likes: 1876, commentCount: 92, shareCount: 334,
                  category: .highlights, hashtags: ["lob", "comeback", "4point0"],
                  durationSeconds: 18, createdAt: Date().addingTimeInterval(-36000),
                  isLiked: false, isFeatured: false),
    ]
}

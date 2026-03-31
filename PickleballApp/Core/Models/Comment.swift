import Foundation

struct Comment: Identifiable, Codable {
    var id: String
    var postId: String
    var userId: String
    var userName: String
    var body: String
    var date: Date
    var likeCount: Int
    var replies: [Comment]
}

extension Comment {
    static func mockComments(for postId: String) -> [Comment] {
        [
            Comment(
                id: "cmt_\(postId)_1",
                postId: postId,
                userId: "user_002",
                userName: "Maria Chen",
                body: "That backhand drive at the end was absolutely wild 🔥 How long have you been playing?",
                date: Date().addingTimeInterval(-900),
                likeCount: 14,
                replies: [
                    Comment(
                        id: "cmt_\(postId)_1_r1",
                        postId: postId,
                        userId: "user_001",
                        userName: "Alex Rivera",
                        body: "About two years now! Still so much to learn 😄",
                        date: Date().addingTimeInterval(-600),
                        likeCount: 3,
                        replies: []
                    )
                ]
            ),
            Comment(
                id: "cmt_\(postId)_2",
                postId: postId,
                userId: "user_003",
                userName: "Jordan Smith",
                body: "Which paddle is that? Looks like a Selkirk but I can't tell from the video.",
                date: Date().addingTimeInterval(-1800),
                likeCount: 7,
                replies: []
            ),
            Comment(
                id: "cmt_\(postId)_3",
                postId: postId,
                userId: "user_004",
                userName: "Sarah Johnson",
                body: "We should run some drills together sometime — I'm at Mueller every Saturday morning 🏓",
                date: Date().addingTimeInterval(-3600),
                likeCount: 11,
                replies: [
                    Comment(
                        id: "cmt_\(postId)_3_r1",
                        postId: postId,
                        userId: "user_002",
                        userName: "Maria Chen",
                        body: "Count me in! Saturday mornings are perfect.",
                        date: Date().addingTimeInterval(-3000),
                        likeCount: 2,
                        replies: []
                    )
                ]
            ),
            Comment(
                id: "cmt_\(postId)_4",
                postId: postId,
                userId: "user_005",
                userName: "Chris Park",
                body: "That kitchen patience is elite level. No wonder you're climbing the ladder 💪",
                date: Date().addingTimeInterval(-7200),
                likeCount: 22,
                replies: []
            ),
            Comment(
                id: "cmt_\(postId)_5",
                postId: postId,
                userId: "user_006",
                userName: "Taylor Kim",
                body: "As a beginner this is so inspiring — this is what I'm working toward!",
                date: Date().addingTimeInterval(-14400),
                likeCount: 5,
                replies: []
            ),
        ]
    }
}

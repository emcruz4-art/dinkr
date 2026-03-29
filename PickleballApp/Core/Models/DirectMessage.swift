import Foundation

struct DMConversation: Identifiable, Hashable {
    var id: String
    var otherUserId: String
    var otherUserName: String
    var otherUserInitial: String
    var lastMessage: String
    var lastMessageTime: Date
    var unreadCount: Int
    var isOnline: Bool
}

struct DMMessage: Identifiable {
    var id: String
    var conversationId: String
    var senderId: String  // "me" or other user id
    var text: String
    var timestamp: Date
    var isRead: Bool
    var reaction: String?  // optional emoji reaction
}

// MARK: - Mock Data

extension DMConversation {
    static let mockConversations: [DMConversation] = [
        DMConversation(
            id: "conv_001",
            otherUserId: "user_002",
            otherUserName: "Maria Chen",
            otherUserInitial: "M",
            lastMessage: "Great game yesterday! That third set was intense 🔥",
            lastMessageTime: Calendar.current.date(byAdding: .minute, value: -2, to: Date()) ?? Date(),
            unreadCount: 3,
            isOnline: true
        ),
        DMConversation(
            id: "conv_002",
            otherUserId: "user_003",
            otherUserName: "Jordan Smith",
            otherUserInitial: "J",
            lastMessage: "Are you joining the Austin Open next weekend?",
            lastMessageTime: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date(),
            unreadCount: 1,
            isOnline: true
        ),
        DMConversation(
            id: "conv_003",
            otherUserId: "user_007",
            otherUserName: "Jamie Lee",
            otherUserInitial: "J",
            lastMessage: "I'll bring my extra paddle just in case",
            lastMessageTime: Calendar.current.date(byAdding: .hour, value: -3, to: Date()) ?? Date(),
            unreadCount: 0,
            isOnline: false
        ),
        DMConversation(
            id: "conv_004",
            otherUserId: "user_004",
            otherUserName: "Sarah Johnson",
            otherUserInitial: "S",
            lastMessage: "Women's league signup is open through Friday!",
            lastMessageTime: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            unreadCount: 0,
            isOnline: false
        ),
        DMConversation(
            id: "conv_005",
            otherUserId: "user_005",
            otherUserName: "Chris Park",
            otherUserInitial: "C",
            lastMessage: "Want to play Saturday morning? Mueller courts at 8am",
            lastMessageTime: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            unreadCount: 2,
            isOnline: true
        ),
        DMConversation(
            id: "conv_006",
            otherUserId: "user_009",
            otherUserName: "Riley Torres",
            otherUserInitial: "R",
            lastMessage: "Count me in for the round robin!",
            lastMessageTime: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            unreadCount: 0,
            isOnline: false
        ),
    ]
}

extension DMMessage {
    static func mockMessages(for conversationId: String) -> [DMMessage] {
        let now = Date()
        func ago(_ minutes: Int) -> Date {
            Calendar.current.date(byAdding: .minute, value: -minutes, to: now) ?? now
        }

        switch conversationId {
        case "conv_001":
            return [
                DMMessage(id: "m001_1", conversationId: conversationId, senderId: "user_002",
                          text: "Hey! Are you free this weekend for a match?", timestamp: ago(62), isRead: true, reaction: nil),
                DMMessage(id: "m001_2", conversationId: conversationId, senderId: "me",
                          text: "Yeah, Saturday works! What time?", timestamp: ago(58), isRead: true, reaction: nil),
                DMMessage(id: "m001_3", conversationId: conversationId, senderId: "user_002",
                          text: "Let's do 9am at Zilker. I'll book court 3", timestamp: ago(55), isRead: true, reaction: "👏"),
                DMMessage(id: "m001_4", conversationId: conversationId, senderId: "me",
                          text: "Perfect. Should we do singles or find a doubles partner?", timestamp: ago(50), isRead: true, reaction: nil),
                DMMessage(id: "m001_5", conversationId: conversationId, senderId: "user_002",
                          text: "Jordan might be down. Let me ask", timestamp: ago(45), isRead: true, reaction: nil),
                DMMessage(id: "m001_6", conversationId: conversationId, senderId: "user_002",
                          text: "He's in! Doubles it is 🏓", timestamp: ago(40), isRead: true, reaction: "🔥"),
                DMMessage(id: "m001_7", conversationId: conversationId, senderId: "me",
                          text: "Awesome. Can't wait!", timestamp: ago(38), isRead: true, reaction: nil),
                DMMessage(id: "m001_8", conversationId: conversationId, senderId: "user_002",
                          text: "Btw are you entering the Austin Open? Registration closes Thursday",
                          timestamp: ago(10), isRead: false, reaction: nil),
                DMMessage(id: "m001_9", conversationId: conversationId, senderId: "user_002",
                          text: "Great game yesterday! That third set was intense 🔥",
                          timestamp: ago(2), isRead: false, reaction: nil),
            ]

        case "conv_002":
            return [
                DMMessage(id: "m002_1", conversationId: conversationId, senderId: "me",
                          text: "Jordan! Heard you've been crushing it at Mueller lately", timestamp: ago(120), isRead: true, reaction: nil),
                DMMessage(id: "m002_2", conversationId: conversationId, senderId: "user_003",
                          text: "Ha, trying to! My backhand is finally clicking", timestamp: ago(115), isRead: true, reaction: "🎯"),
                DMMessage(id: "m002_3", conversationId: conversationId, senderId: "me",
                          text: "We should run some drills together sometime", timestamp: ago(110), isRead: true, reaction: nil),
                DMMessage(id: "m002_4", conversationId: conversationId, senderId: "user_003",
                          text: "100%. I do mornings Monday/Wednesday if you're ever free", timestamp: ago(105), isRead: true, reaction: nil),
                DMMessage(id: "m002_5", conversationId: conversationId, senderId: "me",
                          text: "Wednesday morning could work. What time?", timestamp: ago(100), isRead: true, reaction: nil),
                DMMessage(id: "m002_6", conversationId: conversationId, senderId: "user_003",
                          text: "7am sharp. Coach Dave runs the drill session. It's free", timestamp: ago(90), isRead: true, reaction: nil),
                DMMessage(id: "m002_7", conversationId: conversationId, senderId: "me",
                          text: "I'm in. See you then!", timestamp: ago(85), isRead: true, reaction: "❤️"),
                DMMessage(id: "m002_8", conversationId: conversationId, senderId: "user_003",
                          text: "Also — are you joining the Austin Open next weekend?",
                          timestamp: ago(60), isRead: false, reaction: nil),
            ]

        case "conv_003":
            return [
                DMMessage(id: "m003_1", conversationId: conversationId, senderId: "user_007",
                          text: "Great match yesterday. Your dink game is seriously improving", timestamp: ago(200), isRead: true, reaction: nil),
                DMMessage(id: "m003_2", conversationId: conversationId, senderId: "me",
                          text: "Thanks Jamie! Still got a long way to go to reach your level", timestamp: ago(195), isRead: true, reaction: nil),
                DMMessage(id: "m003_3", conversationId: conversationId, senderId: "user_007",
                          text: "Don't sell yourself short. Your third shot drop has gotten much sharper", timestamp: ago(190), isRead: true, reaction: "🎯"),
                DMMessage(id: "m003_4", conversationId: conversationId, senderId: "me",
                          text: "Been working on it every morning. Paying off finally", timestamp: ago(180), isRead: true, reaction: nil),
                DMMessage(id: "m003_5", conversationId: conversationId, senderId: "user_007",
                          text: "Want to play Sunday? I'll bring my training paddle", timestamp: ago(175), isRead: true, reaction: nil),
                DMMessage(id: "m003_6", conversationId: conversationId, senderId: "me",
                          text: "Sunday works! Maybe 10am?", timestamp: ago(170), isRead: true, reaction: nil),
                DMMessage(id: "m003_7", conversationId: conversationId, senderId: "user_007",
                          text: "Perfect. I'll bring my extra paddle just in case", timestamp: ago(165), isRead: true, reaction: nil),
                DMMessage(id: "m003_8", conversationId: conversationId, senderId: "me",
                          text: "See you then! Looking forward to it 🏓", timestamp: ago(160), isRead: true, reaction: nil),
                DMMessage(id: "m003_9", conversationId: conversationId, senderId: "user_007",
                          text: "Same! I'll have the coffee ready ☕", timestamp: ago(155), isRead: true, reaction: "😂"),
            ]

        case "conv_004":
            return [
                DMMessage(id: "m004_1", conversationId: conversationId, senderId: "user_004",
                          text: "Hey! We're starting a new women's 3.5 round robin next month", timestamp: ago(1500), isRead: true, reaction: nil),
                DMMessage(id: "m004_2", conversationId: conversationId, senderId: "me",
                          text: "Oh nice! Is it open to new players?", timestamp: ago(1490), isRead: true, reaction: nil),
                DMMessage(id: "m004_3", conversationId: conversationId, senderId: "user_004",
                          text: "Absolutely. We'd love to have you. It's every Thursday 6pm", timestamp: ago(1480), isRead: true, reaction: nil),
                DMMessage(id: "m004_4", conversationId: conversationId, senderId: "me",
                          text: "Thursdays work great for me! What's the format?", timestamp: ago(1470), isRead: true, reaction: nil),
                DMMessage(id: "m004_5", conversationId: conversationId, senderId: "user_004",
                          text: "Rotating doubles, 8 players. $5 per session for court fees", timestamp: ago(1460), isRead: true, reaction: "👏"),
                DMMessage(id: "m004_6", conversationId: conversationId, senderId: "me",
                          text: "That sounds amazing. Count me in!", timestamp: ago(1450), isRead: true, reaction: nil),
                DMMessage(id: "m004_7", conversationId: conversationId, senderId: "user_004",
                          text: "Wonderful! I'll add you to the group chat", timestamp: ago(1440), isRead: true, reaction: nil),
                DMMessage(id: "m004_8", conversationId: conversationId, senderId: "user_004",
                          text: "Women's league signup is open through Friday!", timestamp: ago(1440), isRead: true, reaction: nil),
            ]

        case "conv_005":
            return [
                DMMessage(id: "m005_1", conversationId: conversationId, senderId: "user_005",
                          text: "Yo! You around this weekend?", timestamp: ago(1560), isRead: true, reaction: nil),
                DMMessage(id: "m005_2", conversationId: conversationId, senderId: "me",
                          text: "Yeah what's up?", timestamp: ago(1555), isRead: true, reaction: nil),
                DMMessage(id: "m005_3", conversationId: conversationId, senderId: "user_005",
                          text: "Trying to get a solid doubles crew together for Saturday", timestamp: ago(1550), isRead: true, reaction: nil),
                DMMessage(id: "m005_4", conversationId: conversationId, senderId: "me",
                          text: "I'm in! Who else is playing?", timestamp: ago(1545), isRead: true, reaction: nil),
                DMMessage(id: "m005_5", conversationId: conversationId, senderId: "user_005",
                          text: "Jamie and probably Maria. Maybe Jordan if he's not competing", timestamp: ago(1540), isRead: true, reaction: nil),
                DMMessage(id: "m005_6", conversationId: conversationId, senderId: "me",
                          text: "That's a great lineup. Should be a fun session", timestamp: ago(1535), isRead: true, reaction: "🔥"),
                DMMessage(id: "m005_7", conversationId: conversationId, senderId: "user_005",
                          text: "Right? My kitchen game has been on fire lately too", timestamp: ago(1530), isRead: true, reaction: nil),
                DMMessage(id: "m005_8", conversationId: conversationId, senderId: "user_005",
                          text: "Want to play Saturday morning? Mueller courts at 8am",
                          timestamp: ago(1440), isRead: false, reaction: nil),
                DMMessage(id: "m005_9", conversationId: conversationId, senderId: "user_005",
                          text: "I can reserve 2 courts if we get 8 people together",
                          timestamp: ago(1430), isRead: false, reaction: nil),
            ]

        case "conv_006":
            return [
                DMMessage(id: "m006_1", conversationId: conversationId, senderId: "me",
                          text: "Riley! Saw you entered the Dinkr round robin — nice!", timestamp: ago(2900), isRead: true, reaction: nil),
                DMMessage(id: "m006_2", conversationId: conversationId, senderId: "user_009",
                          text: "Yeah! Super stoked. Should be a blast", timestamp: ago(2890), isRead: true, reaction: nil),
                DMMessage(id: "m006_3", conversationId: conversationId, senderId: "me",
                          text: "I signed up too. Hope we end up in the same bracket", timestamp: ago(2880), isRead: true, reaction: nil),
                DMMessage(id: "m006_4", conversationId: conversationId, senderId: "user_009",
                          text: "That would be so fun! May the best dinkmaster win 😂", timestamp: ago(2870), isRead: true, reaction: "😂"),
                DMMessage(id: "m006_5", conversationId: conversationId, senderId: "me",
                          text: "Ha! No mercy on the court 🏓", timestamp: ago(2860), isRead: true, reaction: nil),
                DMMessage(id: "m006_6", conversationId: conversationId, senderId: "user_009",
                          text: "You been practicing the erne lately? I've been drilling it", timestamp: ago(2850), isRead: true, reaction: nil),
                DMMessage(id: "m006_7", conversationId: conversationId, senderId: "me",
                          text: "Not enough lol. I keep telegraphing it too early", timestamp: ago(2840), isRead: true, reaction: nil),
                DMMessage(id: "m006_8", conversationId: conversationId, senderId: "user_009",
                          text: "Pro tip: disguise it with a body fake first", timestamp: ago(2830), isRead: true, reaction: "🎯"),
                DMMessage(id: "m006_9", conversationId: conversationId, senderId: "user_009",
                          text: "Count me in for the round robin!", timestamp: ago(2820), isRead: true, reaction: nil),
                DMMessage(id: "m006_10", conversationId: conversationId, senderId: "me",
                          text: "Can't wait! See you there 🙌", timestamp: ago(2810), isRead: true, reaction: nil),
            ]

        default:
            return [
                DMMessage(id: "default_1", conversationId: conversationId, senderId: "me",
                          text: "Hey! Want to play this weekend?", timestamp: ago(60), isRead: true, reaction: nil),
                DMMessage(id: "default_2", conversationId: conversationId, senderId: conversationId,
                          text: "Sure! What time works for you?", timestamp: ago(55), isRead: true, reaction: nil),
            ]
        }
    }
}

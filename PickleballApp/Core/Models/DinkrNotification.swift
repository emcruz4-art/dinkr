import Foundation

enum DinkrNotificationType: String, Codable {
    case gameInvite     // someone invited you to a game
    case kudos          // someone liked/kudos'd your game summary
    case newFollower    // someone followed you
    case gameReminder   // your game is starting soon
    case groupActivity  // post in a group you belong to
    case playerRequest  // player matching request
    case achievementUnlocked  // you earned a badge
    case tournamentUpdate // event update
    case newChallenger  // leaderboard challenge
}

struct DinkrNotification: Identifiable, Hashable {
    var id: String
    var type: DinkrNotificationType
    var fromUserId: String
    var fromUserName: String
    var title: String
    var body: String
    var receivedAt: Date
    var isRead: Bool
    var actionTarget: String?  // e.g. game session ID, user ID, event ID
}

extension DinkrNotification {
    static let mockNotifications: [DinkrNotification] = [
        DinkrNotification(id: "notif_001", type: .gameInvite,
                          fromUserId: "user_002", fromUserName: "Maria Chen",
                          title: "Game Invite", body: "Maria Chen invited you to a doubles game at Westside Courts. Tomorrow 8am.",
                          receivedAt: Date().addingTimeInterval(-900), isRead: false, actionTarget: "gs1"),
        DinkrNotification(id: "notif_002", type: .kudos,
                          fromUserId: "user_003", fromUserName: "Jordan Smith",
                          title: "Jordan gave you kudos 🏓", body: "Jordan Smith and 4 others kudos'd your game summary from yesterday.",
                          receivedAt: Date().addingTimeInterval(-3600), isRead: false, actionTarget: nil),
        DinkrNotification(id: "notif_003", type: .newFollower,
                          fromUserId: "user_007", fromUserName: "Jamie Lee",
                          title: "New Follower", body: "Jamie Lee (4.5 · Austin) started following you.",
                          receivedAt: Date().addingTimeInterval(-7200), isRead: true, actionTarget: "user_007"),
        DinkrNotification(id: "notif_004", type: .gameReminder,
                          fromUserId: "system", fromUserName: "Dinkr",
                          title: "⏰ Game Starting in 30 min", body: "Your doubles game at Westside Pickleball Complex starts in 30 minutes. 2 spots still open — share with friends!",
                          receivedAt: Date().addingTimeInterval(-1800), isRead: false, actionTarget: "gs1"),
        DinkrNotification(id: "notif_005", type: .groupActivity,
                          fromUserId: "user_004", fromUserName: "Sarah Johnson",
                          title: "New post in S. Austin Crew", body: "Sarah Johnson: 'Mueller open play THIS SUNDAY 8am! Who's in? 🙋‍♀️'",
                          receivedAt: Date().addingTimeInterval(-10800), isRead: true, actionTarget: "grp_001"),
        DinkrNotification(id: "notif_006", type: .playerRequest,
                          fromUserId: "user_009", fromUserName: "Riley Torres",
                          title: "Player Match Request", body: "Riley Torres (3.5 · 0.4 mi) wants to connect as a doubles partner.",
                          receivedAt: Date().addingTimeInterval(-14400), isRead: false, actionTarget: "user_009"),
        DinkrNotification(id: "notif_007", type: .achievementUnlocked,
                          fromUserId: "system", fromUserName: "Dinkr",
                          title: "Achievement Unlocked! 🏆", body: "You earned the 'Reliable Pro' badge for maintaining a 4.8+ reliability score over 50 games.",
                          receivedAt: Date().addingTimeInterval(-86400), isRead: true, actionTarget: nil),
        DinkrNotification(id: "notif_008", type: .newChallenger,
                          fromUserId: "user_005", fromUserName: "Chris Park",
                          title: "Leaderboard Challenge 🔥", body: "Chris Park just passed you on the weekly leaderboard! You're now #5. Play more to reclaim your spot.",
                          receivedAt: Date().addingTimeInterval(-172800), isRead: true, actionTarget: nil),
        DinkrNotification(id: "notif_009", type: .tournamentUpdate,
                          fromUserId: "system", fromUserName: "Austin Pickleball Alliance",
                          title: "Austin Open: Registration Closing Soon", body: "Only 78 spots left for the Austin Open on Apr 5. Registration closes in 3 days.",
                          receivedAt: Date().addingTimeInterval(-259200), isRead: true, actionTarget: "evt_001"),
        DinkrNotification(id: "notif_010", type: .kudos,
                          fromUserId: "user_002", fromUserName: "Maria Chen",
                          title: "Maria gave you kudos 🎉", body: "Maria Chen kudos'd your 11–7 win against Jordan.",
                          receivedAt: Date().addingTimeInterval(-345600), isRead: true, actionTarget: nil),
    ]

    var iconName: String {
        switch type {
        case .gameInvite: return "figure.pickleball"
        case .kudos: return "hands.clap.fill"
        case .newFollower: return "person.badge.plus"
        case .gameReminder: return "alarm.fill"
        case .groupActivity: return "person.3.fill"
        case .playerRequest: return "person.2.wave.2"
        case .achievementUnlocked: return "trophy.fill"
        case .tournamentUpdate: return "calendar.badge.exclamationmark"
        case .newChallenger: return "flame.fill"
        }
    }

    var accentColor: String {
        switch type {
        case .gameInvite: return "dinkrGreen"
        case .kudos: return "dinkrCoral"
        case .newFollower: return "dinkrSky"
        case .gameReminder: return "dinkrAmber"
        case .groupActivity: return "dinkrGreen"
        case .playerRequest: return "dinkrSky"
        case .achievementUnlocked: return "dinkrAmber"
        case .tournamentUpdate: return "dinkrCoral"
        case .newChallenger: return "dinkrCoral"
        }
    }
}

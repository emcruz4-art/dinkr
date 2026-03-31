import Foundation

// MARK: - Notification Type

enum DinkrNotificationType: String, Codable {
    // Games
    case gameInvite             // someone invited you to a game
    case gameReminder           // your game is starting soon
    case rsvpConfirmed          // your RSVP was confirmed
    case gameResult             // match result logged, DUPR updated
    case playerRequest          // player matching request
    case attendanceConfirmation // session ended — confirm who showed up
    case noShowReported         // you were reported as a no-show
    case matchChallenge         // someone challenged you to a match
    // Social
    case kudos                  // someone liked/kudos'd your game summary
    case newFollower            // someone followed you
    case friendRequest          // someone wants to connect
    case newMessage             // direct message or group message
    case groupActivity          // post in a group you belong to
    case groupInvite            // invited to join a group
    case challengeReceived      // someone sent you a challenge
    case challengeCompleted     // a challenge you're in finished
    case newChallenger          // leaderboard challenge
    // System
    case achievementUnlocked    // you earned a badge
    case tournamentUpdate       // event update
    case newListing             // saved search matched a new marketplace listing
}

// MARK: - Pending Action Kind

enum NotifActionKind {
    case acceptDecline          // Friend request / group invite / match challenge
    case acceptView             // Match challenge — Accept or View
    case viewBadge              // Achievement unlocked
    case viewResult             // Game result / DUPR update
    case viewCourt              // Game reminder with court chip
    case none
}

// MARK: - Model

struct DinkrNotification: Identifiable, Hashable {
    var id: String
    var type: DinkrNotificationType
    var fromUserId: String
    var fromUserName: String
    var title: String
    var body: String
    var receivedAt: Date
    var isRead: Bool
    var isMuted: Bool
    var actionTarget: String?   // game session ID, user ID, event ID, group ID …
    var courtName: String?      // used by .gameReminder for the court chip
    var groupKey: String?       // notifications with the same groupKey can be collapsed
    var pendingActionResolved: Bool  // if true, inline action buttons disappear
}

// MARK: - Convenience initialiser (backwards-compatible)

extension DinkrNotification {
    init(
        id: String,
        type: DinkrNotificationType,
        fromUserId: String,
        fromUserName: String,
        title: String,
        body: String,
        receivedAt: Date,
        isRead: Bool,
        actionTarget: String?,
        courtName: String? = nil,
        groupKey: String? = nil,
        isMuted: Bool = false,
        pendingActionResolved: Bool = false
    ) {
        self.id = id
        self.type = type
        self.fromUserId = fromUserId
        self.fromUserName = fromUserName
        self.title = title
        self.body = body
        self.receivedAt = receivedAt
        self.isRead = isRead
        self.isMuted = isMuted
        self.actionTarget = actionTarget
        self.courtName = courtName
        self.groupKey = groupKey
        self.pendingActionResolved = pendingActionResolved
    }
}

// MARK: - Derived Properties

extension DinkrNotification {

    var iconName: String {
        switch type {
        case .gameInvite:             return "figure.pickleball"
        case .gameReminder:           return "alarm.fill"
        case .rsvpConfirmed:          return "checkmark.seal.fill"
        case .gameResult:             return "chart.line.uptrend.xyaxis"
        case .playerRequest:          return "person.2.wave.2"
        case .attendanceConfirmation: return "person.fill.questionmark"
        case .noShowReported:         return "exclamationmark.circle.fill"
        case .matchChallenge:         return "bolt.fill"
        case .kudos:                  return "hands.clap.fill"
        case .newFollower:            return "person.badge.plus"
        case .friendRequest:          return "person.crop.circle.badge.plus"
        case .newMessage:             return "bubble.left.fill"
        case .groupActivity:          return "person.3.fill"
        case .groupInvite:            return "person.3.sequence.fill"
        case .challengeReceived:      return "trophy.fill"
        case .challengeCompleted:     return "checkmark.seal.fill"
        case .newChallenger:          return "flame.fill"
        case .achievementUnlocked:    return "trophy.fill"
        case .tournamentUpdate:       return "calendar.badge.exclamationmark"
        case .newListing:             return "tag.fill"
        }
    }

    var accentColor: String {
        switch type {
        case .gameInvite:             return "dinkrGreen"
        case .gameReminder:           return "dinkrAmber"
        case .rsvpConfirmed:          return "dinkrGreen"
        case .gameResult:             return "dinkrSky"
        case .playerRequest:          return "dinkrSky"
        case .attendanceConfirmation: return "dinkrAmber"
        case .noShowReported:         return "dinkrCoral"
        case .matchChallenge:         return "dinkrAmber"
        case .kudos:                  return "dinkrCoral"
        case .newFollower:            return "dinkrSky"
        case .friendRequest:          return "dinkrSky"
        case .newMessage:             return "dinkrNavy"
        case .groupActivity:          return "dinkrGreen"
        case .groupInvite:            return "dinkrGreen"
        case .challengeReceived:      return "dinkrAmber"
        case .challengeCompleted:     return "dinkrGreen"
        case .newChallenger:          return "dinkrCoral"
        case .achievementUnlocked:    return "dinkrAmber"
        case .tournamentUpdate:       return "dinkrCoral"
        case .newListing:             return "dinkrNavy"
        }
    }

    /// What kind of inline action buttons (if any) should be shown.
    var actionKind: NotifActionKind {
        switch type {
        case .friendRequest, .groupInvite: return .acceptDecline
        case .matchChallenge:              return .acceptView
        case .achievementUnlocked:         return .viewBadge
        case .gameResult:                  return .viewResult
        case .gameReminder:                return .viewCourt
        default:                           return .none
        }
    }

    /// Avatar initials derived from the sender name.
    var avatarInitials: String {
        let parts = fromUserName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))"
        }
        return String(fromUserName.prefix(2)).uppercased()
    }
}

// MARK: - Mock Data

extension DinkrNotification {
    static let mockNotifications: [DinkrNotification] = [

        // 1 — Game reminder with court chip (1 hour out)
        DinkrNotification(
            id: "notif_001", type: .gameReminder,
            fromUserId: "system", fromUserName: "Dinkr",
            title: "Your game at Westside starts in 1 hour 🏓",
            body: "Doubles · 4 players confirmed · Court 3",
            receivedAt: Date().addingTimeInterval(-180),
            isRead: false, actionTarget: "gs1",
            courtName: "Westside Pickleball Complex"),

        // 2 — New message with sender name
        DinkrNotification(
            id: "notif_002", type: .newMessage,
            fromUserId: "user_003", fromUserName: "Jordan Smith",
            title: "Jordan Smith",
            body: "Hey, want to play tomorrow? I grabbed a court at Mueller 8am 🎯",
            receivedAt: Date().addingTimeInterval(-420),
            isRead: false, actionTarget: "dm_003",
            groupKey: "dm_user_003"),

        // 3 — RSVP confirmed
        DinkrNotification(
            id: "notif_003", type: .rsvpConfirmed,
            fromUserId: "system", fromUserName: "Dinkr",
            title: "RSVP Confirmed ✅",
            body: "Your RSVP for Saturday doubles is confirmed. See you at Westside!",
            receivedAt: Date().addingTimeInterval(-600),
            isRead: false, actionTarget: "gs2"),

        // 4 — Friend request with inline Accept/Decline
        DinkrNotification(
            id: "notif_004", type: .friendRequest,
            fromUserId: "user_007", fromUserName: "Sarah Chen",
            title: "Sarah Chen wants to connect",
            body: "Sarah Chen (4.0 · Austin) sent you a friend request.",
            receivedAt: Date().addingTimeInterval(-900),
            isRead: false, actionTarget: "user_007"),

        // 5 — Achievement unlocked with View badge button
        DinkrNotification(
            id: "notif_005", type: .achievementUnlocked,
            fromUserId: "system", fromUserName: "Dinkr",
            title: "🏆 You earned 'Century Club'",
            body: "You've played 100 games on Dinkr. The badge is now on your profile.",
            receivedAt: Date().addingTimeInterval(-1200),
            isRead: false, actionTarget: "badge_century_club"),

        // 6 — Game result / DUPR update
        DinkrNotification(
            id: "notif_006", type: .gameResult,
            fromUserId: "system", fromUserName: "Dinkr",
            title: "Match result logged 📈",
            body: "Your match result was logged. DUPR updated +0.08",
            receivedAt: Date().addingTimeInterval(-3600),
            isRead: false, actionTarget: "gs1"),

        // 7 — DinkrGroup invite with inline Accept/Decline
        DinkrNotification(
            id: "notif_007", type: .groupInvite,
            fromUserId: "user_002", fromUserName: "Maria Garcia",
            title: "DinkrGroup Invite",
            body: "Maria invited you to join South Austin Ballers 🎉",
            receivedAt: Date().addingTimeInterval(-5400),
            isRead: false, actionTarget: "grp_002"),

        // 8 — Match challenge with Accept/View inline
        DinkrNotification(
            id: "notif_008", type: .matchChallenge,
            fromUserId: "user_011", fromUserName: "Jordan Lee",
            title: "Jordan challenged you! ⚡",
            body: "Jordan Lee challenged you to a game. Choose a time and court.",
            receivedAt: Date().addingTimeInterval(-7200),
            isRead: false, actionTarget: "ch_003"),

        // 9 — New listing from saved search
        DinkrNotification(
            id: "notif_009", type: .newListing,
            fromUserId: "system", fromUserName: "Dinkr Market",
            title: "New paddle on your saved search 👀",
            body: "Selkirk Power Air Invikta listed for $180 — great condition, Austin TX.",
            receivedAt: Date().addingTimeInterval(-9000),
            isRead: true, actionTarget: "listing_042"),

        // 10 — DinkrGroup message (part of a collapse group)
        DinkrNotification(
            id: "notif_010", type: .newMessage,
            fromUserId: "user_004", fromUserName: "Sarah Johnson",
            title: "South Austin Ballers",
            body: "Sarah Johnson: Anyone free for open play at 6pm tonight?",
            receivedAt: Date().addingTimeInterval(-10800),
            isRead: true, actionTarget: "grp_001",
            groupKey: "group_grp_001"),

        // 11 — More group messages (collapsed under same key)
        DinkrNotification(
            id: "notif_011", type: .newMessage,
            fromUserId: "user_005", fromUserName: "Chris Park",
            title: "South Austin Ballers",
            body: "Chris Park: I'm in! What courts?",
            receivedAt: Date().addingTimeInterval(-10750),
            isRead: true, actionTarget: "grp_001",
            groupKey: "group_grp_001"),

        DinkrNotification(
            id: "notif_012", type: .newMessage,
            fromUserId: "user_009", fromUserName: "Riley Torres",
            title: "South Austin Ballers",
            body: "Riley Torres: Mueller has open courts all evening 🙌",
            receivedAt: Date().addingTimeInterval(-10700),
            isRead: true, actionTarget: "grp_001",
            groupKey: "group_grp_001"),

        // 12 — Kudos
        DinkrNotification(
            id: "notif_013", type: .kudos,
            fromUserId: "user_003", fromUserName: "Jordan Smith",
            title: "Jordan gave you kudos 🏓",
            body: "Jordan Smith and 4 others kudos'd your game summary from yesterday.",
            receivedAt: Date().addingTimeInterval(-86400 + 3600),
            isRead: true, actionTarget: nil),

        // 13 — New follower
        DinkrNotification(
            id: "notif_014", type: .newFollower,
            fromUserId: "user_015", fromUserName: "Jamie Lee",
            title: "New Follower",
            body: "Jamie Lee (4.5 · Austin) started following you.",
            receivedAt: Date().addingTimeInterval(-86400 + 7200),
            isRead: true, actionTarget: "user_015"),

        // 14 — Attendance confirmation
        DinkrNotification(
            id: "notif_015", type: .attendanceConfirmation,
            fromUserId: "system", fromUserName: "Dinkr",
            title: "Attendance Check",
            body: "Your game at Mueller ended. Confirm who showed up to keep scores accurate.",
            receivedAt: Date().addingTimeInterval(-86400 + 12000),
            isRead: false, actionTarget: "gs2"),

        // 15 — No-show reported
        DinkrNotification(
            id: "notif_016", type: .noShowReported,
            fromUserId: "user_010", fromUserName: "Alex Rivera",
            title: "No-Show Reported",
            body: "Alex Rivera reported you as a no-show for the 7am game at Dove Springs. Dispute if incorrect.",
            receivedAt: Date().addingTimeInterval(-86400 * 2 + 3600),
            isRead: false, actionTarget: "gs3"),

        // 16 — Tournament update
        DinkrNotification(
            id: "notif_017", type: .tournamentUpdate,
            fromUserId: "system", fromUserName: "Austin Pickleball Alliance",
            title: "Austin Open: Spots Running Out",
            body: "Only 78 spots left for the Austin Open on Apr 5. Registration closes in 3 days.",
            receivedAt: Date().addingTimeInterval(-86400 * 2 + 7200),
            isRead: true, actionTarget: "evt_001"),

        // 17 — Leaderboard challenge
        DinkrNotification(
            id: "notif_018", type: .newChallenger,
            fromUserId: "user_005", fromUserName: "Chris Park",
            title: "Leaderboard Challenge 🔥",
            body: "Chris Park just passed you on the weekly leaderboard! You're now #5. Play more to reclaim your spot.",
            receivedAt: Date().addingTimeInterval(-86400 * 3),
            isRead: true, actionTarget: nil),

        // 18 — Game invite
        DinkrNotification(
            id: "notif_019", type: .gameInvite,
            fromUserId: "user_002", fromUserName: "Maria Garcia",
            title: "Game Invite",
            body: "Maria Garcia invited you to a doubles game at Westside Courts. Tomorrow 8am.",
            receivedAt: Date().addingTimeInterval(-86400 * 3 + 3600),
            isRead: true, actionTarget: "gs4"),
    ]
}

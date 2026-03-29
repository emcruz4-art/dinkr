import Foundation

struct ChatThread: Identifiable, Codable, Hashable {
    var id: String
    var participantIds: [String]
    var participantNames: [String]
    var lastMessage: ChatMessage?
    var messages: [ChatMessage]
    var isGroupChat: Bool
    var groupName: String?
    var updatedAt: Date
    var unreadCount: Int
}

struct ChatMessage: Identifiable, Codable, Hashable {
    var id: String
    var senderId: String
    var senderName: String
    var content: String
    var type: MessageType
    var sentAt: Date
    var isRead: Bool
    var mediaURL: String?
}

extension ChatThread {
    static let mockThreads: [ChatThread] = [
        ChatThread(
            id: "chat_001",
            participantIds: ["user_001", "user_002"],
            participantNames: ["Alex Rivera", "Maria Chen"],
            lastMessage: ChatMessage(id: "msg_last_1", senderId: "user_002", senderName: "Maria Chen",
                                     content: "See you Saturday! 🏓", type: .text,
                                     sentAt: Date().addingTimeInterval(-1800), isRead: false, mediaURL: nil),
            messages: [],
            isGroupChat: false, groupName: nil,
            updatedAt: Date().addingTimeInterval(-1800), unreadCount: 1
        ),
        ChatThread(
            id: "chat_grp_001",
            participantIds: ["user_001", "user_003", "user_004", "user_005"],
            participantNames: ["Alex Rivera", "Jordan Smith", "Sarah Johnson", "Chris Park"],
            lastMessage: ChatMessage(id: "msg_last_2", senderId: "user_003", senderName: "Jordan Smith",
                                     content: "Courts open at 6:30 tomorrow", type: .text,
                                     sentAt: Date().addingTimeInterval(-3600), isRead: true, mediaURL: nil),
            messages: [],
            isGroupChat: true, groupName: "South Austin Dinkers",
            updatedAt: Date().addingTimeInterval(-3600), unreadCount: 0
        ),
    ]
}

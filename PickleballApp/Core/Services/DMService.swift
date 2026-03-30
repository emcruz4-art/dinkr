import Foundation
import FirebaseFirestore
import Observation

// MARK: - Firestore document models

struct ConversationDoc: Codable {
    var id: String
    var participantIds: [String]
    var participantNames: [String: String]   // userId → displayName
    var lastMessage: String
    var lastMessageSenderId: String
    var lastMessageTime: Date
    var updatedAt: Date
    var unreadCounts: [String: Int]          // userId → count
    var isGroupChat: Bool
    var groupName: String?
}

struct MessageDoc: Codable, Identifiable {
    var id: String
    var senderId: String
    var senderName: String
    var content: String
    var sentAt: Date
    var isRead: Bool
    var reaction: String?
}

// MARK: - DMService

// NOTE: The conversations query (participantIds arrayContains + updatedAt descending) requires
// a composite Firestore index. Create it in the Firebase console:
//   Collection: conversations
//   Fields:     participantIds (Arrays) ASC  +  updatedAt (Descending)
// Firebase will also prompt you with a direct link in the Xcode console when the query first runs.

@Observable
final class DMService {
    static let shared = DMService()
    private let db = Firestore.firestore()
    private init() {}

    private var conversationListener: ListenerRegistration?
    private var messageListeners: [String: ListenerRegistration] = [:]

    // MARK: - Conversation ID
    // Always sorted so both users resolve to the same document
    static func conversationId(userId1: String, userId2: String) -> String {
        [userId1, userId2].sorted().joined(separator: "_")
    }

    // MARK: - Load conversations (one-shot fetch)
    func loadConversations(for userId: String) async -> [DMConversation] {
        guard let snapshot = try? await db
            .collection(FirestoreCollections.conversations)
            .whereField("participantIds", arrayContains: userId)
            .order(by: "updatedAt", descending: true)
            .getDocuments()
        else { return [] }

        return snapshot.documents.compactMap { doc -> DMConversation? in
            guard let convDoc = try? doc.data(as: ConversationDoc.self) else { return nil }
            return toConversation(convDoc, currentUserId: userId)
        }
    }

    // MARK: - Real-time conversations listener
    func startConversationsListener(
        userId: String,
        onChange: @escaping ([DMConversation]) -> Void
    ) -> ListenerRegistration {
        let query = db
            .collection(FirestoreCollections.conversations)
            .whereField("participantIds", arrayContains: userId)
            .order(by: "updatedAt", descending: true)

        return query.addSnapshotListener { snapshot, error in
            guard let snapshot else { return }
            let conversations = snapshot.documents.compactMap { doc -> DMConversation? in
                guard let convDoc = try? doc.data(as: ConversationDoc.self) else { return nil }
                return self.toConversation(convDoc, currentUserId: userId)
            }
            onChange(conversations)
        }
    }

    // MARK: - Start or get conversation
    func startConversation(
        currentUserId: String,
        currentUserName: String,
        targetUserId: String,
        targetUserName: String
    ) async -> String {
        let convId = DMService.conversationId(userId1: currentUserId, userId2: targetUserId)
        let ref = db.collection(FirestoreCollections.conversations).document(convId)
        let snap = try? await ref.getDocument()
        if snap?.exists == true { return convId }

        let doc = ConversationDoc(
            id: convId,
            participantIds: [currentUserId, targetUserId],
            participantNames: [currentUserId: currentUserName, targetUserId: targetUserName],
            lastMessage: "",
            lastMessageSenderId: "",
            lastMessageTime: Date(),
            updatedAt: Date(),
            unreadCounts: [currentUserId: 0, targetUserId: 0],
            isGroupChat: false,
            groupName: nil
        )
        try? await ref.setData(try Firestore.Encoder().encode(doc))
        return convId
    }

    // MARK: - Load messages (paginated, most recent first)
    func loadMessages(conversationId: String, limit: Int = 50) async -> [DMMessage] {
        guard let snapshot = try? await db
            .collection(FirestoreCollections.conversations)
            .document(conversationId)
            .collection("messages")
            .order(by: "sentAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        else { return [] }

        // Reverse so oldest message is first (natural chat order)
        return snapshot.documents
            .compactMap { doc -> DMMessage? in
                guard let msgDoc = try? doc.data(as: MessageDoc.self) else { return nil }
                return toMessage(msgDoc, currentUserId: "", conversationId: conversationId)
            }
            .reversed()
    }

    // MARK: - Real-time messages listener
    func startMessagesListener(
        conversationId: String,
        onChange: @escaping ([DMMessage]) -> Void
    ) -> ListenerRegistration {
        let query = db
            .collection(FirestoreCollections.conversations)
            .document(conversationId)
            .collection("messages")
            .order(by: "sentAt", descending: false)

        return query.addSnapshotListener { snapshot, error in
            guard let snapshot else { return }
            let messages = snapshot.documents.compactMap { doc -> DMMessage? in
                guard let msgDoc = try? doc.data(as: MessageDoc.self) else { return nil }
                return self.toMessage(msgDoc, currentUserId: "", conversationId: conversationId)
            }
            onChange(messages)
        }
    }

    // MARK: - Send message
    func sendMessage(
        conversationId: String,
        senderId: String,
        senderName: String,
        content: String
    ) async throws {
        let msgRef = db
            .collection(FirestoreCollections.conversations)
            .document(conversationId)
            .collection("messages")
            .document()

        let msg = MessageDoc(
            id: msgRef.documentID,
            senderId: senderId,
            senderName: senderName,
            content: content,
            sentAt: Date(),
            isRead: false,
            reaction: nil
        )
        try msgRef.setData(from: msg)

        // Update conversation metadata and increment unread counts for other participants
        let convRef = db.collection(FirestoreCollections.conversations).document(conversationId)
        let convSnap = try? await convRef.getDocument()
        let conv = try? convSnap?.data(as: ConversationDoc.self)

        var unreadUpdates: [String: Any] = [:]
        for participantId in (conv?.participantIds ?? []) {
            if participantId != senderId {
                unreadUpdates["unreadCounts.\(participantId)"] = FieldValue.increment(Int64(1))
            }
        }

        var updateData: [String: Any] = [
            "lastMessage": content,
            "lastMessageSenderId": senderId,
            "lastMessageTime": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        updateData.merge(unreadUpdates) { $1 }
        try? await convRef.updateData(updateData)
    }

    // MARK: - Mark as read
    func markAsRead(conversationId: String, userId: String) async {
        try? await db
            .collection(FirestoreCollections.conversations)
            .document(conversationId)
            .updateData(["unreadCounts.\(userId)": 0])
    }

    // MARK: - React to message
    func reactToMessage(conversationId: String, messageId: String, reaction: String?) async {
        let ref = db
            .collection(FirestoreCollections.conversations)
            .document(conversationId)
            .collection("messages")
            .document(messageId)

        if let reaction {
            try? await ref.updateData(["reaction": reaction])
        } else {
            try? await ref.updateData(["reaction": FieldValue.delete()])
        }
    }

    // MARK: - Conversion helpers

    func toConversation(_ doc: ConversationDoc, currentUserId: String) -> DMConversation? {
        guard let otherUserId = doc.participantIds.first(where: { $0 != currentUserId }),
              let otherUserName = doc.participantNames[otherUserId]
        else { return nil }

        return DMConversation(
            id: doc.id,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            otherUserInitial: String(otherUserName.prefix(1)),
            lastMessage: doc.lastMessage,
            lastMessageTime: doc.lastMessageTime,
            unreadCount: doc.unreadCounts[currentUserId] ?? 0,
            isOnline: false
        )
    }

    func toMessage(_ doc: MessageDoc, currentUserId: String, conversationId: String) -> DMMessage {
        DMMessage(
            id: doc.id,
            conversationId: conversationId,
            senderId: (!currentUserId.isEmpty && doc.senderId == currentUserId) ? "me" : doc.senderId,
            text: doc.content,
            timestamp: doc.sentAt,
            isRead: doc.isRead,
            reaction: doc.reaction
        )
    }
}

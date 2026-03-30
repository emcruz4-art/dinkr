import Foundation
import FirebaseFirestore

struct Comment: Identifiable, Codable {
    var id: String
    var postId: String
    var authorId: String
    var authorName: String
    var authorAvatarURL: String?
    var content: String
    var createdAt: Date
}

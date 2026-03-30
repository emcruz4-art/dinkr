import Foundation
import FirebaseFirestore
import Observation

@Observable
final class VideoService {
    static let shared = VideoService()
    private let db = Firestore.firestore()
    private init() {}

    func loadFeaturedVideos() async -> [VideoPost] {
        guard let snapshot = try? await db
            .collection("videoHighlights")
            .whereField("isFeatured", isEqualTo: true)
            .order(by: "likes", descending: true)
            .limit(to: 6)
            .getDocuments()
        else { return VideoPost.mockVideos.filter { $0.isFeatured } }

        let videos = snapshot.documents.compactMap { try? $0.data(as: VideoPost.self) }
        return videos.isEmpty ? VideoPost.mockVideos.filter { $0.isFeatured } : videos
    }

    func loadVideos(category: VideoCategory) async -> [VideoPost] {
        var query = db.collection("videoHighlights")
            .order(by: "createdAt", descending: true)
            .limit(to: 20) as Query
        if category != .all {
            query = db.collection("videoHighlights")
                .whereField("category", isEqualTo: category.rawValue)
                .order(by: "createdAt", descending: true)
                .limit(to: 20)
        }
        guard let snapshot = try? await query.getDocuments() else {
            return category == .all ? VideoPost.mockVideos :
                   VideoPost.mockVideos.filter { $0.category == category }
        }
        let videos = snapshot.documents.compactMap { try? $0.data(as: VideoPost.self) }
        return videos.isEmpty ? (category == .all ? VideoPost.mockVideos :
            VideoPost.mockVideos.filter { $0.category == category }) : videos
    }

    func toggleLike(videoId: String, userId: String, isLiking: Bool) async {
        try? await db.collection("videoHighlights").document(videoId).updateData([
            "likes": FieldValue.increment(isLiking ? Int64(1) : Int64(-1))
        ])
    }
}

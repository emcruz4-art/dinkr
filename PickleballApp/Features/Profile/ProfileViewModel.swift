import Foundation
import Observation
import SwiftUI
import PhotosUI

@Observable
final class ProfileViewModel {
    var user: User? = nil
    var posts: [Post] = []
    var gameResults: [GameResult] = []
    var isLoading = false
    var showEditProfile = false

    private let firestoreService = FirestoreService.shared
    private let imageService = ImageService.shared

    func load(authService: AuthService) async {
        isLoading = true
        defer { isLoading = false }
        user = authService.currentUser
        await loadPosts()
        if let userId = user?.id {
            gameResults = await GameResultService.shared.loadResults(for: userId)
        }
    }

    func loadPosts() async {
        guard let uid = user?.id else { return }
        do {
            posts = try await firestoreService.queryCollection(
                collection: FirestoreCollections.posts,
                field: "authorId",
                isEqualTo: uid
            )
        } catch {
            print("[ProfileViewModel] loadPosts error: \(error)")
        }
    }

    func updateAvatar(image: UIImage, authService: AuthService) async {
        guard let uid = user?.id else { return }
        do {
            let path = "avatars/\(uid)/profile.jpg"
            let urlString = try await imageService.upload(image, path: path)
            user?.avatarURL = urlString
            try await firestoreService.updateDocument(
                collection: FirestoreCollections.users,
                documentId: uid,
                data: ["avatarURL": urlString]
            )
            authService.currentUser?.avatarURL = urlString
        } catch {
            print("[ProfileViewModel] updateAvatar error: \(error)")
        }
    }

    func signOut(authService: AuthService) {
        authService.signOut()
    }
}

import Foundation
import SwiftUI
import PhotosUI
import FirebaseStorage

@Observable
final class ImageService {
    var isUploading: Bool = false
    var uploadProgress: Double = 0
    var error: String? = nil

    // MARK: - PhotosUI Picker Support

    func loadImage(from item: PhotosPickerItem) async -> UIImage? {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return nil }
        return image
    }

    // MARK: - Firebase Storage Upload

    func uploadImage(_ image: UIImage, path: String) async throws -> URL {
        isUploading = true
        uploadProgress = 0
        defer { isUploading = false; uploadProgress = 0 }

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw ImageError.compressionFailed
        }

        let storageRef = Storage.storage().reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        let uploadTask = storageRef.putData(data, metadata: metadata)
        uploadTask.observe(.progress) { [weak self] snapshot in
            let progress = Double(snapshot.progress?.completedUnitCount ?? 0) /
                           Double(snapshot.progress?.totalUnitCount ?? 1)
            self?.uploadProgress = progress
        }

        _ = try await storageRef.putDataAsync(data, metadata: metadata)
        return try await storageRef.downloadURL()
    }

    // MARK: - Upload and return String URL

    func uploadAndGetURL(_ image: UIImage, path: String) async throws -> String {
        let url = try await uploadImage(image, path: path)
        return url.absoluteString
    }

    // MARK: - Delete from Storage

    func deleteImage(at url: String) async throws {
        try await Storage.storage().reference(forURL: url).delete()
    }
}

enum ImageError: LocalizedError {
    case compressionFailed
    case uploadFailed(String)

    var errorDescription: String? {
        switch self {
        case .compressionFailed: return "Image compression failed."
        case .uploadFailed(let msg): return "Upload failed: \(msg)"
        }
    }
}

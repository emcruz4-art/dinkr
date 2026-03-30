import FirebaseStorage
import UIKit

final class ImageService {
    static let shared = ImageService()
    private let storage = Storage.storage()
    private var cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 100
    }

    // MARK: - Upload

    /// Compresses and uploads a UIImage to the given storage path.
    /// Returns the public download URL string.
    func upload(_ image: UIImage, path: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw ImageError.compressionFailed
        }

        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    // MARK: - Fetch & Cache

    /// Downloads a UIImage from the given URL string, caching the result.
    /// Subsequent calls for the same URL return the cached copy immediately.
    func fetchImage(urlString: String) async throws -> UIImage {
        let key = urlString as NSString

        if let cached = cache.object(forKey: key) {
            return cached
        }

        guard let url = URL(string: urlString) else {
            throw ImageError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ImageError.downloadFailed("Non-2xx response from server")
        }

        guard let image = UIImage(data: data) else {
            throw ImageError.downloadFailed("Could not decode image data")
        }

        cache.setObject(image, forKey: key)
        return image
    }

    // MARK: - Delete

    /// Deletes the file at the given storage path (not a download URL).
    func delete(path: String) async throws {
        try await storage.reference().child(path).delete()
    }
}

// MARK: - Storage Path Helpers

enum StoragePaths {
    static func avatar(userId: String) -> String { "avatars/\(userId).jpg" }
    static func postMedia(postId: String, index: Int) -> String { "posts/\(postId)/\(index).jpg" }
    static func listingPhoto(listingId: String, index: Int) -> String { "listings/\(listingId)/\(index).jpg" }
}

// MARK: - Errors

enum ImageError: LocalizedError {
    case compressionFailed
    case invalidURL
    case downloadFailed(String)
    case uploadFailed(String)

    var errorDescription: String? {
        switch self {
        case .compressionFailed:        return "Image compression failed."
        case .invalidURL:               return "The image URL is invalid."
        case .downloadFailed(let msg):  return "Download failed: \(msg)"
        case .uploadFailed(let msg):    return "Upload failed: \(msg)"
        }
    }
}

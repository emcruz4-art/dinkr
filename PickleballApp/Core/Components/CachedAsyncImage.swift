import SwiftUI
import UIKit

/// A drop-in replacement for AsyncImage that uses ImageService's in-memory cache.
/// Images are fetched once, stored in NSCache, and served instantly on subsequent views.
struct CachedAsyncImage: View {
    let urlString: String?
    var placeholder: AnyView = AnyView(Color.cardBackground)

    @State private var image: UIImage? = nil
    @State private var isLoaded = false

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .opacity(isLoaded ? 1 : 0)
                    .animation(.easeIn(duration: 0.25), value: isLoaded)
            } else {
                placeholder
            }
        }
        .task(id: urlString) {
            await load()
        }
    }

    @MainActor
    private func load() async {
        guard let urlString, !urlString.isEmpty else { return }
        isLoaded = false
        image = nil
        do {
            let fetched = try await ImageService.shared.fetchImage(urlString: urlString)
            image = fetched
            isLoaded = true
        } catch {
            // Leave placeholder visible on failure
        }
    }
}

// MARK: - Convenience Initializers

extension CachedAsyncImage {
    /// Creates a CachedAsyncImage with a custom SwiftUI placeholder view.
    init<Placeholder: View>(urlString: String?, @ViewBuilder placeholder: () -> Placeholder) {
        self.urlString = urlString
        self.placeholder = AnyView(placeholder())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // Nil URL — shows placeholder
        CachedAsyncImage(urlString: nil)
            .frame(width: 80, height: 80)
            .clipShape(Circle())

        // Custom placeholder
        CachedAsyncImage(urlString: nil) {
            ZStack {
                Color.dinkrGreen.opacity(0.15)
                Image(systemName: "person.fill")
                    .foregroundStyle(Color.dinkrGreen)
                    .font(.title)
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
    }
    .padding()
}

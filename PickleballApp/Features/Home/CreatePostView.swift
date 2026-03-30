import SwiftUI
import PhotosUI
import UIKit

// MARK: - ViewModel

@Observable
final class CreatePostViewModel {
    var content: String = ""
    var selectedImages: [UIImage] = []
    var postType: PostType = .highlight
    var tags: [String] = []
    var tagInput: String = ""
    var isLoading: Bool = false
    var uploadProgress: Double = 0
    var errorMessage: String? = nil
    var didPost: Bool = false

    var canPost: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedImages.isEmpty
    }

    func addTag(_ raw: String) {
        let cleaned = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .lowercased()
        guard !cleaned.isEmpty, !tags.contains(cleaned), tags.count < 10 else { return }
        tags.append(cleaned)
        tagInput = ""
    }

    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    func removeImage(at index: Int) {
        guard selectedImages.indices.contains(index) else { return }
        selectedImages.remove(at: index)
    }

    @MainActor
    func submit(authorId: String, authorName: String, authorAvatarURL: String?) async throws {
        isLoading = true
        uploadProgress = 0
        errorMessage = nil
        defer { isLoading = false }

        let postId = UUID().uuidString
        var mediaURLs: [String] = []

        // Upload images
        let imageCount = Double(max(selectedImages.count, 1))
        for (index, image) in selectedImages.enumerated() {
            let path = StoragePaths.postMedia(postId: postId, index: index)
            let url = try await ImageService.shared.upload(image, path: path)
            mediaURLs.append(url)
            uploadProgress = Double(index + 1) / imageCount
        }

        uploadProgress = 1.0

        let post = Post(
            id: postId,
            authorId: authorId,
            authorName: authorName,
            authorAvatarURL: authorAvatarURL,
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            mediaURLs: mediaURLs,
            postType: postType,
            likes: 0,
            commentCount: 0,
            createdAt: Date(),
            isLiked: false,
            tags: tags,
            groupId: nil
        )

        try await FirestoreService.shared.setDocument(post, collection: FirestoreCollections.posts, documentId: postId)
        didPost = true
    }
}

// MARK: - Post Type Metadata

private extension PostType {
    var label: String {
        switch self {
        case .highlight:       return "Highlight"
        case .question:        return "Question"
        case .lookingForGame:  return "LFG"
        case .winCelebration:  return "Result"
        case .courtReview:     return "Tip"
        case .general:         return "Achievement"
        }
    }

    var emoji: String {
        switch self {
        case .highlight:       return "🏆"
        case .question:        return "❓"
        case .lookingForGame:  return "🎮"
        case .winCelebration:  return "📊"
        case .courtReview:     return "💡"
        case .general:         return "🏅"
        }
    }
}

// MARK: - Audience Enum

private enum PostAudience: String, CaseIterable {
    case everyone = "Everyone"
    case friends  = "Friends"
}

// MARK: - CreatePostView

struct CreatePostView: View {
    let authorId: String
    let authorName: String
    let authorAvatarURL: String?

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CreatePostViewModel()
    @State private var audience: PostAudience = .everyone

    // Image picking
    @State private var showMediaDialog: Bool = false
    @State private var showLibraryPicker: Bool = false
    @State private var showCameraPicker: Bool = false
    @State private var pendingPickerImage: UIImage? = nil

    // Error
    @State private var showError: Bool = false

    private let maxChars: Int = 280
    private let warnThreshold: Int = 240
    private let quickTags: [String] = ["pickleball", "dink", "erne", "austin"]

    init(authorId: String = "me", authorName: String = "You", authorAvatarURL: String? = nil) {
        self.authorId = authorId
        self.authorName = authorName
        self.authorAvatarURL = authorAvatarURL
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                scrollContent
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: viewModel.isLoading ? 56 : 0)
                    }

                if viewModel.isLoading {
                    uploadProgressBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    keyboardToolbar
                }
            }
        }
        // Image sheets
        .sheet(isPresented: $showLibraryPicker) {
            MultiImagePicker(selectedImages: $viewModel.selectedImages, maxCount: 4)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showCameraPicker) {
            CameraView(selectedImage: $pendingPickerImage)
                .ignoresSafeArea()
        }
        .onChange(of: pendingPickerImage) { _, newImage in
            if let img = newImage, viewModel.selectedImages.count < 4 {
                viewModel.selectedImages.append(img)
                pendingPickerImage = nil
            }
        }
        .onChange(of: viewModel.didPost) { _, posted in
            if posted { dismiss() }
        }
        .alert("Post Failed", isPresented: $showError, presenting: viewModel.errorMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { msg in
            Text(msg)
        }
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                postTypeChips
                    .padding(.top, 12)

                authorRow
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                Divider().padding(.top, 12)

                contentEditor
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                if !viewModel.selectedImages.isEmpty {
                    mediaThumbnails
                        .padding(.top, 12)
                }

                addPhotoRow
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                Divider().padding(.top, 12)

                tagsSection
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
                .foregroundStyle(.primary)
        }
        ToolbarItem(placement: .principal) {
            Text("New Post")
                .font(.headline)
        }
        ToolbarItem(placement: .confirmationAction) {
            Button {
                Task {
                    do {
                        try await viewModel.submit(
                            authorId: authorId,
                            authorName: authorName,
                            authorAvatarURL: authorAvatarURL
                        )
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color.dinkrGreen)
                        .scaleEffect(0.85)
                } else {
                    Text("Post")
                        .fontWeight(.semibold)
                        .foregroundStyle(viewModel.canPost ? Color.dinkrGreen : Color.secondary)
                }
            }
            .disabled(!viewModel.canPost || viewModel.isLoading)
        }
    }

    // MARK: - Keyboard Toolbar

    private var keyboardToolbar: some View {
        HStack(spacing: 20) {
            Button {
                showMediaDialog = true
            } label: {
                Label("Photo", systemImage: "photo.on.rectangle.angled")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(Color.dinkrSky)
            }
            .disabled(viewModel.selectedImages.count >= 4)
            .confirmationDialog("Add Photo", isPresented: $showMediaDialog, titleVisibility: .visible) {
                Button("Camera") { showCameraPicker = true }
                Button("Photo Library") { showLibraryPicker = true }
                Button("Cancel", role: .cancel) {}
            }

            Button {
                // Scroll to tags section — focus is handled by .focused
            } label: {
                Label("Tag", systemImage: "number")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(Color.dinkrGreen)
            }

            Spacer()

            // Character counter in keyboard toolbar
            let count = viewModel.content.count
            Text("\(count)/\(maxChars)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(count > warnThreshold ? Color.dinkrCoral : Color.secondary)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Post Type Chips

    private var postTypeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PostType.allCases, id: \.self) { type in
                    let selected = viewModel.postType == type
                    Button {
                        withAnimation(.spring(duration: 0.2)) {
                            viewModel.postType = type
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(type.emoji)
                                .font(.caption)
                            Text(type.label)
                                .font(.subheadline.weight(selected ? .semibold : .regular))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(selected ? Color.dinkrGreen : Color.cardBackground)
                        )
                        .foregroundStyle(selected ? .white : .primary)
                        .overlay(
                            Capsule()
                                .stroke(selected ? Color.clear : Color.secondary.opacity(0.25), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Author Row

    private var authorRow: some View {
        HStack(spacing: 10) {
            AvatarView(urlString: authorAvatarURL, displayName: authorName, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(authorName)
                    .font(.subheadline.weight(.semibold))

                Menu {
                    ForEach(PostAudience.allCases, id: \.self) { option in
                        Button {
                            audience = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if audience == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: audience == .everyone ? "globe" : "person.2.fill")
                            .font(.caption2)
                        Text(audience.rawValue)
                            .font(.caption.weight(.medium))
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.cardBackground))
                    .foregroundStyle(Color.dinkrGreen)
                }
            }

            Spacer()
        }
    }

    // MARK: - Content Editor

    private var contentEditor: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ZStack(alignment: .topLeading) {
                if viewModel.content.isEmpty {
                    Text("What's happening on the court?")
                        .foregroundStyle(Color.secondary.opacity(0.6))
                        .font(.body)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $viewModel.content)
                    .font(.body)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .onChange(of: viewModel.content) { _, newValue in
                        if newValue.count > maxChars {
                            viewModel.content = String(newValue.prefix(maxChars))
                        }
                    }
            }

            // Character counter — right-aligned below editor
            let charCount = viewModel.content.count
            Text("\(charCount)/\(maxChars)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(charCount > warnThreshold ? Color.dinkrCoral : Color.secondary)
                .animation(.easeInOut, value: charCount > warnThreshold)
        }
    }

    // MARK: - Media Thumbnails

    private var mediaThumbnails: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.selectedImages.indices, id: \.self) { index in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: viewModel.selectedImages[index])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            withAnimation(.spring(duration: 0.25)) {
                                viewModel.removeImage(at: index)
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.55))
                                    .frame(width: 24, height: 24)
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(6)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Add Photo Row

    private var addPhotoRow: some View {
        HStack(spacing: 10) {
            Button {
                showMediaDialog = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "camera.badge.plus")
                    Text("Add Photo")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(Color.dinkrSky)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.dinkrSky.opacity(0.1))
                )
            }
            .disabled(viewModel.selectedImages.count >= 4)
            .confirmationDialog("Add Photo", isPresented: $showMediaDialog, titleVisibility: .visible) {
                Button("Camera") { showCameraPicker = true }
                Button("Photo Library") { showLibraryPicker = true }
                Button("Cancel", role: .cancel) {}
            }

            if viewModel.selectedImages.count >= 4 {
                Text("Max 4 photos")
                    .font(.caption)
                    .foregroundStyle(Color.dinkrCoral)
            } else {
                Text("\(viewModel.selectedImages.count)/4")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tags")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.secondary)

            // Existing tag chips
            if !viewModel.tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(viewModel.tags, id: \.self) { tag in
                        tagChip(tag)
                    }
                }
            }

            // Tag input field
            HStack(spacing: 8) {
                Image(systemName: "number")
                    .foregroundStyle(Color.dinkrGreen)
                    .font(.caption)
                TextField("Add tag", text: $viewModel.tagInput)
                    .font(.subheadline)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        viewModel.addTag(viewModel.tagInput)
                    }
                if !viewModel.tagInput.isEmpty {
                    Button {
                        viewModel.addTag(viewModel.tagInput)
                    } label: {
                        Image(systemName: "return")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.cardBackground))

            // Quick-add common tags
            HStack(spacing: 8) {
                Text("Quick add:")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                FlowLayout(spacing: 6) {
                    ForEach(quickTags.filter { !viewModel.tags.contains($0) }, id: \.self) { tag in
                        Button {
                            viewModel.addTag(tag)
                        } label: {
                            Text("#\(tag)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.dinkrGreen)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.dinkrGreen.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func tagChip(_ tag: String) -> some View {
        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
            Button {
                withAnimation(.spring(duration: 0.2)) {
                    viewModel.removeTag(tag)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.dinkrGreen))
    }

    // MARK: - Upload Progress Bar

    private var uploadProgressBar: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.dinkrGreen.opacity(0.2))
                        .frame(height: 4)
                    Rectangle()
                        .fill(Color.dinkrGreen)
                        .frame(width: geo.size.width * viewModel.uploadProgress, height: 4)
                        .animation(.linear(duration: 0.2), value: viewModel.uploadProgress)
                }
            }
            .frame(height: 4)

            HStack(spacing: 8) {
                ProgressView()
                    .tint(Color.dinkrGreen)
                    .scaleEffect(0.8)
                Text("Uploading… \(Int(viewModel.uploadProgress * 100))%")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.dinkrGreen)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }
}

// MARK: - Multi-Image Picker (PHPicker, up to 4)

private struct MultiImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    let maxCount: Int
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = maxCount - selectedImages.count
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MultiImagePicker

        init(_ parent: MultiImagePicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            let providers = results.map(\.itemProvider).filter { $0.canLoadObject(ofClass: UIImage.self) }
            for provider in providers {
                provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                    DispatchQueue.main.async {
                        guard let self, let image = object as? UIImage,
                              self.parent.selectedImages.count < self.parent.maxCount else { return }
                        self.parent.selectedImages.append(image)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CreatePostView(authorId: "preview_user", authorName: "Evan Cruz", authorAvatarURL: nil)
}

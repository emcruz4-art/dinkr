import SwiftUI

// MARK: - ViewModel

@Observable
final class CreatePostViewModel {
    var content: String = ""
    var selectedPostType: PostType = .general
    var tags: [String] = []
    var tagInput: String = ""
    var taggedUserIds: [String] = []
    var hasPhoto: Bool = false
    var locationTag: String? = nil
    var courtTag: String? = nil
    var starRating: Int = 0
    var isLoading: Bool = false
    var uploadProgress: Double = 0
    var errorMessage: String? = nil
    var didPost: Bool = false

    var canPost: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

    @MainActor
    func submit(authorId: String, authorName: String, authorAvatarURL: String?) async {
        isLoading = true
        defer { isLoading = false }

        // Simulate async post submission (no Firebase in stub)
        try? await Task.sleep(nanoseconds: 800_000_000)

        let postId = UUID().uuidString
        let _ = Post(
            id: postId,
            authorId: authorId,
            authorName: authorName,
            authorAvatarURL: authorAvatarURL,
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            mediaURLs: hasPhoto ? ["placeholder://photo"] : [],
            postType: selectedPostType,
            likes: 0,
            commentCount: 0,
            createdAt: Date(),
            isLiked: false,
            tags: tags,
            taggedUserIds: taggedUserIds,
            groupId: nil
        )

        didPost = true
    }
}

// MARK: - Post Type Metadata

private extension PostType {
    var displayLabel: String {
        switch self {
        case .general:        return "General"
        case .highlight:      return "Highlight"
        case .winCelebration: return "Win"
        case .courtReview:    return "Court Review"
        case .lookingForGame: return "Looking for Game"
        case .question:       return "Question"
        }
    }

    var displayEmoji: String {
        switch self {
        case .general:        return "💬"
        case .highlight:      return "🎯"
        case .winCelebration: return "🏆"
        case .courtReview:    return "⭐"
        case .lookingForGame: return "🎾"
        case .question:       return "❓"
        }
    }

    var placeholder: String {
        switch self {
        case .general:
            return "What's on your mind? Share a thought, tip, or update with the community…"
        case .highlight:
            return "Describe your highlight moment! What happened on court that you want to share?"
        case .winCelebration:
            return "Share your win! What was the score, who did you play, and how did it feel?"
        case .courtReview:
            return "Review this court — surface quality, lighting, facilities, overall vibe…"
        case .lookingForGame:
            return "Looking for a game? Share your skill level, preferred time, and location…"
        case .question:
            return "Ask the community anything — strategy, gear, rules, local events…"
        }
    }
}

// MARK: - Mock Court Names

private let mockCourtNames: [String] = [
    "Westside Pickleball Complex",
    "Mueller Recreation Center",
    "Zilker Park Courts",
    "Brushy Creek Sports Park"
]

// MARK: - CreatePostView

struct CreatePostView: View {
    let authorId: String
    let authorName: String
    let authorAvatarURL: String?

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CreatePostViewModel()

    // Sheet states
    @State private var showTagPicker: Bool = false
    @State private var showCourtPicker: Bool = false

    private let maxChars: Int = 280
    private let warnThreshold: Int = 250

    init(authorId: String = "me", authorName: String = "You", authorAvatarURL: String? = nil) {
        self.authorId = authorId
        self.authorName = authorName
        self.authorAvatarURL = authorAvatarURL
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Post type selector
                    postTypeChips
                        .padding(.top, 12)

                    // Author row
                    authorRow
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    Divider().padding(.top, 12)

                    // Text composer
                    textComposer
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    // Tagged users pills
                    if !viewModel.taggedUserIds.isEmpty {
                        taggedUserPills
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    // Photo placeholder
                    if viewModel.hasPhoto {
                        photoPlaceholder
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    }

                    // Location chip
                    if let loc = viewModel.locationTag {
                        locationChip(loc)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    // Court Review extras
                    if viewModel.selectedPostType == .courtReview {
                        courtReviewExtras
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    }

                    Divider().padding(.top, 12)

                    // Bottom actions row
                    bottomActionsRow
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .sheet(isPresented: $showTagPicker) {
            UserTagPicker(taggedIds: $viewModel.taggedUserIds)
        }
        .sheet(isPresented: $showCourtPicker) {
            courtPickerSheet
        }
        .onChange(of: viewModel.didPost) { _, posted in
            if posted { dismiss() }
        }
    }

    // MARK: - Post Type Chips

    private var postTypeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PostType.allCases, id: \.self) { type in
                    let selected = viewModel.selectedPostType == type
                    Button {
                        withAnimation(.spring(duration: 0.2)) {
                            viewModel.selectedPostType = type
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(type.displayEmoji)
                                .font(.caption)
                            Text(type.displayLabel)
                                .font(.subheadline.weight(selected ? .semibold : .regular))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(selected ? Color.dinkrGreen : Color.cardBackground)
                        )
                        .foregroundStyle(selected ? Color.white : Color.primary)
                        .overlay(
                            Capsule()
                                .stroke(
                                    selected ? Color.clear : Color.secondary.opacity(0.25),
                                    lineWidth: 1
                                )
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
            Text(authorName)
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
    }

    // MARK: - Text Composer

    private var textComposer: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ZStack(alignment: .topLeading) {
                if viewModel.content.isEmpty {
                    Text(viewModel.selectedPostType.placeholder)
                        .foregroundStyle(Color.secondary.opacity(0.55))
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

            let charCount = viewModel.content.count
            Text("\(charCount) / \(maxChars)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(charCount >= warnThreshold ? Color.dinkrCoral : Color.secondary)
                .animation(.easeInOut, value: charCount >= warnThreshold)
        }
    }

    // MARK: - Tagged User Pills

    private var taggedUserPills: some View {
        let allUsers = User.mockPlayers + [User.mockCurrentUser]
        let taggedUsers = viewModel.taggedUserIds.compactMap { id in
            allUsers.first { $0.id == id }
        }

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(taggedUsers) { user in
                    HStack(spacing: 4) {
                        // Avatar initial circle
                        ZStack {
                            Circle()
                                .fill(Color.dinkrGreen)
                                .frame(width: 20, height: 20)
                            Text(String(user.displayName.prefix(1)))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.white)
                        }

                        Text(user.displayName.components(separatedBy: " ").first ?? user.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.primary)

                        Button {
                            withAnimation(.spring(duration: 0.2)) {
                                viewModel.taggedUserIds.removeAll { $0 == user.id }
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.dinkrGreen.opacity(0.1), in: Capsule())
                    .overlay(Capsule().stroke(Color.dinkrGreen.opacity(0.3), lineWidth: 1))
                }
            }
        }
    }

    // MARK: - Photo Placeholder

    private var photoPlaceholder: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 240, height: 160)

                Image(systemName: "photo")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
            .frame(width: 240, height: 160)

            Button {
                withAnimation(.spring(duration: 0.25)) {
                    viewModel.hasPhoto = false
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.55))
                        .frame(width: 26, height: 26)
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white)
                }
            }
            .buttonStyle(.plain)
            .padding(6)
        }
    }

    // MARK: - Location Chip

    private func locationChip(_ location: String) -> some View {
        HStack(spacing: 6) {
            Text("📍")
                .font(.caption)
            Text(location)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.dinkrSky)

            Button {
                withAnimation(.spring(duration: 0.2)) {
                    viewModel.locationTag = nil
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.dinkrSky.opacity(0.1), in: Capsule())
        .overlay(Capsule().stroke(Color.dinkrSky.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Court Review Extras

    private var courtReviewExtras: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Court tag picker
            HStack(spacing: 8) {
                Text("🏟")
                    .font(.subheadline)

                if let court = viewModel.courtTag {
                    HStack(spacing: 6) {
                        Text(court)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.primary)
                        Button {
                            withAnimation {
                                viewModel.courtTag = nil
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.secondary)
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 8))
                } else {
                    Button {
                        showCourtPicker = true
                    } label: {
                        Text("Tag a Court")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.dinkrAmber)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.dinkrAmber.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.dinkrAmber.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Star rating
            HStack(spacing: 4) {
                Text("Rating")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.secondary)

                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            withAnimation(.spring(duration: 0.15)) {
                                viewModel.starRating = star
                            }
                        } label: {
                            Image(systemName: star <= viewModel.starRating ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundStyle(
                                    star <= viewModel.starRating ? Color.dinkrAmber : Color.secondary.opacity(0.4)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Bottom Actions Row

    private var bottomActionsRow: some View {
        HStack(spacing: 16) {
            // Photo button
            Button {
                withAnimation(.spring(duration: 0.25)) {
                    if !viewModel.hasPhoto {
                        viewModel.hasPhoto = true
                    }
                }
            } label: {
                Image(systemName: "camera.fill")
                    .font(.title3)
                    .foregroundStyle(viewModel.hasPhoto ? Color.secondary : Color.dinkrSky)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.hasPhoto)

            // Tag players button
            Button {
                showTagPicker = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "at")
                        .font(.title3)
                    if viewModel.taggedUserIds.isEmpty {
                        Text("Tag players")
                            .font(.subheadline.weight(.medium))
                    } else {
                        Text("Tag players (\(viewModel.taggedUserIds.count))")
                            .font(.subheadline.weight(.medium))
                    }
                }
                .foregroundStyle(Color.dinkrGreen)
            }
            .buttonStyle(.plain)

            // Location button
            Button {
                withAnimation(.spring(duration: 0.2)) {
                    if viewModel.locationTag == nil {
                        viewModel.locationTag = "Austin, TX"
                    }
                }
            } label: {
                Image(systemName: "mappin.circle.fill")
                    .font(.title3)
                    .foregroundStyle(viewModel.locationTag != nil ? Color.secondary : Color.dinkrCoral)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.locationTag != nil)

            Spacer()

            // Post button
            Button {
                Task {
                    await viewModel.submit(
                        authorId: authorId,
                        authorName: authorName,
                        authorAvatarURL: authorAvatarURL
                    )
                }
            } label: {
                ZStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Color.white)
                            .scaleEffect(0.85)
                            .frame(width: 60, height: 34)
                    } else {
                        Text("Post")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.white)
                            .frame(width: 60, height: 34)
                    }
                }
                .background(
                    Capsule()
                        .fill(viewModel.canPost ? Color.dinkrGreen : Color.secondary.opacity(0.3))
                )
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canPost || viewModel.isLoading)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
                .foregroundStyle(Color.primary)
        }
        ToolbarItem(placement: .principal) {
            Text("New Post")
                .font(.headline)
        }
    }

    // MARK: - Court Picker Sheet

    private var courtPickerSheet: some View {
        NavigationStack {
            List(mockCourtNames, id: \.self) { courtName in
                Button {
                    withAnimation {
                        viewModel.courtTag = courtName
                    }
                    showCourtPicker = false
                } label: {
                    HStack {
                        Text("🏟")
                        Text(courtName)
                            .font(.subheadline)
                            .foregroundStyle(Color.primary)
                        Spacer()
                        if viewModel.courtTag == courtName {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.dinkrGreen)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .navigationTitle("Tag a Court")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCourtPicker = false }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CreatePostView(authorId: "preview_user", authorName: "Evan Cruz", authorAvatarURL: nil)
}

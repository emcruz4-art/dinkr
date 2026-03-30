import SwiftUI

// MARK: - Model

struct Highlight: Identifiable {
    var id: String
    var authorName: String
    var authorInitial: String
    var caption: String
    var tags: [String]
    var likeCount: Int
    var commentCount: Int
    var shareCount: Int
    var isLiked: Bool
    var duration: String
    var gradientColors: [Color]
    var shotType: String
}

extension Highlight {
    static let mockHighlights: [Highlight] = [
        Highlight(
            id: "1",
            authorName: "Jordan Rivera",
            authorInitial: "J",
            caption: "Around-the-post from the kitchen line. Still can't believe this went in 🔥",
            tags: ["#atp", "#erne", "#pickleball"],
            likeCount: 2841,
            commentCount: 134,
            shareCount: 88,
            isLiked: false,
            duration: "0:09",
            gradientColors: [Color.dinkrGreen, Color.dinkrNavy],
            shotType: "ATP"
        ),
        Highlight(
            id: "2",
            authorName: "Mia Chen",
            authorInitial: "M",
            caption: "That erne transition out of the kitchen is now in my rotation for good.",
            tags: ["#erne", "#kitchen", "#pro"],
            likeCount: 5123,
            commentCount: 210,
            shareCount: 302,
            isLiked: true,
            duration: "0:12",
            gradientColors: [Color.dinkrCoral, Color.dinkrAmber],
            shotType: "Erne"
        ),
        Highlight(
            id: "3",
            authorName: "Alex Torres",
            authorInitial: "A",
            caption: "21-ball dink rally at 4.5 open play. My arm was gone by ball 15.",
            tags: ["#dinkrally", "#consistency", "#4point5"],
            likeCount: 987,
            commentCount: 62,
            shareCount: 41,
            isLiked: false,
            duration: "0:34",
            gradientColors: [Color.dinkrSky, Color.dinkrGreen],
            shotType: "Dink Rally"
        ),
        Highlight(
            id: "4",
            authorName: "Sam Patel",
            authorInitial: "S",
            caption: "Speed-up from the backhand side, put it right at the hip. They never saw it coming.",
            tags: ["#smash", "#speedup", "#offensive"],
            likeCount: 3304,
            commentCount: 189,
            shareCount: 156,
            isLiked: false,
            duration: "0:07",
            gradientColors: [Color.dinkrAmber, Color.dinkrCoral],
            shotType: "Smash"
        ),
        Highlight(
            id: "5",
            authorName: "Taylor Brooks",
            authorInitial: "T",
            caption: "Third-shot drop into the kitchen — rolled off the tape perfectly.",
            tags: ["#reset", "#thirdshot", "#softgame"],
            likeCount: 1750,
            commentCount: 94,
            shareCount: 73,
            isLiked: true,
            duration: "0:11",
            gradientColors: [Color.dinkrNavy, Color.dinkrSky],
            shotType: "Reset"
        ),
        Highlight(
            id: "6",
            authorName: "Casey Nguyen",
            authorInitial: "C",
            caption: "Partner set it up perfectly and I just had to finish. Best combo of the tournament.",
            tags: ["#atp", "#doubles", "#teamwork"],
            likeCount: 4217,
            commentCount: 278,
            shareCount: 411,
            isLiked: false,
            duration: "0:15",
            gradientColors: [Color(red: 0.55, green: 0.20, blue: 0.80), Color.dinkrCoral],
            shotType: "ATP"
        ),
        Highlight(
            id: "7",
            authorName: "Drew Kim",
            authorInitial: "D",
            caption: "When the lob is perfectly placed and you watch your opponent run it down — and still miss.",
            tags: ["#lob", "#offensive", "#clutch"],
            likeCount: 2090,
            commentCount: 115,
            shareCount: 99,
            isLiked: false,
            duration: "0:08",
            gradientColors: [Color(red: 0.10, green: 0.60, blue: 0.70), Color.dinkrNavy],
            shotType: "Smash"
        ),
        Highlight(
            id: "8",
            authorName: "Riley Shaw",
            authorInitial: "R",
            caption: "Slowest hands at the NVZ but somehow this reset saved the point. Pure luck, I'll take it.",
            tags: ["#reset", "#kitchen", "#beginner"],
            likeCount: 672,
            commentCount: 48,
            shareCount: 29,
            isLiked: true,
            duration: "0:18",
            gradientColors: [Color.dinkrGreen, Color(red: 0.10, green: 0.55, blue: 0.45)],
            shotType: "Reset"
        )
    ]
}

// MARK: - Highlight Reel View

struct HighlightReelView: View {
    @State private var highlights: [Highlight] = Highlight.mockHighlights
    @State private var currentIndex: Int = 0
    @State private var showCreateSheet: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(highlights.enumerated()), id: \.element.id) { index, highlight in
                    HighlightCard(
                        highlight: binding(for: index),
                        isActive: currentIndex == index
                    )
                    .tag(index)
                    .ignoresSafeArea()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Top-right create button
            Button {
                showCreateSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 4)
            }
            .padding(.top, 56)
            .padding(.trailing, 20)
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateHighlightSheet()
        }
    }

    private func binding(for index: Int) -> Binding<Highlight> {
        Binding(
            get: { highlights[index] },
            set: { highlights[index] = $0 }
        )
    }
}

// MARK: - Highlight Card

struct HighlightCard: View {
    @Binding var highlight: Highlight
    var isActive: Bool

    @State private var progress: CGFloat = 0
    @State private var likeScale: CGFloat = 1.0
    @State private var isBookmarked = false
    @State private var showComments = false
    @State private var showShare = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Gradient video placeholder
                LinearGradient(
                    colors: highlight.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Subtle texture overlay
                Rectangle()
                    .fill(.black.opacity(0.10))
                    .ignoresSafeArea()

                // Bottom dark gradient for readability
                LinearGradient(
                    colors: [.clear, .black.opacity(0.70)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Bottom-left text overlay
                VStack(alignment: .leading, spacing: 8) {
                    // Author
                    Text("@\(highlight.authorName.lowercased().replacingOccurrences(of: " ", with: ""))")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)

                    // Caption
                    Text(highlight.caption)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(highlight.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(.white.opacity(0.20), in: Capsule())
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
                .frame(maxWidth: geo.size.width - 80, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Progress bar at very bottom
                VStack {
                    Spacer()
                    GeometryReader { barGeo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(.white.opacity(0.30))
                                .frame(height: 4)
                            Rectangle()
                                .fill(.white)
                                .frame(width: barGeo.size.width * progress, height: 4)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 0)
                    .padding(.bottom, 0)
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .overlay(alignment: .topLeading) {
                // Shot type badge
                HStack(spacing: 4) {
                    Text(shotTypeEmoji(highlight.shotType))
                        .font(.caption)
                    Text(highlight.shotType)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.black.opacity(0.55), in: Capsule())
                .padding(.top, 56)
                .padding(.leading, 16)
            }
            .overlay(alignment: .topTrailing) {
                // Duration badge
                Text(highlight.duration)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.55), in: Capsule())
                    .padding(.top, 56)
                    .padding(.trailing, 60) // offset for + button
            }
            .overlay(alignment: .trailing) {
                // Right-side action column
                rightSideBar
                    .padding(.trailing, 16)
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            if isActive { startProgress() }
        }
        .onChange(of: isActive) { _, active in
            if active {
                progress = 0
                startProgress()
            } else {
                progress = 0
            }
        }
    }

    // MARK: Right Sidebar

    private var rightSideBar: some View {
        VStack(spacing: 24) {
            // Author avatar
            Button {
                HapticManager.selection()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen)
                        .frame(width: 46, height: 46)
                    Text(highlight.authorInitial)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }
                .overlay(
                    Circle()
                        .strokeBorder(.white, lineWidth: 2)
                )
            }

            // Like
            VStack(spacing: 4) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        highlight.isLiked.toggle()
                        likeScale = 1.4
                        highlight.likeCount += highlight.isLiked ? 1 : -1
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            likeScale = 1.0
                        }
                    }
                } label: {
                    Image(systemName: highlight.isLiked ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundStyle(highlight.isLiked ? Color.dinkrCoral : .white)
                        .scaleEffect(likeScale)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
                Text(formatCount(highlight.likeCount))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            }

            // Comment
            VStack(spacing: 4) {
                Button {
                    HapticManager.selection()
                    showComments = true
                } label: {
                    Image(systemName: "bubble.right")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
                Text(formatCount(highlight.commentCount))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            }

            // Share
            VStack(spacing: 4) {
                Button {
                    HapticManager.selection()
                    showShare = true
                } label: {
                    Image(systemName: "arrowshape.turn.up.right")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
                Text(formatCount(highlight.shareCount))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            }

            // Save / Bookmark
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    isBookmarked.toggle()
                }
                HapticManager.medium()
            } label: {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.title2)
                    .foregroundStyle(isBookmarked ? Color.dinkrAmber : .white)
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
        }
        .sheet(isPresented: $showComments) {
            NavigationStack {
                VStack(spacing: 16) {
                    Text("Comments")
                        .font(.headline)
                    Text("Comments coming soon.")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.top, 24)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showComments = false }
                            .foregroundStyle(Color.dinkrGreen)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showShare) {
            NavigationStack {
                VStack(spacing: 16) {
                    Text("Share Highlight")
                        .font(.headline)
                    Text("Sharing coming soon.")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.top, 24)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showShare = false }
                            .foregroundStyle(Color.dinkrGreen)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: Helpers

    private func startProgress() {
        withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
            progress = 1.0
        }
    }

    private func shotTypeEmoji(_ type: String) -> String {
        switch type {
        case "ATP":         return "🎾"
        case "Erne":        return "⚡️"
        case "Dink Rally":  return "🏓"
        case "Smash":       return "💥"
        case "Reset":       return "🧊"
        default:            return "🎯"
        }
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            let k = Double(count) / 1000.0
            return String(format: "%.1fK", k)
        }
        return "\(count)"
    }
}

// MARK: - Create Highlight Sheet

struct CreateHighlightSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let allShotTypes = ["ATP", "Erne", "Dink", "Smash", "Drop Shot", "Lob", "Around-the-Post", "Trick Shot"]
    private let allTags = ["ATP", "Erne", "Dink", "Smash", "Drop Shot", "Lob", "Around-the-Post", "Trick Shot"]

    @State private var selectedShotType: String = "ATP"
    @State private var caption: String = ""
    @State private var selectedTags: Set<String> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // Shot type picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Shot Type")
                            .font(.headline.weight(.semibold))
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(allShotTypes, id: \.self) { shot in
                                    Button {
                                        selectedShotType = shot
                                    } label: {
                                        Text(shot)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(selectedShotType == shot ? .white : Color.dinkrNavy)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                selectedShotType == shot
                                                    ? Color.dinkrGreen
                                                    : Color.cardBackground,
                                                in: Capsule()
                                            )
                                            .overlay(
                                                Capsule()
                                                    .strokeBorder(
                                                        selectedShotType == shot ? Color.clear : Color.dinkrNavy.opacity(0.15),
                                                        lineWidth: 1
                                                    )
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Caption
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Caption")
                            .font(.headline.weight(.semibold))
                            .padding(.horizontal)

                        TextField("What happened on that shot?", text: $caption, axis: .vertical)
                            .font(.subheadline)
                            .lineLimit(3...5)
                            .padding(14)
                            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                    }

                    // Tags
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tags")
                            .font(.headline.weight(.semibold))
                            .padding(.horizontal)

                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 110), spacing: 10)],
                            spacing: 10
                        ) {
                            ForEach(allTags, id: \.self) { tag in
                                Button {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                } label: {
                                    Text("#\(tag.lowercased().replacingOccurrences(of: " ", with: ""))")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(selectedTags.contains(tag) ? .white : Color.dinkrGreen)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            selectedTags.contains(tag)
                                                ? Color.dinkrGreen
                                                : Color.dinkrGreen.opacity(0.10),
                                            in: Capsule()
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Post button
                    Button {
                        dismiss()
                    } label: {
                        Text("Post Highlight")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.dinkrCoral, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .padding(.top, 8)
            }
            .navigationTitle("Share a Highlight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HighlightReelView()
}

import SwiftUI

// MARK: - VideoHighlightsFeedView
// Full-screen TikTok-style vertical-paging feed for VideoHighlight items.
// Simulates playback with gradient cards (no real AVPlayer needed for mock data).

struct VideoHighlightsFeedView: View {
    var initialCategory: VideoCategory = .all

    @State private var selectedCategory: VideoCategory = .all
    @State private var activeVideoId: String? = nil
    @Environment(\.dismiss) private var dismiss

    private var allVideos: [VideoHighlight] { VideoHighlight.mockHighlights }

    private var filteredVideos: [VideoHighlight] {
        selectedCategory == .all
            ? allVideos
            : allVideos.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            // ── Paging vertical scroll ──────────────────────────────
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(filteredVideos) { video in
                        SimulatedVideoCard(
                            video: video,
                            isActive: activeVideoId == video.id
                        )
                        .containerRelativeFrame([.horizontal, .vertical])
                        .onAppear { activeVideoId = video.id }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .ignoresSafeArea()

            // ── Top overlay: close + category filter ───────────────
            VStack(spacing: 0) {
                Color.clear.frame(height: 54)  // safe area buffer

                HStack(spacing: 10) {
                    // Close button
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.45))
                            .clipShape(Circle())
                    }

                    Spacer()

                    // Category filter pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(VideoCategory.allCases) { cat in
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedCategory = cat
                                        activeVideoId = filteredVideos.first?.id
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: cat.icon)
                                            .font(.system(size: 10, weight: .semibold))
                                        Text(cat.rawValue)
                                            .font(.system(size: 12,
                                                          weight: selectedCategory == cat ? .bold : .medium))
                                    }
                                    .foregroundStyle(selectedCategory == cat ? Color.black : Color.white.opacity(0.9))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(selectedCategory == cat ? Color.white : Color.clear)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    .background(Color.black.opacity(0.35))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 14)
            }
        }
        .onAppear {
            selectedCategory = initialCategory
            activeVideoId = filteredVideos.first?.id
        }
    }
}

// MARK: - SimulatedVideoCard

private struct SimulatedVideoCard: View {
    let video: VideoHighlight
    let isActive: Bool

    @State private var isPlaying: Bool = false
    @State private var isLiked: Bool = false
    @State private var likeCount: Int
    @State private var showFloatingHeart = false

    init(video: VideoHighlight, isActive: Bool) {
        self.video = video
        self.isActive = isActive
        _isLiked = State(initialValue: false)
        _likeCount = State(initialValue: video.likes)
    }

    private var gradientColors: [Color] {
        switch video.category {
        case .all:         return [Color.dinkrGreen.opacity(0.55),  Color.dinkrNavy.opacity(0.95)]
        case .highlights:  return [Color.dinkrCoral.opacity(0.55),  Color.dinkrNavy.opacity(0.95)]
        case .tutorials:   return [Color.dinkrSky.opacity(0.55),    Color.dinkrNavy.opacity(0.95)]
        case .tournaments: return [Color.dinkrAmber.opacity(0.55),  Color.dinkrNavy.opacity(0.95)]
        }
    }

    var body: some View {
        ZStack {
            // ── Simulated video background ─────────────────────────
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Category icon watermark
            Image(systemName: categoryWatermarkIcon)
                .font(.system(size: 120, weight: .thin))
                .foregroundStyle(.white.opacity(0.07))
                .offset(x: 60, y: -80)

            // ── Double-tap to like (clear hit area) ─────────────────
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        if !isLiked {
                            isLiked = true
                            likeCount += 1
                            showFloatingHeart = true
                        }
                    }
                    Task {
                        try? await Task.sleep(nanoseconds: 900_000_000)
                        withAnimation { showFloatingHeart = false }
                    }
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.25)) { isPlaying.toggle() }
                }

            // ── Floating heart on double-tap ───────────────────────
            if showFloatingHeart {
                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)
                    .scaleEffect(showFloatingHeart ? 1.0 : 0.1)
                    .opacity(showFloatingHeart ? 1 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: showFloatingHeart)
                    .allowsHitTesting(false)
            }

            // ── Center play/pause button ───────────────────────────
            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .font(.system(size: 64, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
                .shadow(color: .black.opacity(0.4), radius: 6)
                .scaleEffect(isPlaying ? 0.85 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPlaying)
                .allowsHitTesting(false)

            // ── Right action sidebar ───────────────────────────────
            FeedActionsColumn(
                isLiked: $isLiked,
                likeCount: $likeCount,
                commentCount: Int.random(in: 20...300),
                shareCount: Int.random(in: 10...500),
                playerName: video.playerName
            )

            // ── Bottom info overlay ────────────────────────────────
            FeedInfoOverlay(video: video)
        }
        .onChange(of: isActive) { _, active in
            withAnimation(.easeInOut(duration: 0.2)) {
                isPlaying = active
            }
        }
        .onAppear {
            if isActive { isPlaying = true }
        }
        .onDisappear {
            isPlaying = false
        }
    }

    private var categoryWatermarkIcon: String {
        switch video.category {
        case .all:         return "play.rectangle.fill"
        case .highlights:  return "flame.fill"
        case .tutorials:   return "graduationcap.fill"
        case .tournaments: return "trophy.fill"
        }
    }
}

// MARK: - FeedActionsColumn (right sidebar)

private struct FeedActionsColumn: View {
    @Binding var isLiked: Bool
    @Binding var likeCount: Int
    let commentCount: Int
    let shareCount: Int
    let playerName: String

    var body: some View {
        VStack(spacing: 22) {
            Spacer()

            // Creator avatar
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen.opacity(0.75))
                        .frame(width: 50, height: 50)
                    Text(String(playerName.prefix(1)))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }
                .overlay(alignment: .bottom) {
                    ZStack {
                        Circle().fill(Color.dinkrGreen).frame(width: 20, height: 20)
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .offset(y: 10)
                }
                .padding(.bottom, 6)
            }

            // Like button
            FeedActionButton(
                icon: isLiked ? "heart.fill" : "heart",
                count: likeCount,
                color: isLiked ? Color.dinkrCoral : .white
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    isLiked.toggle()
                    likeCount += isLiked ? 1 : -1
                }
            }

            // Comment button
            FeedActionButton(icon: "bubble.left.fill", count: commentCount, color: .white) {}

            // Share button
            FeedActionButton(icon: "square.and.arrow.up", count: shareCount, color: .white) {}
        }
        .padding(.trailing, 14)
        .padding(.bottom, 110)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

private struct FeedActionButton: View {
    let icon: String
    let count: Int
    let color: Color
    let action: () -> Void

    private func label(_ n: Int) -> String {
        n >= 1000 ? String(format: "%.1fK", Double(n) / 1000) : "\(n)"
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(color)
                    .shadow(color: .black.opacity(0.4), radius: 2)
                Text(label(count))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FeedInfoOverlay (bottom)

private struct FeedInfoOverlay: View {
    let video: VideoHighlight

    private var categoryLabel: String {
        switch video.category {
        case .all:         return "▶ Video"
        case .highlights:  return "🔥 Highlight"
        case .tutorials:   return "🎓 Tutorial"
        case .tournaments: return "🏆 Tournament"
        }
    }

    private var categoryColor: Color {
        switch video.category {
        case .all:         return Color.dinkrGreen
        case .highlights:  return Color.dinkrCoral
        case .tutorials:   return Color.dinkrSky
        case .tournaments: return Color.dinkrAmber
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            // Player name + category badge
            HStack(spacing: 8) {
                Text("@\(video.playerName.replacingOccurrences(of: " ", with: "_").lowercased())")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                Text(categoryLabel)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(categoryColor.opacity(0.85))
                    .clipShape(Capsule())
            }

            // Video title
            Text(video.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .shadow(color: .black.opacity(0.5), radius: 2)

            // Court name
            HStack(spacing: 5) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.dinkrGreen)
                Text(video.courtName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
            }

            // Duration + view count
            HStack(spacing: 10) {
                Label(video.duration, systemImage: "clock")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))

                Text("·")
                    .foregroundStyle(.white.opacity(0.5))

                Label(
                    video.viewCount >= 1000
                        ? String(format: "%.1fK views", Double(video.viewCount) / 1000)
                        : "\(video.viewCount) views",
                    systemImage: "eye"
                )
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 90)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.6)],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview {
    VideoHighlightsFeedView(initialCategory: .highlights)
}

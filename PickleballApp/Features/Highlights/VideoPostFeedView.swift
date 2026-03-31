import SwiftUI
import AVKit

// MARK: - Main Feed

struct VideoPostFeedView: View {
    var initialCategory: VideoPostCategory = .all
    @State private var selectedCategory: VideoPostCategory = .all
    @State private var videos: [VideoPost] = VideoPost.mockVideos
    @State private var activeVideoId: String? = nil
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss

    var filteredVideos: [VideoPost] {
        selectedCategory == .all ? videos : videos.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(.white).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Paging video scroll
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredVideos) { video in
                            VideoPlayerCard(
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
            }

            // Top overlay bar
            VStack(spacing: 0) {
                // Safe area buffer
                Color.clear.frame(height: 54)

                HStack(spacing: 10) {
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
                    HStack(spacing: 2) {
                        ForEach(VideoPostCategory.allCases) { cat in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedCategory = cat
                                }
                                Task {
                                    isLoading = true
                                    videos = await VideoService.shared.loadVideos(category: cat)
                                    activeVideoId = filteredVideos.first?.id
                                    isLoading = false
                                }
                            } label: {
                                Text(cat.rawValue)
                                    .font(.system(size: 12, weight: selectedCategory == cat ? .bold : .medium))
                                    .foregroundStyle(selectedCategory == cat ? Color.black : Color.white.opacity(0.85))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(selectedCategory == cat ? Color.white : Color.clear)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
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
        .task {
            videos = await VideoService.shared.loadVideos(category: initialCategory)
            activeVideoId = filteredVideos.first?.id
        }
    }
}

// MARK: - Video Player Card

struct VideoPlayerCard: View {
    let video: VideoPost
    let isActive: Bool

    @State private var player: AVPlayer? = nil
    @State private var isLiked: Bool
    @State private var likeCount: Int
    @State private var showFloatingHeart = false
    @State private var showControls = false

    init(video: VideoPost, isActive: Bool) {
        self.video = video
        self.isActive = isActive
        _isLiked = State(initialValue: video.isLiked)
        _likeCount = State(initialValue: video.likes)
    }

    var body: some View {
        ZStack {
            Color.black

            // Video layer
            if let player {
                AVPlayerLayerView(player: player)
                    .ignoresSafeArea()
            } else {
                // Gradient thumbnail placeholder while player initialises
                VideoThumbnailPlaceholder(category: video.category, title: video.title)
            }

            // Tap to toggle pause / single-tap shows controls
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    // Double-tap: like with floating heart
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
                    withAnimation(.easeInOut(duration: 0.2)) { showControls.toggle() }
                    if showControls {
                        Task {
                            try? await Task.sleep(nanoseconds: 2_500_000_000)
                            withAnimation { showControls = false }
                        }
                    }
                }

            // Floating heart on double-tap
            if showFloatingHeart {
                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)
                    .scaleEffect(showFloatingHeart ? 1 : 0.1)
                    .opacity(showFloatingHeart ? 1 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: showFloatingHeart)
                    .allowsHitTesting(false)
            }

            // Pause icon overlay
            if showControls {
                Image(systemName: player?.timeControlStatus == .playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.4), radius: 4)
                    .allowsHitTesting(false)
                    .onTapGesture {
                        if player?.timeControlStatus == .playing {
                            player?.pause()
                        } else {
                            player?.play()
                        }
                    }
            }

            // Right action column
            VideoActionsColumn(
                isLiked: $isLiked,
                likeCount: $likeCount,
                commentCount: video.commentCount,
                shareCount: video.shareCount,
                creatorName: video.creatorName,
                creatorUsername: video.creatorUsername
            )

            // Bottom info overlay
            VideoInfoOverlay(video: video)
        }
        .onChange(of: isActive) { _, active in
            if active {
                player?.seek(to: .zero)
                player?.play()
            } else {
                player?.pause()
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func setupPlayer() {
        guard let url = URL(string: video.videoURL) else { return }
        let avPlayer = AVPlayer(url: url)
        avPlayer.isMuted = false
        // Loop the video
        NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: avPlayer.currentItem,
            queue: .main
        ) { _ in
            avPlayer.seek(to: .zero)
            if isActive { avPlayer.play() }
        }
        player = avPlayer
        if isActive { avPlayer.play() }
    }
}

// MARK: - AVPlayer UIViewRepresentable (no native controls)

struct AVPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        PlayerUIView(player: player)
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.setPlayer(player)
    }
}

final class PlayerUIView: UIView {
    private var playerLayer: AVPlayerLayer

    init(player: AVPlayer) {
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        super.init(frame: .zero)
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    func setPlayer(_ player: AVPlayer) {
        playerLayer.player = player
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

// MARK: - Gradient thumbnail placeholder

private struct VideoThumbnailPlaceholder: View {
    let category: VideoPostCategory
    let title: String

    private var gradientColors: [Color] {
        category == .drills
            ? [Color.dinkrGreen.opacity(0.7), Color.dinkrNavy]
            : [Color.dinkrCoral.opacity(0.7), Color.dinkrNavy]
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)

            VStack(spacing: 16) {
                Image(systemName: category == .drills ? "figure.pickleball" : "trophy.fill")
                    .font(.system(size: 64, weight: .thin))
                    .foregroundStyle(.white.opacity(0.6))

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
}

// MARK: - Right action column

private struct VideoActionsColumn: View {
    @Binding var isLiked: Bool
    @Binding var likeCount: Int
    let commentCount: Int
    let shareCount: Int
    let creatorName: String
    let creatorUsername: String

    var body: some View {
        VStack(spacing: 22) {
            Spacer()

            // Creator avatar
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen.opacity(0.7))
                        .frame(width: 48, height: 48)
                    Text(String(creatorName.prefix(1)))
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

            // Like
            VideoActionButton(
                icon: isLiked ? "heart.fill" : "heart",
                count: likeCount,
                color: isLiked ? .red : .white
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    isLiked.toggle()
                    likeCount += isLiked ? 1 : -1
                }
            }

            // Comment
            VideoActionButton(icon: "bubble.left.fill", count: commentCount, color: .white) {}

            // Share
            VideoActionButton(icon: "square.and.arrow.up", count: shareCount, color: .white) {}
        }
        .padding(.trailing, 14)
        .padding(.bottom, 110)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

private struct VideoActionButton: View {
    let icon: String
    let count: Int
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(color)
                    .shadow(color: .black.opacity(0.4), radius: 2)
                Text(count >= 1000 ? String(format: "%.1fK", Double(count) / 1000) : "\(count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bottom info overlay

private struct VideoInfoOverlay: View {
    let video: VideoPost

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Creator name
            HStack(spacing: 6) {
                Text("@\(video.creatorUsername)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)

                // Category pill
                Text(video.category == .drills ? "🎯 Drill" : "🔥 Highlight")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(video.category == .drills
                        ? Color.dinkrGreen.opacity(0.8)
                        : Color.dinkrCoral.opacity(0.8))
                    .clipShape(Capsule())
            }

            // Title
            Text(video.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .shadow(color: .black.opacity(0.5), radius: 2)

            // Hashtags
            Text(video.hashtags.map { "#\($0)" }.joined(separator: " "))
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .shadow(color: .black.opacity(0.5), radius: 2)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 90)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        // Gradient scrim behind text
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.55)],
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
    VideoPostFeedView()
}

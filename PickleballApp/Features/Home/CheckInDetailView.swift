import SwiftUI

// MARK: - CheckInStory Model

struct CheckInStory: Identifiable {
    var id: String
    var playerName: String
    var courtName: String
    var format: GameFormat
    var skillLevel: SkillLevel
    var caption: String?
    var status: String
    var date: Date
}

extension CheckInStory {
    static let mock: [CheckInStory] = [
        CheckInStory(
            id: "s1",
            playerName: "Maria Chen",
            courtName: "Westside Courts",
            format: .doubles,
            skillLevel: .intermediate35,
            caption: "Best morning session all week! 🎉",
            status: "🔥 Playing today!",
            date: Date().addingTimeInterval(-7200)
        ),
        CheckInStory(
            id: "s2",
            playerName: "Jordan Blake",
            courtName: "Mueller Park",
            format: .mixed,
            skillLevel: .advanced40,
            caption: nil,
            status: "🔥 Playing today!",
            date: Date().addingTimeInterval(-4320)
        ),
        CheckInStory(
            id: "s3",
            playerName: "Jamie Torres",
            courtName: "Barton Springs",
            format: .openPlay,
            skillLevel: .intermediate30,
            caption: "Open slots available, come join!",
            status: "Looking for players 👀",
            date: Date().addingTimeInterval(-1680)
        ),
        CheckInStory(
            id: "s4",
            playerName: "Sarah Kim",
            courtName: "South Lamar",
            format: .singles,
            skillLevel: .advanced45,
            caption: "Trying to sharpen my third shot drop.",
            status: "🔥 Playing today!",
            date: Date().addingTimeInterval(-2700)
        ),
        CheckInStory(
            id: "s5",
            playerName: "Riley Nguyen",
            courtName: "Zilker Park",
            format: .round_robin,
            skillLevel: .beginner25,
            caption: nil,
            status: "Just warming up 🌞",
            date: Date().addingTimeInterval(-900)
        )
    ]
}

// MARK: - CheckInDetailView

struct CheckInDetailView: View {
    let stories: [CheckInStory]
    var startIndex: Int = 0

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var progress: CGFloat = 0
    @State private var timer: Timer? = nil
    @State private var replyText: String = ""
    @State private var showDirectMessage = false
    @State private var pendingReaction: String? = nil

    private let storyDuration: Double = 5.0

    init(stories: [CheckInStory], startIndex: Int = 0) {
        self.stories = stories
        self.startIndex = startIndex
        _currentIndex = State(initialValue: startIndex)
    }

    var currentStory: CheckInStory { stories[currentIndex] }

    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()

            // Story card area
            VStack(spacing: 0) {
                // Progress bars + close button
                VStack(spacing: 10) {
                    // Progress bars row
                    HStack(spacing: 4) {
                        ForEach(stories.indices, id: \.self) { index in
                            ProgressBarSegment(
                                isCurrent: index == currentIndex,
                                isCompleted: index < currentIndex,
                                progress: index == currentIndex ? progress : 0
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // Close button row
                    HStack {
                        Spacer()
                        Button {
                            HapticManager.selection()
                            stopTimer()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 16)
                    }
                }

                Spacer()

                // Central check-in card
                CheckInStoryCard(story: currentStory)
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                    .id(currentStory.id)

                Spacer()

                // Reaction + reply bar
                reactionBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
            }

            // Tap navigation overlay (left/right halves)
            HStack(spacing: 0) {
                // Left half — previous
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticManager.selection()
                        goToPrevious()
                    }

                // Right half — next
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticManager.selection()
                        goToNext()
                    }
            }
            .ignoresSafeArea()
        }
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.height > 80 {
                        stopTimer()
                        dismiss()
                    }
                }
        )
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
        .fullScreenCover(isPresented: $showDirectMessage) {
            DirectMessageView(
                conversationId: currentStory.id,
                otherUserName: currentStory.playerName,
                otherUserInitial: String(currentStory.playerName.prefix(1)),
                isOnline: false
            )
        }
    }

    // MARK: - Reaction Bar

    private var reactionBar: some View {
        VStack(spacing: 12) {
            // Reaction emoji buttons
            HStack(spacing: 20) {
                ForEach(["❤️", "🎾", "🔥"], id: \.self) { emoji in
                    Button {
                        HapticManager.medium()
                        pendingReaction = emoji
                        stopTimer()
                        showDirectMessage = true
                    } label: {
                        Text(emoji)
                            .font(.system(size: 28))
                            .frame(width: 52, height: 52)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            // Reply text input
            HStack(spacing: 10) {
                TextField("Reply...", text: $replyText)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .tint(Color.dinkrGreen)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
                    .onTapGesture {
                        stopTimer()
                    }

                if !replyText.isEmpty {
                    Button {
                        HapticManager.success()
                        stopTimer()
                        showDirectMessage = true
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Timer Logic

    private func startTimer() {
        progress = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            let increment = 0.05 / storyDuration
            if progress < 1.0 {
                progress += increment
            } else {
                goToNext()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func goToNext() {
        stopTimer()
        if currentIndex < stories.count - 1 {
            currentIndex += 1
            startTimer()
        } else {
            dismiss()
        }
    }

    private func goToPrevious() {
        stopTimer()
        if currentIndex > 0 {
            currentIndex -= 1
        }
        startTimer()
    }
}

// MARK: - Progress Bar Segment

private struct ProgressBarSegment: View {
    let isCurrent: Bool
    let isCompleted: Bool
    let progress: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(height: 3)

                if isCompleted {
                    Capsule()
                        .fill(Color.white)
                        .frame(height: 3)
                } else if isCurrent {
                    Capsule()
                        .fill(Color.white)
                        .frame(width: geo.size.width * progress, height: 3)
                }
            }
        }
        .frame(height: 3)
    }
}

// MARK: - CheckInStoryCard

private struct CheckInStoryCard: View {
    let story: CheckInStory

    var body: some View {
        VStack(spacing: 18) {
            // Avatar + Name
            VStack(spacing: 10) {
                AvatarView(urlString: nil, displayName: story.playerName, size: 80)

                Text(story.playerName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.dinkrNavy)
            }

            // Court + Location
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(Color.dinkrCoral)
                        .font(.subheadline)
                    Text(story.courtName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)
                }
                Text("📍 Austin, TX")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Time ago chip
            Text(story.date.timeAgoShort)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.dinkrNavy.opacity(0.75))
                .clipShape(Capsule())

            // Format + Skill badges
            HStack(spacing: 8) {
                BadgeChip(text: story.format.displayName, color: Color.dinkrSky)
                BadgeChip(text: story.skillLevel.label, color: skillColor(story.skillLevel))
            }

            // Optional caption
            if let caption = story.caption {
                Text("\u{201C}\(caption)\u{201D}")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 8)
            }

            // Status
            Text(story.status)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.dinkrCoral)
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 8)
    }

    private func skillColor(_ level: SkillLevel) -> Color {
        switch level.color {
        case "green":  return Color.dinkrGreen
        case "blue":   return Color.dinkrSky
        case "orange": return Color.dinkrAmber
        case "red":    return Color.dinkrCoral
        default:       return Color.dinkrGreen
        }
    }
}

// MARK: - BadgeChip

private struct BadgeChip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.35), lineWidth: 1)
            )
    }
}

// MARK: - GameFormat Display Name

private extension GameFormat {
    var displayName: String {
        switch self {
        case .singles:      return "Singles"
        case .doubles:      return "Doubles"
        case .mixed:        return "Mixed"
        case .openPlay:     return "Open Play"
        case .round_robin:  return "Round Robin"
        }
    }
}

// MARK: - Date Time Ago Helper

private extension Date {
    var timeAgoShort: String {
        let seconds = Int(Date().timeIntervalSince(self))
        if seconds < 60 { return "just now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        return "\(hours / 24)d ago"
    }
}

// MARK: - Preview

#Preview {
    CheckInDetailView(stories: CheckInStory.mock, startIndex: 0)
}

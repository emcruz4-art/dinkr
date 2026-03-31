import SwiftUI

// MARK: - OpenPlayQueueView

struct OpenPlayQueueView: View {
    let courtName: String

    @State private var isInQueue: Bool = true
    @Environment(\.dismiss) private var dismiss

    private let totalCapacity = 20
    private let currentCount = 14
    private let userQueuePosition = 4
    private let estimatedWaitMinutes = 20

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        courtHeaderSection
                        positionBanner
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        VStack(spacing: 20) {
                            rotationInfoCard
                            queueListSection
                            activeCourtsSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                }

                // Floating join/leave button pinned to bottom
                VStack {
                    Spacer()
                    queueToggleButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                        .background(
                            LinearGradient(
                                colors: [Color.appBackground.opacity(0), Color.appBackground],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 110)
                            .allowsHitTesting(false),
                            alignment: .bottom
                        )
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
    }

    // MARK: - Court Header

    private var courtHeaderSection: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color.dinkrNavy, Color.dinkrNavy.opacity(0.80)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 170)

            // Court line decoration
            Canvas { ctx, size in
                var path = Path()
                let w = size.width
                let h = size.height
                path.move(to: CGPoint(x: 20, y: h * 0.4))
                path.addLine(to: CGPoint(x: w - 20, y: h * 0.4))
                path.move(to: CGPoint(x: w / 2, y: h * 0.4))
                path.addLine(to: CGPoint(x: w / 2, y: h * 0.9))
                path.move(to: CGPoint(x: 20, y: h * 0.4))
                path.addLine(to: CGPoint(x: 20, y: h * 0.9))
                path.move(to: CGPoint(x: w - 20, y: h * 0.4))
                path.addLine(to: CGPoint(x: w - 20, y: h * 0.9))
                ctx.stroke(path, with: .color(.white.opacity(0.06)), lineWidth: 1.5)
            }
            .frame(height: 170)
            .allowsHitTesting(false)

            VStack(spacing: 6) {
                // Live badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.dinkrGreen)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.dinkrGreen.opacity(0.35), lineWidth: 4)
                        )
                    Text("Open Play in Progress")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.dinkrGreen)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.dinkrGreen.opacity(0.12), in: Capsule())
                .overlay(Capsule().stroke(Color.dinkrGreen.opacity(0.3), lineWidth: 1))

                Text(courtName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                // Participant count
                HStack(spacing: 5) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.dinkrAmber)
                    Text("\(currentCount) / \(totalCapacity) players")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }

                // Capacity bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.dinkrAmber)
                            .frame(
                                width: geo.size.width * CGFloat(currentCount) / CGFloat(totalCapacity),
                                height: 5
                            )
                    }
                }
                .frame(height: 5)
                .padding(.horizontal, 40)
                .padding(.top, 2)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Position Banner

    private var positionBanner: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.dinkrAmber.opacity(0.2))
                    .frame(width: 36, height: 36)
                Text("#\(userQueuePosition)")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Color.dinkrAmber)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("You're #\(userQueuePosition) in line")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.dinkrAmber)
                Text("~\(estimatedWaitMinutes) min estimated wait")
                    .font(.caption)
                    .foregroundStyle(Color.dinkrAmber.opacity(0.8))
            }

            Spacer()

            Image(systemName: "timer")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.dinkrAmber)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.dinkrAmber.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.dinkrAmber.opacity(0.4), lineWidth: 1.5)
                )
        )
    }

    // MARK: - Rotation Info Card

    private var rotationInfoCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.dinkrSky.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.dinkrSky)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Rotation System")
                    .font(.subheadline.weight(.semibold))
                Text("Courts rotate every 15 min · Winners stay, losers rotate out · Next group enters from queue")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Queue List

    private var queueListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader("Queue", icon: "list.number")
                Spacer()
                Text("\(mockQueuePlayers.count) waiting")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 6) {
                ForEach(mockQueuePlayers) { entry in
                    QueuePlayerRow(entry: entry, isCurrentUser: entry.position == userQueuePosition)
                }
            }
        }
        .padding(14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Active Courts

    private var activeCourtsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Active Courts", icon: "sportscourt.fill")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(mockActiveCourts) { court in
                    ActiveCourtCard(court: court)
                }
            }
        }
        .padding(14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Queue Toggle Button

    private var queueToggleButton: some View {
        Button {
            HapticManager.light()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isInQueue.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isInQueue ? "minus.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                Text(isInQueue ? "Leave Queue" : "Join Queue")
                    .font(.headline.weight(.bold))
            }
            .foregroundStyle(isInQueue ? Color.dinkrCoral : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Group {
                    if isInQueue {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.dinkrCoral, lineWidth: 2)
                            .background(Color.dinkrCoral.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.82)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
            )
            .shadow(
                color: isInQueue ? Color.clear : Color.dinkrGreen.opacity(0.35),
                radius: 10, x: 0, y: 5
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section Header Helper

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.dinkrGreen)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.4)
        }
    }

    // MARK: - Mock Data

    private var mockQueuePlayers: [QueueEntry] {
        [
            QueueEntry(id: "q1", position: 1, displayName: "Maria Chen", skillLevel: .intermediate35, avatarURL: nil),
            QueueEntry(id: "q2", position: 2, displayName: "Jordan Smith", skillLevel: .advanced40, avatarURL: nil),
            QueueEntry(id: "q3", position: 3, displayName: "Riley Torres", skillLevel: .intermediate35, avatarURL: nil),
            QueueEntry(id: "q4", position: 4, displayName: "Alex Rivera", skillLevel: .intermediate35, avatarURL: nil),
            QueueEntry(id: "q5", position: 5, displayName: "Taylor Kim", skillLevel: .intermediate30, avatarURL: nil),
            QueueEntry(id: "q6", position: 6, displayName: "Sam Nguyen", skillLevel: .advanced40, avatarURL: nil),
            QueueEntry(id: "q7", position: 7, displayName: "Casey Torres", skillLevel: .intermediate35, avatarURL: nil),
            QueueEntry(id: "q8", position: 8, displayName: "Morgan Davis", skillLevel: .intermediate30, avatarURL: nil),
        ]
    }

    private var mockActiveCourts: [ActiveCourt] {
        [
            ActiveCourt(id: "c1", number: 1, players: ["Alex", "Maria", "Jordan", "Sam"], minutesLeft: 7),
            ActiveCourt(id: "c2", number: 2, players: ["Riley", "Chris", "Taylor", "Jamie"], minutesLeft: 12),
            ActiveCourt(id: "c3", number: 3, players: ["Morgan", "Drew", "Casey", "Lee"], minutesLeft: 3),
            ActiveCourt(id: "c4", number: 4, players: ["Pat", "Quinn", "Blair", "Avery"], minutesLeft: 10),
        ]
    }
}

// MARK: - QueuePlayerRow

private struct QueuePlayerRow: View {
    let entry: QueueEntry
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Position number
            ZStack {
                Circle()
                    .fill(isCurrentUser ? Color.dinkrAmber : Color.secondary.opacity(0.1))
                    .frame(width: 28, height: 28)
                Text("\(entry.position)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isCurrentUser ? Color.dinkrNavy : Color.secondary)
            }

            AvatarView(urlString: entry.avatarURL, displayName: entry.displayName, size: 36)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isCurrentUser ? Color.dinkrAmber : Color.primary)
                    if isCurrentUser {
                        Text("You")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.dinkrAmber)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.dinkrAmber.opacity(0.15), in: Capsule())
                    }
                }
                SkillBadge(level: entry.skillLevel, compact: true)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentUser ? Color.dinkrAmber.opacity(0.07) : Color.appBackground)
                .overlay(
                    Group {
                        if isCurrentUser {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.dinkrAmber.opacity(0.35), lineWidth: 1)
                        }
                    }
                )
        )
    }
}

// MARK: - ActiveCourtCard

private struct ActiveCourtCard: View {
    let court: ActiveCourt

    private var urgencyColor: Color {
        court.minutesLeft <= 4 ? Color.dinkrCoral : court.minutesLeft <= 8 ? Color.dinkrAmber : Color.dinkrGreen
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Court \(court.number)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dinkrNavy)

                Spacer()

                // Timer pill
                HStack(spacing: 3) {
                    Image(systemName: "timer")
                        .font(.system(size: 9, weight: .semibold))
                    Text("\(court.minutesLeft)m")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(urgencyColor)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(urgencyColor.opacity(0.12), in: Capsule())
            }

            // Player avatars
            HStack(spacing: -6) {
                ForEach(court.players.prefix(4), id: \.self) { name in
                    AvatarView(displayName: name, size: 28)
                        .overlay(Circle().stroke(Color.cardBackground, lineWidth: 1.5))
                }
            }

            Text(court.players.joined(separator: ", "))
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Supporting Models

private struct QueueEntry: Identifiable {
    let id: String
    let position: Int
    let displayName: String
    let skillLevel: SkillLevel
    let avatarURL: String?
}

private struct ActiveCourt: Identifiable {
    let id: String
    let number: Int
    let players: [String]
    let minutesLeft: Int
}

// MARK: - Preview

#Preview {
    OpenPlayQueueView(courtName: "Westside Pickleball Complex")
}

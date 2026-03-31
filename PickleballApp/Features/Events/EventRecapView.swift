import SwiftUI

// MARK: - Data Models

struct RecapParticipant: Identifiable {
    let id: String
    let rank: Int
    let displayName: String
    let wins: Int
    let losses: Int
    let pointDifferential: Int
    let isMVP: Bool
}

// MARK: - EventRecapView

struct EventRecapView: View {
    let event: Event

    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var shareText = ""

    // Mock data
    private let participants: [RecapParticipant] = [
        RecapParticipant(id: "p1", rank: 1, displayName: "Jordan Lee",    wins: 6, losses: 0, pointDifferential: +42, isMVP: true),
        RecapParticipant(id: "p2", rank: 2, displayName: "Alex Rivera",   wins: 5, losses: 1, pointDifferential: +28, isMVP: false),
        RecapParticipant(id: "p3", rank: 3, displayName: "Morgan Chen",   wins: 4, losses: 2, pointDifferential: +15, isMVP: false),
        RecapParticipant(id: "p4", rank: 4, displayName: "Sam Torres",    wins: 3, losses: 3, pointDifferential: -2,  isMVP: false),
        RecapParticipant(id: "p5", rank: 5, displayName: "Casey Park",    wins: 2, losses: 4, pointDifferential: -19, isMVP: false),
        RecapParticipant(id: "p6", rank: 6, displayName: "Dana Kim",      wins: 1, losses: 5, pointDifferential: -30, isMVP: false),
        RecapParticipant(id: "p7", rank: 7, displayName: "Riley Nguyen",  wins: 0, losses: 6, pointDifferential: -34, isMVP: false),
    ]

    private var mvpPlayer: RecapParticipant? {
        participants.first(where: \.isMVP)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Trophy Header
                trophyHeader

                VStack(spacing: 24) {
                    // Podium Section
                    podiumSection

                    // MVP Section
                    if let mvp = mvpPlayer {
                        mvpSection(player: mvp)
                    }

                    // Full Results Table
                    resultsTableSection

                    // Photo Highlights
                    photoHighlightsSection

                    // Action Buttons
                    actionButtonsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 48)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Event Recap")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ActivityShareSheet(items: [shareText])
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Trophy Header

    private var trophyHeader: some View {
        ZStack {
            LinearGradient(
                colors: [Color.dinkrNavy, Color.dinkrNavy.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.dinkrAmber.opacity(0.2))
                        .frame(width: 80, height: 80)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(Color.dinkrAmber)
                }

                Text(event.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text(event.dateTime.formatted(.dateTime.month(.wide).day().year()))
                    .font(.subheadline)
                    .foregroundStyle(Color.dinkrGreen)
            }
            .padding(.vertical, 36)
        }
    }

    // MARK: - Podium

    private var podiumSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Podium", icon: "medal.fill", color: Color.dinkrAmber)

            HStack(alignment: .bottom, spacing: 12) {
                // 2nd place
                if participants.count > 1 {
                    podiumCard(participant: participants[1], height: 110)
                }

                // 1st place (center, tallest)
                if participants.count > 0 {
                    podiumCard(participant: participants[0], height: 140)
                }

                // 3rd place
                if participants.count > 2 {
                    podiumCard(participant: participants[2], height: 90)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func podiumCard(participant: RecapParticipant, height: CGFloat) -> some View {
        let (medalIcon, medalColor): (String, Color) = {
            switch participant.rank {
            case 1: return ("medal.fill", Color.dinkrAmber)
            case 2: return ("medal.fill", Color(white: 0.75))
            default: return ("medal.fill", Color(red: 0.8, green: 0.5, blue: 0.2))
            }
        }()

        VStack(spacing: 8) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(medalColor.opacity(0.15))
                    .frame(width: 52, height: 52)
                Text(participant.displayName.prefix(1))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(medalColor)
            }
            .overlay(
                Circle().strokeBorder(medalColor, lineWidth: 2)
            )

            Text(participant.displayName.components(separatedBy: " ").first ?? participant.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            HStack(spacing: 2) {
                Image(systemName: medalIcon)
                    .font(.system(size: 9))
                    .foregroundStyle(medalColor)
                Text("\(participant.wins)W-\(participant.losses)L")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // Podium block
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(medalColor.opacity(0.18))
                    .frame(height: height)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(medalColor.opacity(0.4), lineWidth: 1)
                    )

                Text("\(participant.rank)")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(medalColor)
                    .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - MVP Section

    @ViewBuilder
    private func mvpSection(player: RecapParticipant) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Player of the Tournament", icon: "star.fill", color: Color.dinkrAmber)

            HStack(spacing: 16) {
                // Gold badge avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.dinkrAmber, Color.dinkrAmber.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)
                    Text(player.displayName.prefix(1))
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(Color.dinkrNavy)
                }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.dinkrAmber)
                        .background(Color.appBackground, in: Circle())
                        .offset(x: 4, y: 4)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(player.displayName)
                        .font(.headline)

                    HStack(spacing: 8) {
                        RecapStatPill(value: "\(player.wins)W", color: Color.dinkrGreen)
                        RecapStatPill(value: "\(player.losses)L", color: Color.dinkrCoral)
                        RecapStatPill(value: "+\(player.pointDifferential) pts", color: Color.dinkrAmber)
                    }

                    Text("Undefeated. Dominant performance throughout the bracket.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.dinkrAmber.opacity(0.12), Color.dinkrAmber.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.dinkrAmber.opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
    }

    // MARK: - Results Table

    private var resultsTableSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Full Results", icon: "list.number", color: Color.dinkrSky)

            VStack(spacing: 0) {
                // Header row
                HStack(spacing: 0) {
                    Text("#")
                        .frame(width: 32, alignment: .center)
                    Text("Player")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("W-L")
                        .frame(width: 48, alignment: .center)
                    Text("+/-")
                        .frame(width: 48, alignment: .trailing)
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.cardBackground)
                .clipShape(.rect(topLeadingRadius: 12, topTrailingRadius: 12))

                Divider()

                ForEach(Array(participants.enumerated()), id: \.element.id) { index, player in
                    ResultRow(
                        participant: player,
                        isLast: index == participants.count - 1
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }

    // MARK: - Photo Highlights

    private var photoHighlightsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Highlights", icon: "camera.fill", color: Color.dinkrSky)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(photoHighlightData, id: \.0) { item in
                        PhotoHighlightCard(
                            label: item.1,
                            gradient: item.2
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var photoHighlightData: [(String, String, [Color])] {
        [
            ("h1", "Opening Rally",    [Color.dinkrGreen,   Color.dinkrSky]),
            ("h2", "Match Point",      [Color.dinkrCoral,   Color.dinkrAmber]),
            ("h3", "Crowd Energy",     [Color.dinkrNavy,    Color.dinkrSky]),
            ("h4", "Trophy Moment",    [Color.dinkrAmber,   Color.dinkrCoral]),
            ("h5", "DinkrGroup Photo",      [Color.dinkrSky,     Color.dinkrGreen]),
            ("h6", "Net Celebrations", [Color.dinkrGreen,   Color.dinkrNavy]),
        ]
    }

    // MARK: - Action Buttons

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Share Results
            Button {
                shareText = buildShareText()
                showShareSheet = true
            } label: {
                Label("Share Results", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 14))
            }

            // Play Again
            NavigationLink {
                EventsView()
            } label: {
                Label("Play Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundStyle(Color.dinkrNavy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.dinkrAmber)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func buildShareText() -> String {
        guard let winner = participants.first else { return "" }
        let dateStr = event.dateTime.formatted(.dateTime.month().day().year())
        var lines = [
            "🏆 \(event.title) — Recap",
            "📅 \(dateStr)",
            "",
            "Podium:"
        ]
        for p in participants.prefix(3) {
            let medal = ["🥇","🥈","🥉"][safe: p.rank - 1] ?? "🏅"
            lines.append("\(medal) \(p.displayName) — \(p.wins)W / \(p.losses)L")
        }
        lines += [
            "",
            "MVP: \(winner.displayName) 🌟",
            "",
            "See you on the courts! 🎾 — via Dinkr"
        ]
        return lines.joined(separator: "\n")
    }

    @ViewBuilder
    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
        }
    }
}

// MARK: - ResultRow

private struct ResultRow: View {
    let participant: RecapParticipant
    let isLast: Bool

    private var diffColor: Color {
        participant.pointDifferential >= 0 ? Color.dinkrGreen : Color.dinkrCoral
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Rank
                ZStack {
                    if participant.rank <= 3 {
                        let c: Color = participant.rank == 1 ? Color.dinkrAmber
                            : participant.rank == 2 ? Color(white: 0.7) : Color(red: 0.8, green: 0.5, blue: 0.2)
                        Circle()
                            .fill(c.opacity(0.15))
                            .frame(width: 22, height: 22)
                    }
                    Text("\(participant.rank)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(participant.rank <= 3 ? Color.dinkrAmber : .secondary)
                }
                .frame(width: 32, alignment: .center)

                // Name + MVP badge
                HStack(spacing: 6) {
                    Text(participant.displayName)
                        .font(.subheadline.weight(participant.isMVP ? .semibold : .regular))
                        .foregroundStyle(.primary)

                    if participant.isMVP {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.dinkrAmber)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // W-L
                Text("\(participant.wins)-\(participant.losses)")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.primary)
                    .frame(width: 48, alignment: .center)

                // Point differential
                Text(participant.pointDifferential >= 0 ? "+\(participant.pointDifferential)" : "\(participant.pointDifferential)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(diffColor)
                    .frame(width: 48, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.cardBackground)

            if !isLast {
                Divider()
                    .padding(.leading, 44)
            }
        }
    }
}

// MARK: - PhotoHighlightCard

private struct PhotoHighlightCard: View {
    let label: String
    let gradient: [Color]

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Simulated photo grain texture
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.0), Color.black.opacity(0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "camera.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(10)
        }
        .frame(width: 150, height: 105)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: gradient[0].opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - StatPill

private struct RecapStatPill: View {
    let value: String
    let color: Color

    var body: some View {
        Text(value)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
    }
}

// MARK: - Array safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EventRecapView(event: Event.mockEvents[0])
    }
}

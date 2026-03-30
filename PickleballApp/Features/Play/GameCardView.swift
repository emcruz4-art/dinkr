import SwiftUI

struct GameCardView: View {
    let session: GameSession
    @State private var isPressed = false

    // MARK: - Computed helpers

    var countdownText: String {
        let diff = session.dateTime.timeIntervalSinceNow
        if diff < 0 { return "Started" }
        if diff < 3600 { return "In \(Int(diff/60))m" }
        if diff < 86400 {
            return "In \(Int(diff/3600))h \(Int((diff.truncatingRemainder(dividingBy: 3600))/60))m"
        }
        return session.dateTime.formatted(.dateTime.weekday(.short).hour().minute())
    }

    var isUrgent: Bool {
        session.dateTime.timeIntervalSinceNow < 3600
    }

    /// Top gradient strip colors by game format.
    var formatAccentColors: [Color] {
        switch session.format {
        case .doubles:     return [Color.dinkrGreen, Color.dinkrGreen.opacity(0.55)]
        case .singles:     return [Color.dinkrSky,   Color.dinkrSky.opacity(0.55)]
        case .openPlay:    return [Color.dinkrAmber,  Color.dinkrAmber.opacity(0.55)]
        case .mixed:       return [Color.dinkrCoral,  Color.dinkrCoral.opacity(0.55)]
        case .round_robin: return [Color.dinkrNavy,   Color.dinkrSky.opacity(0.65)]
        }
    }

    var skillPillColor: Color {
        switch session.skillRange.lowerBound {
        case .beginner20, .beginner25:         return Color.dinkrGreen
        case .intermediate30, .intermediate35: return Color.dinkrSky
        case .advanced40, .advanced45:         return Color.dinkrCoral
        case .pro50:                            return Color.dinkrNavy
        }
    }

    var fillRatio: Double {
        guard session.totalSpots > 0 else { return 0 }
        return Double(session.rsvps.count) / Double(session.totalSpots)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Hero accent strip ──────────────────────────────────────────
            LinearGradient(
                colors: formatAccentColors,
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 6)
            .clipShape(
                .rect(
                    topLeadingRadius: 18,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 18
                )
            )

            // ── Card body ─────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 12) {

                // Row 1: Court name + countdown badge
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(session.courtName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(
                            session.dateTime.formatted(
                                .dateTime.weekday(.short)
                                         .month(.abbreviated)
                                         .day()
                                         .hour()
                                         .minute()
                            )
                        )
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()

                    // Countdown pill — coral if urgent, green otherwise
                    Text(countdownText)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(isUrgent ? Color.dinkrCoral : Color.dinkrGreen)
                        .clipShape(Capsule())
                }

                // Row 2: Format label + skill range pills
                HStack(spacing: 6) {
                    Text(session.format.rawValue.capitalized)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(formatAccentColors[0])
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(formatAccentColors[0].opacity(0.12))
                        .clipShape(Capsule())

                    Text(
                        "\(session.skillRange.lowerBound.label) – \(session.skillRange.upperBound.label)"
                    )
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(skillPillColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(skillPillColor.opacity(0.12))
                    .clipShape(Capsule())

                    Spacer()
                }

                // Row 3: Host avatar + name + star rating | fee badge
                HStack(spacing: 8) {
                    AvatarView(displayName: session.hostName, size: 24)

                    Text(session.hostName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)

                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.dinkrAmber)
                        Text("4.8")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.dinkrAmber)
                    }

                    Spacer()

                    // Fee badge — amber pill for paid, subtle green for free
                    if let fee = session.fee {
                        Text(fee == 0 ? "Free" : "$\(Int(fee))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(fee == 0 ? Color.dinkrGreen : .white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                fee == 0
                                    ? Color.dinkrGreen.opacity(0.15)
                                    : Color.dinkrAmber
                            )
                            .clipShape(Capsule())
                    }
                }

                // Row 4: Notes (optional, truncated)
                if !session.notes.isEmpty {
                    Text(session.notes)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Row 5: Spot progress bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(session.rsvps.count) / \(session.totalSpots) spots")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(
                            "\(session.spotsRemaining) left"
                        )
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(
                            session.spotsRemaining <= 1 ? Color.dinkrCoral : .secondary
                        )
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.dinkrGreen.opacity(0.15))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(session.isFull ? Color.dinkrCoral : Color.dinkrGreen)
                                .frame(width: geo.size.width * fillRatio)
                        }
                    }
                    .frame(height: 4)
                }
            }
            .padding(14)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(
            color: formatAccentColors[0].opacity(0.18),
            radius: 10, x: 0, y: 4
        )
        // Scale-on-press spring animation
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 14) {
            ForEach(GameSession.mockSessions) { session in
                GameCardView(session: session)
            }
        }
        .padding()
    }
}

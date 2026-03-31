import SwiftUI

// MARK: - Achievement Share View

struct AchievementShareView: View {
    let achievement: Achievement
    let user: User

    @Environment(\.dismiss) private var dismiss
    @State private var showConfetti = false
    @State private var cardScale: CGFloat = 0.88
    @State private var cardOpacity: Double = 0
    @State private var renderedImage: UIImage? = nil
    @State private var isRendering = false

    private var badgeColor: Color {
        switch achievement.color {
        case "dinkrGreen":  return Color.dinkrGreen
        case "dinkrNavy":   return Color.dinkrNavy
        case "dinkrCoral":  return Color.dinkrCoral
        case "dinkrSky":    return Color.dinkrSky
        default:            return Color.dinkrAmber
        }
    }

    private var badgeEmoji: String {
        switch achievement.badgeType {
        case .tournamentWinner:   return "🏆"
        case .reliablePro:        return "⭐️"
        case .communityChampion:  return "🤝"
        case .centennial:         return "💯"
        case .firstGame:          return "🎉"
        case .womensPioneer:      return "💪"
        case .courtBuilder:       return "🏗️"
        }
    }

    var body: some View {
        ZStack {
            // Dark scrim background
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                // ── Top controls ─────────────────────────────────────────
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.caption.weight(.bold))
                            Text("Close")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.12), in: Capsule())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // ── Share card ────────────────────────────────────────────
                AchievementShareCard(
                    achievement: achievement,
                    user: user,
                    badgeEmoji: badgeEmoji,
                    badgeColor: badgeColor
                )
                .scaleEffect(cardScale)
                .opacity(cardOpacity)
                .padding(.horizontal, 20)

                // ── Action buttons ────────────────────────────────────────
                VStack(spacing: 12) {
                    if let image = renderedImage {
                        ShareLink(
                            item: Image(uiImage: image),
                            preview: SharePreview(
                                "I unlocked \"\(achievement.title)\" on Dinkr! 🎉 #Dinkr #Pickleball",
                                image: Image(uiImage: image)
                            )
                        ) {
                            HStack(spacing: 10) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.subheadline.weight(.bold))
                                Text("Share Achievement")
                                    .font(.subheadline.weight(.bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    } else {
                        Button {
                            renderCard()
                        } label: {
                            HStack(spacing: 10) {
                                if isRendering {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.9)
                                } else {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.subheadline.weight(.bold))
                                }
                                Text(isRendering ? "Preparing…" : "Share Achievement")
                                    .font(.subheadline.weight(.bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(isRendering)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }

            // ── Confetti ──────────────────────────────────────────────────
            if showConfetti {
                AchievementShareConfetti()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            // Animate card in
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.08)) {
                cardScale = 1.0
                cardOpacity = 1.0
            }
            // Confetti burst
            showConfetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                showConfetti = false
            }
            // Pre-render on appear for snappy sharing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                renderCard()
            }
        }
    }

    private func renderCard() {
        isRendering = true
        let card = AchievementShareCard(
            achievement: achievement,
            user: user,
            badgeEmoji: badgeEmoji,
            badgeColor: badgeColor
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        if let image = renderer.uiImage {
            renderedImage = image
        }
        isRendering = false
    }
}

// MARK: - Shareable Card (also used as ImageRenderer source)

struct AchievementShareCard: View {
    let achievement: Achievement
    let user: User
    let badgeEmoji: String
    let badgeColor: Color

    private var formattedDate: String {
        guard let date = achievement.unlockedDate else { return "Today" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        ZStack {
            // ── Background gradient ───────────────────────────────────────
            LinearGradient(
                colors: [
                    Color.dinkrNavy,
                    Color.dinkrNavy.opacity(0.88),
                    Color(red: 0.07, green: 0.10, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // ── Subtle court line pattern ─────────────────────────────────
            GeometryReader { geo in
                Canvas { ctx, size in
                    let w = size.width
                    let h = size.height
                    var path = Path()
                    // Horizontal lines
                    for ratio in [0.25, 0.50, 0.75] as [CGFloat] {
                        path.move(to: CGPoint(x: 20, y: h * ratio))
                        path.addLine(to: CGPoint(x: w - 20, y: h * ratio))
                    }
                    // Vertical center
                    path.move(to: CGPoint(x: w / 2, y: 20))
                    path.addLine(to: CGPoint(x: w / 2, y: h - 20))
                    ctx.stroke(path, with: .color(.white.opacity(0.04)), lineWidth: 1)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }

            // ── Colored glow behind emoji ─────────────────────────────────
            Circle()
                .fill(badgeColor.opacity(0.18))
                .frame(width: 180, height: 180)
                .blur(radius: 40)
                .offset(y: -30)

            // ── Card content ──────────────────────────────────────────────
            VStack(spacing: 0) {
                // Player corner info
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                        HStack(spacing: 4) {
                            Text("Level \(user.skillLevel.label)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color.dinkrGreen.opacity(0.9))
                            if let dupr = user.duprRating {
                                Text("· DUPR \(String(format: "%.2f", dupr))")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.55))
                            }
                        }
                    }
                    Spacer()
                    // Dinkr wordmark (top right)
                    Text("dinkr")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(Color.dinkrGreen)
                        .tracking(1.5)
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)

                Spacer()

                // ── Badge emoji ───────────────────────────────────────────
                ZStack {
                    Circle()
                        .fill(badgeColor.opacity(0.16))
                        .frame(width: 110, height: 110)
                    Circle()
                        .stroke(badgeColor.opacity(0.45), lineWidth: 2)
                        .frame(width: 110, height: 110)
                    Text(badgeEmoji)
                        .font(.system(size: 52))
                }

                // ── Achievement name ──────────────────────────────────────
                Text(achievement.title)
                    .font(.title.weight(.black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 18)

                // ── Unlock date ───────────────────────────────────────────
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrSky.opacity(0.85))
                    Text("Unlocked on \(formattedDate)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .padding(.top, 8)

                // ── Description ───────────────────────────────────────────
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.80))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 28)
                    .padding(.top, 12)

                // ── XP chip ───────────────────────────────────────────────
                HStack(spacing: 5) {
                    Image(systemName: "bolt.fill")
                        .font(.caption.weight(.bold))
                    Text("+\(achievement.xpReward) XP")
                        .font(.caption.weight(.heavy))
                }
                .foregroundStyle(Color.dinkrAmber)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.dinkrAmber.opacity(0.18), in: Capsule())
                .overlay(Capsule().stroke(Color.dinkrAmber.opacity(0.35), lineWidth: 1))
                .padding(.top, 14)

                Spacer()

                // ── Bottom wordmark strip ─────────────────────────────────
                HStack(spacing: 6) {
                    Text("🥒")
                        .font(.caption)
                    Text("DINKR")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(2.5)
                        .foregroundStyle(Color.dinkrGreen.opacity(0.75))
                    Text("· Play. Connect. Dink.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.35))
                    Spacer()
                    Text("dinkr.app")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.35))
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
            }
        }
        .frame(width: 340, height: 440)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: badgeColor.opacity(0.25), radius: 28, x: 0, y: 12)
        .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 6)
    }
}

// MARK: - Confetti for share view

private struct AchievementShareConfetti: View {
    @State private var animate = false

    private struct Piece: Identifiable {
        let id: Int
        let color: Color
        let angle: Double
        let distance: CGFloat
        let size: CGFloat
        let shape: Int  // 0=circle, 1=rect
    }

    private let pieces: [Piece] = [
        Piece(id: 0, color: Color.dinkrGreen,  angle: -100, distance: 220, size: 14, shape: 0),
        Piece(id: 1, color: Color.dinkrAmber,  angle:  -75, distance: 240, size: 12, shape: 1),
        Piece(id: 2, color: Color.dinkrCoral,  angle:  -45, distance: 210, size: 16, shape: 0),
        Piece(id: 3, color: Color.dinkrSky,    angle:  -15, distance: 250, size: 10, shape: 1),
        Piece(id: 4, color: Color.dinkrGreen,  angle:   10, distance: 230, size: 14, shape: 0),
        Piece(id: 5, color: Color.dinkrAmber,  angle:   40, distance: 260, size: 12, shape: 0),
        Piece(id: 6, color: Color.dinkrCoral,  angle:   70, distance: 220, size: 16, shape: 1),
        Piece(id: 7, color: Color.dinkrSky,    angle:  100, distance: 200, size: 10, shape: 0),
        Piece(id: 8, color: .white,            angle: -120, distance: 190, size: 8,  shape: 1),
        Piece(id: 9, color: .white,            angle:  120, distance: 180, size: 8,  shape: 1),
    ]

    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height * 0.42

            ZStack {
                ForEach(pieces) { piece in
                    Group {
                        if piece.shape == 0 {
                            Circle()
                                .fill(piece.color)
                                .frame(width: piece.size, height: piece.size)
                        } else {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(piece.color)
                                .frame(width: piece.size * 0.7, height: piece.size * 1.4)
                                .rotationEffect(.degrees(animate ? Double(piece.id) * 37 : 0))
                        }
                    }
                    .offset(
                        x: animate ? cos(piece.angle * .pi / 180) * piece.distance : 0,
                        y: animate ? sin(piece.angle * .pi / 180) * piece.distance : 0
                    )
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? 0.3 : 1)
                    .position(x: cx, y: cy)
                    .animation(
                        .easeOut(duration: 1.2).delay(Double(piece.id) * 0.04),
                        value: animate
                    )
                }
            }
        }
        .onAppear { animate = true }
    }
}

// MARK: - Preview

#Preview {
    AchievementShareView(
        achievement: Achievement.all[3],
        user: User.mockCurrentUser
    )
}

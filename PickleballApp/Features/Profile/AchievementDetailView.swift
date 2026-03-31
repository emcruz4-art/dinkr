import SwiftUI

// MARK: - Detail Sheet

struct AchievementDetailView: View {
    let achievement: Achievement
    var user: User = User.mockCurrentUser
    /// Pass `true` the first time this sheet is shown after the achievement flips to unlocked
    var justUnlocked: Bool = false

    @Environment(\.dismiss) private var dismiss
    @State private var animateProgress: Bool = false
    @State private var showConfetti: Bool = false
    @State private var showShareView: Bool = false

    // Resolve a brand color string → Color
    private var badgeColor: Color {
        switch achievement.color {
        case "dinkrGreen":  return Color.dinkrGreen
        case "dinkrNavy":   return Color.dinkrNavy
        case "dinkrCoral":  return Color.dinkrCoral
        case "dinkrSky":    return Color.dinkrSky
        default:            return Color.dinkrAmber
        }
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ── Badge icon ──────────────────────────────────────
                    ZStack {
                        Circle()
                            .fill(
                                achievement.isUnlocked
                                    ? badgeColor.opacity(0.15)
                                    : Color.secondary.opacity(0.08)
                            )
                            .frame(width: 120, height: 120)
                            .shadow(
                                color: achievement.isUnlocked ? badgeColor.opacity(0.55) : .clear,
                                radius: 20, x: 0, y: 6
                            )

                        Image(systemName: achievement.icon)
                            .font(.system(size: 48, weight: .semibold))
                            .foregroundStyle(
                                achievement.isUnlocked
                                    ? badgeColor
                                    : Color.secondary.opacity(0.25)
                            )
                            .saturation(achievement.isUnlocked ? 1 : 0)

                        if !achievement.isUnlocked {
                            Circle()
                                .fill(Color.black.opacity(0.30))
                                .frame(width: 120, height: 120)
                            Image(systemName: "lock.fill")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }
                    .padding(.top, 28)

                    // ── XP chip ─────────────────────────────────────────
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.caption.weight(.bold))
                        Text("+\(achievement.xpReward) XP")
                            .font(.caption.weight(.heavy))
                    }
                    .foregroundStyle(Color.dinkrAmber)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.dinkrAmber.opacity(0.15))
                    .clipShape(Capsule())

                    // ── Title + description ──────────────────────────────
                    VStack(spacing: 8) {
                        Text(achievement.title)
                            .font(.title2.weight(.bold))
                            .multilineTextAlignment(.center)

                        Text(achievement.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .padding(.horizontal, 20)

                    // ── Progress bar ─────────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Progress")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(achievement.progress) / \(achievement.goal)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(
                                    achievement.isUnlocked ? Color.dinkrGreen : .secondary
                                )
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondary.opacity(0.15))
                                    .frame(height: 12)

                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        achievement.isUnlocked
                                            ? Color.dinkrGreen
                                            : Color.secondary.opacity(0.4)
                                    )
                                    .frame(
                                        width: geo.size.width * (animateProgress ? achievement.progressFraction : 0),
                                        height: 12
                                    )
                                    .animation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.15), value: animateProgress)
                            }
                        }
                        .frame(height: 12)
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)

                    // ── Unlock criteria ──────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        Label("How to Unlock", systemImage: "info.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            Image(systemName: achievement.isUnlocked ? "checkmark.circle.fill" : "circle.dashed")
                                .foregroundStyle(achievement.isUnlocked ? Color.dinkrGreen : .secondary)
                                .font(.title3)
                            Text(achievement.requirement)
                                .font(.subheadline)
                        }

                        if achievement.isUnlocked, let date = achievement.unlockedDate {
                            HStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .foregroundStyle(Color.dinkrSky)
                                    .font(.title3)
                                Text("Unlocked \(date.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)

                    // ── Share button ─────────────────────────────────────
                    if achievement.isUnlocked {
                        Button {
                            showShareView = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.subheadline.weight(.semibold))
                                Text("Share Achievement")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.dinkrGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.horizontal, 20)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 32)
                }
            }

            // ── Confetti overlay (justUnlocked only) ────────────────────
            if showConfetti {
                ConfettiBurst()
                    .allowsHitTesting(false)
            }
        }
        .presentationDetents([.medium])
        .sheet(isPresented: $showShareView) {
            AchievementShareView(achievement: achievement, user: user)
        }
        .onAppear {
            animateProgress = true
            if justUnlocked {
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    showConfetti = false
                }
            }
        }
    }
}

// MARK: - Confetti burst (5 circles)

private struct ConfettiBurst: View {
    @State private var animate = false

    private let pieces: [(color: Color, angle: Double, distance: CGFloat)] = [
        (Color.dinkrGreen,  -80, 160),
        (Color.dinkrAmber,  -30, 180),
        (Color.dinkrCoral,    0, 200),
        (Color.dinkrSky,    35, 170),
        (Color.dinkrNavy,   80, 155),
    ]

    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height * 0.38

            ZStack {
                ForEach(pieces.indices, id: \.self) { i in
                    let piece = pieces[i]
                    Circle()
                        .fill(piece.color)
                        .frame(width: 16, height: 16)
                        .offset(
                            x: animate ? cos(piece.angle * .pi / 180) * piece.distance : 0,
                            y: animate ? sin(piece.angle * .pi / 180) * piece.distance : 0
                        )
                        .opacity(animate ? 0 : 1)
                        .scaleEffect(animate ? 0.4 : 1)
                        .position(x: cx, y: cy)
                        .animation(
                            .easeOut(duration: 1.0).delay(Double(i) * 0.06),
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
    AchievementDetailView(achievement: Achievement.all[3], user: User.mockCurrentUser, justUnlocked: true)
}

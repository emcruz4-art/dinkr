import SwiftUI

// MARK: - MatchRecapData
// All data needed to present a post-game recap screen.

struct MatchRecapData {
    let result: GameResult
    let player: User
    let opponent: User
    let courtName: String
    let format: GameFormat
    let durationMinutes: Int
    let duprChange: Double
}

// MARK: - MatchRecapView
// Post-game recap screen presented after logging a result.

struct MatchRecapView: View {
    let data: MatchRecapData

    @Environment(\.dismiss) private var dismiss

    // Sequenced animation state
    @State private var scoreAppeared    = false
    @State private var statsAppeared    = false
    @State private var ratingAppeared   = false
    @State private var timelineAppeared = false
    @State private var cardAppeared     = false
    @State private var showConfetti     = false
    @State private var showShareSheet   = false

    private var isWin: Bool { data.result.isWin }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        scoreHeroSection
                        gameStatsSection
                        ratingImpactSection
                        keyMomentsSection
                        shareCardPreviewSection
                        actionButtons
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 48)
                }

                // Confetti overlay
                if showConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
            .navigationTitle("Match Recap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            MatchShareSheet(result: data.result, player: data.player)
        }
        .onAppear { runEntrySequence() }
    }

    // MARK: - Entry Animation Sequence

    private func runEntrySequence() {
        // Score hero
        withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.1)) {
            scoreAppeared = true
        }
        // Game stats
        withAnimation(.easeOut(duration: 0.4).delay(0.45)) {
            statsAppeared = true
        }
        // Rating impact
        withAnimation(.spring(response: 0.5, dampingFraction: 0.72).delay(0.65)) {
            ratingAppeared = true
        }
        // Timeline
        withAnimation(.easeOut(duration: 0.38).delay(0.85)) {
            timelineAppeared = true
        }
        // Share card
        withAnimation(.easeOut(duration: 0.35).delay(1.05)) {
            cardAppeared = true
        }
        // Confetti only on win
        if isWin {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }

    // MARK: - Score Hero Section

    private var scoreHeroSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.dinkrNavy,
                            isWin
                                ? Color(red: 0.06, green: 0.32, blue: 0.18)
                                : Color(red: 0.36, green: 0.10, blue: 0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            CourtLinesBackground()
                .opacity(0.06)
                .clipShape(RoundedRectangle(cornerRadius: 24))

            VStack(spacing: 0) {
                // Result badge
                resultBadge
                    .padding(.top, 22)
                    .padding(.bottom, 16)
                    .scaleEffect(scoreAppeared ? 1 : 0.4)
                    .opacity(scoreAppeared ? 1 : 0)

                // Score
                HStack(alignment: .center, spacing: 0) {
                    // My score
                    VStack(spacing: 4) {
                        Text("\(data.result.myScore)")
                            .font(.system(size: 72, weight: .black, design: .rounded))
                            .foregroundStyle(isWin ? Color.dinkrGreen : Color.dinkrCoral)
                            .contentTransition(.numericText())
                        Text("You")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .frame(maxWidth: .infinity)

                    // Dash
                    VStack(spacing: 5) {
                        Circle()
                            .fill(Color.white.opacity(0.22))
                            .frame(width: 5, height: 5)
                        Circle()
                            .fill(Color.white.opacity(0.22))
                            .frame(width: 5, height: 5)
                    }

                    // Opponent score
                    VStack(spacing: 4) {
                        Text("\(data.result.opponentScore)")
                            .font(.system(size: 72, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                            .contentTransition(.numericText())
                        Text(data.result.opponentName.components(separatedBy: " ").first
                             ?? data.result.opponentName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.55))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
                .scaleEffect(scoreAppeared ? 1 : 0.6)
                .opacity(scoreAppeared ? 1 : 0)
                .padding(.bottom, 18)

                // Meta chips
                HStack(spacing: 8) {
                    recapMetaChip(icon: "mappin.circle.fill",
                                  text: data.courtName.components(separatedBy: " ").prefix(2).joined(separator: " "),
                                  color: Color.dinkrSky)
                    recapMetaChip(icon: "figure.pickleball",
                                  text: data.format.rawValue.capitalized,
                                  color: Color.dinkrAmber)
                    recapMetaChip(icon: "clock.fill",
                                  text: "\(data.durationMinutes)m",
                                  color: Color.white.opacity(0.5))
                }
                .padding(.bottom, 20)
                .opacity(scoreAppeared ? 1 : 0)
                .offset(y: scoreAppeared ? 0 : 12)
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
    }

    private var resultBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: isWin ? "trophy.fill" : "arrow.uturn.left")
                .font(.system(size: 12, weight: .bold))
            Text(isWin ? "Victory!" : "Close Match")
                .font(.system(size: 13, weight: .black, design: .rounded))
        }
        .foregroundStyle(isWin ? Color.dinkrNavy : .white)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            isWin ? Color.dinkrAmber : Color.white.opacity(0.18),
            in: Capsule()
        )
    }

    private func recapMetaChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(1)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.1), in: Capsule())
    }

    // MARK: - Game Stats Section

    private var gameStatsSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Game Stats", icon: "chart.bar.fill")
                .padding(.bottom, 12)

            HStack(spacing: 10) {
                gameStat(
                    icon: "repeat.circle.fill",
                    iconColor: Color.dinkrSky,
                    value: "\(longestRally)",
                    label: "Longest Rally"
                )
                gameStat(
                    icon: "arrow.down.circle.fill",
                    iconColor: Color.dinkrGreen,
                    value: "\(aces)",
                    label: "Aces"
                )
                gameStat(
                    icon: "xmark.circle.fill",
                    iconColor: Color.dinkrCoral,
                    value: "\(unforcedErrors)",
                    label: "UF Errors"
                )
                gameStat(
                    icon: "speedometer",
                    iconColor: Color.dinkrAmber,
                    value: "\(Int(avgRallyLength))",
                    label: "Avg Rally"
                )
            }
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.secondary.opacity(0.08), lineWidth: 1))
        .opacity(statsAppeared ? 1 : 0)
        .offset(y: statsAppeared ? 0 : 18)
    }

    private func gameStat(icon: String, iconColor: Color, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.primary)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.3)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 14))
    }

    // Mock deterministic game stats
    private var longestRally: Int  { max(4, (data.result.myScore + data.result.opponentScore) % 14 + 5) }
    private var aces: Int          { max(1, data.result.myScore % 5) }
    private var unforcedErrors: Int { max(2, data.result.opponentScore % 6 + 1) }
    private var avgRallyLength: Double { Double(longestRally) * 0.55 }

    // MARK: - Rating Impact Section

    private var ratingImpactSection: some View {
        HStack(spacing: 14) {
            // DUPR icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill((data.duprChange >= 0 ? Color.dinkrGreen : Color.dinkrCoral).opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: data.duprChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(data.duprChange >= 0 ? Color.dinkrGreen : Color.dinkrCoral)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("DUPR Rating Impact")
                    .font(.subheadline.weight(.semibold))
                Text(data.duprChange >= 0
                     ? "Your rating improved after this match"
                     : "Tight loss — keep grinding")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Change badge (animated arrow)
            HStack(spacing: 4) {
                Image(systemName: data.duprChange >= 0 ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .black))
                Text(String(format: "%+.2f", data.duprChange))
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                data.duprChange >= 0 ? Color.dinkrGreen : Color.dinkrCoral,
                in: RoundedRectangle(cornerRadius: 10)
            )
            .scaleEffect(ratingAppeared ? 1 : 0.5)
            .opacity(ratingAppeared ? 1 : 0)
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.secondary.opacity(0.08), lineWidth: 1))
        .opacity(ratingAppeared ? 1 : 0)
        .offset(y: ratingAppeared ? 0 : 14)
    }

    // MARK: - Key Moments Timeline

    private var keyMomentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Key Moments", icon: "clock.badge.fill")

            VStack(spacing: 0) {
                ForEach(Array(keyMoments.enumerated()), id: \.offset) { index, moment in
                    KeyMomentRow(
                        moment: moment,
                        isLast: index == keyMoments.count - 1
                    )
                    .opacity(timelineAppeared ? 1 : 0)
                    .offset(x: timelineAppeared ? 0 : -20)
                    .animation(
                        .spring(response: 0.45, dampingFraction: 0.78)
                            .delay(0.85 + Double(index) * 0.1),
                        value: timelineAppeared
                    )
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.secondary.opacity(0.08), lineWidth: 1))
    }

    private var keyMoments: [KeyMoment] {
        let opponentFirst = data.result.opponentName.components(separatedBy: " ").first
                           ?? data.result.opponentName
        let myScore = data.result.myScore
        let oppScore = data.result.opponentScore
        let tieScore = min(myScore, oppScore) - 2
        let tieDisplay = max(tieScore, 1)

        return [
            KeyMoment(icon: "flag.fill",
                      color: Color.dinkrSky,
                      title: "Match started",
                      subtitle: "Both players warm and ready"),
            KeyMoment(icon: "arrow.up.right.circle.fill",
                      color: Color.dinkrAmber,
                      title: "\(tieDisplay)-\(tieDisplay) tie broken",
                      subtitle: "5 consecutive points — momentum shift"),
            KeyMoment(icon: isWin ? "bolt.fill" : "exclamationmark.triangle.fill",
                      color: isWin ? Color.dinkrGreen : Color.dinkrCoral,
                      title: isWin ? "Game point secured at \(myScore - 1)-\(oppScore)" : "Critical point lost at \(myScore)-\(oppScore - 1)",
                      subtitle: isWin ? "Clean winner down the line" : "Unforced error at net"),
            KeyMoment(icon: isWin ? "trophy.fill" : "arrow.counterclockwise.circle.fill",
                      color: isWin ? Color.dinkrAmber : Color.dinkrSky,
                      title: isWin ? "Match point! \(myScore)-\(oppScore)" : "Final score: \(myScore)-\(oppScore)",
                      subtitle: isWin ? "Great match vs \(opponentFirst)!" : "Strong effort — rematch \(opponentFirst)?"),
        ]
    }

    // MARK: - Share Card Preview

    private var shareCardPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Share Card Preview", icon: "square.and.arrow.up.fill")

            MatchShareCard(result: data.result, player: data.player)
                .scaleEffect(0.84)
                .frame(height: 360 * 0.84)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 6)
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.secondary.opacity(0.08), lineWidth: 1))
        .opacity(cardAppeared ? 1 : 0)
        .offset(y: cardAppeared ? 0 : 22)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Share Result
            Button {
                HapticManager.medium()
                showShareSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .bold))
                    Text("Share Result")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.dinkrGreen.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            // Play Again
            Button {
                HapticManager.light()
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Play Again")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Color.dinkrGreen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.dinkrGreen, lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
        }
        .opacity(cardAppeared ? 1 : 0)
    }

    // MARK: - Helpers

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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - KeyMoment Model

private struct KeyMoment {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
}

// MARK: - KeyMomentRow

private struct KeyMomentRow: View {
    let moment: KeyMoment
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline icon + connector
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(moment.color.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: moment.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(moment.color)
                }

                if !isLast {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 2, height: 28)
                }
            }

            // Text
            VStack(alignment: .leading, spacing: 3) {
                Text(moment.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(moment.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 7)

            Spacer()
        }
        .padding(.bottom, isLast ? 0 : 4)
    }
}

// MARK: - CourtLinesBackground (reuse-compatible local copy for ZStack fill)

private struct CourtLinesBackground: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width; let h = size.height
            var path = Path()
            path.move(to: .init(x: 0, y: h * 0.38))
            path.addLine(to: .init(x: w, y: h * 0.38))
            path.move(to: .init(x: 0, y: h * 0.62))
            path.addLine(to: .init(x: w, y: h * 0.62))
            path.move(to: .init(x: w * 0.5, y: 0))
            path.addLine(to: .init(x: w * 0.5, y: h))
            path.move(to: .init(x: 0.04 * w, y: 0))
            path.addLine(to: .init(x: 0.04 * w, y: h))
            path.move(to: .init(x: 0.96 * w, y: 0))
            path.addLine(to: .init(x: 0.96 * w, y: h))
            ctx.stroke(path, with: .color(.white), lineWidth: 1.2)
        }
    }
}

// MARK: - Preview

#Preview("Match Recap – Win") {
    MatchRecapView(data: MatchRecapData(
        result: GameResult.mockResults[0],
        player: User.mockCurrentUser,
        opponent: User.mockPlayers[0],
        courtName: "Westside Pickleball Complex",
        format: .doubles,
        durationMinutes: 42,
        duprChange: 0.15
    ))
}

#Preview("Match Recap – Loss") {
    MatchRecapView(data: MatchRecapData(
        result: GameResult.mockResults[1],
        player: User.mockCurrentUser,
        opponent: User.mockPlayers[1],
        courtName: "Mueller Recreation Center",
        format: .singles,
        durationMinutes: 35,
        duprChange: -0.08
    ))
}

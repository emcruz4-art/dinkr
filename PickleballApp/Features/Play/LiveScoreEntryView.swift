import SwiftUI

// MARK: - LiveScoreEntryView

struct LiveScoreEntryView: View {
    let session: GameSession
    @Binding var liveScore: GameSession.LiveScoreSnapshot?

    @Environment(\.dismiss) private var dismiss

    // MARK: Local state

    @State private var scoreA: Int
    @State private var scoreB: Int
    @State private var servingTeam: String   // "A" or "B"
    @State private var pulseScale: CGFloat = 1.0
    @State private var livePulse: Bool = false

    // MARK: Derived

    private var teamAName: String {
        session.format == .singles ? session.hostName : "Team A"
    }
    private var teamBName: String {
        session.format == .singles ? "Opponent" : "Team B"
    }

    private let maxScore = 21

    // MARK: Init

    init(session: GameSession, liveScore: Binding<GameSession.LiveScoreSnapshot?>) {
        self.session = session
        self._liveScore = liveScore
        let existing = liveScore.wrappedValue
        _scoreA = State(initialValue: existing?.scoreA ?? 0)
        _scoreB = State(initialValue: existing?.scoreB ?? 0)
        _servingTeam = State(initialValue: existing?.servingTeam ?? "A")
    }

    // MARK: Body

    var body: some View {
        ZStack {
            Color.dinkrNavy
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                liveBadge
                    .padding(.top, 20)
                scoreBoard
                    .padding(.top, 28)
                servingRow
                    .padding(.top, 20)
                Spacer()
                endGameButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.trailing, 20)
            .padding(.top, 16)
        }
    }

    // MARK: - LIVE Badge

    private var liveBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.dinkrCoral)
                .frame(width: 10, height: 10)
                .scaleEffect(livePulse ? 1.4 : 0.8)
                .animation(
                    .easeInOut(duration: 0.7).repeatForever(autoreverses: true),
                    value: livePulse
                )
                .onAppear { livePulse = true }

            Text("LIVE")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dinkrCoral)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.dinkrCoral.opacity(0.15))
        .clipShape(Capsule())
        .overlay(
            Capsule().strokeBorder(Color.dinkrCoral.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Scoreboard

    private var scoreBoard: some View {
        HStack(spacing: 0) {
            teamScorePanel(
                teamName: teamAName,
                score: $scoreA,
                isServing: servingTeam == "A",
                teamKey: "A"
            )

            // Divider dash
            Text("–")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.3))
                .frame(width: 44)

            teamScorePanel(
                teamName: teamBName,
                score: $scoreB,
                isServing: servingTeam == "B",
                teamKey: "B"
            )
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func teamScorePanel(
        teamName: String,
        score: Binding<Int>,
        isServing: Bool,
        teamKey: String
    ) -> some View {
        VStack(spacing: 14) {
            // Team name + serving indicator
            HStack(spacing: 8) {
                Text(teamName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isServing ? Color.dinkrCoral : Color.white.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if isServing {
                    Circle()
                        .fill(Color.dinkrAmber)
                        .frame(width: 10, height: 10)
                        .scaleEffect(livePulse ? 1.4 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                            value: livePulse
                        )
                }
            }

            // Score number
            Text("\(score.wrappedValue)")
                .font(.system(size: 80, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.35, dampingFraction: 0.6), value: score.wrappedValue)
                .frame(minWidth: 80)

            // +/- buttons
            HStack(spacing: 16) {
                Button {
                    if score.wrappedValue > 0 {
                        score.wrappedValue -= 1
                    }
                } label: {
                    scoreAdjustButton(symbol: "minus", enabled: score.wrappedValue > 0)
                }
                .disabled(score.wrappedValue <= 0)

                Button {
                    if score.wrappedValue < maxScore {
                        score.wrappedValue += 1
                    }
                } label: {
                    scoreAdjustButton(symbol: "plus", enabled: score.wrappedValue < maxScore)
                }
                .disabled(score.wrappedValue >= maxScore)
            }
        }
        .frame(maxWidth: .infinity)
        // Tap the whole panel to toggle serving
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                servingTeam = teamKey
            }
        }
    }

    private func scoreAdjustButton(symbol: String, enabled: Bool) -> some View {
        ZStack {
            Circle()
                .fill(enabled ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                .frame(width: 52, height: 52)
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(enabled ? .white : Color.white.opacity(0.3))
        }
    }

    // MARK: - Serving Row

    private var servingRow: some View {
        VStack(spacing: 6) {
            Text("TAP TEAM PANEL TO CHANGE SERVER")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Color.white.opacity(0.4))

            HStack(spacing: 6) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.dinkrAmber.opacity(0.7))
                Text("\(servingTeam == "A" ? teamAName : teamBName) is serving")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.dinkrAmber)
            }
        }
    }

    // MARK: - End Game Button

    private var endGameButton: some View {
        Button {
            commitAndDismiss(complete: true)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 16, weight: .semibold))
                Text("End Game")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.dinkrCoral)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Helpers

    private func commitAndDismiss(complete: Bool) {
        liveScore = GameSession.LiveScoreSnapshot(
            scoreA: scoreA,
            scoreB: scoreB,
            teamAName: teamAName,
            teamBName: teamBName,
            isComplete: complete,
            servingTeam: servingTeam
        )
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    LiveScoreEntryView(
        session: GameSession.mockSessions[0],
        liveScore: .constant(nil)
    )
}

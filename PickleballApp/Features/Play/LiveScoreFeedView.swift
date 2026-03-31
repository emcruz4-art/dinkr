import SwiftUI

// MARK: - LiveScoreFeedView

struct LiveScoreFeedView: View {
    @State private var liveSessions: [GameSession] = GameSession.mockSessions.filter { $0.liveScore != nil }
    @State private var pulseRed = false
    @State private var lastUpdated = Date()
    @State private var showSpectateToast = false
    @State private var spectateToastSession: String = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    // Top status bar
                    liveHeaderBar
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                    if liveSessions.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(liveSessions) { session in
                                if let score = session.liveScore {
                                    LiveGameCard(
                                        session: session,
                                        score: score,
                                        onSpectate: {
                                            spectateToastSession = session.courtName
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                showSpectateToast = true
                                            }
                                            HapticManager.selection()
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                                                withAnimation { showSpectateToast = false }
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
            .refreshable {
                simulateScoreUpdates()
                lastUpdated = Date()
            }
            .background(Color.appBackground)

            // Spectate toast
            if showSpectateToast {
                spectateToastBanner
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 24)
            }
        }
        .navigationTitle("Live Now 🔴")
        .navigationBarTitleDisplayMode(.large)
        // Auto-refresh every 30 seconds via .task sleep loop
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                simulateScoreUpdates()
                lastUpdated = Date()
            }
        }
        .onAppear { pulseRed = true }
    }

    // MARK: - Header Bar

    private var liveHeaderBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 9, height: 9)
                .scaleEffect(pulseRed ? 1.45 : 0.85)
                .animation(
                    .easeInOut(duration: 0.75).repeatForever(autoreverses: true),
                    value: pulseRed
                )

            Text("\(liveSessions.count) GAME\(liveSessions.count == 1 ? "" : "S") IN PROGRESS")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(Color.dinkrCoral)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Updated \(timeAgoString(lastUpdated))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 60)
            Image(systemName: "sportscourt")
                .font(.system(size: 52))
                .foregroundStyle(Color.dinkrGreen.opacity(0.35))
            Text("No live games right now.")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
            Text("Check back soon!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 60)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Spectate Toast

    private var spectateToastBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "eye.fill")
                .foregroundStyle(Color.dinkrAmber)
            VStack(alignment: .leading, spacing: 1) {
                Text("Spectate Mode")
                    .font(.subheadline.weight(.bold))
                Text("Coming soon — stay tuned!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.12), radius: 12, y: 4)
        )
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private func simulateScoreUpdates() {
        liveSessions = liveSessions.map { session in
            guard var score = session.liveScore, !score.isComplete else { return session }
            var updated = session
            // Randomly increment one team
            if Bool.random() {
                score.scoreA += Int.random(in: 0...1)
            } else {
                score.scoreB += Int.random(in: 0...1)
            }
            score.servingTeam = Bool.random() ? "A" : "B"
            updated.liveScore = score
            return updated
        }
    }

    private func timeAgoString(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 5 { return "just now" }
        if seconds < 60 { return "\(seconds)s ago" }
        return "\(seconds / 60)m ago"
    }
}

// MARK: - LiveGameCard

private struct LiveGameCard: View {
    let session: GameSession
    let score: GameSession.LiveScoreSnapshot
    var onSpectate: () -> Void

    @State private var livePulse = false

    /// Rough estimate: session started some minutes before now based on score
    private var elapsedMinutes: Int {
        let totalPoints = score.scoreA + score.scoreB
        // ~1.5 min per point on average
        return max(1, Int(Double(totalPoints) * 1.5))
    }

    private var formatLabel: String {
        session.format.rawValue.capitalized
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top chrome: LIVE badge + court + time
            HStack(spacing: 8) {
                liveBadge
                Text(session.courtName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                formatBadge
                HStack(spacing: 3) {
                    Image(systemName: "timer")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("~\(elapsedMinutes)m")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            // Scoreboard
            HStack(alignment: .center, spacing: 0) {
                // Team A
                teamPanel(
                    name: score.teamAName,
                    score: score.scoreA,
                    isServing: score.servingTeam == "A",
                    alignment: .leading
                )

                // Center divider + score
                VStack(spacing: 2) {
                    Text("\(score.scoreA)  ·  \(score.scoreB)")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(Color.primary)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity)

                // Team B
                teamPanel(
                    name: score.teamBName,
                    score: score.scoreB,
                    isServing: score.servingTeam == "B",
                    alignment: .trailing
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().padding(.horizontal, 16)

            // Action row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Skill Range")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.secondary)
                    Text("\(session.skillRange.lowerBound.rawValue) – \(session.skillRange.upperBound.rawValue)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrSky)
                }

                Spacer()

                Button(action: onSpectate) {
                    HStack(spacing: 5) {
                        Image(systemName: "eye.fill")
                            .font(.caption)
                        Text("Spectate")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.dinkrNavy)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.06), radius: 6, y: 2)
        .onAppear { livePulse = true }
    }

    @ViewBuilder
    private func teamPanel(name: String, score: Int, isServing: Bool, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            HStack(spacing: 4) {
                if isServing && alignment == .trailing {
                    Circle()
                        .fill(Color.dinkrAmber)
                        .frame(width: 8, height: 8)
                        .scaleEffect(livePulse ? 1.4 : 0.8)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: livePulse)
                }
                Text(name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if isServing && alignment == .leading {
                    Circle()
                        .fill(Color.dinkrAmber)
                        .frame(width: 8, height: 8)
                        .scaleEffect(livePulse ? 1.4 : 0.8)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: livePulse)
                }
            }
            if isServing {
                Text("SERVING")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(Color.dinkrAmber)
            } else {
                Text(" ")
                    .font(.system(size: 8))
            }
        }
        .frame(maxWidth: 100, alignment: alignment == .leading ? .leading : .trailing)
    }

    private var liveBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .scaleEffect(livePulse ? 1.4 : 0.8)
                .animation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true), value: livePulse)
            Text("LIVE")
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(Color.red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.red.opacity(0.1))
        .clipShape(Capsule())
    }

    private var formatBadge: some View {
        Text(formatLabel)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(Color.dinkrGreen)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.dinkrGreen.opacity(0.12))
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        LiveScoreFeedView()
    }
}

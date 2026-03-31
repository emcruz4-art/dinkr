import SwiftUI

// MARK: - TournamentStanding

struct TournamentStanding: Identifiable {
    let id = UUID()
    let rank: Int
    let playerName: String
    let wins: Int
    let losses: Int
    let points: Int
    let prize: String
}

// MARK: - StatsLeader

struct TournamentStatsLeaders {
    let mostWinsPlayer: String
    let mostWinsCount: Int
    let highestScorePlayer: String
    let highestScore: String
    let mostImprovedPlayer: String
    let duprChange: String
}

// MARK: - ConfettiParticle

private struct TournamentConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let delay: Double
    let color: Color
    let size: CGFloat
    let rotation: Double
}

// MARK: - ConfettiView

private struct TournamentConfettiView: View {
    @State private var animate = false

    private let particles: [TournamentConfettiParticle] = (0..<40).map { i in
        TournamentConfettiParticle(
            x: CGFloat.random(in: 0...1),
            delay: Double.random(in: 0...1.2),
            color: [Color.dinkrGreen, Color.dinkrAmber, Color.dinkrCoral, Color.dinkrSky, .white].randomElement()!,
            size: CGFloat.random(in: 6...12),
            rotation: Double.random(in: 0...360)
        )
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { p in
                RoundedRectangle(cornerRadius: 2)
                    .fill(p.color)
                    .frame(width: p.size, height: p.size * 0.5)
                    .rotationEffect(.degrees(animate ? p.rotation + 360 : p.rotation))
                    .position(
                        x: geo.size.width * p.x,
                        y: animate ? geo.size.height + 40 : -20
                    )
                    .animation(
                        .easeIn(duration: Double.random(in: 1.4...2.2))
                        .delay(p.delay)
                        .repeatForever(autoreverses: false),
                        value: animate
                    )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear { animate = true }
    }
}

// MARK: - TrophyPodiumView

private struct TrophyPodiumView: View {
    let first: String
    let second: String
    let third: String

    @State private var trophyScale: CGFloat = 0.5
    @State private var trophyOpacity: Double = 0
    @State private var podiumReveal = false

    var body: some View {
        VStack(spacing: 12) {
            // Trophy icon — 1st place
            Image(systemName: "trophy.fill")
                .font(.system(size: 44))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.dinkrAmber, Color.dinkrAmber.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(trophyScale)
                .opacity(trophyOpacity)
                .shadow(color: Color.dinkrAmber.opacity(0.5), radius: 12, x: 0, y: 4)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.2)) {
                        trophyScale = 1.0
                        trophyOpacity = 1
                    }
                }

            // Podium — 2nd, 1st, 3rd layout
            HStack(alignment: .bottom, spacing: 8) {
                // 2nd place
                podiumColumn(
                    rank: 2,
                    name: second,
                    height: 80,
                    topColor: Color(red: 0.75, green: 0.75, blue: 0.78),
                    bottomColor: Color(red: 0.60, green: 0.60, blue: 0.65),
                    medalLabel: "2nd",
                    delay: 0.4
                )

                // 1st place — tallest
                podiumColumn(
                    rank: 1,
                    name: first,
                    height: 110,
                    topColor: Color.dinkrAmber,
                    bottomColor: Color.dinkrAmber.opacity(0.7),
                    medalLabel: "1st",
                    delay: 0.2
                )

                // 3rd place
                podiumColumn(
                    rank: 3,
                    name: third,
                    height: 60,
                    topColor: Color(red: 0.80, green: 0.50, blue: 0.20),
                    bottomColor: Color(red: 0.65, green: 0.38, blue: 0.12),
                    medalLabel: "3rd",
                    delay: 0.6
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private func podiumColumn(
        rank: Int,
        name: String,
        height: CGFloat,
        topColor: Color,
        bottomColor: Color,
        medalLabel: String,
        delay: Double
    ) -> some View {
        @State var revealed = false
        VStack(spacing: 6) {
            // Medal circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [topColor, bottomColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: topColor.opacity(0.4), radius: 6, x: 0, y: 2)

                VStack(spacing: 1) {
                    Text(medalLabel)
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white)
                    Text(medalEmoji(rank: rank))
                        .font(.system(size: 14))
                }
            }

            Text(name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 90)

            // Podium block
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [topColor.opacity(0.9), bottomColor.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: revealed ? height : 0)
                .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(delay), value: revealed)
        }
        .frame(maxWidth: .infinity)
        .onAppear { revealed = true }
    }

    private func medalEmoji(rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }
}

// MARK: - TournamentResultsView

struct TournamentResultsView: View {
    let eventName: String
    let division: String
    var bracket: Bracket? = nil

    @State private var showExportAlert = false
    @State private var showConfetti = true

    // MARK: - Mock standings (8+ players)

    private var standings: [TournamentStanding] {
        [
            TournamentStanding(rank: 1, playerName: "Marcus Webb",     wins: 5, losses: 0, points: 500, prize: "$1,500"),
            TournamentStanding(rank: 2, playerName: "Jordan Rivera",   wins: 4, losses: 1, points: 420, prize: "$750"),
            TournamentStanding(rank: 3, playerName: "Avery Chen",      wins: 3, losses: 1, points: 350, prize: "$350"),
            TournamentStanding(rank: 4, playerName: "Taylor Brooks",   wins: 3, losses: 2, points: 290, prize: "$150"),
            TournamentStanding(rank: 5, playerName: "Sam Nguyen",      wins: 2, losses: 2, points: 220, prize: "$75"),
            TournamentStanding(rank: 6, playerName: "Casey Kim",       wins: 2, losses: 3, points: 175, prize: "$50"),
            TournamentStanding(rank: 7, playerName: "Riley Patel",     wins: 1, losses: 3, points: 110, prize: "—"),
            TournamentStanding(rank: 8, playerName: "Morgan Hayes",    wins: 1, losses: 4, points: 80,  prize: "—"),
            TournamentStanding(rank: 9, playerName: "Drew Santos",     wins: 0, losses: 4, points: 40,  prize: "—"),
            TournamentStanding(rank: 10, playerName: "Alex Torres",    wins: 0, losses: 5, points: 20,  prize: "—"),
        ]
    }

    private var statsLeaders: TournamentStatsLeaders {
        TournamentStatsLeaders(
            mostWinsPlayer: "Marcus Webb",
            mostWinsCount: 5,
            highestScorePlayer: "Jordan Rivera",
            highestScore: "15–3",
            mostImprovedPlayer: "Riley Patel",
            duprChange: "+0.34"
        )
    }

    private var shareText: String {
        """
        \(eventName) — \(division) Division Results

        🥇 1st: \(standings[0].playerName) — \(standings[0].wins)W \(standings[0].losses)L | Prize: \(standings[0].prize)
        🥈 2nd: \(standings[1].playerName) — \(standings[1].wins)W \(standings[1].losses)L | Prize: \(standings[1].prize)
        🥉 3rd: \(standings[2].playerName) — \(standings[2].wins)W \(standings[2].losses)L | Prize: \(standings[2].prize)

        Stats Leaders
        Most Wins: \(statsLeaders.mostWinsPlayer) (\(statsLeaders.mostWinsCount) wins)
        Highest Score: \(statsLeaders.highestScorePlayer) (\(statsLeaders.highestScore))
        Most Improved DUPR: \(statsLeaders.mostImprovedPlayer) (\(statsLeaders.duprChange))

        🏓 Results via Dinkr
        """
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    headerBanner
                    podiumSection
                    standingsSection
                    statsLeadersSection
                    actionButtons
                        .padding(.bottom, 40)
                }
            }

            if showConfetti {
                TournamentConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Export Coming Soon", isPresented: $showExportAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("PDF bracket export will be available in a future update.")
        }
        .onAppear {
            // Auto-hide confetti after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showConfetti = false
                }
            }
        }
    }

    // MARK: - Header Banner

    @ViewBuilder
    private var headerBanner: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color.dinkrNavy, Color.dinkrNavy.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 130)

            VStack(spacing: 4) {
                Text(eventName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                HStack(spacing: 6) {
                    Image(systemName: "flag.checkered")
                        .font(.caption.weight(.semibold))
                    Text(division)
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(Color.dinkrAmber)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.dinkrAmber.opacity(0.18), in: Capsule())
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Podium Section

    @ViewBuilder
    private var podiumSection: some View {
        VStack(spacing: 0) {
            TrophyPodiumView(
                first: standings[0].playerName,
                second: standings[1].playerName,
                third: standings[2].playerName
            )
            .padding(.top, 28)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
            .background(Color.dinkrNavy.opacity(0.04))
        }
    }

    // MARK: - Standings Table

    @ViewBuilder
    private var standingsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(icon: "list.number", title: "Standings")

            // Table header
            HStack(spacing: 0) {
                Text("Rank")
                    .frame(width: 46, alignment: .center)
                Text("Player")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("W")
                    .frame(width: 28, alignment: .center)
                Text("L")
                    .frame(width: 28, alignment: .center)
                Text("Pts")
                    .frame(width: 42, alignment: .center)
                Text("Prize")
                    .frame(width: 58, alignment: .trailing)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.cardBackground)

            Divider()

            ForEach(standings) { standing in
                standingRow(standing)
                if standing.rank < standings.count {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }

    @ViewBuilder
    private func standingRow(_ standing: TournamentStanding) -> some View {
        let highlight = medalHighlight(rank: standing.rank)

        HStack(spacing: 0) {
            // Rank
            ZStack {
                if let (bg, _) = highlight {
                    Circle()
                        .fill(bg.opacity(0.18))
                        .frame(width: 28, height: 28)
                }
                Text(standing.rank <= 3 ? medalEmoji(standing.rank) : "#\(standing.rank)")
                    .font(.system(size: standing.rank <= 3 ? 16 : 12, weight: .bold, design: .rounded))
                    .foregroundStyle(highlight?.1 ?? Color.secondary)
            }
            .frame(width: 46, alignment: .center)

            // Player name
            Text(standing.playerName)
                .font(.system(size: 14, weight: standing.rank <= 3 ? .semibold : .regular))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // W
            Text("\(standing.wins)")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.dinkrGreen)
                .frame(width: 28, alignment: .center)

            // L
            Text("\(standing.losses)")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.dinkrCoral)
                .frame(width: 28, alignment: .center)

            // Pts
            Text("\(standing.points)")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.dinkrNavy)
                .frame(width: 42, alignment: .center)

            // Prize
            Text(standing.prize)
                .font(.system(size: 12, weight: standing.prize != "—" ? .semibold : .regular))
                .foregroundStyle(standing.prize != "—" ? Color.dinkrAmber : Color.secondary)
                .lineLimit(1)
                .frame(width: 58, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            highlight != nil
                ? highlight!.0.opacity(0.05)
                : Color.clear
        )
    }

    // MARK: - Stats Leaders Section

    @ViewBuilder
    private var statsLeadersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "chart.bar.fill", title: "Stats Leaders")

            VStack(spacing: 10) {
                statLeaderRow(
                    icon: "trophy.fill",
                    iconColor: Color.dinkrAmber,
                    label: "Most Wins",
                    player: statsLeaders.mostWinsPlayer,
                    value: "\(statsLeaders.mostWinsCount) wins"
                )
                Divider().padding(.leading, 52)
                statLeaderRow(
                    icon: "flame.fill",
                    iconColor: Color.dinkrCoral,
                    label: "Highest Game Score",
                    player: statsLeaders.highestScorePlayer,
                    value: statsLeaders.highestScore
                )
                Divider().padding(.leading, 52)
                statLeaderRow(
                    icon: "arrow.up.forward.circle.fill",
                    iconColor: Color.dinkrGreen,
                    label: "Most Improved DUPR",
                    player: statsLeaders.mostImprovedPlayer,
                    value: statsLeaders.duprChange
                )
            }
            .padding(16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 16)
        }
        .padding(.top, 20)
    }

    @ViewBuilder
    private func statLeaderRow(icon: String, iconColor: Color, label: String, player: String, value: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.14))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.secondary)
                Text(player)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(iconColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(iconColor.opacity(0.12), in: Capsule())
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showExportAlert = true
            } label: {
                Label("Download Bracket PDF", systemImage: "arrow.down.doc.fill")
            }
            .secondaryButton()

            ShareLink(
                item: shareText,
                subject: Text("\(eventName) Results"),
                message: Text(shareText)
            ) {
                Label("Share Results", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.dinkrGreen)
            Text(title)
                .font(.headline)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private func medalEmoji(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }

    /// Returns (highlightColor, textColor) for top-3 ranks, nil otherwise.
    private func medalHighlight(rank: Int) -> (Color, Color)? {
        switch rank {
        case 1: return (Color.dinkrAmber, Color.dinkrAmber)
        case 2: return (Color(red: 0.75, green: 0.75, blue: 0.78), Color(red: 0.55, green: 0.55, blue: 0.60))
        case 3: return (Color(red: 0.80, green: 0.50, blue: 0.20), Color(red: 0.70, green: 0.40, blue: 0.10))
        default: return nil
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TournamentResultsView(
            eventName: "Austin Open Pickleball Tournament",
            division: "Mixed Doubles 4.0+"
        )
    }
}

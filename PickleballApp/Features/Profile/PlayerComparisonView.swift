import SwiftUI

// MARK: - PlayerComparisonView
// Side-by-side stats comparison between the current user and any other player.
// Entry point: UserProfileView "Compare" button.

struct PlayerComparisonView: View {
    let currentUser: User
    let opponent: User

    @Environment(\.dismiss) private var dismiss

    // Animation state
    @State private var barsAppeared = false
    @State private var strengthsAppeared = false

    // Mutual games (deterministic mock based on shared IDs)
    private var mutualGamesCount: Int {
        let seed = (Int(currentUser.id.suffix(3)) ?? 1) + (Int(opponent.id.suffix(3)) ?? 1)
        return max(0, seed % 8)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        comparisonSection
                        strengthsSection
                        playTogetherSection
                        challengeButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82).delay(0.25)) {
                barsAppeared = true
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.65)) {
                strengthsAppeared = true
            }
        }
    }

    // MARK: - Header (two avatars + VS badge)

    private var headerSection: some View {
        ZStack {
            // Background card
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.dinkrNavy, Color.dinkrNavy.opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Subtle court lines
            CourtLinesOverlay()
                .opacity(0.06)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            HStack(spacing: 0) {
                // Current user side
                playerHeaderColumn(currentUser, isCurrentUser: true)

                // VS badge
                ZStack {
                    Circle()
                        .fill(Color.dinkrAmber)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.dinkrAmber.opacity(0.45), radius: 8, x: 0, y: 3)
                    Text("VS")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(Color.dinkrNavy)
                }

                // Opponent side
                playerHeaderColumn(opponent, isCurrentUser: false)
            }
            .padding(.vertical, 22)
        }
        .frame(maxWidth: .infinity)
    }

    private func playerHeaderColumn(_ user: User, isCurrentUser: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(
                        isCurrentUser ? Color.dinkrGreen : Color.dinkrCoral,
                        lineWidth: 2.5
                    )
                    .frame(width: 72, height: 72)
                AvatarView(
                    urlString: user.avatarURL,
                    displayName: user.displayName,
                    size: 66
                )
            }

            Text(isCurrentUser ? "You" : user.displayName.components(separatedBy: " ").first ?? user.displayName)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text("@\(user.username)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(1)

            if let dupr = user.duprRating {
                Text(String(format: "%.2f", dupr))
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(Color.dinkrAmber)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.dinkrAmber.opacity(0.18), in: Capsule())
            } else {
                Text(user.skillLevel.label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.dinkrSky)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.dinkrSky.opacity(0.18), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Comparison Rows

    private var comparisonSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Stats Comparison", icon: "chart.bar.fill")
                .padding(.bottom, 12)

            VStack(spacing: 10) {
                ForEach(ComparisonStat.all(current: currentUser, opponent: opponent)) { stat in
                    ComparisonRowView(stat: stat, barsAppeared: barsAppeared)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.secondary.opacity(0.08), lineWidth: 1))
    }

    // MARK: - Strengths Section

    private var strengthsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Strengths Breakdown", icon: "bolt.heart.fill")

            HStack(alignment: .top, spacing: 12) {
                strengthsCard(
                    title: "You excel at",
                    icon: "checkmark.seal.fill",
                    iconColor: Color.dinkrGreen,
                    strengths: currentUserStrengths
                )
                strengthsCard(
                    title: "They excel at",
                    icon: "checkmark.seal.fill",
                    iconColor: Color.dinkrCoral,
                    strengths: opponentStrengths
                )
            }
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.secondary.opacity(0.08), lineWidth: 1))
        .opacity(strengthsAppeared ? 1 : 0)
        .offset(y: strengthsAppeared ? 0 : 16)
    }

    private func strengthsCard(title: String, icon: String, iconColor: Color, strengths: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.3)
            }

            VStack(alignment: .leading, spacing: 5) {
                ForEach(strengths, id: \.self) { strength in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(iconColor)
                            .frame(width: 5, height: 5)
                        Text(strength)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var currentUserStrengths: [String] {
        strengthsForUser(currentUser)
    }

    private var opponentStrengths: [String] {
        strengthsForUser(opponent)
    }

    private func strengthsForUser(_ user: User) -> [String] {
        let pool: [[String]] = [
            ["Consistency", "Dinking"],
            ["Power", "Serving"],
            ["Third Shot Drop", "Resets"],
            ["Lobbing", "Court Coverage"],
            ["Speed-Ups", "Volleys"],
            ["Kitchen Game", "Patience"],
        ]
        let index = (user.gamesPlayed + user.wins) % pool.count
        return pool[index]
    }

    // MARK: - Play Together Section

    private var playTogetherSection: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.dinkrSky.opacity(0.15))
                    .frame(width: 46, height: 46)
                Image(systemName: "figure.2.arms.open")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.dinkrSky)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(mutualGamesCount == 0
                     ? "No games together yet"
                     : "You've played together \(mutualGamesCount) time\(mutualGamesCount == 1 ? "" : "s")")
                    .font(.subheadline.weight(.semibold))
                Text(mutualGamesCount == 0
                     ? "Challenge them to your first match!"
                     : "Keep the rivalry going")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if mutualGamesCount > 0 {
                Text("\(mutualGamesCount)")
                    .font(.title2.weight(.black))
                    .foregroundStyle(Color.dinkrSky)
                    .monospacedDigit()
            }
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.secondary.opacity(0.08), lineWidth: 1))
    }

    // MARK: - Challenge Button

    private var challengeButton: some View {
        Button {
            HapticManager.medium()
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 15, weight: .bold))
                Text("Challenge \(opponent.displayName.components(separatedBy: " ").first ?? opponent.displayName)")
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
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

// MARK: - ComparisonStat Model

struct ComparisonStat: Identifiable {
    let id: String
    let label: String
    let icon: String
    let leftValue: String
    let rightValue: String
    let leftRaw: Double   // 0…1 normalized for fill bar
    let rightRaw: Double  // 0…1 normalized for fill bar

    var leftIsBetter: Bool { leftRaw >= rightRaw }
    var rightIsBetter: Bool { rightRaw > leftRaw }

    static func all(current: User, opponent: User) -> [ComparisonStat] {
        let currentDUPR  = current.duprRating ?? (3.0 + Double(current.skillLevel.sortIndex) * 0.35)
        let opponentDUPR = opponent.duprRating ?? (3.0 + Double(opponent.skillLevel.sortIndex) * 0.35)
        let duprMax      = max(currentDUPR, opponentDUPR, 5.5)

        let currentWR  = current.winRate
        let opponentWR = opponent.winRate

        let maxGames = Double(max(current.gamesPlayed, opponent.gamesPlayed, 1))

        let currentStreak  = Double(max(1, (current.wins * 3) % 7 + 1))
        let opponentStreak = Double(max(1, (opponent.wins * 3) % 7 + 1))
        let maxStreak = max(currentStreak, opponentStreak, 1)

        // Avg points per game: mock deterministic value
        let currentAvg  = current.gamesPlayed > 0
            ? 7.0 + (Double(current.wins) / Double(current.gamesPlayed)) * 4.0
            : 7.0
        let opponentAvg = opponent.gamesPlayed > 0
            ? 7.0 + (Double(opponent.wins) / Double(opponent.gamesPlayed)) * 4.0
            : 7.0
        let maxAvg = max(currentAvg, opponentAvg, 1)

        // Best win: opponent skill level (higher = better win)
        let currentBestWin  = bestWinScore(user: current)
        let opponentBestWin = bestWinScore(user: opponent)
        let maxBestWin = max(currentBestWin, opponentBestWin, 1)

        return [
            ComparisonStat(
                id: "dupr",
                label: "DUPR Rating",
                icon: "star.fill",
                leftValue: String(format: "%.2f", currentDUPR),
                rightValue: String(format: "%.2f", opponentDUPR),
                leftRaw: currentDUPR / duprMax,
                rightRaw: opponentDUPR / duprMax
            ),
            ComparisonStat(
                id: "winrate",
                label: "Win Rate",
                icon: "percent",
                leftValue: "\(Int(currentWR * 100))%",
                rightValue: "\(Int(opponentWR * 100))%",
                leftRaw: currentWR,
                rightRaw: opponentWR
            ),
            ComparisonStat(
                id: "games",
                label: "Games Played",
                icon: "figure.pickleball",
                leftValue: "\(current.gamesPlayed)",
                rightValue: "\(opponent.gamesPlayed)",
                leftRaw: Double(current.gamesPlayed) / maxGames,
                rightRaw: Double(opponent.gamesPlayed) / maxGames
            ),
            ComparisonStat(
                id: "avgpts",
                label: "Avg Pts / Game",
                icon: "chart.line.uptrend.xyaxis",
                leftValue: String(format: "%.1f", currentAvg),
                rightValue: String(format: "%.1f", opponentAvg),
                leftRaw: currentAvg / maxAvg,
                rightRaw: opponentAvg / maxAvg
            ),
            ComparisonStat(
                id: "streak",
                label: "Current Streak",
                icon: "flame.fill",
                leftValue: "\(Int(currentStreak))W",
                rightValue: "\(Int(opponentStreak))W",
                leftRaw: currentStreak / maxStreak,
                rightRaw: opponentStreak / maxStreak
            ),
            ComparisonStat(
                id: "bestwin",
                label: "Best Win",
                icon: "trophy.fill",
                leftValue: bestWinLabel(user: current),
                rightValue: bestWinLabel(user: opponent),
                leftRaw: currentBestWin / maxBestWin,
                rightRaw: opponentBestWin / maxBestWin
            ),
        ]
    }

    private static func bestWinScore(user: User) -> Double {
        // Mock: deterministic from win count
        let index = user.wins % 7
        let levels: [Double] = [3.0, 3.5, 3.5, 4.0, 4.0, 4.5, 5.0]
        return levels[index]
    }

    private static func bestWinLabel(user: User) -> String {
        let index = user.wins % 7
        let labels = ["3.0", "3.5", "3.5", "4.0", "4.0", "4.5", "5.0+"]
        return labels[index]
    }
}

// MARK: - ComparisonRowView

private struct ComparisonRowView: View {
    let stat: ComparisonStat
    let barsAppeared: Bool

    var body: some View {
        VStack(spacing: 6) {
            // Values + label row
            HStack(alignment: .center, spacing: 0) {
                // Left value (current user)
                Text(stat.leftValue)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(stat.leftIsBetter ? Color.dinkrGreen : Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Center label
                HStack(spacing: 4) {
                    Image(systemName: stat.icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.dinkrGreen)
                    Text(stat.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: 130)

                // Right value (opponent)
                Text(stat.rightValue)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(stat.rightIsBetter ? Color.dinkrGreen : Color.primary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Dual fill bar
            GeometryReader { proxy in
                let totalWidth = proxy.size.width
                let leftFill = totalWidth * (barsAppeared ? stat.leftRaw : 0)
                let rightFill = totalWidth * (barsAppeared ? stat.rightRaw : 0)

                HStack(spacing: 2) {
                    // Left bar (fills left→center)
                    ZStack(alignment: .trailing) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.1))
                        Capsule()
                            .fill(stat.leftIsBetter ? Color.dinkrGreen : Color.dinkrSky)
                            .frame(width: leftFill / 2)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 5)
                    .clipped()

                    // Right bar (fills right→center)
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.1))
                        Capsule()
                            .fill(stat.rightIsBetter ? Color.dinkrGreen : Color.dinkrSky)
                            .frame(width: rightFill / 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 5)
                    .clipped()
                }
                .animation(.spring(response: 0.55, dampingFraction: 0.78), value: barsAppeared)
            }
            .frame(height: 5)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(Color.appBackground.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - CourtLinesOverlay (local, for header card)

private struct CourtLinesOverlay: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width; let h = size.height
            var path = Path()
            path.move(to: .init(x: 0, y: h * 0.4))
            path.addLine(to: .init(x: w, y: h * 0.4))
            path.move(to: .init(x: 0, y: h * 0.6))
            path.addLine(to: .init(x: w, y: h * 0.6))
            path.move(to: .init(x: w * 0.5, y: 0))
            path.addLine(to: .init(x: w * 0.5, y: h))
            ctx.stroke(path, with: .color(.white), lineWidth: 1.2)
        }
    }
}

// MARK: - Preview

#Preview("Player Comparison") {
    PlayerComparisonView(
        currentUser: User.mockCurrentUser,
        opponent: User.mockPlayers[0]
    )
}

#Preview("Player Comparison – Higher Opponent") {
    PlayerComparisonView(
        currentUser: User.mockCurrentUser,
        opponent: User.mockPlayers[6]
    )
}

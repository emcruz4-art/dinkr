import SwiftUI

// MARK: - HeadToHeadView

struct HeadToHeadView: View {
    let playerA: User
    let playerB: User

    @Environment(\.dismiss) private var dismiss

    // MARK: Mock head-to-head data

    private let h2hWins = 3
    private let h2hLosses = 2

    private var mockMatches: [H2HMatch] {
        [
            H2HMatch(id: "m1", date: Date().addingTimeInterval(-86400 * 3),
                     scoreA: 11, scoreB: 8, courtName: "Westside Pickleball Complex"),
            H2HMatch(id: "m2", date: Date().addingTimeInterval(-86400 * 10),
                     scoreA: 7, scoreB: 11, courtName: "Mueller Recreation Center"),
            H2HMatch(id: "m3", date: Date().addingTimeInterval(-86400 * 18),
                     scoreA: 11, scoreB: 9, courtName: "South Lamar Sports Club"),
            H2HMatch(id: "m4", date: Date().addingTimeInterval(-86400 * 25),
                     scoreA: 11, scoreB: 6, courtName: "Barton Springs Tennis Center"),
            H2HMatch(id: "m5", date: Date().addingTimeInterval(-86400 * 33),
                     scoreA: 9, scoreB: 11, courtName: "Mueller Recreation Center"),
        ]
    }

    private var statsRows: [StatRow] {
        let duprA = playerA.duprRating ?? (Double(playerA.wins) / max(Double(playerA.gamesPlayed), 1) * 2.5 + 2.0)
        let duprB = playerB.duprRating ?? (Double(playerB.wins) / max(Double(playerB.gamesPlayed), 1) * 2.5 + 2.0)
        let winRateA = playerA.winRate * 100
        let winRateB = playerB.winRate * 100
        let streakA = max(1, (playerA.wins * 3) % 7 + 1)
        let streakB = max(1, (playerB.wins * 3) % 7 + 1)
        let avgScoreA = 9.4
        let avgScoreB = 8.7

        return [
            StatRow(name: "DUPR",
                    valueA: String(format: "%.2f", duprA),
                    numericA: duprA,
                    valueB: String(format: "%.2f", duprB),
                    numericB: duprB),
            StatRow(name: "Win Rate",
                    valueA: String(format: "%.0f%%", winRateA),
                    numericA: winRateA,
                    valueB: String(format: "%.0f%%", winRateB),
                    numericB: winRateB),
            StatRow(name: "Games Played",
                    valueA: "\(playerA.gamesPlayed)",
                    numericA: Double(playerA.gamesPlayed),
                    valueB: "\(playerB.gamesPlayed)",
                    numericB: Double(playerB.gamesPlayed)),
            StatRow(name: "Avg Score",
                    valueA: String(format: "%.1f", avgScoreA),
                    numericA: avgScoreA,
                    valueB: String(format: "%.1f", avgScoreB),
                    numericB: avgScoreB),
            StatRow(name: "Streak",
                    valueA: "\(streakA)W",
                    numericA: Double(streakA),
                    valueB: "\(streakB)W",
                    numericB: Double(streakB)),
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    h2hRecordSection
                    statsSection
                    recentMatchesSection
                    challengeButton
                        .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(Color.appBackground)
            .navigationTitle("Head to Head")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
    }

    // MARK: - Header: avatars + VS

    private var headerSection: some View {
        ZStack {
            // Background gradient card
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [Color.dinkrNavy, Color.dinkrNavy.opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            HStack(spacing: 0) {
                // Player A
                playerAvatarBlock(player: playerA, alignment: .leading)

                Spacer()

                // VS badge
                ZStack {
                    Circle()
                        .fill(Color.dinkrAmber)
                        .frame(width: 52, height: 52)
                        .shadow(color: Color.dinkrAmber.opacity(0.5), radius: 10, x: 0, y: 4)
                    Text("VS")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(Color.dinkrNavy)
                }

                Spacer()

                // Player B
                playerAvatarBlock(player: playerB, alignment: .trailing)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
    }

    private func playerAvatarBlock(player: User, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 8) {
            AvatarView(urlString: player.avatarURL, displayName: player.displayName, size: 68)
                .overlay(
                    Circle()
                        .stroke(Color.dinkrGreen, lineWidth: 2.5)
                )

            Text(player.displayName)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("@\(player.username)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.55))

            SkillBadge(level: player.skillLevel, compact: true)
        }
        .frame(width: 110)
    }

    // MARK: - H2H Record

    private var h2hRecordSection: some View {
        VStack(spacing: 6) {
            Text("HEAD TO HEAD RECORD")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(1.0)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(h2hWins)")
                    .font(.system(size: 64, weight: .black))
                    .foregroundStyle(Color.dinkrGreen)

                Text("  –  ")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Color.secondary)

                Text("\(h2hLosses)")
                    .font(.system(size: 64, weight: .black))
                    .foregroundStyle(Color.dinkrCoral)
            }

            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text(playerA.displayName.components(separatedBy: " ").first ?? playerA.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                    Text("Wins")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 2) {
                    Text(playerB.displayName.components(separatedBy: " ").first ?? playerB.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrCoral)
                    Text("Wins")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Stats Comparison Table

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Stats Comparison", icon: "chart.bar.fill")

            VStack(spacing: 2) {
                // Column header
                HStack {
                    Text(playerA.displayName.components(separatedBy: " ").first ?? "Player A")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.dinkrGreen)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("STAT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(0.8)
                        .frame(width: 90)

                    Text(playerB.displayName.components(separatedBy: " ").first ?? "Player B")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.dinkrCoral)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 4)

                ForEach(statsRows) { row in
                    StatComparisonRow(row: row)
                }
            }
        }
        .padding(14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Recent Matches

    private var recentMatchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Recent Matches", icon: "clock.arrow.circlepath")

            VStack(spacing: 8) {
                ForEach(mockMatches) { match in
                    H2HMatchRow(
                        match: match,
                        playerAName: playerA.displayName.components(separatedBy: " ").first ?? "A",
                        playerBName: playerB.displayName.components(separatedBy: " ").first ?? "B"
                    )
                }
            }
        }
        .padding(14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Challenge Again Button

    private var challengeButton: some View {
        Button {
            HapticManager.light()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 15, weight: .bold))
                Text("Challenge Again")
                    .font(.headline.weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.82)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 10, x: 0, y: 5)
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
}

// MARK: - StatComparisonRow

private struct StatComparisonRow: View {
    let row: StatRow

    private var total: Double { row.numericA + row.numericB }
    private var fractionA: Double { total > 0 ? row.numericA / total : 0.5 }
    private var aWins: Bool { row.numericA > row.numericB }
    private var bWins: Bool { row.numericB > row.numericA }
    private var tied: Bool { row.numericA == row.numericB }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(row.valueA)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(aWins ? Color.dinkrGreen : tied ? Color.primary : Color.primary.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(row.name)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.3)
                    .frame(width: 90, alignment: .center)
                    .multilineTextAlignment(.center)

                Text(row.valueB)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(bWins ? Color.dinkrCoral : tied ? Color.primary : Color.primary.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Proportion bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.1))
                        .frame(height: 6)

                    // Player A fill (left side)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(aWins ? Color.dinkrGreen : Color.secondary.opacity(0.3))
                        .frame(width: geo.size.width * fractionA, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - H2HMatchRow

private struct H2HMatchRow: View {
    let match: H2HMatch
    let playerAName: String
    let playerBName: String

    private var aWon: Bool { match.scoreA > match.scoreB }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            // W/L pill
            Text(aWon ? "W" : "L")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(aWon ? Color.dinkrGreen : Color.dinkrCoral, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(match.courtName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(Self.dateFormatter.string(from: match.date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Score
            HStack(spacing: 4) {
                Text("\(match.scoreA)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(aWon ? Color.dinkrGreen : Color.primary)
                Text("–")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(match.scoreB)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(!aWon ? Color.dinkrCoral : Color.primary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Supporting Models

private struct StatRow: Identifiable {
    let id = UUID()
    let name: String
    let valueA: String
    let numericA: Double
    let valueB: String
    let numericB: Double
}

private struct H2HMatch: Identifiable {
    let id: String
    let date: Date
    let scoreA: Int
    let scoreB: Int
    let courtName: String
}

// MARK: - Preview

#Preview {
    HeadToHeadView(
        playerA: User.mockCurrentUser,
        playerB: User.mockPlayers[0]
    )
}

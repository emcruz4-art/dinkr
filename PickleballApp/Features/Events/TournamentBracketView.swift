import SwiftUI

// MARK: - Models

struct LegacyBracketMatch: Identifiable {
    var id: String
    var round: Int        // 1 = quarterfinal, 2 = semifinal, 3 = final
    var player1Name: String
    var player2Name: String
    var score1: String?   // "11-8" or nil if not played
    var score2: String?
    var winner: Int?      // 1 or 2, nil if not played
}

extension LegacyBracketMatch {
    /// 8-player single-elimination bracket — 3 rounds, 7 matches.
    /// Some matches are complete, some are pending.
    static let mockBracket: [LegacyBracketMatch] = [
        // Round 1 — Quarterfinals (4 matches)
        LegacyBracketMatch(id: "m1", round: 1, player1Name: "Alex Rivera",   player2Name: "Sam Torres",
                     score1: "11",  score2: "7",  winner: 1),
        LegacyBracketMatch(id: "m2", round: 1, player1Name: "Jordan Smith",  player2Name: "Casey Nguyen",
                     score1: "9",   score2: "11", winner: 2),
        LegacyBracketMatch(id: "m3", round: 1, player1Name: "Morgan Davis",  player2Name: "Riley Park",
                     score1: "11",  score2: "5",  winner: 1),
        LegacyBracketMatch(id: "m4", round: 1, player1Name: "Taylor Kim",    player2Name: "Jamie Lee",
                     score1: "11",  score2: "9",  winner: 1),
        // Round 2 — Semifinals (2 matches)
        LegacyBracketMatch(id: "m5", round: 2, player1Name: "Alex Rivera",   player2Name: "Casey Nguyen",
                     score1: "11",  score2: "8",  winner: 1),
        LegacyBracketMatch(id: "m6", round: 2, player1Name: "Morgan Davis",  player2Name: "Taylor Kim",
                     score1: nil,   score2: nil,  winner: nil),
        // Round 3 — Final (1 match)
        LegacyBracketMatch(id: "m7", round: 3, player1Name: "Alex Rivera",   player2Name: "TBD",
                     score1: nil,   score2: nil,  winner: nil),
    ]
}

// MARK: - LegacyBracketMatchCard

private struct LegacyBracketMatchCard: View {
    let match: LegacyBracketMatch

    var body: some View {
        VStack(spacing: 0) {
            playerRow(
                name: match.player1Name,
                score: match.score1,
                isWinner: match.winner == 1,
                isPending: match.winner == nil
            )
            Divider()
            playerRow(
                name: match.player2Name,
                score: match.score2,
                isWinner: match.winner == 2,
                isPending: match.winner == nil
            )
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    match.winner == nil
                        ? Color.secondary.opacity(0.4)
                        : Color.clear,
                    style: match.winner == nil
                        ? StrokeStyle(lineWidth: 1.5, dash: [5, 3])
                        : StrokeStyle(lineWidth: 0)
                )
        )
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private func playerRow(name: String, score: String?, isWinner: Bool, isPending: Bool) -> some View {
        HStack(spacing: 0) {
            // Winner accent border
            Rectangle()
                .fill(isWinner ? Color.dinkrGreen : Color.clear)
                .frame(width: 4)

            HStack(spacing: 6) {
                Text(name)
                    .font(.system(size: 13, weight: isWinner ? .bold : .regular))
                    .foregroundColor(isWinner ? Color.primary : Color.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                if let score = score {
                    Text(score)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(isWinner ? Color.dinkrCoral : Color.secondary)
                } else if isPending {
                    Text("—")
                        .font(.system(size: 13))
                        .foregroundColor(Color.secondary.opacity(0.5))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
        }
        .frame(height: 38)
    }
}

// MARK: - Connector Line

private struct ConnectorLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.25))
            .frame(width: 20, height: 1.5)
    }
}

// MARK: - Bracket Column

private struct BracketColumn: View {
    let title: String
    let matches: [LegacyBracketMatch]
    let topPadding: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.secondary)
                .padding(.bottom, 8)

            Spacer().frame(height: topPadding)

            ForEach(Array(matches.enumerated()), id: \.element.id) { index, match in
                LegacyBracketMatchCard(match: match)
                    .frame(width: 180)
                if index < matches.count - 1 {
                    Spacer().frame(height: spacingBetweenCards)
                }
            }

            Spacer()
        }
    }

    private var spacingBetweenCards: CGFloat {
        switch matches.count {
        case 4: return 16
        case 2: return 92
        default: return 0
        }
    }
}

// MARK: - Champion Display

private struct ChampionDisplay: View {
    let winnerName: String?

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 32))
                .foregroundColor(Color.dinkrAmber)

            Text("Champion")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.secondary)

            Text(winnerName ?? "TBD")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(winnerName != nil ? Color.dinkrNavy : Color.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 120)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.cardBackground)
                .shadow(color: Color.dinkrAmber.opacity(0.18), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.dinkrAmber.opacity(0.4), lineWidth: 1.5)
        )
    }
}

// MARK: - Results Row

private struct BracketResultRow: View {
    let match: LegacyBracketMatch
    let roundLabel: String

    var body: some View {
        HStack(spacing: 12) {
            // Round badge
            Text(roundLabel)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.dinkrNavy.opacity(0.75))
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if match.winner == 1 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.dinkrGreen)
                    }
                    Text(match.player1Name)
                        .font(.system(size: 13, weight: match.winner == 1 ? .bold : .regular))
                        .foregroundColor(match.winner == 1 ? Color.primary : Color.secondary)
                }
                HStack(spacing: 4) {
                    if match.winner == 2 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.dinkrGreen)
                    }
                    Text(match.player2Name)
                        .font(.system(size: 13, weight: match.winner == 2 ? .bold : .regular))
                        .foregroundColor(match.winner == 2 ? Color.primary : Color.secondary)
                }
            }

            Spacer()

            if let s1 = match.score1, let s2 = match.score2 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(s1)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(match.winner == 1 ? Color.dinkrCoral : Color.secondary)
                    Text(s2)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(match.winner == 2 ? Color.dinkrCoral : Color.secondary)
                }
            } else {
                Text("Pending")
                    .font(.system(size: 12))
                    .foregroundColor(Color.secondary.opacity(0.6))
                    .italic()
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
    }
}

// MARK: - TournamentBracketView

struct TournamentBracketView: View {
    let event: Event
    @State private var selectedTab: Int = 0

    private let allMatches: [LegacyBracketMatch] = LegacyBracketMatch.mockBracket

    private var quarterfinals: [LegacyBracketMatch] { allMatches.filter { $0.round == 1 } }
    private var semifinals: [LegacyBracketMatch]    { allMatches.filter { $0.round == 2 } }
    private var finals: [LegacyBracketMatch]        { allMatches.filter { $0.round == 3 } }

    private var champion: String? {
        guard let finalMatch = finals.first, let w = finalMatch.winner else { return nil }
        return w == 1 ? finalMatch.player1Name : finalMatch.player2Name
    }

    private var completedMatches: [LegacyBracketMatch] {
        allMatches.filter { $0.winner != nil }
    }

    private func roundLabel(for match: LegacyBracketMatch) -> String {
        switch match.round {
        case 1: return "QF"
        case 2: return "SF"
        case 3: return "F"
        default: return "R\(match.round)"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.primary)

                    HStack(spacing: 12) {
                        Label(event.dateTime.formatted(date: .abbreviated, time: .omitted),
                              systemImage: "calendar")
                        Label("8 Players", systemImage: "person.3.fill")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(Color.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Segmented control
                Picker("View", selection: $selectedTab) {
                    Text("Bracket").tag(0)
                    Text("Results").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                if selectedTab == 0 {
                    bracketView
                } else {
                    resultsView
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Tournament Bracket")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: Bracket Tab

    private var bracketView: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {
                // Quarterfinals column
                BracketColumn(title: "Quarterfinals", matches: quarterfinals, topPadding: 0)

                // QF → SF connectors
                connectorsGroup(count: 4, cardHeight: 76, spacing: 16)

                // Semifinals column
                BracketColumn(title: "Semifinals", matches: semifinals, topPadding: 46)

                // SF → Final connectors
                connectorsGroup(count: 2, cardHeight: 76, spacing: 92)

                // Final column
                BracketColumn(title: "Final", matches: finals, topPadding: 138)

                // Final → Champion connector
                HStack(spacing: 0) {
                    ConnectorLine()
                }
                .padding(.top, 214)

                // Champion display
                VStack(spacing: 0) {
                    Spacer().frame(height: 176)
                    ChampionDisplay(winnerName: champion)
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    /// Renders vertical bracket connectors between rounds.
    @ViewBuilder
    private func connectorsGroup(count: Int, cardHeight: CGFloat, spacing: CGFloat) -> some View {
        let pairCount = count / 2
        VStack(spacing: 0) {
            ForEach(0..<pairCount, id: \.self) { _ in
                VStack(spacing: 0) {
                    // Top horizontal line
                    HStack(spacing: 0) {
                        ConnectorLine()
                        Spacer()
                    }
                    .frame(width: 20, height: 1.5)
                    .padding(.top, cardHeight / 2 - 0.75)

                    // Vertical bridge
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.25))
                            .frame(width: 1.5)
                    }
                    .frame(width: 20, height: spacing + cardHeight)

                    // Bottom horizontal line
                    HStack(spacing: 0) {
                        ConnectorLine()
                        Spacer()
                    }
                    .frame(width: 20, height: 1.5)
                    .padding(.bottom, cardHeight / 2 - 0.75)

                    // Mid connector out to next column
                    HStack(spacing: 0) {
                        Spacer()
                        ConnectorLine()
                    }
                    .frame(width: 20, height: 1.5)
                    .offset(y: -(spacing + cardHeight) / 2 - cardHeight / 2 - 0.75)
                }
                .frame(width: 20)
            }
        }
        .frame(width: 20)
    }

    // MARK: Results Tab

    private var resultsView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if completedMatches.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 36))
                            .foregroundColor(Color.secondary.opacity(0.5))
                        Text("No results yet")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    ForEach(completedMatches) { match in
                        BracketResultRow(match: match, roundLabel: roundLabel(for: match))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Preview

#Preview {
    TournamentBracketView(event: Event.mockEvents[0])
}

import SwiftUI

struct GameHistoryView: View {
    let results: [GameResult] = GameResult.mockResults

    var wins: Int { results.filter { $0.isWin }.count }
    var losses: Int { results.filter { !$0.isWin }.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Stats summary card
                HStack(spacing: 0) {
                    StatPillCard(value: "\(wins)", label: "Wins", color: Color.dinkrGreen)
                    Divider().frame(height: 40)
                    StatPillCard(value: "\(losses)", label: "Losses", color: Color.dinkrCoral)
                    Divider().frame(height: 40)
                    StatPillCard(value: "\(Int(Double(wins) / Double(max(results.count, 1)) * 100))%", label: "Win Rate", color: Color.dinkrSky)
                }
                .padding(.horizontal)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                .padding(.top, 12)

                // Game history timeline
                LazyVStack(spacing: 10) {
                    ForEach(results) { result in
                        GameResultRow(result: result)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }
}

struct StatPillCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.heavy))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}

struct GameResultRow: View {
    let result: GameResult

    var body: some View {
        HStack(spacing: 12) {
            // W/L badge
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(result.isWin ? Color.dinkrGreen.opacity(0.15) : Color.dinkrCoral.opacity(0.15))
                    .frame(width: 36, height: 36)
                Text(result.isWin ? "W" : "L")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(result.isWin ? Color.dinkrGreen : Color.dinkrCoral)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("vs. \(result.opponentName)")
                        .font(.subheadline.weight(.semibold))
                    SkillBadge(level: result.opponentSkill)
                }
                HStack(spacing: 8) {
                    Text(result.courtName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(result.format.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(result.scoreDisplay)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(result.isWin ? Color.dinkrGreen : Color.dinkrCoral)
                Text(result.playedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

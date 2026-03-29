import SwiftUI

struct GameSummaryCard: View {
    let result: GameResult

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 10) {
                AvatarView(displayName: "Alex Rivera", size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Alex Rivera")
                        .font(.subheadline.weight(.semibold))
                    Text("played a game · " + result.playedAt.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "figure.pickleball")
                    .foregroundStyle(Color.dinkrGreen)
            }
            .padding(14)

            // Result banner
            ZStack {
                LinearGradient(
                    colors: result.isWin
                        ? [Color.dinkrGreen.opacity(0.8), Color.dinkrNavy]
                        : [Color.dinkrCoral.opacity(0.6), Color.dinkrNavy],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 80)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.isWin ? "Victory 🏆" : "Tough Loss")
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(.white)
                        Text("vs. \(result.opponentName)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                    Text(result.scoreDisplay)
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
            }

            // Stats row
            HStack(spacing: 0) {
                SummaryStatCell(value: result.format.rawValue.capitalized, label: "Format", icon: "figure.pickleball")
                Divider().frame(height: 40)
                SummaryStatCell(value: result.courtName.components(separatedBy: " ").first ?? "Court", label: "Court", icon: "sportscourt.fill")
                Divider().frame(height: 40)
                SummaryStatCell(value: result.opponentSkill.label, label: "Opponent", icon: "person.fill")
            }
            .padding(.vertical, 8)
            .background(Color.cardBackground)

            // Reactions + Kudos
            HStack(spacing: 16) {
                Button {} label: {
                    HStack(spacing: 5) {
                        Image(systemName: "hands.clap.fill")
                            .foregroundStyle(Color.dinkrAmber)
                        Text("Kudos")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Button {} label: {
                    HStack(spacing: 5) {
                        Image(systemName: "bubble.right")
                            .foregroundStyle(.secondary)
                        Text("Comment")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Text("24 kudos")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

private struct SummaryStatCell: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(Color.dinkrGreen)
            Text(value)
                .font(.caption.weight(.bold))
                .lineLimit(1)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

#Preview {
    GameSummaryCard(result: GameResult.mockResults[0])
        .padding()
}

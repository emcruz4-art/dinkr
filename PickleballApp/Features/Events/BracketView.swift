import SwiftUI

// MARK: - BracketMatchCard

struct BracketMatchCard: View {
    let match: NewBracketMatch

    var body: some View {
        VStack(spacing: 0) {
            playerRow(
                name: match.participantAName ?? "TBD",
                score: match.scoreA,
                isWinner: match.isComplete && match.winnerId == match.participantAId,
                isTBD: match.participantAId == nil
            )
            Divider()
            playerRow(
                name: match.participantBName ?? "TBD",
                score: match.scoreB,
                isWinner: match.isComplete && match.winnerId == match.participantBId,
                isTBD: match.participantBId == nil
            )
        }
        .frame(width: 160, height: 72)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .topTrailing) {
            if match.isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.dinkrGreen)
                    .padding(4)
            }
        }
        .shadow(color: Color.black.opacity(0.07), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private func playerRow(name: String, score: String, isWinner: Bool, isTBD: Bool) -> some View {
        HStack(spacing: 6) {
            // Winner accent strip
            Rectangle()
                .fill(isWinner ? Color.dinkrGreen : Color.clear)
                .frame(width: 3)

            Text(isTBD ? "TBD" : name)
                .font(.system(size: 12, weight: isWinner ? .bold : .regular))
                .foregroundStyle(isTBD ? Color.secondary : (isWinner ? Color.primary : Color.primary))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 2)

            if !score.isEmpty {
                Text(score)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isWinner ? Color.dinkrGreen : Color.secondary)
            }
        }
        .padding(.trailing, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - BracketView

struct BracketView: View {
    let bracket: Bracket

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Champion Banner
                    if let champ = bracket.champion {
                        championBanner(name: champ.displayName)
                    }

                    // Format badge
                    HStack {
                        Label(bracket.format.rawValue, systemImage: bracket.format.icon)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.dinkrGreen.opacity(0.12), in: Capsule())
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Bracket scroll
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 0) {
                            ForEach(Array(bracket.rounds.enumerated()), id: \.offset) { idx, roundMatches in
                                let roundNum = idx + 1
                                let isLast = roundNum == bracket.rounds.count

                                VStack(alignment: .leading, spacing: 12) {
                                    // Round column header
                                    Text(bracket.roundLabel(for: roundNum))
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color.secondary)
                                        .frame(width: 160, alignment: .center)

                                    ForEach(roundMatches) { match in
                                        BracketMatchCard(match: match)
                                    }
                                }
                                .padding(.leading, idx == 0 ? 16 : 0)

                                // Connector line between columns
                                if !isLast {
                                    Rectangle()
                                        .fill(Color.secondary.opacity(0.3))
                                        .frame(width: 20, height: 1)
                                        .padding(.top, 56) // align roughly to first card mid
                                }
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 8)
                    }

                    Divider().padding(.horizontal)

                    // Participants list
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Participants")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(bracket.participants) { participant in
                            participantRow(participant)
                        }
                    }
                    .padding(.bottom, 32)
                }
                .padding(.vertical)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("\(bracket.eventName) Bracket")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Champion Banner

    @ViewBuilder
    private func championBanner(name: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 28))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text("Champion")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Text(name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color.dinkrAmber, Color.dinkrAmber.opacity(0.75)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.dinkrAmber.opacity(0.35), radius: 8, x: 0, y: 3)
        .padding(.horizontal)
    }

    // MARK: - Participant Row

    @ViewBuilder
    private func participantRow(_ participant: BracketParticipant) -> some View {
        HStack(spacing: 12) {
            Text("#\(participant.seed)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.dinkrGreen)
                .frame(width: 32, alignment: .trailing)

            Text(participant.displayName)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            Text(participant.skillLevel.rawValue)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.secondary.opacity(0.1), in: Capsule())

            if let dupr = participant.duprRating {
                Label(String(format: "%.2f", dupr), systemImage: "star.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrAmber)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    BracketView(bracket: Bracket.mock)
}

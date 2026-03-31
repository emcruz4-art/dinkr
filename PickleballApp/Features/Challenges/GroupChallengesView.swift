import SwiftUI

// MARK: - GroupChallengesView

struct GroupChallengesView: View {
    @State private var showNewGroupChallenge = false

    private var activeChallenges: [GroupChallenge] {
        GroupChallenge.mockGroupChallenges.filter { $0.status == .active }
    }

    private var pendingChallenges: [GroupChallenge] {
        GroupChallenge.mockGroupChallenges.filter { $0.status == .pending }
    }

    var body: some View {
        ZStack {
            if GroupChallenge.mockGroupChallenges.isEmpty {
                GroupChallengesEmptyState()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Active Section
                        if !activeChallenges.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionLabel(text: "ACTIVE GROUP CHALLENGES")
                                    .padding(.horizontal, 20)

                                ForEach(activeChallenges) { challenge in
                                    GroupChallengeHeroCard(challenge: challenge)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }

                        // Pending Section
                        if !pendingChallenges.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionLabel(text: "PENDING")
                                    .padding(.horizontal, 20)

                                ForEach(pendingChallenges) { challenge in
                                    GroupChallengePendingRow(challenge: challenge)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 36)
                }
            }
        }
    }
}

// MARK: - Section Label

private struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(.secondary)
            .tracking(1)
    }
}

// MARK: - Hero Card (Active)

struct GroupChallengeHeroCard: View {
    let challenge: GroupChallenge

    private var total: Int { challenge.challengerScore + challenge.challengedScore }

    private var challengerFraction: CGFloat {
        guard total > 0 else { return 0.5 }
        return CGFloat(challenge.challengerScore) / CGFloat(total)
    }

    private var challengedFraction: CGFloat {
        guard total > 0 else { return 0.5 }
        return CGFloat(challenge.challengedScore) / CGFloat(total)
    }

    private var daysChipColor: Color {
        if challenge.isExpired { return Color.dinkrCoral }
        if challenge.daysRemaining <= 2 { return Color.dinkrAmber }
        return Color.dinkrSky
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Title + metric chip
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.dinkrGreen.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: challenge.metric.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(Color.dinkrGreen)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.dinkrNavy)
                        .lineLimit(2)
                    Text(challenge.metric.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(challenge.isExpired ? "Expired" : "\(challenge.daysRemaining)d left")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(daysChipColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(daysChipColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            // Score comparison
            HStack(alignment: .top, spacing: 12) {
                // Challenger group
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.challengerGroupName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(challenge.challengerPlayerCount) players")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // VS label
                Text("VS")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                    .padding(.top, 4)

                // Challenged group
                VStack(alignment: .trailing, spacing: 4) {
                    Text(challenge.challengedGroupName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.trailing)
                    Text("\(challenge.challengedPlayerCount) players")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Progress bars + scores
            VStack(spacing: 8) {
                // Challenger bar
                HStack(spacing: 10) {
                    Text("\(challenge.challengerScore)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.dinkrGreen)
                        .frame(minWidth: 36, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.secondary.opacity(0.12))
                                .frame(height: 10)
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.dinkrGreen)
                                .frame(width: geo.size.width * min(challengerFraction, 1.0), height: 10)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: challenge.challengerScore)
                        }
                    }
                    .frame(height: 10)
                }

                // Challenged bar
                HStack(spacing: 10) {
                    Text("\(challenge.challengedScore)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.dinkrCoral)
                        .frame(minWidth: 36, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.secondary.opacity(0.12))
                                .frame(height: 10)
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.dinkrCoral)
                                .frame(width: geo.size.width * min(challengedFraction, 1.0), height: 10)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: challenge.challengedScore)
                        }
                    }
                    .frame(height: 10)
                }
            }

            // Leading indicator
            if let leader = challenge.leadingGroupName {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.dinkrAmber)
                    Text("\(leader) leading")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrAmber)
                }
            } else {
                Text("Tied — anyone's game!")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrSky)
            }

            // Stakes
            if !challenge.stakes.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(challenge.stakes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.dinkrNavy.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // View Details button
            Button {
                HapticManager.selection()
            } label: {
                Text("View Details")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dinkrGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.dinkrGreen.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.dinkrGreen.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Pending Row

private struct GroupChallengePendingRow: View {
    let challenge: GroupChallenge

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.dinkrAmber.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: challenge.metric.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color.dinkrAmber)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dinkrNavy)
                    .lineLimit(2)

                Text("\(challenge.challengerGroupName) challenged \(challenge.challengedGroupName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Pending")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.dinkrAmber)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.dinkrAmber.opacity(0.12))
                    .clipShape(Capsule())

                Text("\(challenge.daysRemaining)d to start")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.dinkrAmber.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Empty State

private struct GroupChallengesEmptyState: View {
    var body: some View {
        EmptyStateView(
            icon: "person.3.fill",
            title: "No DinkrGroup Challenges",
            message: "Challenge another group to compete on aggregate metrics!"
        )
        .padding(.top, 60)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        GroupChallengesView()
            .navigationTitle("Challenges")
    }
    .environment(AuthService())
}

import SwiftUI

// MARK: - ChallengesView

struct ChallengesView: View {
    @State private var selectedSegment = 0
    @State private var showNewChallenge = false
    @Namespace private var segmentNamespace

    private let currentUserId = "user_001"
    private let segments = ["Active", "Pending", "History"]

    private var activeChallenges: [Challenge] {
        Challenge.mockChallenges.filter { $0.status == .active }
    }

    private var pendingChallenges: [Challenge] {
        Challenge.mockChallenges.filter { $0.status == .pending }
    }

    private var historyChallenges: [Challenge] {
        Challenge.mockChallenges.filter { $0.status == .completed || $0.status == .declined || $0.status == .cancelled }
    }

    private var winningCount: Int {
        activeChallenges.filter { challenge in
            guard let me = challenge.participants.first(where: { $0.id == currentUserId }),
                  let leader = challenge.leadingParticipant else { return false }
            return leader.id == me.id
        }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.dinkrNavy.opacity(0.04), Color.appBackground, Color.dinkrGreen.opacity(0.02)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Custom segmented control
                    ChallengesSegmentBar(segments: segments, selected: $selectedSegment, namespace: segmentNamespace)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    ScrollView {
                        VStack(spacing: 16) {
                            switch selectedSegment {
                            case 0:
                                ActiveTab(
                                    challenges: activeChallenges,
                                    currentUserId: currentUserId,
                                    winningCount: winningCount
                                )
                            case 1:
                                PendingTab(
                                    challenges: pendingChallenges,
                                    currentUserId: currentUserId
                                )
                            default:
                                HistoryTab(
                                    challenges: historyChallenges,
                                    currentUserId: currentUserId
                                )
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 36)
                    }
                }
            }
            .navigationTitle("Challenges")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.medium()
                        showNewChallenge = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                }
            }
        }
        .sheet(isPresented: $showNewChallenge) {
            NewChallengeView()
        }
    }
}

// MARK: - Segment Bar

private struct ChallengesSegmentBar: View {
    let segments: [String]
    @Binding var selected: Int
    let namespace: Namespace.ID

    var body: some View {
        HStack(spacing: 0) {
            ForEach(segments.indices, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        selected = i
                    }
                    HapticManager.selection()
                } label: {
                    VStack(spacing: 6) {
                        Text(segments[i])
                            .font(.subheadline.weight(selected == i ? .bold : .regular))
                            .foregroundStyle(selected == i ? Color.dinkrGreen : Color.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)

                        ZStack {
                            if selected == i {
                                Capsule()
                                    .fill(Color.dinkrGreen)
                                    .frame(height: 3)
                                    .matchedGeometryEffect(id: "challengeSegment", in: namespace)
                            } else {
                                Capsule().fill(Color.clear).frame(height: 3)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(alignment: .bottom) { Divider() }
    }
}

// MARK: - Active Tab

private struct ActiveTab: View {
    let challenges: [Challenge]
    let currentUserId: String
    let winningCount: Int

    var body: some View {
        VStack(spacing: 16) {
            // Standing card
            StandingCard(total: challenges.count, winning: winningCount)
                .padding(.horizontal, 20)

            if challenges.isEmpty {
                EmptyStateView(
                    icon: "trophy.fill",
                    title: "No Active Challenges",
                    message: "Tap + to challenge a friend!"
                )
                .padding(.top, 40)
            } else {
                ForEach(challenges) { challenge in
                    NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                        ChallengeCard(challenge: challenge, currentUserId: currentUserId)
                            .padding(.horizontal, 20)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Pending Tab

private struct PendingTab: View {
    let challenges: [Challenge]
    let currentUserId: String

    private var incoming: [Challenge] {
        challenges.filter { $0.challengerId != currentUserId }
    }

    private var outgoing: [Challenge] {
        challenges.filter { $0.challengerId == currentUserId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if incoming.isEmpty && outgoing.isEmpty {
                EmptyStateView(
                    icon: "bell.badge",
                    title: "No Pending Challenges",
                    message: "Incoming and outgoing challenges appear here"
                )
                .padding(.top, 40)
                .frame(maxWidth: .infinity)
            } else {
                if !incoming.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("INCOMING")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .tracking(1)
                            .padding(.horizontal, 20)

                        ForEach(incoming) { challenge in
                            NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                                ChallengeCard(challenge: challenge, currentUserId: currentUserId, showAcceptDecline: true)
                                    .padding(.horizontal, 20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !outgoing.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("OUTGOING")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .tracking(1)
                            .padding(.horizontal, 20)

                        ForEach(outgoing) { challenge in
                            NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                                ChallengeCard(challenge: challenge, currentUserId: currentUserId)
                                    .padding(.horizontal, 20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - History Tab

private struct HistoryTab: View {
    let challenges: [Challenge]
    let currentUserId: String

    var body: some View {
        VStack(spacing: 12) {
            if challenges.isEmpty {
                EmptyStateView(
                    icon: "clock.arrow.circlepath",
                    title: "No Challenge History",
                    message: "Completed challenges will appear here"
                )
                .padding(.top, 40)
            } else {
                ForEach(challenges) { challenge in
                    NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                        HistoryChallengeCard(challenge: challenge, currentUserId: currentUserId)
                            .padding(.horizontal, 20)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Standing Card

private struct StandingCard: View {
    let total: Int
    let winning: Int

    var losing: Int { total - winning }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your Standing")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                    .textCase(.uppercase)

                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Circle().fill(Color.dinkrGreen).frame(width: 10, height: 10)
                        Text("\(winning) Winning")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                    HStack(spacing: 6) {
                        Circle().fill(Color.dinkrCoral).frame(width: 10, height: 10)
                        Text("\(losing) Losing")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.dinkrCoral)
                    }
                }
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 5)
                    .frame(width: 52, height: 52)

                Circle()
                    .trim(from: 0, to: total > 0 ? Double(winning) / Double(total) : 0)
                    .stroke(Color.dinkrGreen, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))

                Text("\(total)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.dinkrNavy)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

// MARK: - ChallengeCard

struct ChallengeCard: View {
    let challenge: Challenge
    let currentUserId: String
    var showAcceptDecline: Bool = false

    @State private var accepted = false
    @State private var declined = false

    private var typeColor: Color { challenge.type.brandColor }

    private var daysChipColor: Color {
        if challenge.isExpired { return Color.dinkrCoral }
        if challenge.daysRemaining <= 2 { return Color.dinkrAmber }
        return Color.dinkrSky
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(typeColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: challenge.type.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(typeColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.dinkrNavy)
                        .lineLimit(1)
                    Text(challenge.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Days remaining chip
                if challenge.status == .active || challenge.status == .pending {
                    Text(challenge.isExpired ? "Expired" : "\(challenge.daysRemaining)d left")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(daysChipColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(daysChipColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            // Progress section (2 participants)
            if challenge.participants.count >= 2 {
                let p1 = challenge.participants[0]
                let p2 = challenge.participants[1]

                VStack(spacing: 8) {
                    ParticipantProgressRow(participant: p1, goalValue: challenge.goalValue, goalUnit: challenge.goalUnit, typeColor: typeColor)
                    ParticipantProgressRow(participant: p2, goalValue: challenge.goalValue, goalUnit: challenge.goalUnit, typeColor: Color.dinkrSky)
                }

                // VS divider label
                HStack {
                    Spacer()
                    Text("VS")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.secondary)
                        .tracking(1)
                    Spacer()
                }
                .padding(.vertical, -4)
            }

            // Accept / Decline row for incoming pending
            if showAcceptDecline && challenge.status == .pending && !accepted && !declined {
                HStack(spacing: 12) {
                    Button {
                        HapticManager.medium()
                        withAnimation { declined = true }
                    } label: {
                        Text("Decline")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrCoral)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.dinkrCoral.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)

                    Button {
                        HapticManager.medium()
                        withAnimation { accepted = true }
                    } label: {
                        Text("Accept")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.dinkrGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            } else if accepted {
                Label("Challenge Accepted!", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dinkrGreen)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if declined {
                Label("Challenge Declined", systemImage: "xmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(typeColor.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - ParticipantProgressRow

struct ParticipantProgressRow: View {
    let participant: ChallengeParticipant
    let goalValue: Double
    let goalUnit: String
    let typeColor: Color

    private var valueLabel: String {
        if goalValue < 1 {
            return String(format: "%.2f \(goalUnit)", participant.currentValue)
        } else if participant.currentValue == participant.currentValue.rounded() {
            return "\(Int(participant.currentValue)) \(goalUnit)"
        } else {
            return String(format: "%.1f \(goalUnit)", participant.currentValue)
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            AvatarView(urlString: participant.avatarURL, displayName: participant.displayName, size: 28)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(participant.displayName.components(separatedBy: " ").first ?? participant.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)
                    Spacer()
                    Text(valueLabel)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(typeColor)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.12))
                            .frame(height: 7)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(typeColor)
                            .frame(width: geo.size.width * min(participant.progress, 1.0), height: 7)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: participant.progress)
                    }
                }
                .frame(height: 7)
            }
        }
    }
}

// MARK: - History Challenge Card

private struct HistoryChallengeCard: View {
    let challenge: Challenge
    let currentUserId: String

    private var myResult: Bool? {
        challenge.participants.first(where: { $0.id == currentUserId })?.isWinner
    }

    private var winnerName: String {
        challenge.participants.first(where: { $0.isWinner })?.displayName ?? "—"
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(challenge.type.brandColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: challenge.type.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(challenge.type.brandColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dinkrNavy)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let won = myResult {
                        Text(won ? "You Won" : "You Lost")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(won ? Color.dinkrGreen : Color.dinkrCoral)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background((won ? Color.dinkrGreen : Color.dinkrCoral).opacity(0.12))
                            .clipShape(Capsule())
                    }
                    Text("vs \(challenge.participants.filter { $0.id != currentUserId }.first?.displayName ?? "—")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let msg = challenge.winnerMessage, !msg.isEmpty {
                Image(systemName: "quote.bubble.fill")
                    .foregroundStyle(Color.dinkrAmber.opacity(0.7))
                    .font(.system(size: 14))
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    ChallengesView()
        .environment(AuthService())
}

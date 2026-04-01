import SwiftUI

// MARK: - ChallengeSummaryDetailView

struct ChallengeSummaryDetailView: View {
    let challenge: Challenge
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService
    @State private var showLogProgress = false
    @State private var animateRings = false

    private var currentUserId: String { authService.currentUser?.id ?? "" }
    private var typeColor: Color { challenge.type.brandColor }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero header
                HeroHeader(challenge: challenge, typeColor: typeColor)

                // Content
                VStack(spacing: 20) {
                    // Participants rings
                    if challenge.participants.count >= 2 {
                        ParticipantsRingSection(
                            participants: challenge.participants,
                            challenge: challenge,
                            animateRings: animateRings,
                            typeColor: typeColor
                        )
                    }

                    // Winner banner
                    if challenge.status == .completed {
                        WinnerBanner(challenge: challenge, currentUserId: currentUserId, typeColor: typeColor)
                    }

                    // Challenge rules
                    RulesSection(challenge: challenge, typeColor: typeColor)

                    // Activity timeline
                    TimelineSection(typeColor: typeColor)

                    // Log Progress button
                    if challenge.status == .active {
                        Button {
                            HapticManager.medium()
                            showLogProgress = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                Text("Log Progress")
                                    .font(.headline)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [typeColor, typeColor.opacity(0.82)],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: typeColor.opacity(0.38), radius: 10, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .sheet(isPresented: $showLogProgress) {
            LogProgressSheet(challenge: challenge, typeColor: typeColor)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.25)) {
                animateRings = true
            }
        }
    }
}

// MARK: - Hero Header

private struct HeroHeader: View {
    let challenge: Challenge
    let typeColor: Color

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient background
            LinearGradient(
                colors: [Color.dinkrNavy, typeColor.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 200)

            // Decorative icon
            Image(systemName: challenge.type.icon)
                .font(.system(size: 120, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.06))
                .offset(x: 180, y: -20)

            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.18))
                            .frame(width: 42, height: 42)
                        Image(systemName: challenge.type.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(challenge.type.rawValue.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white.opacity(0.7))
                            .tracking(1.2)

                        StatusBadge(status: challenge.status)
                    }
                }
                .padding(.bottom, 4)

                Text(challenge.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text(challenge.description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(2)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: ChallengeStatus

    private var color: Color {
        switch status {
        case .active:    return Color.dinkrGreen
        case .pending:   return Color.dinkrAmber
        case .completed: return Color.dinkrSky
        case .declined:  return .secondary
        case .cancelled: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            if status == .active {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
            }
            Text(status.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.2))
        .clipShape(Capsule())
    }
}

// MARK: - Participants Ring Section

private struct ParticipantsRingSection: View {
    let participants: [ChallengeParticipant]
    let challenge: Challenge
    let animateRings: Bool
    let typeColor: Color

    private let ringColors: [Color] = [Color.dinkrGreen, Color.dinkrSky]

    var body: some View {
        VStack(spacing: 16) {
            Text("STANDINGS")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .tracking(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            HStack(spacing: 0) {
                ForEach(participants.indices, id: \.self) { i in
                    let p = participants[i]
                    let color = ringColors[min(i, ringColors.count - 1)]

                    VStack(spacing: 12) {
                        ZStack {
                            // Track ring
                            Circle()
                                .stroke(color.opacity(0.15), lineWidth: 10)
                                .frame(width: 100, height: 100)

                            // Progress ring
                            Circle()
                                .trim(from: 0, to: animateRings ? min(p.progress, 1.0) : 0)
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(colors: [color.opacity(0.7), color]),
                                        center: .center,
                                        startAngle: .degrees(-90),
                                        endAngle: .degrees(270)
                                    ),
                                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                )
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 0.9, dampingFraction: 0.75).delay(Double(i) * 0.12), value: animateRings)

                            // Avatar
                            AvatarView(urlString: p.avatarURL, displayName: p.displayName, size: 72)

                            // Winner crown
                            if p.isWinner {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.dinkrAmber)
                                    .offset(y: -50)
                            }
                        }

                        VStack(spacing: 3) {
                            Text(p.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.dinkrNavy)

                            Text("@\(p.username)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            // Progress stat
                            if challenge.goalValue < 1 {
                                Text(String(format: "%.2f / %.2f \(challenge.goalUnit)", p.currentValue, challenge.goalValue))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(color)
                            } else {
                                Text("\(Int(p.currentValue)) / \(Int(challenge.goalValue)) \(challenge.goalUnit)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(color)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)
        }
    }
}

// MARK: - Winner Banner

private struct WinnerBanner: View {
    let challenge: Challenge
    let currentUserId: String
    let typeColor: Color

    private var winner: ChallengeParticipant? {
        challenge.participants.first(where: { $0.isWinner })
    }

    private var iWon: Bool {
        winner?.id == currentUserId
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: iWon
                                ? [Color.dinkrAmber.opacity(0.18), Color.dinkrGreen.opacity(0.12)]
                                : [Color.dinkrNavy.opacity(0.08), Color.dinkrSky.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(iWon ? Color.dinkrAmber.opacity(0.4) : Color.secondary.opacity(0.2), lineWidth: 1)
                    )

                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(iWon ? Color.dinkrAmber.opacity(0.2) : Color.dinkrSky.opacity(0.15))
                            .frame(width: 52, height: 52)
                        Image(systemName: iWon ? "trophy.fill" : "medal.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(iWon ? Color.dinkrAmber : Color.dinkrSky)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(iWon ? "You Won!" : "\(winner?.displayName ?? "—") Won!")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(iWon ? Color.dinkrAmber : Color.dinkrNavy)

                        if let msg = challenge.winnerMessage, !msg.isEmpty {
                            Text(msg)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer()
                }
                .padding(16)
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Rules Section

private struct RulesSection: View {
    let challenge: Challenge
    let typeColor: Color

    private var ruleItems: [(String, String)] {
        [
            ("Goal", "\(challenge.goalValue < 1 ? String(format: "%.2f", challenge.goalValue) : String(Int(challenge.goalValue))) \(challenge.goalUnit)"),
            ("Duration", "\(formattedDateRange)"),
            ("Visibility", challenge.isPublic ? "Public — visible in feed" : "Private"),
            ("Type", challenge.type.rawValue),
        ]
    }

    private var formattedDateRange: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return "\(fmt.string(from: challenge.startDate)) – \(fmt.string(from: challenge.endDate))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CHALLENGE RULES")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .tracking(1)

            VStack(spacing: 0) {
                ForEach(ruleItems.indices, id: \.self) { i in
                    let item = ruleItems[i]
                    HStack {
                        Text(item.0)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(item.1)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrNavy)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)

                    if i < ruleItems.count - 1 {
                        Divider().padding(.horizontal, 16)
                    }
                }
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Timeline Section

private struct TimelineSection: View {
    let typeColor: Color

    private struct TimelineEvent: Identifiable {
        let id = UUID()
        let actor: String
        let action: String
        let timeAgo: String
        let icon: String
    }

    private let events: [TimelineEvent] = [
        TimelineEvent(actor: "Alex", action: "logged 2 wins", timeAgo: "2h ago", icon: "plus.circle.fill"),
        TimelineEvent(actor: "Jordan", action: "logged 1 win", timeAgo: "5h ago", icon: "plus.circle.fill"),
        TimelineEvent(actor: "Alex", action: "logged 2 wins", timeAgo: "1d ago", icon: "plus.circle.fill"),
        TimelineEvent(actor: "Jordan", action: "accepted the challenge", timeAgo: "3d ago", icon: "checkmark.circle.fill"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACTIVITY")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .tracking(1)

            VStack(spacing: 0) {
                ForEach(events) { event in
                    HStack(spacing: 12) {
                        Image(systemName: event.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(typeColor)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 4) {
                                Text(event.actor)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.dinkrNavy)
                                Text(event.action)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Text(event.timeAgo)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)

                    Divider().padding(.horizontal, 16)
                }
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Log Progress Sheet

private struct LogProgressSheet: View {
    let challenge: Challenge
    let typeColor: Color
    @Environment(\.dismiss) private var dismiss
    @State private var progressValue: Double = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Image(systemName: challenge.type.icon)
                        .font(.system(size: 44))
                        .foregroundStyle(typeColor)
                        .padding(20)
                        .background(typeColor.opacity(0.12))
                        .clipShape(Circle())

                    Text("Log Your Progress")
                        .font(.title2.weight(.bold))
                    Text(challenge.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                VStack(spacing: 12) {
                    HStack {
                        Text("Current \(challenge.goalUnit)")
                            .font(.headline)
                        Spacer()
                        Text(progressValue < 1
                             ? String(format: "%.2f", progressValue)
                             : "\(Int(progressValue))")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(typeColor)
                    }
                    .padding(.horizontal, 20)

                    Stepper(
                        value: $progressValue,
                        in: 0...challenge.goalValue,
                        step: challenge.goalValue < 1 ? 0.01 : 1
                    ) {
                        Text("")
                    }
                    .padding(.horizontal, 20)

                    ProgressView(value: progressValue, total: challenge.goalValue)
                        .tint(typeColor)
                        .padding(.horizontal, 20)
                        .animation(.spring(), value: progressValue)
                }
                .padding(.vertical, 20)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)

                Button {
                    HapticManager.medium()
                    dismiss()
                } label: {
                    Text("Save Progress")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(typeColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: typeColor.opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)

                Spacer()
            }
            .navigationTitle("Log Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChallengeSummaryDetailView(challenge: Challenge.mockChallenges[0])
    }
    .environment(AuthService())
}

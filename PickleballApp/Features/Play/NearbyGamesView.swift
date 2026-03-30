import SwiftUI

struct NearbyGamesView: View {
    var viewModel: PlayViewModel
    private let currentUser = User.mockCurrentUser

    private var sessions: [GameSession] {
        viewModel.sortedSessions(playerSkill: currentUser.skillLevel)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Sort bar
                sortBar
                    .padding(.horizontal)
                    .padding(.top, 4)

                if viewModel.isLoading {
                    ProgressView().padding(.top, 40)
                } else if sessions.isEmpty {
                    EmptyStateView(
                        icon: "figure.pickleball",
                        title: "No Games Nearby",
                        message: "Be the first to host a game in your area!",
                        actionLabel: "Host a Game",
                        action: { viewModel.showHostGame = true }
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(sessions) { session in
                        NavigationLink {
                            GameSessionDetailView(session: session, viewModel: viewModel)
                        } label: {
                            GameCardView(
                                session: session,
                                matchScore: viewModel.sortMode == .skillMatch
                                    ? viewModel.matchScore(session: session, playerSkill: currentUser.skillLevel)
                                    : nil
                            )
                            .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .refreshable { await viewModel.load() }
    }

    // MARK: - Sort Bar

    private var sortBar: some View {
        HStack(spacing: 0) {
            ForEach(PlayViewModel.GameSortMode.allCases, id: \.self) { mode in
                let isSelected = viewModel.sortMode == mode
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        viewModel.sortMode = mode
                        HapticManager.selection()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 10, weight: .semibold))
                        Text(mode.rawValue)
                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                    }
                    .foregroundStyle(isSelected ? .white : Color.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        isSelected ? Color.dinkrGreen : Color.clear,
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(4)
        .background(Color(UIColor.secondarySystemBackground), in: Capsule())
    }
}

// MARK: - GameDetailView (legacy, kept for backward compat)

struct GameDetailView: View {
    let session: GameSession
    var viewModel: PlayViewModel
    private let currentUserId = "user_001"

    var isRsvped: Bool { session.rsvps.contains(currentUserId) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(session.courtName)
                        .font(.title2.weight(.bold))
                    Text(session.dateTime.friendlyDateString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    InfoChip(icon: "figure.pickleball", label: session.format.rawValue)
                    InfoChip(icon: "person.2", label: "\(session.spotsRemaining) spots left")
                    if !session.isPublic {
                        InfoChip(icon: "lock.fill", label: "Private")
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Skill Level")
                        .font(.subheadline.weight(.semibold))
                    HStack {
                        SkillBadge(level: session.skillRange.lowerBound)
                        Text("–")
                        SkillBadge(level: session.skillRange.upperBound)
                    }
                }

                if !session.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes").font(.subheadline.weight(.semibold))
                        Text(session.notes).font(.subheadline).foregroundStyle(.secondary)
                    }
                }

                Button {
                    viewModel.rsvp(to: session)
                } label: {
                    Text(isRsvped ? "Cancel RSVP" : (session.isFull ? "Join Waitlist" : "RSVP"))
                        .primaryButton()
                }
            }
            .padding()
        }
        .navigationTitle("Game Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoChip: View {
    let icon: String
    let label: String

    var body: some View {
        Label(label, systemImage: icon)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.cardBackground)
            .clipShape(Capsule())
    }
}

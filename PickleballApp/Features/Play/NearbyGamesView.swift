import SwiftUI

// MARK: - GameViewMode

enum GameViewMode: String, CaseIterable {
    case list     = "List"
    case calendar = "Calendar"

    var icon: String {
        switch self {
        case .list:     return "list.bullet"
        case .calendar: return "calendar"
        }
    }
}

// MARK: - NearbyGamesView

struct NearbyGamesView: View {
    var viewModel: PlayViewModel
    @Environment(AuthService.self) private var authService
    @State private var showDiscover = false
    @State private var viewMode: GameViewMode = .list

    private var sessions: [GameSession] {
        viewModel.sortedSessions(playerSkill: authService.currentUser?.skillLevel ?? .intermediate30)
    }

    var body: some View {
        ZStack {
            if viewMode == .list {
                listContent
                    .transition(.opacity)
            } else {
                calendarContent
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: viewMode)
        .refreshable { await viewModel.load() }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                viewModeToggle
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticManager.medium()
                    showDiscover = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Discover")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.dinkrGreen, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showDiscover) {
            SwipeGameDiscoveryView()
        }
    }

    // MARK: - List content

    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Sort bar
                sortBar
                    .padding(.horizontal)
                    .padding(.top, 4)

                if viewModel.isLoading {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonGameCard()
                            .padding(.horizontal)
                    }
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
                                    ? viewModel.matchScore(session: session, playerSkill: authService.currentUser?.skillLevel ?? .intermediate30)
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
    }

    // MARK: - Calendar content

    private var calendarContent: some View {
        ScrollView {
            GameCalendarView(sessions: sessions, viewModel: viewModel)
                .padding(.top, 4)
        }
    }

    // MARK: - View mode toggle

    private var viewModeToggle: some View {
        HStack(spacing: 0) {
            ForEach(GameViewMode.allCases, id: \.self) { mode in
                let isActive = viewMode == mode
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        viewMode = mode
                        HapticManager.selection()
                    }
                } label: {
                    Image(systemName: mode.icon)
                        .font(.system(size: 13, weight: isActive ? .bold : .regular))
                        .foregroundStyle(isActive ? .white : Color.secondary)
                        .frame(width: 32, height: 28)
                        .background(
                            isActive ? Color.dinkrNavy : Color.clear,
                            in: RoundedRectangle(cornerRadius: 7)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
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
    @Environment(AuthService.self) private var authService
    private var currentUserId: String? { authService.currentUser?.id }

    var isRsvped: Bool { session.rsvps.contains(currentUserId ?? "") }

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

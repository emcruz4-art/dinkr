import SwiftUI

// MARK: - PlayTab (focused 5-tab model)

enum PlayTab: String, CaseIterable, Identifiable {
    case games       = "Games"
    case mySessions  = "My Games"
    case courts      = "Courts"
    case players     = "Players"
    case leaderboard = "Leaderboard"
    case live        = "Live"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .games:       return "figure.pickleball"
        case .mySessions:  return "calendar.badge.checkmark"
        case .courts:      return "mappin.circle"
        case .players:     return "person.2"
        case .leaderboard: return "trophy"
        case .live:        return "dot.radiowaves.left.andright"
        }
    }
}

// MARK: - PlayView

struct PlayView: View {
    @State private var viewModel = PlayViewModel()
    @Environment(AuthService.self) private var authService
    @State private var showLogResult = false
    @State private var showSearch = false

    // Active tab for the custom 5-tab bar
    @State private var activeTab: PlayTab = .games

    // Matched-geometry namespace for the sliding pill
    @Namespace private var tabNamespace

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── Custom 5-tab segmented control ────────────────────────
                playTabBar

                // Subtle green gradient separator
                Divider()

                // ── Content area ──────────────────────────────────────────
                tabContent
                    .animation(.easeInOut(duration: 0.22), value: activeTab)
                    .id(activeTab)
            }
            .navigationTitle("Play")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .tint(Color.dinkrNavy)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        Button {
                            showLogResult = true
                        } label: {
                            Label("Log Result", systemImage: "square.and.pencil")
                        }
                        .tint(Color.dinkrGreen)

                        Button {
                            viewModel.showHostGame = true
                        } label: {
                            Label("Host", systemImage: "plus.circle.fill")
                        }
                        .tint(Color.dinkrGreen)
                    }
                }
            }
        }
        .sheet(isPresented: $showSearch) {
            SearchView()
        }
        .sheet(isPresented: $viewModel.showHostGame) {
            HostGameView()
        }
        .sheet(isPresented: $showLogResult) {
            LogGameResultView()
        }
        .task {
            viewModel.currentUserId = authService.currentUser?.id
            await viewModel.load()
        }
    }

    // MARK: - Tab Bar

    private var playTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(PlayTab.allCases) { tab in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.74)) {
                            activeTab = tab
                        }
                    } label: {
                        tabPill(tab)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.appBackground)
    }

    @ViewBuilder
    private func tabPill(_ tab: PlayTab) -> some View {
        let isSelected = activeTab == tab

        ZStack {
            // Sliding background pill via matched geometry
            if isSelected {
                Capsule()
                    .fill(Color.dinkrGreen)
                    .matchedGeometryEffect(id: "activePill", in: tabNamespace)
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 1)
            }

            HStack(spacing: 5) {
                // Live tab: static red dot badge on its icon
                if tab == .live {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                            .foregroundStyle(isSelected ? .white : Color.secondary)

                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                            .offset(x: 3, y: -3)
                    }
                } else {
                    Image(systemName: tab.icon)
                        .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                        .foregroundStyle(isSelected ? .white : Color.secondary)
                }

                Text(tab.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? .white : Color.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            // Unselected border ring
            .background(
                Capsule()
                    .strokeBorder(
                        isSelected ? Color.clear : Color.secondary.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch activeTab {
        case .games:
            VStack(spacing: 0) {
                GameFilterBar(
                    selectedFormat: $viewModel.selectedFormat,
                    todayOnly: $viewModel.todayOnly
                )
                NearbyGamesView(viewModel: viewModel)
            }
        case .mySessions:
            MySessionsView(viewModel: viewModel)
        case .courts:
            CourtListView(venues: viewModel.nearbyVenues)
        case .players:
            FindPlayersView(
                players: viewModel.nearbyPlayers,
                currentUserId: authService.currentUser?.id ?? ""
            )
        case .leaderboard:
            LeaderboardContainerView()
        case .live:
            LiveScoreFeedView()
        }
    }
}

// MARK: - LivePlayView (retained for other call sites)
struct LivePlayView: View {
    var viewModel: PlayViewModel
    @State private var showAvailability = false
    @State private var pulseAnimation = false
    @State private var showJoinConfirmation = false
    @State private var invitedPlayer: String? = nil

    let liveSessionPlayers: [String] = ["Maria Chen", "Jordan Smith", "Chris Park", "Riley Torres"]
    let waitingPlayers: [String] = ["Taylor Kim", "Morgan Davis", "Jamie Lee"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Live indicator banner
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(pulseAnimation ? 1.4 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(), value: pulseAnimation)
                    Text("LIVE NOW · 3 ACTIVE SESSIONS")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(Color.dinkrCoral)
                    Spacer()
                    Text("Updated just now")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                .onAppear { pulseAnimation = true }

                // Live Score Feed quick-access banner
                NavigationLink(destination: LiveScoreFeedView()) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.red)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Live Score Feed")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.primary)
                            Text("See all games happening right now")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.red.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                // Live session drafting card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Westside Pickleball Complex")
                                .font(.headline.weight(.bold))
                            Text("Court 3 · Doubles · 3.5+ · Starting now")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("2/4")
                                .font(.title3.weight(.heavy))
                                .foregroundStyle(Color.dinkrGreen)
                            Text("spots")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text("PLAYER DRAFT")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                        ForEach(0..<4) { i in
                            VStack(spacing: 4) {
                                if i < liveSessionPlayers.count {
                                    ZStack {
                                        Circle()
                                            .fill(Color.dinkrGreen.opacity(0.15))
                                            .frame(width: 44, height: 44)
                                        Text(String(liveSessionPlayers[i].prefix(1)))
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(Color.dinkrGreen)
                                    }
                                    Text(liveSessionPlayers[i].components(separatedBy: " ").first ?? "")
                                        .font(.system(size: 9, weight: .semibold))
                                        .lineLimit(1)
                                } else {
                                    ZStack {
                                        Circle()
                                            .stroke(Color.dinkrGreen.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [4]))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "plus")
                                            .foregroundStyle(Color.dinkrGreen.opacity(0.5))
                                    }
                                    Text("Open")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Button {
                        HapticManager.success()
                        showJoinConfirmation = true
                    } label: {
                        Text(showJoinConfirmation ? "Joining..." : "Join This Session")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(showJoinConfirmation ? Color.dinkrGreen.opacity(0.7) : Color.dinkrGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(showJoinConfirmation)
                }
                .padding(16)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)

                // Waiting room
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("WAITING ROOM")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(waitingPlayers.count) players")
                            .font(.caption2)
                            .foregroundStyle(Color.dinkrSky)
                    }

                    ForEach(waitingPlayers, id: \.self) { player in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color.dinkrSky.opacity(0.15))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(String(player.prefix(1)))
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(Color.dinkrSky)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(player)
                                    .font(.subheadline.weight(.semibold))
                                Text("3.5 · Available now · 0.5 mi")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                HapticManager.selection()
                                invitedPlayer = player
                            } label: {
                                Text(invitedPlayer == player ? "Invited!" : "Invite")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(invitedPlayer == player ? Color.white : Color.dinkrSky)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(invitedPlayer == player ? Color.dinkrSky : Color.dinkrSky.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)

                // Set availability card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(Color.dinkrAmber)
                        Text("YOUR AVAILABILITY")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            showAvailability = true
                        } label: {
                            Text("Edit")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.dinkrGreen)
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showAvailability) {
                            Text("Set Availability")
                                .font(.title2.weight(.bold))
                                .padding()
                                .presentationDetents([.medium])
                        }
                    }

                    HStack(spacing: 8) {
                        ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                            let available = ["Sat", "Sun", "Wed"].contains(day)
                            VStack(spacing: 3) {
                                Text(day)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(available ? Color.dinkrGreen : .secondary)
                                Circle()
                                    .fill(available ? Color.dinkrGreen : Color.secondary.opacity(0.2))
                                    .frame(width: 6, height: 6)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }

                    Text("You'll be pinged when someone needs a player on your available days.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
        .refreshable {}
    }
}

// MARK: - CourtRowCard (retained for backward compat)
struct CourtRowCard: View {
    let venue: CourtVenue
    var body: some View {
        CourtVenueRow(venue: venue, onDirections: {})
    }
}

#Preview {
    PlayView()
        .environment(LocationService())
}

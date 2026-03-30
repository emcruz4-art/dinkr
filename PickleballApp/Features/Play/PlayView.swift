import SwiftUI

struct PlayView: View {
    @State private var viewModel = PlayViewModel()
    @Environment(AuthService.self) private var authService

    // MARK: - Segment icons
    private func segmentIcon(_ seg: PlayViewModel.PlaySegment) -> String {
        switch seg {
        case .games:       return "figure.pickleball"
        case .live:        return "dot.radiowaves.left.and.right"
        case .courts:      return "mappin.and.ellipse"
        case .players:     return "person.2.fill"
        case .match:       return "arrow.left.arrow.right.circle.fill"
        case .leaderboard: return "trophy.fill"
        }
    }

    // Strip emoji from rawValue for clean pill labels
    private func segmentLabel(_ seg: PlayViewModel.PlaySegment) -> String {
        switch seg {
        case .games:       return "Games"
        case .live:        return "Live"
        case .courts:      return "Courts"
        case .players:     return "Players"
        case .match:       return "Match"
        case .leaderboard: return "Rankings"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── Premium pill segment selector ──────────────────────────
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(PlayViewModel.PlaySegment.allCases, id: \.self) { seg in
                            let isSelected = viewModel.selectedSegment == seg
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                                    viewModel.selectedSegment = seg
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: segmentIcon(seg))
                                        .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                                        .foregroundStyle(
                                            isSelected ? .white : Color.secondary
                                        )
                                    Text(segmentLabel(seg))
                                        .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                                        .foregroundStyle(
                                            isSelected ? .white : Color.secondary
                                        )
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    isSelected
                                        ? Color.dinkrGreen
                                        : Color.clear
                                )
                                .clipShape(Capsule())
                                // Subtle border on unselected pills
                                .overlay(
                                    Capsule()
                                        .strokeBorder(
                                            isSelected
                                                ? Color.clear
                                                : Color.secondary.opacity(0.2),
                                            lineWidth: 1
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color.appBackground)

                // Subtle gradient separator below the pill bar
                LinearGradient(
                    colors: [Color.dinkrGreen.opacity(0.12), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 6)

                // ── Content area ───────────────────────────────────────────
                switch viewModel.selectedSegment {
                case .games:
                    VStack(spacing: 0) {
                        GameFilterBar(
                            selectedFormat: $viewModel.selectedFormat,
                            todayOnly: $viewModel.todayOnly
                        )
                        NearbyGamesView(viewModel: viewModel)
                    }
                case .live:
                    LivePlayView(viewModel: viewModel)
                case .courts:
                    CourtDiscoveryView(venues: viewModel.nearbyVenues)
                case .players:
                    FindPlayersView(players: viewModel.nearbyPlayers, currentUserId: authService.currentUser?.id ?? "")
                case .match:
                    PlayerMatchView()
                case .leaderboard:
                    LeaderboardView()
                }
            }
            .navigationTitle("Play")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showHostGame = true
                    } label: {
                        Label("Host", systemImage: "plus.circle.fill")
                    }
                    .tint(Color.dinkrGreen)
                }
            }
        }
        .sheet(isPresented: $viewModel.showHostGame) {
            HostGameView()
        }
        .task { await viewModel.load() }
    }
}

// MARK: - Live Play View (NBA-draft style)
struct LivePlayView: View {
    var viewModel: PlayViewModel
    @State private var showAvailability = false
    @State private var pulseAnimation = false

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

                    // Player slots - NBA draft style
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

                    Button {} label: {
                        Text("Join This Session")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.dinkrGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
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
                            Button {} label: {
                                Text("Invite")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.dinkrSky)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(Color.dinkrSky.opacity(0.12))
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
                        Button {} label: {
                            Text("Edit")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.dinkrGreen)
                        }
                        .buttonStyle(.plain)
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

// MARK: - Leaderboard View
struct LeaderboardView: View {
    @State private var selectedPeriod = 0
    let periods = ["This Week", "This Month", "All Time"]

    struct LeaderEntry: Identifiable {
        let id: String
        let rank: Int
        let name: String
        let wins: Int
        let games: Int
        let winRate: Double
        let streak: Int
    }

    let leaders: [LeaderEntry] = [
        LeaderEntry(id: "1", rank: 1, name: "Jamie Lee",     wins: 18, games: 21, winRate: 0.857, streak: 7),
        LeaderEntry(id: "2", rank: 2, name: "Maria Chen",    wins: 15, games: 19, winRate: 0.789, streak: 4),
        LeaderEntry(id: "3", rank: 3, name: "Chris Park",    wins: 14, games: 18, winRate: 0.778, streak: 3),
        LeaderEntry(id: "4", rank: 4, name: "Alex Rivera",   wins: 12, games: 17, winRate: 0.706, streak: 2),
        LeaderEntry(id: "5", rank: 5, name: "Jordan Smith",  wins: 11, games: 16, winRate: 0.688, streak: 1),
        LeaderEntry(id: "6", rank: 6, name: "Sarah Johnson", wins: 10, games: 15, winRate: 0.667, streak: 0),
        LeaderEntry(id: "7", rank: 7, name: "Riley Torres",  wins: 9,  games: 14, winRate: 0.643, streak: 0),
        LeaderEntry(id: "8", rank: 8, name: "Morgan Davis",  wins: 6,  games: 12, winRate: 0.500, streak: 0),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Period picker
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(0..<periods.count, id: \.self) { i in
                        Text(periods[i]).tag(i)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top)

                // Top 3 podium
                HStack(alignment: .bottom, spacing: 12) {
                    PodiumCard(entry: leaders[1], medalColor: Color.secondary)
                    PodiumCard(entry: leaders[0], medalColor: Color.dinkrAmber, isFirst: true)
                    PodiumCard(entry: leaders[2], medalColor: Color(red: 0.8, green: 0.5, blue: 0.2))
                }
                .padding(.horizontal)

                // Full leaderboard
                VStack(spacing: 0) {
                    ForEach(leaders) { entry in
                        LeaderboardRow(entry: entry, isCurrentUser: entry.name == "Alex Rivera")
                        if entry.id != leaders.last?.id {
                            Divider().padding(.horizontal)
                        }
                    }
                }
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
    }
}

struct PodiumCard: View {
    let entry: LeaderboardView.LeaderEntry
    let medalColor: Color
    var isFirst: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(medalColor.opacity(0.15))
                    .frame(width: isFirst ? 64 : 52, height: isFirst ? 64 : 52)
                Text(String(entry.name.prefix(1)))
                    .font(isFirst ? .title.weight(.heavy) : .title2.weight(.bold))
                    .foregroundStyle(medalColor)
            }
            Text(entry.name.components(separatedBy: " ").first ?? "")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Text("\(entry.wins)W")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(entry.rank == 1 ? "🥇" : entry.rank == 2 ? "🥈" : "🥉")
                .font(.title3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isFirst ? 16 : 10)
        .background(isFirst ? medalColor.opacity(0.08) : Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardView.LeaderEntry
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text("#\(entry.rank)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(entry.rank <= 3 ? Color.dinkrAmber : .secondary)
                .frame(width: 28)

            ZStack {
                Circle()
                    .fill(isCurrentUser ? Color.dinkrGreen.opacity(0.15) : Color.secondary.opacity(0.1))
                    .frame(width: 36, height: 36)
                Text(String(entry.name.prefix(1)))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isCurrentUser ? Color.dinkrGreen : .secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(entry.name)
                        .font(.subheadline.weight(isCurrentUser ? .bold : .regular))
                    if isCurrentUser {
                        Text("YOU")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.dinkrGreen)
                            .clipShape(Capsule())
                    }
                }
                Text("\(entry.wins)W \(entry.games - entry.wins)L · \(Int(entry.winRate * 100))% win rate")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if entry.streak > 0 {
                VStack(spacing: 1) {
                    Text("🔥 \(entry.streak)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.dinkrCoral)
                    Text("streak")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isCurrentUser ? Color.dinkrGreen.opacity(0.04) : Color.clear)
    }
}

// CourtListView kept for backward compat
struct CourtListView: View {
    let venues: [CourtVenue]
    var body: some View {
        CourtDiscoveryView(venues: venues)
    }
}

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

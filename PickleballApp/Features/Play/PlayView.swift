import SwiftUI

struct PlayView: View {
    @State private var viewModel = PlayViewModel()
    @Environment(AuthService.self) private var authService
    @State private var showLogResult = false

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
        .sheet(isPresented: $viewModel.showHostGame) {
            HostGameView()
        }
        .sheet(isPresented: $showLogResult) {
            LogGameResultView()
        }
        .task { await viewModel.load() }
    }
}

// MARK: - Live Play View (NBA-draft style)
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

// MARK: - Leaderboard View
struct LeaderboardView: View {
    @State private var leaderboardMode = 0   // 0 = DUPR, 1 = Win Rate, 2 = Company
    @State private var selectedPeriod = 0
    let periods = ["This Week", "This Month", "All Time"]

    struct LeaderEntry: Identifiable {
        let id: String
        let name: String
        let username: String
        let duprRating: Double
        let wins: Int
        let games: Int
        let winRate: Double
        let streak: Int
        var rank: Int = 0
    }

    // Sorted by DUPR descending
    let allEntries: [LeaderEntry] = [
        LeaderEntry(id: "1", name: "Alex Rivera",   username: "pickleking",      duprRating: 4.69, wins: 12, games: 17, winRate: 0.706, streak: 2),
        LeaderEntry(id: "2", name: "Jamie Lee",     username: "jamiepb",         duprRating: 4.52, wins: 18, games: 21, winRate: 0.857, streak: 7),
        LeaderEntry(id: "3", name: "Jordan Smith",  username: "jordan_4point0",  duprRating: 4.21, wins: 11, games: 16, winRate: 0.688, streak: 1),
        LeaderEntry(id: "4", name: "Chris Park",    username: "chrisp_dink",     duprRating: 4.05, wins: 14, games: 18, winRate: 0.778, streak: 3),
        LeaderEntry(id: "5", name: "Maria Chen",    username: "maria_plays",     duprRating: 3.87, wins: 15, games: 19, winRate: 0.789, streak: 4),
        LeaderEntry(id: "6", name: "Sarah Johnson", username: "sarahj_pb",       duprRating: 3.65, wins: 10, games: 15, winRate: 0.667, streak: 0),
        LeaderEntry(id: "7", name: "Riley Torres",  username: "riley_dinkmaster",duprRating: 3.55, wins: 9,  games: 14, winRate: 0.643, streak: 0),
        LeaderEntry(id: "8", name: "Taylor Kim",    username: "tkim_pickles",    duprRating: 2.98, wins: 6,  games: 12, winRate: 0.500, streak: 0),
    ]

    var duprRanked: [LeaderEntry] {
        allEntries.sorted { $0.duprRating > $1.duprRating }
            .enumerated().map { i, e in
                var e = e; e.rank = i + 1; return e
            }
    }

    var winRateRanked: [LeaderEntry] {
        allEntries.sorted { $0.winRate > $1.winRate }
            .enumerated().map { i, e in
                var e = e; e.rank = i + 1; return e
            }
    }

    var leaders: [LeaderEntry] { leaderboardMode == 0 ? duprRanked : winRateRanked }

    var body: some View {
        ZStack {
            if leaderboardMode == 2 {
                // Company leaderboard — shown inline (no nested NavigationStack)
                ScrollView {
                    VStack(spacing: 16) {
                        // Mode toggle — keep visible so user can switch back
                        Picker("Mode", selection: $leaderboardMode) {
                            Text("DUPR Rating").tag(0)
                            Text("Win Rate").tag(1)
                            Text("Company").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top, 12)

                        OrgLeaderboardView()
                    }
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Mode toggle
                        Picker("Mode", selection: $leaderboardMode) {
                            Text("DUPR Rating").tag(0)
                            Text("Win Rate").tag(1)
                            Text("Company").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top, 12)

                        // Period picker (win rate only)
                        if leaderboardMode == 1 {
                            Picker("Period", selection: $selectedPeriod) {
                                ForEach(0..<periods.count, id: \.self) { i in
                                    Text(periods[i]).tag(i)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                        }

                        // DUPR info banner
                        if leaderboardMode == 0 {
                            HStack(spacing: 10) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(Color.dinkrAmber)
                                    .font(.subheadline)
                                Text("DUPR (Dynamic Universal Pickleball Rating) is the world's most accurate pickleball rating system.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(Color.dinkrAmber.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }

                        // Top 3 podium
                        if leaders.count >= 3 {
                            HStack(alignment: .bottom, spacing: 10) {
                                DUPRPodiumCard(entry: leaders[1], medalColor: Color(red: 0.75, green: 0.75, blue: 0.78), mode: leaderboardMode)
                                DUPRPodiumCard(entry: leaders[0], medalColor: Color.dinkrAmber, isFirst: true, mode: leaderboardMode)
                                DUPRPodiumCard(entry: leaders[2], medalColor: Color(red: 0.80, green: 0.52, blue: 0.25), mode: leaderboardMode)
                            }
                            .padding(.horizontal)
                        }

                        // Full leaderboard list
                        VStack(spacing: 0) {
                            ForEach(leaders) { entry in
                                DUPRLeaderboardRow(entry: entry, isCurrentUser: entry.username == "pickleking", mode: leaderboardMode)
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
    }
}

struct DUPRPodiumCard: View {
    let entry: LeaderboardView.LeaderEntry
    let medalColor: Color
    var isFirst: Bool = false
    let mode: Int

    var body: some View {
        VStack(spacing: 6) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(entry.username == "pickleking" ? Color.dinkrGreen.opacity(0.18) : medalColor.opacity(0.15))
                    .frame(width: isFirst ? 68 : 54, height: isFirst ? 68 : 54)
                    .overlay(
                        Circle().stroke(
                            entry.username == "pickleking" ? Color.dinkrGreen : medalColor,
                            lineWidth: isFirst ? 2.5 : 1.5
                        )
                    )
                Text(String(entry.name.prefix(1)))
                    .font(isFirst ? .title.weight(.heavy) : .title2.weight(.bold))
                    .foregroundStyle(entry.username == "pickleking" ? Color.dinkrGreen : medalColor)
            }

            Text(entry.name.components(separatedBy: " ").first ?? "")
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            // Rating or win stat
            if mode == 0 {
                HStack(spacing: 3) {
                    Text("DUPR")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(Color.dinkrAmber)
                    Text(String(format: "%.2f", entry.duprRating))
                        .font(.system(size: 11, weight: .bold))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.dinkrAmber.opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.dinkrAmber.opacity(0.3), lineWidth: 1))
            } else {
                Text("\(entry.wins)W · \(Int(entry.winRate * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(entry.rank == 1 ? "🥇" : entry.rank == 2 ? "🥈" : "🥉")
                .font(.title3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isFirst ? 16 : 10)
        .background(isFirst ? medalColor.opacity(0.06) : Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct DUPRLeaderboardRow: View {
    let entry: LeaderboardView.LeaderEntry
    let isCurrentUser: Bool
    let mode: Int

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("#\(entry.rank)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(entry.rank <= 3 ? Color.dinkrAmber : .secondary)
                .frame(width: 30, alignment: .leading)

            // Avatar
            ZStack {
                Circle()
                    .fill(isCurrentUser ? Color.dinkrGreen.opacity(0.15) : Color.secondary.opacity(0.1))
                    .frame(width: 38, height: 38)
                Text(String(entry.name.prefix(1)))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isCurrentUser ? Color.dinkrGreen : .secondary)
            }

            // Name + subtitle
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
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
                Text("@\(entry.username)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Right side metric
            if mode == 0 {
                // DUPR rating pill
                HStack(spacing: 3) {
                    Text("DUPR")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color.dinkrAmber)
                    Text(String(format: "%.2f", entry.duprRating))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isCurrentUser ? Color.dinkrAmber : Color.primary)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.dinkrAmber.opacity(isCurrentUser ? 0.18 : 0.08))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.dinkrAmber.opacity(isCurrentUser ? 0.5 : 0.2), lineWidth: 1))
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(entry.winRate * 100))%")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(isCurrentUser ? Color.dinkrGreen : Color.primary)
                    Text("\(entry.wins)W \(entry.games - entry.wins)L")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if entry.streak > 0 {
                    VStack(spacing: 1) {
                        Text("🔥\(entry.streak)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.dinkrCoral)
                        Text("streak")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 6)
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

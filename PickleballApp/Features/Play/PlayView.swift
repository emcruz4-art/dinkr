import SwiftUI

struct PlayView: View {
    @State private var viewModel = PlayViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment picker — 5 segments
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(PlayViewModel.PlaySegment.allCases, id: \.self) { seg in
                            Button {
                                viewModel.selectedSegment = seg
                            } label: {
                                VStack(spacing: 4) {
                                    Text(seg.rawValue)
                                        .font(.caption.weight(viewModel.selectedSegment == seg ? .bold : .regular))
                                        .foregroundStyle(viewModel.selectedSegment == seg ? Color.dinkrGreen : .secondary)
                                    Rectangle()
                                        .fill(viewModel.selectedSegment == seg ? Color.dinkrGreen : Color.clear)
                                        .frame(height: 2)
                                }
                                .frame(minWidth: 70)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .background(Color.appBackground)

                Divider()

                switch viewModel.selectedSegment {
                case .games:
                    VStack(spacing: 0) {
                        GameFilterBar(selectedFormat: $viewModel.selectedFormat,
                                      todayOnly: $viewModel.todayOnly)
                        NearbyGamesView(viewModel: viewModel)
                    }
                case .live:
                    LivePlayView(viewModel: viewModel)
                case .courts:
                    CourtDiscoveryView(venues: viewModel.nearbyVenues)
                case .players:
                    FindPlayersView(players: viewModel.nearbyPlayers)
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

// MARK: - Court Discovery View
struct CourtDiscoveryView: View {
    let venues: [CourtVenue]
    @State private var searchText = ""
    @State private var showFreeOnly = false
    @State private var showIndoorOnly = false

    var filteredVenues: [CourtVenue] {
        venues.filter { venue in
            (searchText.isEmpty || venue.name.localizedCaseInsensitiveContains(searchText)) &&
            (!showIndoorOnly || venue.isIndoor)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search courts...", text: $searchText)
            }
            .padding(10)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "Free / Public", isSelected: showFreeOnly, color: Color.dinkrGreen) {
                        showFreeOnly.toggle()
                    }
                    FilterChip(label: "Indoor", isSelected: showIndoorOnly, color: Color.dinkrSky) {
                        showIndoorOnly.toggle()
                    }
                    FilterChip(label: "Lit Courts", isSelected: false, color: Color.dinkrAmber) {}
                    FilterChip(label: "Open Now", isSelected: false, color: Color.dinkrCoral) {}
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            Divider()

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredVenues) { venue in
                        NavigationLink {
                            CourtDetailView(venue: venue)
                        } label: {
                            CourtDiscoveryCard(venue: venue)
                                .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

struct CourtDiscoveryCard: View {
    let venue: CourtVenue

    var body: some View {
        PickleballCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.dinkrSky.opacity(0.15))
                            .frame(width: 52, height: 52)
                        Image(systemName: venue.isIndoor ? "building.2" : "sportscourt")
                            .foregroundStyle(Color.dinkrSky)
                            .font(.title3)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(venue.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text(venue.address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        HStack(spacing: 8) {
                            Label("\(venue.courtCount) courts", systemImage: "sportscourt")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            if venue.isIndoor {
                                Label("Indoor", systemImage: "building.2")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            if venue.hasLighting {
                                Label("Lights", systemImage: "lightbulb.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow)
                            Text(String(format: "%.1f", venue.rating)).font(.caption.weight(.semibold))
                        }
                        // Availability badge
                        Text("Open")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.dinkrGreen)
                            .clipShape(Capsule())
                    }
                }

                // Map / Directions buttons
                HStack(spacing: 8) {
                    // Apple Maps link
                    Link(destination: URL(string: "maps://maps.apple.com/?q=\(venue.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!) {
                        Label("Apple Maps", systemImage: "map.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.dinkrSky)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    // Google Maps link
                    Link(destination: URL(string: "https://maps.google.com/?q=\(venue.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!) {
                        Label("Google Maps", systemImage: "globe")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrSky)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.dinkrSky.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(14)
        }
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
        CourtDiscoveryCard(venue: venue)
    }
}

#Preview {
    PlayView()
        .environment(LocationService())
}

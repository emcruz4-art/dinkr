import SwiftUI

// MARK: - Data Models

struct LeaderEntry: Identifiable {
    let id: String
    let name: String
    let username: String
    let skillLevel: SkillLevel
    let duprRating: Double
    let wins: Int
    let games: Int
    let winRate: Double
    let streak: Int
    let points: Int
    let city: String
    var rank: Int = 0
    // trend: positive = moved up, negative = moved down, zero = same
    var rankTrend: Int = 0
}

// MARK: - Scope Tab

enum LeaderboardScope: String, CaseIterable {
    case overall   = "Overall"
    case myGroups  = "My Groups"
    case friends   = "Friends"
    case local     = "Local"
}

// MARK: - Time Period

enum LeaderboardPeriod: String, CaseIterable {
    case thisWeek  = "Week"
    case thisMonth = "Month"
    case allTime   = "All Time"
}

// MARK: - Sort Category

enum LeaderboardSort: String, CaseIterable {
    case dupr        = "DUPR Rating"
    case winRate     = "Win Rate"
    case gamesPlayed = "Games Played"
    case streak      = "Streak"
    case points      = "Points"
}

// MARK: - Leaderboard Top-Level Tab

enum LeaderboardTopTab: String, CaseIterable, Identifiable {
    case global  = "Global"
    case company = "Company"

    var id: String { rawValue }
}

// MARK: - LeaderboardContainerView
// Wraps the global LeaderboardView and OrgLeaderboardView under a two-tab header.
// Use this view in PlayView instead of LeaderboardView directly.

struct LeaderboardContainerView: View {
    @State private var topTab: LeaderboardTopTab = .global
    @Namespace private var containerNamespace

    var body: some View {
        VStack(spacing: 0) {

            // ── Two-tab switcher ──────────────────────────────────────────
            HStack(spacing: 8) {
                ForEach(LeaderboardTopTab.allCases) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            topTab = tab
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab == .global ? "globe" : "building.2.fill")
                                .font(.system(size: 11, weight: topTab == tab ? .bold : .regular))
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: topTab == tab ? .bold : .regular))
                        }
                        .foregroundStyle(topTab == tab ? .white : Color.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Group {
                                if topTab == tab {
                                    Capsule()
                                        .fill(tab == .company ? Color.dinkrNavy : Color.dinkrGreen)
                                        .matchedGeometryEffect(id: "topPill", in: containerNamespace)
                                } else {
                                    Capsule()
                                        .fill(Color.clear)
                                }
                            }
                        )
                        .overlay(
                            Capsule().strokeBorder(
                                topTab == tab ? Color.clear : Color.secondary.opacity(0.2),
                                lineWidth: 1
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.appBackground)

            Divider()

            // ── Content ───────────────────────────────────────────────────
            if topTab == .global {
                LeaderboardView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                OrgLeaderboardView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: topTab)
    }
}

// MARK: - LeaderboardView

struct LeaderboardView: View {
    @State private var selectedScope: LeaderboardScope = .overall
    @State private var selectedPeriod: LeaderboardPeriod = .allTime
    @State private var selectedSort: LeaderboardSort = .dupr
    @State private var displayedCount: Int = 8
    @State private var podiumAppeared: Bool = false
    @State private var rankChangeID: UUID = UUID()
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var showJumpConfirmation: Bool = false
    @State private var challengeSheetEntry: LeaderEntry? = nil
    @State private var showChallengeSheet: Bool = false

    // MARK: - Mock Data — Diverse 20-player pool

    private let baseEntries: [LeaderEntry] = [
        LeaderEntry(id: "1",  name: "Derek Martinez",  username: "derekmartinez_5pt0",  skillLevel: .pro50,          duprRating: 5.47, wins: 671, games: 892, winRate: 0.752, streak: 11, points: 9820, city: "Austin, TX"),
        LeaderEntry(id: "2",  name: "Marcus Williams", username: "marcusw_kitchen",     skillLevel: .advanced45,     duprRating: 4.72, wins: 263, games: 398, winRate: 0.661, streak: 6,  points: 7410, city: "Pflugerville, TX"),
        LeaderEntry(id: "3",  name: "Alex Rivera",     username: "pickleking",           skillLevel: .advanced40,     duprRating: 4.69, wins: 89,  games: 142, winRate: 0.627, streak: 2,  points: 4960, city: "Austin, TX"),
        LeaderEntry(id: "4",  name: "Jamie Lee",       username: "jamiepb",             skillLevel: .advanced45,     duprRating: 4.52, wins: 301, games: 445, winRate: 0.676, streak: 7,  points: 6830, city: "Austin, TX"),
        LeaderEntry(id: "5",  name: "Priya Patel",     username: "priyapatel_dinks",    skillLevel: .advanced40,     duprRating: 4.31, wins: 174, games: 267, winRate: 0.652, streak: 4,  points: 5290, city: "Austin, TX"),
        LeaderEntry(id: "6",  name: "Jordan Smith",    username: "jordan_4point0",      skillLevel: .advanced40,     duprRating: 4.21, wins: 51,  games: 87,  winRate: 0.586, streak: 1,  points: 3140, city: "Austin, TX"),
        LeaderEntry(id: "7",  name: "Kevin Park",      username: "kevinpark_spin",      skillLevel: .advanced40,     duprRating: 4.15, wins: 118, games: 193, winRate: 0.611, streak: 3,  points: 4120, city: "Georgetown, TX"),
        LeaderEntry(id: "8",  name: "Chris Park",      username: "chrisp_dink",         skillLevel: .advanced40,     duprRating: 4.05, wins: 198, games: 312, winRate: 0.635, streak: 5,  points: 5580, city: "Round Rock, TX"),
        LeaderEntry(id: "9",  name: "Maria Chen",      username: "maria_plays",         skillLevel: .intermediate35, duprRating: 3.87, wins: 148, games: 203, winRate: 0.729, streak: 9,  points: 6020, city: "Austin, TX"),
        LeaderEntry(id: "10", name: "Aisha Johnson",   username: "aishaj_bangerz",      skillLevel: .intermediate35, duprRating: 3.74, wins: 82,  games: 145, winRate: 0.565, streak: 0,  points: 2890, city: "Austin, TX"),
        LeaderEntry(id: "11", name: "Casey Nguyen",    username: "casey_pb",            skillLevel: .intermediate35, duprRating: 3.42, wins: 22,  games: 30,  winRate: 0.733, streak: 2,  points: 2140, city: "Austin, TX"),
        LeaderEntry(id: "12", name: "Sarah Johnson",   username: "sarahj_pb",           skillLevel: .intermediate35, duprRating: 3.65, wins: 102, games: 176, winRate: 0.580, streak: 0,  points: 3710, city: "Austin, TX"),
        LeaderEntry(id: "13", name: "Riley Torres",    username: "riley_dinkmaster",    skillLevel: .intermediate35, duprRating: 3.55, wins: 73,  games: 121, winRate: 0.603, streak: 0,  points: 2960, city: "Austin, TX"),
        LeaderEntry(id: "14", name: "Drew Patel",      username: "drew_dink",           skillLevel: .advanced40,     duprRating: 4.10, wins: 7,   games: 10,  winRate: 0.700, streak: 1,  points: 1280, city: "Austin, TX"),
        LeaderEntry(id: "15", name: "Sophie Chen",     username: "sophie_serves",       skillLevel: .intermediate30, duprRating: 2.98, wins: 47,  games: 88,  winRate: 0.534, streak: 0,  points: 1850, city: "Austin, TX"),
        LeaderEntry(id: "16", name: "Taylor Kim",      username: "tkim_pickles",        skillLevel: .intermediate30, duprRating: 2.85, wins: 18,  games: 34,  winRate: 0.529, streak: 0,  points: 980,  city: "Cedar Park, TX"),
        LeaderEntry(id: "17", name: "Morgan Davis",    username: "morganplays",         skillLevel: .intermediate30, duprRating: 2.78, wins: 28,  games: 56,  winRate: 0.500, streak: 0,  points: 1120, city: "Austin, TX"),
        LeaderEntry(id: "18", name: "Tyler Brooks",    username: "tylerbrooks_pb",      skillLevel: .beginner25,     duprRating: 2.60, wins: 9,   games: 22,  winRate: 0.409, streak: 0,  points: 540,  city: "San Marcos, TX"),
        LeaderEntry(id: "19", name: "Sam Ortega",      username: "sam_ortega",          skillLevel: .beginner25,     duprRating: 2.45, wins: 3,   games: 9,   winRate: 0.333, streak: 0,  points: 290,  city: "Austin, TX"),
        LeaderEntry(id: "20", name: "Olivia Turner",   username: "oliviaturner_pb",     skillLevel: .beginner20,     duprRating: 2.10, wins: 3,   games: 11,  winRate: 0.273, streak: 0,  points: 180,  city: "Buda, TX"),
    ]

    // Scope membership sets
    private let friendUsernames: Set<String> = [
        "maria_plays", "jordan_4point0", "sarahj_pb",
        "chrisp_dink", "tkim_pickles", "jamiepb", "morganplays", "riley_dinkmaster"
    ]
    private let myGroupUsernames: Set<String> = [
        "jamiepb", "maria_plays", "sarahj_pb", "chrisp_dink",
        "priyapatel_dinks", "marcusw_kitchen", "casey_pb", "drew_dink"
    ]
    private let localUsernames: Set<String> = [
        "pickleking", "maria_plays", "jordan_4point0", "sarahj_pb",
        "jamiepb", "riley_dinkmaster", "aishaj_bangerz", "casey_pb",
        "derekmartinez_5pt0", "sophie_serves", "morganplays", "priyapatel_dinks"
    ]

    // MARK: - Derived ranked lists

    private func ranked(_ entries: [LeaderEntry]) -> [LeaderEntry] {
        entries.enumerated().map { i, e in
            var e = e; e.rank = i + 1; return e
        }
    }

    private func duprBaseRanked() -> [LeaderEntry] {
        ranked(baseEntries.sorted { $0.duprRating > $1.duprRating })
    }

    // Filter pool by scope
    private func poolForScope(_ scope: LeaderboardScope) -> [LeaderEntry] {
        switch scope {
        case .overall:
            return baseEntries
        case .friends:
            return baseEntries.filter { friendUsernames.contains($0.username) }
        case .myGroups:
            return baseEntries.filter { myGroupUsernames.contains($0.username) }
        case .local:
            return baseEntries.filter { localUsernames.contains($0.username) }
        }
    }

    // Simulate period differences on top of scope pool
    private func entriesForPeriod(_ period: LeaderboardPeriod, pool: [LeaderEntry]) -> [LeaderEntry] {
        switch period {
        case .thisWeek:
            return pool.map { e in
                LeaderEntry(id: e.id, name: e.name, username: e.username,
                            skillLevel: e.skillLevel, duprRating: e.duprRating,
                            wins: max(0, e.wins / 12), games: max(1, e.games / 10),
                            winRate: e.winRate * 0.96,
                            streak: e.streak, points: e.points / 10, city: e.city)
            }
        case .thisMonth:
            return pool.map { e in
                LeaderEntry(id: e.id, name: e.name, username: e.username,
                            skillLevel: e.skillLevel, duprRating: e.duprRating,
                            wins: max(0, e.wins / 4), games: max(1, e.games / 4),
                            winRate: e.winRate * 0.98,
                            streak: e.streak, points: e.points / 4, city: e.city)
            }
        case .allTime:
            return pool
        }
    }

    private func sorted(_ entries: [LeaderEntry], by sort: LeaderboardSort) -> [LeaderEntry] {
        switch sort {
        case .dupr:        return entries.sorted { $0.duprRating > $1.duprRating }
        case .winRate:     return entries.sorted { $0.winRate > $1.winRate }
        case .gamesPlayed: return entries.sorted { $0.games > $1.games }
        case .streak:      return entries.sorted { $0.streak > $1.streak }
        case .points:      return entries.sorted { $0.points > $1.points }
        }
    }

    private func currentLeadersFull() -> [LeaderEntry] {
        let pool = poolForScope(selectedScope)
        let periodPool = entriesForPeriod(selectedPeriod, pool: pool)
        return ranked(sorted(periodPool, by: selectedSort))
    }

    private var currentLeaders: [LeaderEntry] {
        currentLeadersFull()
    }

    private var displayedLeaders: [LeaderEntry] {
        Array(currentLeaders.prefix(displayedCount))
    }

    // Trend: compare current rank to All Time DUPR overall rank
    private func trendFor(_ entry: LeaderEntry, in list: [LeaderEntry]) -> Int {
        let allTimeRank = duprBaseRanked().first(where: { $0.id == entry.id })?.rank ?? entry.rank
        return allTimeRank - entry.rank
    }

    private var currentUserEntry: LeaderEntry? {
        currentLeaders.first(where: { $0.username == "pickleking" })
    }
    private var currentUserRank: Int? {
        currentUserEntry?.rank
    }

    // Top X% calculation
    private func topPercentString(rank: Int, total: Int) -> String {
        guard total > 0 else { return "" }
        let pct = Int(ceil(Double(rank) / Double(total) * 100.0))
        return "Top \(pct)%"
    }

    private var scopeMemberCount: Int {
        poolForScope(selectedScope).count
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                            .padding(.bottom, 4)

                        scopeTabBar
                            .padding(.bottom, 8)

                        contentForScope
                    }
                    .padding(.bottom, currentUserRank != nil && (currentUserRank! > 10) ? 80 : 24)
                }
                .onAppear {
                    scrollProxy = proxy
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.68)) {
                            podiumAppeared = true
                        }
                    }
                }
            }

            // Sticky current-user rank bar (only when user is outside top 10)
            if let rank = currentUserRank, rank > 10 {
                stickyUserRankBar(rank: rank)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: selectedScope) { _, _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                rankChangeID = UUID()
                displayedCount = 8
                podiumAppeared = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    podiumAppeared = true
                }
            }
            HapticManager.selection()
        }
        .onChange(of: selectedPeriod) { _, _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                rankChangeID = UUID()
                displayedCount = 8
                podiumAppeared = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    podiumAppeared = true
                }
            }
            HapticManager.selection()
        }
        .onChange(of: selectedSort) { _, _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                rankChangeID = UUID()
                displayedCount = 8
            }
            HapticManager.selection()
        }
        .sheet(isPresented: $showChallengeSheet) {
            if let entry = challengeSheetEntry {
                ChallengeConfirmSheet(entry: entry, onConfirm: {
                    showChallengeSheet = false
                    HapticManager.success()
                }, onCancel: {
                    showChallengeSheet = false
                })
            }
        }
    }

    // MARK: - Scope Content

    @ViewBuilder
    private var contentForScope: some View {
        let pool = poolForScope(selectedScope)
        if (selectedScope == .friends || selectedScope == .myGroups || selectedScope == .local)
            && pool.count < 3 {
            emptyStateSection(scope: selectedScope)
        } else {
            podiumSection
                .padding(.top, 4)

            currentUserCard
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)

            leaderboardListSection
                .padding(.top, 8)
        }
    }

    // MARK: - Header (title + time filter + category filter)

    private var headerSection: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Leaderboard")
                        .font(.title2.weight(.heavy))
                    Text("\(scopeMemberCount) players ranked")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Color.dinkrAmber)
                    .font(.title2)
                    .shadow(color: Color.dinkrAmber.opacity(0.4), radius: 6)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            // Time period chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LeaderboardPeriod.allCases, id: \.self) { period in
                        periodChip(period)
                    }
                }
                .padding(.horizontal, 16)
            }

            // Category sort chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LeaderboardSort.allCases, id: \.self) { sort in
                        sortChip(sort)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func periodChip(_ period: LeaderboardPeriod) -> some View {
        let isSelected = selectedPeriod == period
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                selectedPeriod = period
            }
        } label: {
            Text(period.rawValue)
                .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? .white : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.dinkrGreen : Color.cardBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(
                        isSelected ? Color.clear : Color.secondary.opacity(0.2),
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }

    private func sortChip(_ sort: LeaderboardSort) -> some View {
        let isSelected = selectedSort == sort
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                selectedSort = sort
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: sortIcon(sort))
                    .font(.system(size: 10, weight: .semibold))
                Text(sort.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .bold : .regular))
            }
            .foregroundStyle(isSelected ? Color.dinkrGreen : Color.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.dinkrGreen.opacity(0.12) : Color.cardBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(
                    isSelected ? Color.dinkrGreen.opacity(0.4) : Color.secondary.opacity(0.15),
                    lineWidth: 1
                )
            )
        }
        .buttonStyle(.plain)
    }

    private func sortIcon(_ sort: LeaderboardSort) -> String {
        switch sort {
        case .dupr:        return "star.fill"
        case .winRate:     return "percent"
        case .gamesPlayed: return "gamecontroller.fill"
        case .streak:      return "flame.fill"
        case .points:      return "bolt.fill"
        }
    }

    // MARK: - Scope Tab Bar

    private var scopeTabBar: some View {
        HStack(spacing: 0) {
            ForEach(LeaderboardScope.allCases, id: \.self) { scope in
                scopeTab(scope)
            }
        }
        .padding(.horizontal, 16)
        .background(Color.cardBackground.clipShape(RoundedRectangle(cornerRadius: 14)))
        .padding(.horizontal, 16)
    }

    private func scopeTab(_ scope: LeaderboardScope) -> some View {
        let isSelected = selectedScope == scope
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                selectedScope = scope
            }
        } label: {
            VStack(spacing: 3) {
                Text(scope.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? Color.dinkrGreen : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)

                Rectangle()
                    .fill(isSelected ? Color.dinkrGreen : Color.clear)
                    .frame(height: 2)
                    .clipShape(Capsule())
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.72), value: selectedScope)
    }

    // MARK: - Podium Section

    private var podiumSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("TOP 3")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.secondary)
                Spacer()
                if selectedScope != .overall {
                    Text(selectedScope.rawValue.uppercased())
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(Color.dinkrNavy.opacity(0.5))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.dinkrNavy.opacity(0.06))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)

            if currentLeaders.count >= 3 {
                HStack(alignment: .bottom, spacing: 8) {
                    // 2nd place (left)
                    podiumBlock(
                        entry: currentLeaders[1],
                        platformHeight: 90,
                        medal: .silver,
                        offset: podiumAppeared ? 0 : 60
                    )
                    // 1st place (center, tallest)
                    podiumBlock(
                        entry: currentLeaders[0],
                        platformHeight: 128,
                        medal: .gold,
                        offset: podiumAppeared ? 0 : 80
                    )
                    // 3rd place (right)
                    podiumBlock(
                        entry: currentLeaders[2],
                        platformHeight: 70,
                        medal: .bronze,
                        offset: podiumAppeared ? 0 : 50
                    )
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 8)
    }

    private enum Medal {
        case gold, silver, bronze

        var color: Color {
            switch self {
            case .gold:   return Color(red: 1.0, green: 0.82, blue: 0.12)
            case .silver: return Color(red: 0.75, green: 0.75, blue: 0.80)
            case .bronze: return Color(red: 0.80, green: 0.50, blue: 0.22)
            }
        }

        var gradient: [Color] {
            switch self {
            case .gold:   return [Color(red: 1.0, green: 0.90, blue: 0.30), Color(red: 0.90, green: 0.62, blue: 0.04)]
            case .silver: return [Color(red: 0.90, green: 0.90, blue: 0.94), Color(red: 0.58, green: 0.58, blue: 0.65)]
            case .bronze: return [Color(red: 0.95, green: 0.68, blue: 0.40), Color(red: 0.65, green: 0.38, blue: 0.10)]
            }
        }

        var number: String {
            switch self {
            case .gold: return "1"
            case .silver: return "2"
            case .bronze: return "3"
            }
        }

        var isFirst: Bool { self == .gold }
    }

    private func podiumBlock(
        entry: LeaderEntry,
        platformHeight: CGFloat,
        medal: Medal,
        offset: CGFloat
    ) -> some View {
        let isCurrentUser = entry.username == "pickleking"
        let avatarSize: CGFloat = medal.isFirst ? 64 : 52
        let isFirst = medal.isFirst

        return VStack(spacing: 0) {
            // Crown or medal overlay
            VStack(spacing: 4) {
                if isFirst {
                    Text("👑")
                        .font(.title2)
                        .offset(y: podiumAppeared ? 0 : -10)
                        .opacity(podiumAppeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.25), value: podiumAppeared)
                } else {
                    // Medal number badge
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: medal.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 20, height: 20)
                        Text(medal.number)
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: medal.color.opacity(0.5), radius: 4)
                    .offset(y: podiumAppeared ? 0 : -6)
                    .opacity(podiumAppeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.2), value: podiumAppeared)
                }

                // Avatar circle
                ZStack {
                    // Glow ring for 1st
                    if isFirst {
                        Circle()
                            .fill(medal.color.opacity(0.18))
                            .frame(width: avatarSize + 12, height: avatarSize + 12)
                    }
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isCurrentUser
                                    ? [Color.dinkrGreen.opacity(0.25), Color.dinkrGreen.opacity(0.08)]
                                    : [medal.color.opacity(0.22), medal.color.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: avatarSize, height: avatarSize)
                        .overlay(
                            Circle().stroke(
                                LinearGradient(
                                    colors: isCurrentUser
                                        ? [Color.dinkrGreen, Color.dinkrGreen.opacity(0.4)]
                                        : medal.gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isFirst ? 3 : 2
                            )
                        )

                    Text(String(entry.name.prefix(1)))
                        .font(isFirst ? .title.weight(.heavy) : .title2.weight(.bold))
                        .foregroundStyle(isCurrentUser ? Color.dinkrGreen : medal.color)
                }
                .scaleEffect(podiumAppeared ? 1 : 0.6)
                .animation(.spring(response: 0.55, dampingFraction: 0.65).delay(isFirst ? 0.05 : 0.12), value: podiumAppeared)

                // Name
                Text(entry.name.components(separatedBy: " ").first ?? "")
                    .font(isFirst ? .caption.weight(.bold) : .caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if isCurrentUser {
                    Text("YOU")
                        .font(.system(size: 7, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.dinkrGreen)
                        .clipShape(Capsule())
                }

                statBadge(for: entry, compact: !isFirst)
            }
            .padding(.bottom, 6)

            // Platform
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: medal.gradient.map { $0.opacity(0.28) } + [medal.color.opacity(0.10)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: platformHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                LinearGradient(colors: medal.gradient.map { $0.opacity(0.5) },
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1.5
                            )
                    )

                // Large rank number on platform
                Text(medal.number)
                    .font(.system(size: isFirst ? 28 : 22, weight: .heavy))
                    .foregroundStyle(
                        LinearGradient(colors: medal.gradient, startPoint: .top, endPoint: .bottom)
                    )
                    .padding(.top, 10)

                // Challenge button for 1st place
                if isFirst {
                    VStack {
                        Spacer()
                        Button {
                            challengeSheetEntry = entry
                            showChallengeSheet = true
                            HapticManager.medium()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 9, weight: .bold))
                                Text("Challenge")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.dinkrCoral)
                            .clipShape(Capsule())
                            .shadow(color: Color.dinkrCoral.opacity(0.4), radius: 4, y: 2)
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 10)
                    }
                    .frame(height: platformHeight)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .offset(y: offset)
        .opacity(podiumAppeared ? 1 : 0)
        .animation(
            .spring(response: 0.55, dampingFraction: 0.7)
                .delay(medal == .gold ? 0.05 : medal == .silver ? 0.12 : 0.18),
            value: podiumAppeared
        )
    }

    private func statBadge(for entry: LeaderEntry, compact: Bool = false) -> some View {
        Group {
            switch selectedSort {
            case .dupr:
                HStack(spacing: 3) {
                    if !compact {
                        Text("DUPR")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(Color.dinkrAmber)
                    }
                    Text(String(format: "%.2f", entry.duprRating))
                        .font(.system(size: compact ? 9 : 11, weight: .bold))
                        .foregroundStyle(Color.dinkrAmber)
                }
                .padding(.horizontal, compact ? 5 : 7)
                .padding(.vertical, 3)
                .background(Color.dinkrAmber.opacity(0.12))
                .clipShape(Capsule())
            case .winRate:
                Text("\(Int(entry.winRate * 100))%")
                    .font(.system(size: compact ? 9 : 11, weight: .bold))
                    .foregroundStyle(Color.dinkrGreen)
                    .padding(.horizontal, compact ? 5 : 7)
                    .padding(.vertical, 3)
                    .background(Color.dinkrGreen.opacity(0.10))
                    .clipShape(Capsule())
            case .gamesPlayed:
                Text("\(entry.games)G")
                    .font(.system(size: compact ? 9 : 11, weight: .bold))
                    .foregroundStyle(Color.dinkrSky)
                    .padding(.horizontal, compact ? 5 : 7)
                    .padding(.vertical, 3)
                    .background(Color.dinkrSky.opacity(0.10))
                    .clipShape(Capsule())
            case .streak:
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Color.dinkrCoral)
                    Text("\(entry.streak)")
                        .font(.system(size: compact ? 9 : 11, weight: .bold))
                        .foregroundStyle(Color.dinkrCoral)
                }
                .padding(.horizontal, compact ? 5 : 7)
                .padding(.vertical, 3)
                .background(Color.dinkrCoral.opacity(0.10))
                .clipShape(Capsule())
            case .points:
                HStack(spacing: 2) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(Color.dinkrNavy)
                    Text("\(entry.points)")
                        .font(.system(size: compact ? 9 : 11, weight: .bold))
                        .foregroundStyle(Color.dinkrNavy)
                }
                .padding(.horizontal, compact ? 5 : 7)
                .padding(.vertical, 3)
                .background(Color.dinkrNavy.opacity(0.08))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Current User Rank Card

    private var currentUserCard: some View {
        Group {
            if let userEntry = currentUserEntry, let rank = currentUserRank {
                let trend = trendFor(userEntry, in: currentLeaders)
                let topPctStr = topPercentString(rank: rank, total: currentLeaders.count)

                HStack(spacing: 14) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color.dinkrGreen.opacity(0.18))
                            .frame(width: 46, height: 46)
                            .overlay(Circle().stroke(Color.dinkrGreen.opacity(0.5), lineWidth: 1.5))
                        Text("A")
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(Color.dinkrGreen)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("You're ranked #\(rank)")
                                .font(.subheadline.weight(.bold))
                            Text("YOU")
                                .font(.system(size: 8, weight: .heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.dinkrGreen)
                                .clipShape(Capsule())
                            if !topPctStr.isEmpty {
                                Text(topPctStr)
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(Color.dinkrSky)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.dinkrSky.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                        HStack(spacing: 6) {
                            Label(userEntry.skillLevel.label, systemImage: "chart.bar.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.dinkrSky)
                            Text("·").foregroundStyle(.secondary).font(.caption2)
                            Text("DUPR \(String(format: "%.2f", userEntry.duprRating))")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color.dinkrAmber)
                            Text("·").foregroundStyle(.secondary).font(.caption2)
                            Text("\(userEntry.wins)W \(userEntry.games - userEntry.wins)L")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        if trend > 0 {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundStyle(Color.dinkrGreen)
                                .font(.title3)
                            Text("+\(trend)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.dinkrGreen)
                        } else if trend < 0 {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundStyle(Color.dinkrCoral)
                                .font(.title3)
                            Text("\(trend)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.dinkrCoral)
                        } else {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(Color.secondary)
                                .font(.title3)
                            Text("—")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(14)
                .background(Color.dinkrGreen.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.dinkrGreen.opacity(0.45), lineWidth: 1.5)
                )
            }
        }
    }

    // MARK: - Sticky Bottom Rank Bar

    private func stickyUserRankBar(rank: Int) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.18))
                    .frame(width: 38, height: 38)
                    .overlay(Circle().stroke(Color.dinkrGreen.opacity(0.5), lineWidth: 1.5))
                Text("A")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(Color.dinkrGreen)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text("Your Rank")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("#\(rank)")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(Color.dinkrGreen)
                }
                let topPctStr = topPercentString(rank: rank, total: currentLeaders.count)
                if !topPctStr.isEmpty {
                    Text(topPctStr)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.dinkrSky)
                }
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    displayedCount = max(displayedCount, rank + 2)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        scrollProxy?.scrollTo("row-\(rank)", anchor: .center)
                    }
                }
                HapticManager.light()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Jump to my rank")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.dinkrGreen)
                .clipShape(Capsule())
                .shadow(color: Color.dinkrGreen.opacity(0.4), radius: 6, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color.dinkrGreen.opacity(0.25))
                .frame(height: 1),
            alignment: .top
        )
    }

    // MARK: - Full Leaderboard List

    private var leaderboardListSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("FULL RANKINGS")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(currentLeaders.count) players")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(Array(displayedLeaders.enumerated()), id: \.element.id) { index, entry in
                    let trend = trendFor(entry, in: currentLeaders)
                    let isCurrentUser = entry.username == "pickleking"
                    LeaderboardRow(
                        entry: entry,
                        isCurrentUser: isCurrentUser,
                        sort: selectedSort,
                        trend: trend,
                        topPercentStr: topPercentString(rank: entry.rank, total: currentLeaders.count),
                        animationDelay: Double(index) * 0.03,
                        onChallenge: {
                            challengeSheetEntry = entry
                            showChallengeSheet = true
                            HapticManager.medium()
                        }
                    )
                    .id("row-\(entry.rank)")
                    .id("\(entry.id)-\(rankChangeID)")
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))

                    if index < displayedLeaders.count - 1 {
                        Divider().padding(.horizontal, 16)
                    }
                }
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)

            // Load more
            if displayedCount < currentLeaders.count {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        displayedCount += 8
                    }
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.down.circle")
                            .font(.subheadline)
                        Text("Load more (\(currentLeaders.count - displayedCount) remaining)")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Color.dinkrGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.dinkrGreen.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.dinkrGreen.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
        }
        .padding(.bottom, 16)
    }

    // MARK: - Empty State

    private func emptyStateSection(scope: LeaderboardScope) -> some View {
        let (icon, title, subtitle) = emptyStateCopy(scope: scope)
        return VStack(spacing: 20) {
            Spacer(minLength: 40)

            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.10))
                    .frame(width: 84, height: 84)
                Image(systemName: icon)
                    .font(.system(size: 34))
                    .foregroundStyle(Color.dinkrGreen)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.bold))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                HapticManager.success()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                    Text(scope == .local ? "Find Nearby Players" : "Invite to Dinkr")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 13)
                .background(Color.dinkrGreen)
                .clipShape(Capsule())
                .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 8, y: 3)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity)
    }

    private func emptyStateCopy(scope: LeaderboardScope) -> (String, String, String) {
        switch scope {
        case .friends:
            return ("person.2.badge.plus", "Invite friends to compete",
                    "You need at least 3 friends on Dinkr to see the Friends leaderboard.")
        case .myGroups:
            return ("person.3.fill", "Join a group to compete",
                    "Join or create a group to see how your group stacks up.")
        case .local:
            return ("location.magnifyingglass", "No local players found",
                    "Enable location access to discover players in your area.")
        case .overall:
            return ("trophy", "No rankings yet", "Check back soon!")
        }
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let entry: LeaderEntry
    let isCurrentUser: Bool
    let sort: LeaderboardSort
    let trend: Int
    let topPercentStr: String
    var animationDelay: Double = 0
    var onChallenge: (() -> Void)? = nil

    @State private var appeared = false

    private var rankColor: Color {
        switch entry.rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.78)
        case 3: return Color(red: 0.80, green: 0.52, blue: 0.25)
        default: return Color.secondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                if entry.rank <= 3 {
                    Circle()
                        .fill(rankColor.opacity(0.18))
                        .frame(width: 32, height: 32)
                    Text("\(entry.rank)")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(rankColor)
                } else {
                    Text("#\(entry.rank)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, alignment: .leading)
                }
            }
            .frame(width: 32)

            // Avatar
            ZStack {
                Circle()
                    .fill(isCurrentUser ? Color.dinkrGreen.opacity(0.15) : Color.secondary.opacity(0.10))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle().stroke(
                            isCurrentUser ? Color.dinkrGreen : Color.clear,
                            lineWidth: 1.5
                        )
                    )
                Text(String(entry.name.prefix(1)))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isCurrentUser ? Color.dinkrGreen : Color.secondary)
            }

            // Name + skill + username
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(entry.name)
                        .font(.subheadline.weight(isCurrentUser ? .bold : .regular))
                        .lineLimit(1)
                    if isCurrentUser {
                        Text("YOU")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.dinkrGreen)
                            .clipShape(Capsule())
                        if !topPercentStr.isEmpty {
                            Text(topPercentStr)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Color.dinkrSky)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.dinkrSky.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
                HStack(spacing: 4) {
                    // Skill badge
                    Text(entry.skillLevel.label)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(skillBadgeColor(entry.skillLevel))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(skillBadgeColor(entry.skillLevel).opacity(0.1))
                        .clipShape(Capsule())
                    Text("@\(entry.username)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Trend arrow
            trendView

            // Challenge button (rank 1 only)
            if entry.rank == 1 && !isCurrentUser {
                Button {
                    onChallenge?()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text("#1")
                            .font(.system(size: 10, weight: .heavy))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.dinkrCoral)
                    .clipShape(Capsule())
                    .shadow(color: Color.dinkrCoral.opacity(0.35), radius: 3, y: 1)
                }
                .buttonStyle(.plain)
            }

            // Stat value
            statView
                .frame(minWidth: 60, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(isCurrentUser ? Color.dinkrGreen.opacity(0.05) : Color.clear)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : 18)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75).delay(animationDelay)) {
                appeared = true
            }
        }
    }

    private func skillBadgeColor(_ level: SkillLevel) -> Color {
        switch level {
        case .beginner20, .beginner25:       return Color.dinkrGreen
        case .intermediate30, .intermediate35: return Color.dinkrSky
        case .advanced40, .advanced45:        return Color.dinkrAmber
        case .pro50:                          return Color.dinkrCoral
        }
    }

    @ViewBuilder
    private var trendView: some View {
        if trend > 0 {
            VStack(spacing: 1) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.dinkrGreen)
                Text("+\(trend)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.dinkrGreen)
            }
        } else if trend < 0 {
            VStack(spacing: 1) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.dinkrCoral)
                Text("\(trend)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.dinkrCoral)
            }
        } else {
            Image(systemName: "minus")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.secondary.opacity(0.5))
        }
    }

    @ViewBuilder
    private var statView: some View {
        switch sort {
        case .dupr:
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 3) {
                    Text("DUPR")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(Color.dinkrAmber)
                    Text(String(format: "%.2f", entry.duprRating))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isCurrentUser ? Color.dinkrAmber : Color.primary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.dinkrAmber.opacity(isCurrentUser ? 0.18 : 0.08))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color.dinkrAmber.opacity(isCurrentUser ? 0.5 : 0.2), lineWidth: 1))
            }
        case .winRate:
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(entry.winRate * 100))%")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isCurrentUser ? Color.dinkrGreen : Color.primary)
                Text("\(entry.wins)W \(entry.games - entry.wins)L")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case .gamesPlayed:
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.games)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(isCurrentUser ? Color.dinkrSky : Color.primary)
                Text("games")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        case .streak:
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(entry.streak > 0 ? Color.dinkrCoral : Color.secondary.opacity(0.4))
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(entry.streak)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(entry.streak > 0 ? (isCurrentUser ? Color.dinkrCoral : Color.primary) : Color.secondary.opacity(0.4))
                    Text("streak")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        case .points:
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 3) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.dinkrNavy)
                    Text("\(entry.points)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(isCurrentUser ? Color.dinkrNavy : Color.primary)
                }
                Text("pts")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Challenge Confirm Sheet

private struct ChallengeConfirmSheet: View {
    let entry: LeaderEntry
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 24)

            // Trophy icon
            ZStack {
                Circle()
                    .fill(Color.dinkrCoral.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.dinkrCoral)
            }
            .padding(.bottom, 16)

            Text("Challenge \(entry.name.components(separatedBy: " ").first ?? entry.name)?")
                .font(.title3.weight(.heavy))
                .padding(.bottom, 6)

            Text("You're challenging \(entry.name) (@\(entry.username)) — currently ranked #\(entry.rank). A challenge request will be sent for a match.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 28)

            // Player stats
            HStack(spacing: 0) {
                statPill(label: "DUPR", value: String(format: "%.2f", entry.duprRating), color: Color.dinkrAmber)
                Divider().frame(height: 28)
                statPill(label: "Win Rate", value: "\(Int(entry.winRate * 100))%", color: Color.dinkrGreen)
                Divider().frame(height: 28)
                statPill(label: "Streak", value: "\(entry.streak)", color: Color.dinkrCoral)
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 32)
            .padding(.bottom, 32)

            // Buttons
            VStack(spacing: 10) {
                Button(action: onConfirm) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                        Text("Send Challenge")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.dinkrCoral)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.dinkrCoral.opacity(0.35), radius: 8, y: 3)
                }
                .buttonStyle(.plain)

                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .presentationDetents([.height(480)])
        .presentationDragIndicator(.hidden)
    }

    private func statPill(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScrollView {
            LeaderboardView()
        }
        .navigationTitle("Play")
        .navigationBarTitleDisplayMode(.inline)
    }
}

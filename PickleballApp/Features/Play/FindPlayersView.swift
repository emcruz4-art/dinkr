import SwiftUI

// MARK: - Sort Option

enum PlayerSortOption: String, CaseIterable, Identifiable {
    case bestMatch   = "Best Match"
    case nearest     = "Nearest"
    case mostActive  = "Most Active"
    case newPlayers  = "New Players"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .bestMatch:  return "star.fill"
        case .nearest:    return "location.fill"
        case .mostActive: return "bolt.fill"
        case .newPlayers: return "sparkles"
        }
    }
}

// MARK: - Player Filter State

struct PlayerFilterState {
    var minSkillIndex: Double = 0
    var maxSkillIndex: Double = 6
    var selectedStyles: Set<PlayStyle> = []
    var selectedDays: Set<Weekday> = []
    var radiusMiles: Double = 25

    var isActive: Bool {
        minSkillIndex > 0 || maxSkillIndex < 6 ||
        !selectedStyles.isEmpty || !selectedDays.isEmpty || radiusMiles < 25
    }

    func matches(player: User, currentUser: User) -> Bool {
        let idx = Double(player.skillLevel.sortIndex)
        guard idx >= minSkillIndex && idx <= maxSkillIndex else { return false }

        if !selectedStyles.isEmpty {
            guard let ps = player.playStyle, selectedStyles.contains(ps) else { return false }
        }

        if !selectedDays.isEmpty {
            let playerDays = Set(player.availabilityDays ?? [])
            guard !playerDays.isDisjoint(with: selectedDays) else { return false }
        }

        if let cl = currentUser.location, let pl = player.location {
            let dLat = cl.latitude - pl.latitude
            let dLon = cl.longitude - pl.longitude
            let miles = sqrt(dLat * dLat + dLon * dLon) * 69
            guard miles <= radiusMiles else { return false }
        }

        return true
    }
}

// MARK: - FindPlayersView

struct FindPlayersView: View {
    let players: [User]
    let currentUserId: String

    @State private var searchText: String = ""
    @State private var sortOption: PlayerSortOption = .bestMatch
    @State private var filterState = PlayerFilterState()
    @State private var showFilterSheet = false
    @State private var selectedPlayer: User? = nil
    @State private var isRefreshing = false
    @State private var visibleCount = 10
    @State private var showRecommendations = false

    private let currentUser: User = User.mockCurrentUser // replaced by injected user in production

    // MARK: Derived player lists

    private var filteredPlayers: [User] {
        players
            .filter { $0.id != currentUserId }
            .filter { player in
                if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    let query = searchText.lowercased()
                    return player.displayName.lowercased().contains(query) ||
                           player.city.lowercased().contains(query) ||
                           player.username.lowercased().contains(query)
                }
                return true
            }
            .filter { filterState.matches(player: $0, currentUser: currentUser) }
    }

    private func sortedPlayers(_ list: [User]) -> [User] {
        switch sortOption {
        case .bestMatch:
            return list.sorted {
                CompatibilityScore.compute(current: currentUser, candidate: $0).overall >
                CompatibilityScore.compute(current: currentUser, candidate: $1).overall
            }
        case .nearest:
            return list.sorted { a, b in
                let distA = distanceMiles(from: currentUser.location, to: a.location)
                let distB = distanceMiles(from: currentUser.location, to: b.location)
                return distA < distB
            }
        case .mostActive:
            return list.sorted { $0.gamesPlayed > $1.gamesPlayed }
        case .newPlayers:
            return list.sorted { $0.joinedDate > $1.joinedDate }
        }
    }

    private var allSortedPlayers: [User] { sortedPlayers(filteredPlayers) }
    private var bestMatchPlayers: [User] { Array(sortedPlayers(filteredPlayers).prefix(3)) }
    private var paginatedPlayers: [User] { Array(allSortedPlayers.prefix(visibleCount)) }
    private var hasMore: Bool { visibleCount < allSortedPlayers.count }

    private func distanceMiles(from: GeoPoint?, to: GeoPoint?) -> Double {
        guard let f = from, let t = to else { return 9999 }
        let dLat = f.latitude - t.latitude
        let dLon = f.longitude - t.longitude
        return sqrt(dLat * dLat + dLon * dLon) * 69
    }

    // MARK: Body

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {

                    // ── Search + Filter bar ──
                    searchFilterBar
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                    // ── Sort strip ──
                    sortStrip
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                    if filteredPlayers.isEmpty {
                        EmptyStateView(
                            icon: "person.2",
                            title: "No Players Found",
                            message: "Try adjusting your filters or search terms."
                        )
                        .padding(.top, 40)
                    } else {
                        // ── Recommended Players banner ──
                        if sortOption == .bestMatch && searchText.isEmpty && !filterState.isActive {
                            recommendedBanner
                                .padding(.horizontal, 16)
                                .padding(.bottom, 4)
                        }

                        // ── Best Match section ──
                        if sortOption == .bestMatch && searchText.isEmpty && !filterState.isActive {
                            bestMatchSection
                                .padding(.horizontal, 16)
                                .padding(.bottom, 4)
                        }

                        // ── All Players ──
                        allPlayersSection
                    }
                }
                .padding(.bottom, 24)
            }
            .refreshable {
                await simulateRefresh()
            }
        }
        .sheet(item: $selectedPlayer) { player in
            MatchRequestView(opponent: player)
        }
        .sheet(isPresented: $showFilterSheet) {
            PlayerFilterSheet(filterState: $filterState)
        }
        .sheet(isPresented: $showRecommendations) {
            PlayerRecommendationsView()
        }
    }

    // MARK: Recommended Banner

    private var recommendedBanner: some View {
        Button {
            HapticManager.light()
            showRecommendations = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.dinkrSky.opacity(0.15))
                        .frame(width: 42, height: 42)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.dinkrSky)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recommended for You")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.dinkrNavy)
                    Text("Players matched to your courts, skill & network")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [Color.dinkrSky.opacity(0.08), Color.dinkrGreen.opacity(0.06)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.dinkrSky.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Search + Filter Bar

    private var searchFilterBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.secondary)
                TextField("Search name or location…", text: $searchText)
                    .font(.subheadline)
                    .submitLabel(.search)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        HapticManager.light()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))

            // Filter button
            Button {
                HapticManager.light()
                showFilterSheet = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(filterState.isActive ? Color.dinkrGreen : Color.primary)
                        .padding(10)
                        .background(
                            filterState.isActive ? Color.dinkrGreen.opacity(0.12) : Color.cardBackground,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    filterState.isActive ? Color.dinkrGreen.opacity(0.5) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                    if filterState.isActive {
                        Circle()
                            .fill(Color.dinkrCoral)
                            .frame(width: 8, height: 8)
                            .offset(x: 2, y: -2)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Sort Strip

    private var sortStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PlayerSortOption.allCases) { option in
                    Button {
                        HapticManager.selection()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            sortOption = option
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: option.icon)
                                .font(.system(size: 10, weight: .semibold))
                            Text(option.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(sortOption == option ? .white : Color.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            sortOption == option ? Color.dinkrNavy : Color.cardBackground,
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    sortOption == option ? Color.clear : Color.secondary.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Best Match Section

    private var bestMatchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Best Matches", systemImage: "star.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.dinkrAmber)

            ForEach(bestMatchPlayers) { player in
                NavigationLink(destination: UserProfileView(user: player, currentUserId: currentUserId)) {
                    EnhancedPlayerCard(
                        player: player,
                        currentUser: currentUser,
                        currentUserId: currentUserId,
                        isBestMatch: true,
                        onChallenge: { selectedPlayer = player }
                    )
                }
                .buttonStyle(.plain)
            }

            Divider()
                .padding(.top, 4)
        }
    }

    // MARK: All Players Section

    private var allPlayersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if sortOption == .bestMatch && searchText.isEmpty && !filterState.isActive {
                Label("All Players", systemImage: "person.2.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
            }

            ForEach(paginatedPlayers) { player in
                NavigationLink(destination: UserProfileView(user: player, currentUserId: currentUserId)) {
                    EnhancedPlayerCard(
                        player: player,
                        currentUser: currentUser,
                        currentUserId: currentUserId,
                        isBestMatch: false,
                        onChallenge: { selectedPlayer = player }
                    )
                    .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)
            }

            // Load more
            if hasMore {
                Button {
                    HapticManager.light()
                    withAnimation {
                        visibleCount += 10
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle")
                        Text("Load more players")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Color.dinkrGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.dinkrGreen.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.dinkrGreen.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }
        }
    }

    // MARK: Refresh

    private func simulateRefresh() async {
        isRefreshing = true
        try? await Task.sleep(nanoseconds: 800_000_000)
        visibleCount = 10
        isRefreshing = false
    }
}

// MARK: - Enhanced Player Card

struct EnhancedPlayerCard: View {
    let player: User
    let currentUser: User
    let currentUserId: String
    let isBestMatch: Bool
    var onChallenge: (() -> Void)? = nil

    @State private var isFriend = false
    @State private var checked = false
    @State private var showDMSheet = false

    private var compatScore: CompatibilityScore {
        CompatibilityScore.compute(current: currentUser, candidate: player)
    }

    private var isActiveToday: Bool {
        // Simulate active status from gamesPlayed and joinedDate as proxy
        // In production this comes from a lastActive Firestore field
        player.gamesPlayed > 100 || Calendar.current.isDateInToday(player.joinedDate)
    }

    private var lastActiveLabel: String {
        let days = Calendar.current.dateComponents([.day], from: player.joinedDate, to: Date()).day ?? 0
        if isActiveToday { return "Active today" }
        if days < 3 { return "Active \(days)d ago" }
        if days < 7 { return "Active this week" }
        return "Active \(days / 7)w ago"
    }

    private var distanceLabel: String {
        guard let cl = currentUser.location, let pl = player.location else { return "" }
        let dLat = cl.latitude - pl.latitude
        let dLon = cl.longitude - pl.longitude
        let miles = sqrt(dLat * dLat + dLon * dLon) * 69
        return String(format: "%.1f mi away", miles)
    }

    private var mutualGroupsCount: Int {
        // Intersection of clubIds
        let currentSet = Set(currentUser.clubIds)
        let playerSet = Set(player.clubIds)
        return currentSet.intersection(playerSet).count
    }

    private var showPrivateGate: Bool {
        player.isPrivate && !isFriend && currentUserId != player.id
    }

    private var styles: [PlayStyle] {
        if let all = player.playStyles, !all.isEmpty { return all }
        if let single = player.playStyle { return [single] }
        return []
    }

    var body: some View {
        PickleballCard {
            VStack(alignment: .leading, spacing: 0) {

                // ── Header row ──
                HStack(alignment: .top, spacing: 12) {

                    // Avatar + online dot
                    AvatarView(
                        urlString: player.avatarURL,
                        displayName: player.displayName,
                        size: 54,
                        isOnline: isActiveToday
                    )

                    // Name + meta
                    VStack(alignment: .leading, spacing: 5) {

                        // Name row
                        HStack(spacing: 6) {
                            Text(player.displayName)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.primary)
                                .lineLimit(1)

                            // Verified badge
                            if player.reliabilityScore >= 4.8 {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.dinkrSky)
                            }
                        }

                        // Skill + DUPR
                        HStack(spacing: 6) {
                            SkillBadge(level: player.skillLevel, compact: true)
                            if let dupr = player.duprRating {
                                HStack(spacing: 3) {
                                    Text("DUPR")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.secondary)
                                    Text(String(format: "%.2f", dupr))
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color.dinkrAmber)
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.dinkrAmber.opacity(0.1))
                                .clipShape(Capsule())
                            }

                            // Compatibility badge
                            if currentUserId != player.id {
                                CompatibilityScoreBadge(score: compatScore)
                            }
                        }

                        // Distance + last active
                        HStack(spacing: 10) {
                            if !distanceLabel.isEmpty {
                                Label(distanceLabel, systemImage: "location.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Text(lastActiveLabel)
                                .font(.caption2)
                                .foregroundStyle(isActiveToday ? Color.dinkrGreen : .secondary)
                        }
                    }

                    Spacer(minLength: 0)

                    // Follow button
                    if currentUserId != player.id {
                        FollowButton(
                            currentUserId: currentUserId,
                            targetUserId: player.id,
                            isPrivateAccount: player.isPrivate && !isFriend,
                            size: .compact
                        )
                    }
                }
                .padding(14)

                // ── Style chips + mutual groups ──
                if !styles.isEmpty || mutualGroupsCount > 0 {
                    HStack(spacing: 8) {
                        ForEach(styles, id: \.self) { style in
                            PlayStyleBadge(style: style)
                        }
                        Spacer()
                        if mutualGroupsCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 9, weight: .semibold))
                                Text("\(mutualGroupsCount) shared group\(mutualGroupsCount == 1 ? "" : "s")")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundStyle(Color.dinkrSky)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.dinkrSky.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                }

                // ── Stats row (non-private) ──
                if !showPrivateGate {
                    HStack(spacing: 16) {
                        Label("\(player.gamesPlayed) games", systemImage: "figure.pickleball")
                        Label(String(format: "%.0f%% wins", player.winRate * 100), systemImage: "trophy.fill")
                        Label(player.city, systemImage: "mappin.circle")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                        Text("Private account · \(player.city)")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                }

                // ── Action buttons ──
                if currentUserId != player.id {
                    Divider()
                        .padding(.horizontal, 14)

                    HStack(spacing: 0) {
                        // Message
                        ActionButton(
                            label: "Message",
                            icon: "bubble.left.fill",
                            color: Color.dinkrSky
                        ) {
                            showDMSheet = true
                        }

                        Divider().frame(height: 36)

                        // Challenge
                        ActionButton(
                            label: "Challenge",
                            icon: "bolt.fill",
                            color: Color.dinkrGreen
                        ) {
                            HapticManager.light()
                            onChallenge?()
                        }

                        Divider().frame(height: 36)

                        // Add Friend / Follow
                        ActionButton(
                            label: "Add Friend",
                            icon: "person.badge.plus",
                            color: Color.dinkrAmber
                        ) {
                            HapticManager.light()
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        // Best match glow border
        .overlay(
            isBestMatch ?
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.dinkrAmber.opacity(0.6), Color.dinkrGreen.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
            : nil
        )
        .task {
            guard !checked else { return }
            checked = true
            if player.isPrivate && currentUserId != player.id {
                isFriend = await FollowService.shared.isMutualFollow(
                    currentUserId: currentUserId,
                    targetUserId: player.id
                )
            } else {
                isFriend = true
            }
        }
        .sheet(isPresented: $showDMSheet) {
            // Placeholder: real DMView goes here
            NavigationStack {
                VStack(spacing: 16) {
                    AvatarView(urlString: player.avatarURL, displayName: player.displayName, size: 64)
                    Text("Message \(player.displayName)")
                        .font(.title3.weight(.bold))
                    Text("DM feature coming soon.")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.top, 32)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { showDMSheet = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Player Filter Sheet

struct PlayerFilterSheet: View {
    @Binding var filterState: PlayerFilterState
    @Environment(\.dismiss) private var dismiss

    private let levels = SkillLevel.allCases

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // Skill Range
                    VStack(alignment: .leading, spacing: 14) {
                        PlayerSectionHeader(title: "Skill Level Range", icon: "chart.bar.fill")

                        let minLevel = levels[Int(filterState.minSkillIndex)]
                        let maxLevel = levels[Int(filterState.maxSkillIndex)]

                        HStack {
                            SkillBadge(level: minLevel)
                            Text("to")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            SkillBadge(level: maxLevel)
                            Spacer()
                        }

                        // Min slider
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Minimum")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Slider(
                                value: $filterState.minSkillIndex,
                                in: 0...Double(levels.count - 1),
                                step: 1
                            ) { _ in
                                if filterState.minSkillIndex > filterState.maxSkillIndex {
                                    filterState.maxSkillIndex = filterState.minSkillIndex
                                }
                            }
                            .tint(Color.dinkrGreen)
                        }

                        // Max slider
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Maximum")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Slider(
                                value: $filterState.maxSkillIndex,
                                in: 0...Double(levels.count - 1),
                                step: 1
                            ) { _ in
                                if filterState.maxSkillIndex < filterState.minSkillIndex {
                                    filterState.minSkillIndex = filterState.maxSkillIndex
                                }
                            }
                            .tint(Color.dinkrGreen)
                        }
                    }

                    Divider()

                    // Play Style
                    VStack(alignment: .leading, spacing: 12) {
                        PlayerSectionHeader(title: "Play Style", icon: "figure.mind.and.body")
                        PlayerFlowLayout(spacing: 8) {
                            ForEach(PlayStyle.allCases, id: \.self) { style in
                                PlayerFilterChip(
                                    label: style.rawValue,
                                    icon: style.icon,
                                    isSelected: filterState.selectedStyles.contains(style)
                                ) {
                                    HapticManager.selection()
                                    if filterState.selectedStyles.contains(style) {
                                        filterState.selectedStyles.remove(style)
                                    } else {
                                        filterState.selectedStyles.insert(style)
                                    }
                                }
                            }
                        }
                    }

                    Divider()

                    // Availability Days
                    VStack(alignment: .leading, spacing: 12) {
                        PlayerSectionHeader(title: "Available Days", icon: "calendar")
                        PlayerFlowLayout(spacing: 8) {
                            ForEach(Weekday.allCases) { day in
                                PlayerFilterChip(
                                    label: day.rawValue,
                                    isSelected: filterState.selectedDays.contains(day)
                                ) {
                                    HapticManager.selection()
                                    if filterState.selectedDays.contains(day) {
                                        filterState.selectedDays.remove(day)
                                    } else {
                                        filterState.selectedDays.insert(day)
                                    }
                                }
                            }
                        }
                    }

                    Divider()

                    // Distance Radius
                    VStack(alignment: .leading, spacing: 12) {
                        PlayerSectionHeader(title: "Distance Radius", icon: "location.circle.fill")

                        HStack {
                            Text(filterState.radiusMiles < 50 ?
                                 "\(Int(filterState.radiusMiles)) mi" : "Any distance")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Color.dinkrGreen)
                            Spacer()
                        }

                        Slider(value: $filterState.radiusMiles, in: 1...50, step: 1)
                            .tint(Color.dinkrGreen)

                        HStack {
                            Text("1 mi")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("Any")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Reset + Apply
                    HStack(spacing: 12) {
                        Button("Reset") {
                            HapticManager.light()
                            filterState = PlayerFilterState()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrCoral)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.dinkrCoral.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))

                        Button("Apply Filters") {
                            HapticManager.medium()
                            dismiss()
                        }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("Filter Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Section Header (Filter Sheet)

private struct PlayerSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Color.dinkrNavy)
    }
}

// MARK: - Filter Chip

private struct PlayerFilterChip: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : Color.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                isSelected ? Color.dinkrNavy : Color.cardBackground,
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? Color.clear : Color.secondary.opacity(0.25),
                        lineWidth: 1
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PlayerFlowLayout (wrapping chips)

private struct PlayerFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
                totalHeight = y
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalHeight = y + rowHeight
        }
        return CGSize(width: width, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Legacy PlayerCardView (kept for backward compat in other tabs)

struct PlayerCardView: View {
    let player: User
    let currentUserId: String
    var onChallenge: (() -> Void)? = nil

    @State private var isFriend = false
    @State private var checked = false

    private var showPrivateGate: Bool {
        player.isPrivate && !isFriend && currentUserId != player.id
    }

    var body: some View {
        PickleballCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 14) {
                    ZStack(alignment: .bottomTrailing) {
                        AvatarView(urlString: player.avatarURL, displayName: player.displayName, size: 52)
                        if player.isPrivate {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(3)
                                .background(Color.dinkrNavy)
                                .clipShape(Circle())
                                .offset(x: 4, y: 4)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(player.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.primary)
                            SkillBadge(level: player.skillLevel, compact: true)
                        }

                        if let style = player.playStyle {
                            PlayStyleBadge(style: style)
                        }

                        if let dept = player.department {
                            HStack(spacing: 4) {
                                Image(systemName: "briefcase.fill")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(Color.dinkrSky)
                                Text(dept)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Color.dinkrSky)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.dinkrSky.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(Color.dinkrSky.opacity(0.3), lineWidth: 0.5))
                        }

                        if showPrivateGate {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("Private account · \(player.city)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text(player.city)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 12) {
                                Label("\(player.gamesPlayed) games", systemImage: "figure.pickleball")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Label(String(format: "%.0f%%", player.winRate * 100) + " wins", systemImage: "trophy")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Spacer()

                    if currentUserId != player.id {
                        FollowButton(
                            currentUserId: currentUserId,
                            targetUserId: player.id,
                            isPrivateAccount: player.isPrivate && !isFriend,
                            size: .compact
                        )
                    }
                }
                .padding(14)

                if let onChallenge {
                    Divider()
                        .padding(.horizontal, 14)

                    Button(action: {
                        HapticManager.light()
                        onChallenge()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Challenge")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(Color.dinkrGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .task {
            guard !checked else { return }
            checked = true
            if player.isPrivate && currentUserId != player.id {
                isFriend = await FollowService.shared.isMutualFollow(
                    currentUserId: currentUserId,
                    targetUserId: player.id
                )
            } else {
                isFriend = true
            }
        }
    }
}

// MARK: - Private Profile Screen

struct PrivateProfileScreen: View {
    let user: User
    let currentUserId: String
    var onFriendStatusChange: ((Bool) -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [Color.dinkrNavy, Color.dinkrNavy.opacity(0.7)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 200)

                VStack(spacing: 10) {
                    AvatarView(urlString: user.avatarURL, displayName: user.displayName, size: 72)
                        .overlay(Circle().stroke(Color.dinkrGreen, lineWidth: 2))
                        .padding(.top, 56)

                    Text(user.displayName)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    Text("@\(user.username)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))

                    Text("\(user.followersCount) followers")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.bottom, 16)
                }
            }

            VStack(spacing: 20) {
                Spacer().frame(height: 32)

                ZStack {
                    Circle()
                        .fill(Color.dinkrNavy.opacity(0.08))
                        .frame(width: 80, height: 80)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(Color.dinkrNavy.opacity(0.5))
                }

                VStack(spacing: 8) {
                    Text("This account is private")
                        .font(.title3.weight(.bold))
                    Text("Follow \(user.displayName.components(separatedBy: " ").first ?? user.displayName) to see their games, stats, and posts.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                FollowButton(
                    currentUserId: currentUserId,
                    targetUserId: user.id,
                    isPrivateAccount: true,
                    size: .regular
                )

                Text("Dinkr · Private Account")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Public Profile Body

struct PublicProfileBody: View {
    let user: User

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                statCol("\(user.gamesPlayed)", "Games")
                Divider().frame(height: 32)
                statCol("\(user.followersCount)", "Followers")
                Divider().frame(height: 32)
                statCol("\(user.followingCount)", "Following")
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            if !user.bio.isEmpty {
                Text(user.bio)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
            }
        }
    }

    @ViewBuilder
    private func statCol(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.weight(.bold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Play Style Badge

struct PlayStyleBadge: View {
    let style: PlayStyle

    private var badgeColor: Color {
        switch style.color {
        case "dinkrCoral":  return Color.dinkrCoral
        case "dinkrGreen":  return Color.dinkrGreen
        case "dinkrSky":    return Color.dinkrSky
        case "dinkrAmber":  return Color.dinkrAmber
        case "dinkrNavy":   return Color.dinkrNavy
        default:            return Color.dinkrGreen
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: style.icon)
                .font(.system(size: 10, weight: .semibold))
            Text(style.rawValue)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(badgeColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(badgeColor.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FindPlayersView(players: User.mockPlayers, currentUserId: "user_001")
    }
    .environment(AuthService())
}

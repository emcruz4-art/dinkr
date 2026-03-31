import SwiftUI

// MARK: - SearchView

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @State private var playViewModel = PlayViewModel()
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                SearchBarView(
                    query: $viewModel.query,
                    isFocused: $searchFocused,
                    onSubmit: {
                        viewModel.addRecentSearch(viewModel.query)
                    },
                    onCancel: {
                        viewModel.query = ""
                        searchFocused = false
                    }
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.appBackground)

                ZStack {
                    if viewModel.query.isEmpty {
                        discoveryContent
                            .transition(.opacity)
                    } else {
                        activeSearchContent
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.18), value: viewModel.query.isEmpty)
            }
            .background(Color.appBackground)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    searchFocused = true
                }
            }
        }
    }

    // MARK: - Discovery Content

    private var discoveryContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                recentSearchesSection
                trendingSection
                exploreCategoriesSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Recent Searches

    @ViewBuilder
    private var recentSearchesSection: some View {
        if !viewModel.recentSearches.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recent Searches")
                        .font(.headline)
                        .foregroundStyle(Color.dinkrNavy)

                    Spacer()

                    Button("Clear all") {
                        viewModel.clearAllRecentSearches()
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.dinkrGreen)
                }

                VStack(spacing: 0) {
                    ForEach(viewModel.recentSearches, id: \.self) { term in
                        RecentSearchRow(term: term) {
                            viewModel.selectRecentSearch(term)
                            searchFocused = true
                        } onDelete: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.removeRecentSearch(term)
                            }
                        }
                        if term != viewModel.recentSearches.last {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Trending Section

    private var trendingSection: some View {
        let trendingTerms = ["3.5 doubles", "open play", "Austin courts", "weekend tournament"]
        let trendingPlayers = ["Ben Johns", "Anna Leigh Waters", "Tyson McGuffin"]
        let trendingCourts = ["Mueller Tennis Center", "Roy G. Guerrero Park"]
        let trendingEvents = ["Austin Open 2026", "Spring Singles Slam"]

        return VStack(alignment: .leading, spacing: 16) {
            // Trending list rows
            VStack(alignment: .leading, spacing: 12) {
                Text("Trending Searches")
                    .font(.headline)
                    .foregroundStyle(Color.dinkrNavy)

                VStack(spacing: 0) {
                    ForEach(Array(trendingTerms.enumerated()), id: \.offset) { index, term in
                        TrendingRow(rank: index + 1, term: term, isHot: index < 2) {
                            viewModel.query = term
                            viewModel.addRecentSearch(term)
                            searchFocused = false
                        }
                        if index < trendingTerms.count - 1 {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Trending chips: Players
            TrendingChipsRow(label: "Players", icon: "person.fill", color: Color.dinkrGreen, chips: trendingPlayers) { chip in
                viewModel.query = chip
                viewModel.addRecentSearch(chip)
                searchFocused = false
            }

            // Trending chips: Courts
            TrendingChipsRow(label: "Courts", icon: "sportscourt.fill", color: Color.dinkrSky, chips: trendingCourts) { chip in
                viewModel.query = chip
                viewModel.addRecentSearch(chip)
                searchFocused = false
            }

            // Trending chips: Events
            TrendingChipsRow(label: "Events", icon: "trophy.fill", color: Color.dinkrCoral, chips: trendingEvents) { chip in
                viewModel.query = chip
                viewModel.addRecentSearch(chip)
                searchFocused = false
            }
        }
    }

    // MARK: - Explore Categories

    private var exploreCategoriesSection: some View {
        let categories: [(label: String, icon: String, gradientStart: Color, gradientEnd: Color)] = [
            ("Players",   "person.2.fill",             Color.dinkrGreen, Color.dinkrSky),
            ("Games",     "sportscourt.fill",           Color.dinkrCoral, Color.dinkrAmber),
            ("Courts",    "mappin.circle.fill",         Color.dinkrNavy,  Color.dinkrSky),
            ("Events",    "trophy.fill",                Color.dinkrAmber, Color.dinkrCoral),
            ("Groups",    "person.3.fill",              Color.dinkrGreen, Color.dinkrNavy),
            ("Market",    "tag.fill",                   Color.dinkrSky,   Color.dinkrGreen),
        ]
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

        return VStack(alignment: .leading, spacing: 12) {
            Text("Explore")
                .font(.headline)
                .foregroundStyle(Color.dinkrNavy)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(categories, id: \.label) { cat in
                    CategoryCard(
                        label: cat.label,
                        icon: cat.icon,
                        gradientStart: cat.gradientStart,
                        gradientEnd: cat.gradientEnd,
                        onTap: {
                            viewModel.query = cat.label
                            searchFocused = false
                        }
                    )
                }
            }
        }
    }

    // MARK: - Active Search Content

    private var activeSearchContent: some View {
        VStack(spacing: 0) {
            // Scope filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SearchScope.allCases, id: \.self) { scope in
                        SearchScopeChip(
                            label: scope.rawValue,
                            isSelected: viewModel.scope == scope,
                            count: viewModel.badgeCount(for: scope)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.scope = scope
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color.appBackground)

            Divider()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    switch viewModel.scope {
                    case .all:
                        allResultsContent
                    case .players:
                        fullPlayerResults
                    case .games:
                        fullGameResults
                    case .courts:
                        fullCourtResults
                    case .events:
                        fullEventResults
                    case .groups:
                        fullGroupResults
                    case .market:
                        fullMarketResults
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - All Results

    @ViewBuilder
    private var allResultsContent: some View {
        if !viewModel.hasAnyResults {
            emptyStateView
        } else {
            SwiftUI.Group {
                // Players
                if !viewModel.filteredPlayers.isEmpty {
                    SearchSectionHeader(
                        title: "Players",
                        count: viewModel.filteredPlayers.count,
                        showMore: viewModel.filteredPlayers.count > 3
                    ) { viewModel.scope = .players }
                    ForEach(viewModel.filteredPlayers.prefix(3)) { player in
                        NavigationLink {
                            UserProfileView(user: player, currentUserId: User.mockCurrentUser.id)
                        } label: {
                            PlayerSearchRow(user: player)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 68)
                    }
                }

                // Games
                if !viewModel.filteredSessions.isEmpty {
                    SearchSectionHeader(
                        title: "Games",
                        count: viewModel.filteredSessions.count,
                        showMore: viewModel.filteredSessions.count > 3
                    ) { viewModel.scope = .games }
                    ForEach(viewModel.filteredSessions.prefix(3)) { session in
                        NavigationLink {
                            GameSessionDetailView(session: session, viewModel: playViewModel)
                        } label: {
                            GameSearchRow(session: session)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 68)
                    }
                }

                // Courts
                if !viewModel.filteredCourts.isEmpty {
                    SearchSectionHeader(
                        title: "Courts",
                        count: viewModel.filteredCourts.count,
                        showMore: viewModel.filteredCourts.count > 3
                    ) { viewModel.scope = .courts }
                    ForEach(viewModel.filteredCourts.prefix(3)) { venue in
                        NavigationLink {
                            CourtDetailView(venue: venue)
                        } label: {
                            CourtSearchRow(venue: venue)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 68)
                    }
                }

                // Events
                if !viewModel.filteredEvents.isEmpty {
                    SearchSectionHeader(
                        title: "Events",
                        count: viewModel.filteredEvents.count,
                        showMore: viewModel.filteredEvents.count > 3
                    ) { viewModel.scope = .events }
                    ForEach(viewModel.filteredEvents.prefix(3)) { event in
                        NavigationLink {
                            EventDetailView(event: event)
                        } label: {
                            EventSearchRow(event: event)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 68)
                    }
                }

                // Groups
                if !viewModel.filteredGroups.isEmpty {
                    SearchSectionHeader(
                        title: "Groups",
                        count: viewModel.filteredGroups.count,
                        showMore: viewModel.filteredGroups.count > 3
                    ) { viewModel.scope = .groups }
                    ForEach(viewModel.filteredGroups.prefix(3)) { group in
                        NavigationLink {
                            GroupDetailView(group: group)
                        } label: {
                            GroupSearchRow(group: group)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 68)
                    }
                }

                // Market
                if !viewModel.filteredListings.isEmpty {
                    SearchSectionHeader(
                        title: "Market",
                        count: viewModel.filteredListings.count,
                        showMore: viewModel.filteredListings.count > 3
                    ) { viewModel.scope = .market }
                    ForEach(viewModel.filteredListings.prefix(3)) { listing in
                        NavigationLink {
                            ListingDetailView(listing: listing)
                        } label: {
                            MarketSearchRow(listing: listing)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 68)
                    }
                }
            }
        }
    }

    // MARK: - Full Category Lists

    @ViewBuilder
    private var fullPlayerResults: some View {
        if viewModel.filteredPlayers.isEmpty {
            emptyStateView
        } else {
            ForEach(viewModel.filteredPlayers) { player in
                NavigationLink {
                    UserProfileView(user: player, currentUserId: User.mockCurrentUser.id)
                } label: {
                    PlayerSearchRow(user: player)
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 68)
            }
        }
    }

    @ViewBuilder
    private var fullGameResults: some View {
        if viewModel.filteredSessions.isEmpty {
            emptyStateView
        } else {
            ForEach(viewModel.filteredSessions) { session in
                NavigationLink {
                    GameSessionDetailView(session: session, viewModel: playViewModel)
                } label: {
                    GameSearchRow(session: session)
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 68)
            }
        }
    }

    @ViewBuilder
    private var fullCourtResults: some View {
        if viewModel.filteredCourts.isEmpty {
            emptyStateView
        } else {
            ForEach(viewModel.filteredCourts) { venue in
                NavigationLink {
                    CourtDetailView(venue: venue)
                } label: {
                    CourtSearchRow(venue: venue)
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 68)
            }
        }
    }

    @ViewBuilder
    private var fullEventResults: some View {
        if viewModel.filteredEvents.isEmpty {
            emptyStateView
        } else {
            ForEach(viewModel.filteredEvents) { event in
                NavigationLink {
                    EventDetailView(event: event)
                } label: {
                    EventSearchRow(event: event)
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 68)
            }
        }
    }

    @ViewBuilder
    private var fullGroupResults: some View {
        if viewModel.filteredGroups.isEmpty {
            emptyStateView
        } else {
            ForEach(viewModel.filteredGroups) { group in
                NavigationLink {
                    GroupDetailView(group: group)
                } label: {
                    GroupSearchRow(group: group)
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 68)
            }
        }
    }

    @ViewBuilder
    private var fullMarketResults: some View {
        if viewModel.filteredListings.isEmpty {
            emptyStateView
        } else {
            ForEach(viewModel.filteredListings) { listing in
                NavigationLink {
                    ListingDetailView(listing: listing)
                } label: {
                    MarketSearchRow(listing: listing)
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 68)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 52, weight: .thin))
                .foregroundStyle(Color.dinkrNavy.opacity(0.25))

            Text("No results for \"\(viewModel.query)\"")
                .font(.headline)
                .foregroundStyle(Color.dinkrNavy.opacity(0.6))

            Text("Try a different search or browse a category below")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
        .padding(.horizontal, 32)
    }
}

// MARK: - SearchBarView

struct SearchBarView: View {
    @Binding var query: String
    @FocusState.Binding var isFocused: Bool
    var onSubmit: (() -> Void)? = nil
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.secondary)
                    .font(.system(size: 16, weight: .medium))

                TextField("Search players, games, courts…", text: $query)
                    .font(.body)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isFocused)
                    .submitLabel(.search)
                    .onSubmit { onSubmit?() }

                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.secondary)
                            .font(.system(size: 16))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .animation(.easeInOut(duration: 0.15), value: query.isEmpty)

            if isFocused || !query.isEmpty {
                Button("Cancel") { onCancel() }
                    .font(.body)
                    .foregroundStyle(Color.dinkrGreen)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - SearchScopeChip

private struct SearchScopeChip: View {
    let label: String
    let isSelected: Bool
    let count: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                if let count, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.dinkrGreen.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.dinkrGreen : Color.cardBackground)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SearchSectionHeader

struct SearchSectionHeader: View {
    let title: String
    let count: Int
    let showMore: Bool
    let onShowMore: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.dinkrNavy)
            Text("\(count)")
                .font(.caption)
                .foregroundStyle(Color.secondary)
            Spacer()
            if showMore {
                Button(action: onShowMore) {
                    Text("See all")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 4)
    }
}

// MARK: - RecentSearchRow

struct RecentSearchRow: View {
    let term: String
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 15))
                .foregroundStyle(Color.secondary)
                .frame(width: 32)

            Button(action: onTap) {
                Text(term)
                    .font(.body)
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .padding(6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - TrendingRow

struct TrendingRow: View {
    let rank: Int
    let term: String
    let isHot: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(rank == 1 ? Color.dinkrCoral : Color.secondary)
                    .frame(width: 28, alignment: .center)

                Text(term)
                    .font(.body)
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isHot {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.dinkrCoral)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - TrendingChipsRow

struct TrendingChipsRow: View {
    let label: String
    let icon: String
    let color: Color
    let chips: [String]
    let onTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.dinkrNavy)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(chips, id: \.self) { chip in
                        Button {
                            onTap(chip)
                            HapticManager.selection()
                        } label: {
                            Text(chip)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(color.opacity(0.10))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - CategoryCard

struct CategoryCard: View {
    let label: String
    let icon: String
    let gradientStart: Color
    let gradientEnd: Color
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
            HapticManager.selection()
        } label: {
            ZStack {
                LinearGradient(
                    colors: [gradientStart, gradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: gradientStart.opacity(0.3), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PlayerSearchRow

struct PlayerSearchRow: View {
    let user: User
    @State private var isFollowing: Bool = false

    private var skillColor: Color {
        switch user.skillLevel {
        case .beginner20, .beginner25:          return Color.dinkrGreen
        case .intermediate30, .intermediate35:  return Color.dinkrSky
        case .advanced40, .advanced45:          return Color.dinkrAmber
        case .pro50:                            return Color.dinkrCoral
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(urlString: user.avatarURL, displayName: user.displayName, size: 48)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(user.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.primary)

                    Text(user.skillLevel.label)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(skillColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(skillColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Text("@\(user.username) · \(user.city)")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }

            Spacer()

            // Follow button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isFollowing.toggle()
                }
                HapticManager.selection()
            } label: {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isFollowing ? Color.secondary : Color.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        isFollowing
                            ? Color.cardBackground
                            : Color.dinkrGreen
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(
                            isFollowing ? Color.secondary.opacity(0.4) : Color.clear,
                            lineWidth: 1
                        )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - GameSearchRow

struct GameSearchRow: View {
    let session: GameSession

    private var countdownText: String {
        let interval = session.dateTime.timeIntervalSinceNow
        if interval <= 0 { return "Live" }
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours >= 24 {
            let days = hours / 24
            return "in \(days)d"
        }
        if hours > 0 { return "in \(hours)h \(minutes)m" }
        return "in \(minutes)m"
    }

    private var countdownColor: Color {
        let interval = session.dateTime.timeIntervalSinceNow
        if interval <= 0 { return Color.dinkrCoral }
        if interval < 3600 { return Color.dinkrAmber }
        return Color.dinkrGreen
    }

    private var formatColor: Color {
        switch session.format {
        case .singles:      return Color.dinkrCoral
        case .doubles:      return Color.dinkrGreen
        case .mixed:        return Color.dinkrSky
        case .openPlay:     return Color.dinkrAmber
        case .round_robin:  return Color.dinkrNavy
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.dinkrGreen.opacity(0.12))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.dinkrGreen)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(session.courtName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)

                    Text(session.format.rawValue.capitalized)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(formatColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(formatColor.opacity(0.12))
                        .clipShape(Capsule())
                }

                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: session.dateTime.timeIntervalSinceNow <= 0
                              ? "dot.radiowaves.left.and.right" : "clock")
                            .font(.system(size: 11))
                            .foregroundStyle(countdownColor)
                        Text(countdownText)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(countdownColor)
                    }

                    Text("·")
                        .foregroundStyle(Color.secondary)
                        .font(.caption)

                    HStack(spacing: 3) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(session.isFull ? Color.dinkrCoral : Color.secondary)
                        Text(session.isFull
                             ? "Full"
                             : "\(session.spotsRemaining) spot\(session.spotsRemaining == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundStyle(session.isFull ? Color.dinkrCoral : Color.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(session.skillRange.lowerBound.label)–\(session.skillRange.upperBound.label)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.dinkrNavy)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.dinkrNavy.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                if let fee = session.fee, fee > 0 {
                    Text("$\(Int(fee))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.dinkrAmber)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - CourtSearchRow

struct CourtSearchRow: View {
    let venue: CourtVenue

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.dinkrSky.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.dinkrSky)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(venue.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.dinkrAmber)
                    Text(String(format: "%.1f", venue.rating))
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                    Text("·")
                        .foregroundStyle(Color.secondary)
                    Text("\(venue.courtCount) courts")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }

                Text(venue.address)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(venue.surface.rawValue.capitalized)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.dinkrSky)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.dinkrSky.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                if venue.isIndoor {
                    Text("Indoor")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.dinkrNavy)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.dinkrNavy.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                } else {
                    Text("Outdoor")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.dinkrGreen)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.dinkrGreen.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - EventSearchRow

struct EventSearchRow: View {
    let event: Event

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    private var typeColor: Color {
        switch event.type {
        case .tournament:  return Color.dinkrCoral
        case .clinic:      return Color.dinkrSky
        case .openPlay:    return Color.dinkrGreen
        case .social:      return Color.dinkrAmber
        case .womenOnly:   return Color.dinkrNavy
        case .fundraiser:  return Color.dinkrAmber
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.dinkrCoral.opacity(0.12))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.dinkrCoral)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                    Text(Self.dateFormatter.string(from: event.dateTime))
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }

                Text(event.location)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(event.type.rawValue.capitalized)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(typeColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(typeColor.opacity(0.12))
                    .clipShape(Capsule())

                if let fee = event.entryFee {
                    Text(fee == 0 ? "Free" : "$\(Int(fee))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(fee == 0 ? Color.dinkrGreen : Color.dinkrAmber)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - GroupSearchRow

struct GroupSearchRow: View {
    let group: DinkrGroup
    @State private var joinRequested: Bool = false

    private var typeColor: Color {
        switch group.type {
        case .competitive, .internalLeague: return Color.dinkrCoral
        case .recreational, .neighborhood:  return Color.dinkrGreen
        case .womenOnly:                    return Color.dinkrNavy
        case .publicClub, .privateClub:     return Color.dinkrSky
        case .ageGroup:                     return Color.dinkrAmber
        case .corporate:                    return Color.dinkrNavy
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.dinkrGreen.opacity(0.12))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: group.isPrivate ? "lock.fill" : "person.3.fill")
                        .font(.system(size: group.isPrivate ? 18 : 16))
                        .foregroundStyle(Color.dinkrGreen)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(group.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(group.type.rawValue)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(typeColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(typeColor.opacity(0.12))
                        .clipShape(Capsule())

                    HStack(spacing: 3) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                        Text("\(group.memberCount) members")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.secondary)
                    }
                }
            }

            Spacer()

            // Join / Request button
            if !group.isPrivate || !joinRequested {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        joinRequested.toggle()
                    }
                    HapticManager.selection()
                } label: {
                    Text(joinRequested
                         ? (group.isPrivate ? "Requested" : "Joined")
                         : (group.isPrivate ? "Request" : "Join"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(joinRequested ? Color.secondary : Color.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(joinRequested ? Color.cardBackground : Color.dinkrGreen)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(
                                joinRequested ? Color.secondary.opacity(0.4) : Color.clear,
                                lineWidth: 1
                            )
                        )
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.dinkrGreen)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - MarketSearchRow

struct MarketSearchRow: View {
    let listing: MarketListing

    private var conditionColor: Color {
        switch listing.condition {
        case .brandNew:  return Color.dinkrGreen
        case .likeNew:   return Color.dinkrSky
        case .good:      return Color.dinkrAmber
        case .fair:      return Color.dinkrCoral
        case .forParts:  return Color.secondary
        }
    }

    private var categoryIcon: String {
        switch listing.category {
        case .paddles:     return "tennis.racket"
        case .balls:       return "circle.fill"
        case .bags:        return "bag.fill"
        case .apparel:     return "tshirt.fill"
        case .shoes:       return "shoeprints.fill"
        case .accessories: return "wrench.fill"
        case .courts:      return "sportscourt.fill"
        case .other:       return "tag.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail placeholder (uses category icon until real photos are available)
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.dinkrAmber.opacity(0.10))
                    .frame(width: 52, height: 52)

                if let firstPhoto = listing.photos.first, !firstPhoto.isEmpty {
                    CachedAsyncImage(urlString: firstPhoto)
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: categoryIcon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.dinkrAmber)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.dinkrAmber.opacity(0.2), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("\(listing.brand) \(listing.model)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(listing.condition.rawValue)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(conditionColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(conditionColor.opacity(0.12))
                        .clipShape(Capsule())

                    Text(listing.location)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(Int(listing.price))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.dinkrNavy)

                if listing.isFeatured {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.dinkrAmber)
                        Text("Featured")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.dinkrAmber)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview {
    SearchView()
}

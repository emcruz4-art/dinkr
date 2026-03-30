import SwiftUI

// MARK: - ViewModel

@Observable
final class SearchViewModel {
    var query: String = ""
    var recentSearches: [String] = ["Ben Johns", "Austin Open", "Selkirk paddle", "4.0 doubles"]
    var isLoading: Bool = false

    var isSearching: Bool { !query.isEmpty }

    var playerResults: [User] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return SearchService.shared.cachedUsers.filter {
            $0.displayName.lowercased().contains(q) ||
            $0.username.lowercased().contains(q)
        }
    }

    var eventResults: [Event] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return SearchService.shared.cachedEvents.filter {
            $0.title.lowercased().contains(q) ||
            $0.location.lowercased().contains(q)
        }
    }

    var courtResults: [CourtVenue] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return SearchService.shared.cachedCourts.filter {
            $0.name.lowercased().contains(q) ||
            $0.address.lowercased().contains(q)
        }
    }

    var listingResults: [MarketListing] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return SearchService.shared.cachedListings.filter {
            $0.brand.lowercased().contains(q) ||
            $0.model.lowercased().contains(q)
        }
    }

    func removeRecentSearch(_ term: String) {
        recentSearches.removeAll { $0 == term }
    }

    func selectRecentSearch(_ term: String) {
        query = term
    }

    func loadAll() async {
        guard !SearchService.shared.isLoaded else { return }
        isLoading = true
        await SearchService.shared.loadAll()
        isLoading = false
    }
}

// MARK: - SearchFilterTab

enum SearchFilterTab: String, CaseIterable {
    case all = "All"
    case players = "Players"
    case events = "Events"
    case courts = "Courts"
    case market = "Market"
}

// MARK: - SearchView

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @State private var selectedTab: SearchFilterTab = .all
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                SearchBarView(
                    query: $viewModel.query,
                    isFocused: $searchFocused,
                    onCancel: {
                        viewModel.query = ""
                        searchFocused = false
                    }
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.appBackground)

                if viewModel.isSearching {
                    // Active search state
                    activeSearchContent
                } else {
                    // Default discovery state
                    discoveryContent
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .task { await viewModel.loadAll() }
        }
    }

    // MARK: - Discovery Content

    private var discoveryContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                if viewModel.isLoading || !SearchService.shared.isLoaded {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(Color.dinkrGreen)
                        Text("Loading…")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                    .redacted(reason: .placeholder)
                } else {
                    recentSearchesSection
                    trendingSection
                    exploreCategoriesSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    @ViewBuilder
    private var recentSearchesSection: some View {
        if !viewModel.recentSearches.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Searches")
                    .font(.headline)
                    .foregroundStyle(Color.dinkrNavy)

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

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trending Now")
                .font(.headline)
                .foregroundStyle(Color.dinkrNavy)

            let trendingTerms = [
                "Ben Johns",
                "Selkirk Power Air",
                "Austin Open 2025",
                "ATP shot tutorial",
                "4.0 doubles partner"
            ]

            VStack(spacing: 0) {
                ForEach(Array(trendingTerms.enumerated()), id: \.offset) { index, term in
                    TrendingRow(rank: index + 1, term: term, isHot: index < 3) {
                        viewModel.query = term
                        searchFocused = true
                    }

                    if index < trendingTerms.count - 1 {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var exploreCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Explore Categories")
                .font(.headline)
                .foregroundStyle(Color.dinkrNavy)

            let categories: [(label: String, icon: String, gradientStart: Color, gradientEnd: Color)] = [
                ("Players",    "person.2.fill",       Color.dinkrGreen,  Color.dinkrSky),
                ("Events",     "trophy.fill",         Color.dinkrCoral,  Color.dinkrAmber),
                ("Courts",     "sportscourt.fill",    Color.dinkrNavy,   Color.dinkrSky),
                ("Market",     "bag.fill",            Color.dinkrAmber,  Color.dinkrCoral),
                ("Groups",     "person.3.fill",       Color.dinkrGreen,  Color.dinkrNavy),
                ("Tips & Drills", "target",           Color.dinkrSky,    Color.dinkrGreen)
            ]

            let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(categories, id: \.label) { category in
                    CategoryCard(
                        label: category.label,
                        icon: category.icon,
                        gradientStart: category.gradientStart,
                        gradientEnd: category.gradientEnd,
                        onTap: {
                            viewModel.query = category.label
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
            // Segmented filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SearchFilterTab.allCases, id: \.self) { tab in
                        SearchFilterChip(
                            label: tab.rawValue,
                            isSelected: selectedTab == tab,
                            count: badgeCount(for: tab)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
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
                    switch selectedTab {
                    case .all:
                        allResultsContent
                    case .players:
                        fullPlayerResults
                    case .events:
                        fullEventResults
                    case .courts:
                        fullCourtResults
                    case .market:
                        fullMarketResults
                    }
                }
                .padding(.bottom, 32)
            }
        }
    }

    private func badgeCount(for tab: SearchFilterTab) -> Int? {
        switch tab {
        case .all: return nil
        case .players: return viewModel.playerResults.isEmpty ? nil : viewModel.playerResults.count
        case .events: return viewModel.eventResults.isEmpty ? nil : viewModel.eventResults.count
        case .courts: return viewModel.courtResults.isEmpty ? nil : viewModel.courtResults.count
        case .market: return viewModel.listingResults.isEmpty ? nil : viewModel.listingResults.count
        }
    }

    // MARK: - All Results

    @ViewBuilder
    private var allResultsContent: some View {
        let hasAny = !viewModel.playerResults.isEmpty ||
                     !viewModel.eventResults.isEmpty ||
                     !viewModel.courtResults.isEmpty ||
                     !viewModel.listingResults.isEmpty

        if !hasAny {
            emptyStateView
        } else {
            SwiftUI.Group {
                if !viewModel.playerResults.isEmpty {
                    SearchSectionHeader(
                        title: "Players",
                        count: viewModel.playerResults.count,
                        showMore: viewModel.playerResults.count > 3
                    ) { selectedTab = .players }

                    ForEach(viewModel.playerResults.prefix(3)) { player in
                        NavigationLink {
                            UserProfileView(user: player, currentUserId: User.mockCurrentUser.id)
                        } label: {
                            PlayerSearchRow(user: player)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 68)
                    }
                }

                if !viewModel.eventResults.isEmpty {
                    SearchSectionHeader(
                        title: "Events",
                        count: viewModel.eventResults.count,
                        showMore: viewModel.eventResults.count > 3
                    ) { selectedTab = .events }

                    ForEach(viewModel.eventResults.prefix(3)) { event in
                        NavigationLink {
                            EventDetailView(event: event)
                        } label: {
                            EventSearchRow(event: event)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 68)
                    }
                }

                if !viewModel.courtResults.isEmpty {
                    SearchSectionHeader(
                        title: "Courts",
                        count: viewModel.courtResults.count,
                        showMore: viewModel.courtResults.count > 3
                    ) { selectedTab = .courts }

                    ForEach(viewModel.courtResults.prefix(3)) { court in
                        NavigationLink {
                            CourtDetailView(venue: court)
                        } label: {
                            CourtSearchRow(venue: court)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 68)
                    }
                }

                if !viewModel.listingResults.isEmpty {
                    SearchSectionHeader(
                        title: "Market",
                        count: viewModel.listingResults.count,
                        showMore: viewModel.listingResults.count > 3
                    ) { selectedTab = .market }

                    ForEach(viewModel.listingResults.prefix(3)) { listing in
                        NavigationLink {
                            ListingDetailView(listing: listing)
                        } label: {
                            ListingSearchRow(listing: listing)
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
        if viewModel.playerResults.isEmpty {
            emptyStateView
        } else {
            ForEach(viewModel.playerResults) { player in
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
    private var fullEventResults: some View {
        if viewModel.eventResults.isEmpty {
            emptyStateView
        } else {
            ForEach(viewModel.eventResults) { event in
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
    private var fullCourtResults: some View {
        if viewModel.courtResults.isEmpty {
            emptyStateView
        } else {
            ForEach(viewModel.courtResults) { venue in
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
    private var fullMarketResults: some View {
        if viewModel.listingResults.isEmpty {
            emptyStateView
        } else {
            ForEach(viewModel.listingResults) { listing in
                NavigationLink {
                    ListingDetailView(listing: listing)
                } label: {
                    ListingSearchRow(listing: listing)
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 68)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44, weight: .thin))
                .foregroundStyle(Color.dinkrNavy.opacity(0.3))

            Text("No results for \"\(viewModel.query)\"")
                .font(.headline)
                .foregroundStyle(Color.dinkrNavy.opacity(0.6))

            Text("Try searching for players, events, courts, or gear")
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
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.secondary)
                    .font(.system(size: 16, weight: .medium))

                TextField("Search players, events, courts…", text: $query)
                    .font(.body)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isFocused)
                    .submitLabel(.search)

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
                Button("Cancel") {
                    onCancel()
                }
                .font(.body)
                .foregroundStyle(Color.dinkrGreen)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
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
                    Text("🔥")
                        .font(.system(size: 15))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
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

// MARK: - FilterChip

private struct SearchFilterChip: View {
    let label: String
    let isSelected: Bool
    let count: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))

                if let count = count, count > 0 {
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

// MARK: - PlayerSearchRow

struct PlayerSearchRow: View {
    let user: User
    @State private var isFollowing: Bool = false

    private var skillColor: Color {
        switch user.skillLevel {
        case .beginner20, .beginner25:
            return Color.dinkrGreen
        case .intermediate30, .intermediate35:
            return Color.dinkrSky
        case .advanced40, .advanced45:
            return Color.dinkrAmber
        case .pro50:
            return Color.dinkrCoral
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.dinkrGreen.opacity(0.7), Color.dinkrSky.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
                .overlay {
                    Text(String(user.displayName.prefix(1)).uppercased())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }

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

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isFollowing.toggle()
                }
            } label: {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isFollowing ? Color.dinkrGreen : Color.dinkrGreen)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.dinkrGreen, lineWidth: 1.5)
                            .background(
                                isFollowing
                                    ? Color.dinkrGreen.opacity(0.1)
                                    : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    )
            }
            .buttonStyle(.plain)
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

    var body: some View {
        HStack(spacing: 12) {
            // Icon circle
            Circle()
                .fill(Color.dinkrCoral.opacity(0.15))
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

            if let fee = event.entryFee {
                Text(fee == 0 ? "Free" : "$\(Int(fee))")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(fee == 0 ? Color.dinkrGreen : Color.dinkrAmber)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (fee == 0 ? Color.dinkrGreen : Color.dinkrAmber).opacity(0.12)
                    )
                    .clipShape(Capsule())
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
            // Icon circle
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

                if venue.hasLighting {
                    HStack(spacing: 3) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 10))
                        Text("Lights")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(Color.dinkrAmber)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - ListingSearchRow

struct ListingSearchRow: View {
    let listing: MarketListing

    private var categoryIcon: String {
        switch listing.category {
        case .paddles:    return "sportscourt.fill"
        case .balls:      return "circle.fill"
        case .bags:       return "bag.fill"
        case .apparel:    return "tshirt.fill"
        case .shoes:      return "shoe.fill"
        case .accessories: return "tag.fill"
        case .courts:     return "mappin.circle.fill"
        case .other:      return "square.grid.2x2.fill"
        }
    }

    private var conditionColor: Color {
        switch listing.condition {
        case .brandNew:  return Color.dinkrGreen
        case .likeNew:   return Color.dinkrSky
        case .good:      return Color.dinkrAmber
        case .fair:      return Color.dinkrCoral
        case .forParts:  return Color.secondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon circle
            Circle()
                .fill(Color.dinkrAmber.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: categoryIcon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.dinkrAmber)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text("\(listing.brand) \(listing.model)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(listing.condition.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(conditionColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(conditionColor.opacity(0.12))
                        .clipShape(Capsule())

                    Text(listing.location)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }

            Spacer()

            Text("$\(Int(listing.price))")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.dinkrNavy)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview {
    SearchView()
}

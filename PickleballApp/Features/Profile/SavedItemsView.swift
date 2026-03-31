import SwiftUI

// MARK: - SavedFilter

private enum SavedFilter: String, CaseIterable {
    case all      = "All"
    case games    = "Games"
    case events   = "Events"
    case listings = "Listings"

    var systemImage: String {
        switch self {
        case .all:      return "bookmark.fill"
        case .games:    return "sportscourt"
        case .events:   return "calendar"
        case .listings: return "tag.fill"
        }
    }
}

// MARK: - SavedItemsView

struct SavedItemsView: View {
    @State private var service = BookmarkService.shared
    @State private var selectedFilter: SavedFilter = .all

    // MARK: Filtered data

    private var savedGames: [GameSession] {
        GameSession.mockSessions.filter { service.isSaved(gameId: $0.id) }
    }

    private var savedEvents: [Event] {
        Event.mockEvents.filter { service.isSaved(eventId: $0.id) }
    }

    private var savedListings: [MarketListing] {
        MarketListing.mockListings.filter { service.isSaved(listingId: $0.id) }
    }

    private var totalCount: Int {
        savedGames.count + savedEvents.count + savedListings.count
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    filterBar
                    content
                }
            }
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SavedFilter.allCases, id: \.self) { filter in
                    filterPill(filter)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func filterPill(_ filter: SavedFilter) -> some View {
        let isSelected = selectedFilter == filter
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                selectedFilter = filter
            }
            HapticManager.selection()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: filter.systemImage)
                    .font(.system(size: 11, weight: .semibold))
                Text(filter.rawValue)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : .secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.dinkrGreen : Color.dinkrGreen.opacity(0.10))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch selectedFilter {
        case .all:      allTab
        case .games:    gamesTab
        case .events:   eventsTab
        case .listings: listingsTab
        }
    }

    // MARK: All Tab

    private var allTab: some View {
        ZStack {
            if totalCount == 0 {
                emptyState(message: "Nothing saved yet")
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        if !savedGames.isEmpty {
                            sectionHeader("Games", count: savedGames.count)
                            ForEach(savedGames) { session in
                                GameCardView(session: session)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        unsaveGameButton(session.id)
                                    }
                                    .padding(.horizontal, 16)
                            }
                        }

                        if !savedEvents.isEmpty {
                            sectionHeader("Events", count: savedEvents.count)
                            ForEach(savedEvents) { event in
                                EventCardView(event: event)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        unsaveEventButton(event.id)
                                    }
                                    .padding(.horizontal, 16)
                            }
                        }

                        if !savedListings.isEmpty {
                            sectionHeader("Listings", count: savedListings.count)
                            ForEach(savedListings) { listing in
                                ListingCardView(listing: listing)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        unsaveListingButton(listing.id)
                                    }
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }

    // MARK: Games Tab

    private var gamesTab: some View {
        ZStack {
            if savedGames.isEmpty {
                emptyState(message: "No saved games")
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(savedGames) { session in
                            GameCardView(session: session)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    unsaveGameButton(session.id)
                                }
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 14)
                }
            }
        }
    }

    // MARK: Events Tab

    private var eventsTab: some View {
        ZStack {
            if savedEvents.isEmpty {
                emptyState(message: "No saved events")
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(savedEvents) { event in
                            EventCardView(event: event)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    unsaveEventButton(event.id)
                                }
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 14)
                }
            }
        }
    }

    // MARK: Listings Tab

    private var listingsTab: some View {
        ZStack {
            if savedListings.isEmpty {
                emptyState(message: "No saved listings")
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(savedListings) { listing in
                            ListingCardView(listing: listing)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    unsaveListingButton(listing.id)
                                }
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 14)
                }
            }
        }
    }

    // MARK: Swipe Actions

    private func unsaveGameButton(_ id: String) -> some View {
        Button(role: .destructive) {
            withAnimation { service.toggle(gameId: id) }
            HapticManager.light()
        } label: {
            Label("Unsave", systemImage: "bookmark.slash.fill")
        }
        .tint(Color.dinkrCoral)
    }

    private func unsaveEventButton(_ id: String) -> some View {
        Button(role: .destructive) {
            withAnimation { service.toggle(eventId: id) }
            HapticManager.light()
        } label: {
            Label("Unsave", systemImage: "bookmark.slash.fill")
        }
        .tint(Color.dinkrCoral)
    }

    private func unsaveListingButton(_ id: String) -> some View {
        Button(role: .destructive) {
            withAnimation { service.toggle(listingId: id) }
            HapticManager.light()
        } label: {
            Label("Unsave", systemImage: "bookmark.slash.fill")
        }
        .tint(Color.dinkrCoral)
    }

    // MARK: Helpers

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("(\(count))")
                .font(.footnote)
                .foregroundStyle(Color.dinkrGreen)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private func emptyState(message: String) -> some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "bookmark.slash")
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(Color.dinkrGreen.opacity(0.45))
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SavedItemsView()
}

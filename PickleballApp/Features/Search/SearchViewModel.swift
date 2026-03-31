import Foundation
import Observation
import SwiftUI

// MARK: - SearchScope

enum SearchScope: String, CaseIterable {
    case all     = "All"
    case players = "Players"
    case games   = "Games"
    case courts  = "Courts"
    case events  = "Events"
    case groups  = "Groups"
    case market  = "Market"
}

// MARK: - SearchViewModel

@Observable
final class SearchViewModel {

    // MARK: - Input

    var query: String = "" {
        didSet { scheduleDebounce() }
    }
    var scope: SearchScope = .all

    // MARK: - Debounced query (drives filtering)

    private(set) var debouncedQuery: String = ""
    private var debounceTask: Task<Void, Never>?

    private func scheduleDebounce() {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            debouncedQuery = query
        }
    }

    // MARK: - Recent Searches

    var recentSearches: [String] = ["Ben Johns", "Austin Open", "3.5 doubles", "Mueller courts"]

    func addRecentSearch(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        recentSearches.removeAll { $0.lowercased() == trimmed.lowercased() }
        recentSearches.insert(trimmed, at: 0)
        if recentSearches.count > 5 {
            recentSearches = Array(recentSearches.prefix(5))
        }
    }

    func removeRecentSearch(_ term: String) {
        recentSearches.removeAll { $0 == term }
    }

    func clearAllRecentSearches() {
        withAnimation(.easeInOut(duration: 0.25)) {
            recentSearches.removeAll()
        }
    }

    func selectRecentSearch(_ term: String) {
        query = term
    }

    // MARK: - Computed: Filtered Results (driven by debouncedQuery)

    var filteredPlayers: [User] {
        guard !debouncedQuery.isEmpty else { return [] }
        let q = debouncedQuery.lowercased()
        return User.mockPlayers.filter {
            $0.displayName.lowercased().contains(q) ||
            $0.username.lowercased().contains(q) ||
            $0.city.lowercased().contains(q)
        }
    }

    var filteredSessions: [GameSession] {
        guard !debouncedQuery.isEmpty else { return [] }
        let q = debouncedQuery.lowercased()
        return GameSession.mockSessions.filter {
            $0.courtName.lowercased().contains(q) ||
            $0.hostName.lowercased().contains(q) ||
            $0.format.rawValue.lowercased().contains(q) ||
            $0.notes.lowercased().contains(q)
        }
    }

    var filteredCourts: [CourtVenue] {
        guard !debouncedQuery.isEmpty else { return [] }
        let q = debouncedQuery.lowercased()
        return CourtVenue.mockVenues.filter {
            $0.name.lowercased().contains(q) ||
            $0.address.lowercased().contains(q) ||
            $0.surface.rawValue.lowercased().contains(q)
        }
    }

    var filteredEvents: [Event] {
        guard !debouncedQuery.isEmpty else { return [] }
        let q = debouncedQuery.lowercased()
        return Event.mockEvents.filter {
            $0.title.lowercased().contains(q) ||
            $0.location.lowercased().contains(q) ||
            $0.type.rawValue.lowercased().contains(q) ||
            $0.organizer.lowercased().contains(q)
        }
    }

    var filteredGroups: [DinkrGroup] {
        guard !debouncedQuery.isEmpty else { return [] }
        let q = debouncedQuery.lowercased()
        return DinkrGroup.mockGroups.filter {
            $0.name.lowercased().contains(q) ||
            $0.type.rawValue.lowercased().contains(q) ||
            $0.description.lowercased().contains(q)
        }
    }

    var filteredListings: [MarketListing] {
        guard !debouncedQuery.isEmpty else { return [] }
        let q = debouncedQuery.lowercased()
        return MarketListing.mockListings.filter { listing in
            listing.status == .active && (
                listing.brand.lowercased().contains(q) ||
                listing.model.lowercased().contains(q) ||
                listing.category.rawValue.lowercased().contains(q) ||
                listing.sellerName.lowercased().contains(q) ||
                listing.description.lowercased().contains(q) ||
                listing.location.lowercased().contains(q)
            )
        }
    }

    // MARK: - Aggregate

    var hasAnyResults: Bool {
        !filteredPlayers.isEmpty ||
        !filteredSessions.isEmpty ||
        !filteredCourts.isEmpty ||
        !filteredEvents.isEmpty ||
        !filteredGroups.isEmpty ||
        !filteredListings.isEmpty
    }

    // MARK: - Badge Counts

    func badgeCount(for scope: SearchScope) -> Int? {
        switch scope {
        case .all:     return nil
        case .players: return filteredPlayers.isEmpty   ? nil : filteredPlayers.count
        case .games:   return filteredSessions.isEmpty  ? nil : filteredSessions.count
        case .courts:  return filteredCourts.isEmpty    ? nil : filteredCourts.count
        case .events:  return filteredEvents.isEmpty    ? nil : filteredEvents.count
        case .groups:  return filteredGroups.isEmpty    ? nil : filteredGroups.count
        case .market:  return filteredListings.isEmpty  ? nil : filteredListings.count
        }
    }
}

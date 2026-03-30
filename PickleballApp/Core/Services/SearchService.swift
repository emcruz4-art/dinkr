import Foundation
import FirebaseFirestore
import Observation

@Observable
final class SearchService {
    static let shared = SearchService()
    private let db = Firestore.firestore()
    private init() {}

    // Cached data for filtering
    var cachedUsers: [User] = []
    var cachedEvents: [Event] = []
    var cachedCourts: [CourtVenue] = []
    var cachedListings: [MarketListing] = []
    var isLoaded: Bool = false

    func loadAll() async {
        async let users: [User] = (try? FirestoreService.shared.queryCollectionOrdered(
            collection: FirestoreCollections.users,
            orderBy: "displayName",
            descending: false,
            limit: 100
        )) ?? User.mockPlayers

        async let events: [Event] = (try? FirestoreService.shared.queryCollectionOrdered(
            collection: FirestoreCollections.events,
            orderBy: "dateTime",
            descending: false,
            limit: 50
        )) ?? Event.mockEvents

        async let courts: [CourtVenue] = (try? FirestoreService.shared.queryCollectionOrdered(
            collection: FirestoreCollections.courtVenues,
            orderBy: "name",
            descending: false,
            limit: 50
        )) ?? CourtVenue.mockVenues

        async let listings: [MarketListing] = (try? FirestoreService.shared.queryCollectionOrdered(
            collection: FirestoreCollections.marketListings,
            orderBy: "createdAt",
            descending: true,
            limit: 100
        )) ?? MarketListing.mockListings

        let (u, e, c, l) = await (users, events, courts, listings)
        cachedUsers = u
        cachedEvents = e
        cachedCourts = c
        cachedListings = l
        isLoaded = true
    }
}

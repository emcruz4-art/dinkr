import Foundation
import Observation
import FirebaseFirestore

@Observable
final class EventsViewModel {
    var events: [Event] = []
    var filteredEvents: [Event] = []
    var isLoading = false
    var selectedFilter: EventType? = nil
    var showWomenOnly = false

    private let firestoreService = FirestoreService.shared

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            events = try await firestoreService.queryCollectionWhere(
                collection: FirestoreCollections.events,
                whereField: "dateTime",
                isGreaterThanOrEqualTo: Timestamp(date: Date()),
                orderBy: "dateTime",
                descending: false
            )
            applyFilter()
        } catch {
            print("[EventsViewModel] load error: \(error)")
        }
    }

    func applyFilter() {
        var result = events
        if showWomenOnly { result = result.filter { $0.isWomenOnly } }
        if let filter = selectedFilter { result = result.filter { $0.type == filter } }
        filteredEvents = result
    }
}

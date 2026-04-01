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
    var currentUserId: String? = nil

    private let firestoreService = FirestoreService.shared

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            var loaded: [Event] = try await firestoreService.queryCollectionWhere(
                collection: FirestoreCollections.events,
                whereField: "dateTime",
                isGreaterThanOrEqualTo: Timestamp(date: Date()),
                orderBy: "dateTime",
                descending: false
            )
            // Compute client-side isRegistered from registeredUserIds
            if let uid = currentUserId {
                for i in loaded.indices {
                    loaded[i].isRegistered = loaded[i].registeredUserIds.contains(uid)
                }
            }
            events = loaded
            applyFilter()
        } catch {
            print("[EventsViewModel] load error: \(error)")
        }
    }

    func register(event: Event) async {
        guard let uid = currentUserId,
              let index = events.firstIndex(where: { $0.id == event.id }) else { return }

        let isJoining = !events[index].registeredUserIds.contains(uid)
        if isJoining {
            events[index].registeredUserIds.append(uid)
            events[index].currentParticipants += 1
        } else {
            events[index].registeredUserIds.removeAll { $0 == uid }
            events[index].currentParticipants = max(0, events[index].currentParticipants - 1)
        }
        events[index].isRegistered = isJoining
        applyFilter()

        let fieldValue: Any = isJoining
            ? FieldValue.arrayUnion([uid])
            : FieldValue.arrayRemove([uid])
        let countDelta = isJoining ? Int64(1) : Int64(-1)

        try? await firestoreService.updateDocument(
            collection: FirestoreCollections.events,
            documentId: event.id,
            data: [
                "registeredUserIds": fieldValue,
                "currentParticipants": FieldValue.increment(countDelta)
            ]
        )
    }

    func applyFilter() {
        var result = events
        if showWomenOnly { result = result.filter { $0.isWomenOnly } }
        if let filter = selectedFilter { result = result.filter { $0.type == filter } }
        filteredEvents = result
    }
}

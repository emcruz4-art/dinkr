import Foundation
import Observation

@Observable
final class MarketViewModel {
    var listings: [MarketListing] = []
    var filteredListings: [MarketListing] = []
    var selectedCategory: MarketCategory? = nil
    var searchText = ""
    var isLoading = false
    var showCreateListing = false

    private let firestoreService = FirestoreService.shared

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            listings = try await firestoreService.queryCollectionOrdered(
                collection: FirestoreCollections.marketListings,
                orderBy: "createdAt",
                descending: true
            )
            applyFilter()
        } catch {
            print("[MarketViewModel] load error: \(error)")
        }
    }

    func applyFilter() {
        var result = listings
        if let cat = selectedCategory { result = result.filter { $0.category == cat } }
        if !searchText.isEmpty {
            result = result.filter {
                $0.brand.localizedCaseInsensitiveContains(searchText) ||
                $0.model.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        filteredListings = result
    }
}

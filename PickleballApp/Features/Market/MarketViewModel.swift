import Foundation
import Observation
import FirebaseFirestore

@Observable
final class MarketViewModel {
    var listings: [MarketListing] = []
    var filteredListings: [MarketListing] = []
    var selectedCategory: MarketCategory? = nil
    var searchText = ""
    var isLoading = false
    var showCreateListing = false

    // MARK: - Pagination state

    var lastListingDocument: DocumentSnapshot? = nil
    var hasMoreListings: Bool = true
    var isLoadingMore: Bool = false

    private let firestoreService = FirestoreService.shared

    // MARK: - Load (first page)

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result: (items: [MarketListing], lastDocument: DocumentSnapshot?) = try await firestoreService.getFirstPage(
                collection: FirestoreCollections.marketListings,
                orderBy: "createdAt",
                descending: true,
                pageSize: 20
            )
            await MainActor.run {
                listings = result.items
                lastListingDocument = result.lastDocument
                hasMoreListings = result.items.count >= 20
            }
            applyFilter()
        } catch {
            print("[MarketViewModel] load error: \(error)")
        }
    }

    // MARK: - Load more (subsequent pages)

    func loadMore() async {
        guard hasMoreListings, !isLoadingMore else { return }
        await MainActor.run { isLoadingMore = true }
        defer { Task { @MainActor in isLoadingMore = false } }

        do {
            let result: (items: [MarketListing], lastDocument: DocumentSnapshot?) = try await firestoreService.getPage(
                collection: FirestoreCollections.marketListings,
                orderBy: "createdAt",
                descending: true,
                pageSize: 20,
                after: lastListingDocument
            )
            await MainActor.run {
                listings.append(contentsOf: result.items)
                lastListingDocument = result.lastDocument
                hasMoreListings = result.items.count >= 20
            }
            applyFilter()
        } catch {
            print("[MarketViewModel] loadMore error: \(error)")
        }
    }

    // MARK: - Filtering

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

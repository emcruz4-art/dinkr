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

    // MARK: - Filter state

    var showSoldItems = false
    var showFilterSheet = false
    var minPrice: Double? = nil
    var maxPrice: Double? = nil

    /// nil = show all conditions
    var selectedCondition: ListingCondition? = nil

    /// true = show only free listings (price == 0)
    var showFreeOnly: Bool = false

    // MARK: - Pagination state

    var lastListingDocument: DocumentSnapshot? = nil
    var hasMoreListings: Bool = true
    var isLoadingMore: Bool = false

    private let firestoreService = FirestoreService.shared

    // MARK: - Derived

    var recentlySoldListings: [MarketListing] {
        listings
            .filter { $0.status == .sold }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(3)
            .map { $0 }
    }

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

        // Sold filter vs active filter
        if showSoldItems {
            result = result.filter { $0.status == .sold }
        } else {
            result = result.filter { $0.status == .active || $0.status == .reserved }
        }

        if let cat = selectedCategory { result = result.filter { $0.category == cat } }

        if !searchText.isEmpty {
            result = result.filter {
                $0.brand.localizedCaseInsensitiveContains(searchText) ||
                $0.model.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Price range filter
        if let min = minPrice {
            result = result.filter { $0.price >= min }
        }
        if let max = maxPrice {
            result = result.filter { $0.price <= max }
        }

        // Condition filter
        if let cond = selectedCondition {
            result = result.filter { $0.condition == cond }
        }

        // Free-only filter
        if showFreeOnly {
            result = result.filter { $0.price == 0 }
        }

        filteredListings = result
    }
}

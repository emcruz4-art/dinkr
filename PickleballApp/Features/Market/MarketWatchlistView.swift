import SwiftUI

// MARK: - Watchlist Filter

enum WatchlistFilter: String, CaseIterable {
    case all        = "All"
    case priceDrop  = "Price Drop"
    case endingSoon = "Ending Soon"
    case sold       = "Sold"
}

// MARK: - Watchlist Item (wraps a listing with extra metadata)

struct WatchlistItem: Identifiable {
    let id: String
    let listing: MarketListing
    let originalPrice: Double?   // nil = no drop
    let isSold: Bool
    let endingSoon: Bool         // true if fake expiry is within 24 h

    var hasPriceDrop: Bool { originalPrice != nil }

    var dropPercent: Int? {
        guard let orig = originalPrice, orig > 0 else { return nil }
        return Int(((orig - listing.price) / orig) * 100)
    }
}

// MARK: - MarketWatchlistView

struct MarketWatchlistView: View {
    @State private var activeFilter: WatchlistFilter = .all
    @State private var items: [WatchlistItem] = Self.mockItems

    private static var mockItems: [WatchlistItem] = {
        let listings = MarketListing.mockListings
        return [
            WatchlistItem(id: "w_001", listing: listings[0], originalPrice: 230.00, isSold: false, endingSoon: false),
            WatchlistItem(id: "w_002", listing: listings[1], originalPrice: nil,    isSold: false, endingSoon: true),
            WatchlistItem(id: "w_003", listing: listings[2], originalPrice: nil,    isSold: true,  endingSoon: false),
            WatchlistItem(id: "w_004", listing: listings[5], originalPrice: 120.00, isSold: false, endingSoon: false),
            WatchlistItem(id: "w_005", listing: listings[8], originalPrice: nil,    isSold: false, endingSoon: true),
        ]
    }()

    var filteredItems: [WatchlistItem] {
        switch activeFilter {
        case .all:        return items
        case .priceDrop:  return items.filter { $0.hasPriceDrop }
        case .endingSoon: return items.filter { $0.endingSoon && !$0.isSold }
        case .sold:       return items.filter { $0.isSold }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                    .padding(.top, 4)
                    .padding(.bottom, 8)

                if filteredItems.isEmpty {
                    emptyState
                } else {
                    listContent
                }
            }
            .navigationTitle("Watchlist")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(WatchlistFilter.allCases, id: \.self) { filter in
                    filterChip(filter)
                }
            }
            .padding(.horizontal)
        }
    }

    private func filterChip(_ filter: WatchlistFilter) -> some View {
        let isActive = activeFilter == filter
        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                activeFilter = filter
            }
        } label: {
            Text(filter.rawValue)
                .font(.subheadline.weight(isActive ? .bold : .regular))
                .foregroundStyle(isActive ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isActive ? Color.dinkrGreen : Color.cardBackground)
                .clipShape(Capsule())
                .shadow(color: isActive ? Color.dinkrGreen.opacity(0.35) : .black.opacity(0.05),
                        radius: isActive ? 6 : 3, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - List Content

    private var listContent: some View {
        List {
            ForEach(filteredItems) { item in
                NavigationLink {
                    ListingDetailView(listing: item.listing)
                } label: {
                    watchlistRow(item)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        removeItem(item)
                    } label: {
                        Label("Remove", systemImage: "bookmark.slash")
                    }
                    .tint(Color.dinkrCoral)
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            // Pull-to-refresh: re-apply mock data (real app would re-fetch)
            try? await Task.sleep(nanoseconds: 800_000_000)
        }
    }

    // MARK: - Watchlist Row Card

    private func watchlistRow(_ item: WatchlistItem) -> some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 12) {
                // Image placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.cardBackground)
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 1)
                    Image(systemName: categoryIcon(for: item.listing.category))
                        .font(.system(size: 30))
                        .foregroundStyle(Color.dinkrCoral.opacity(0.35))

                    // Sold overlay
                    if item.isSold {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.55))
                        Text("SOLD")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("\(item.listing.brand) \(item.listing.model)")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                        .foregroundStyle(item.isSold ? .secondary : .primary)

                    HStack(spacing: 6) {
                        Text("$\(Int(item.listing.price))")
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(item.isSold ? .secondary : Color.dinkrCoral)

                        if let orig = item.originalPrice {
                            Text("$\(Int(orig))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .strikethrough()
                        }
                    }

                    HStack(spacing: 6) {
                        // Price-drop badge
                        if let pct = item.dropPercent {
                            Label("Price dropped \(pct)% ↓", systemImage: "arrow.down")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.dinkrGreen)
                                .clipShape(Capsule())
                        }

                        // Ending soon badge
                        if item.endingSoon && !item.isSold {
                            Label("Ending Soon", systemImage: "clock.fill")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.dinkrAmber)
                                .clipShape(Capsule())
                        }
                    }

                    Text(item.listing.condition.rawValue + " · " + item.listing.location)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.07), radius: 7, x: 0, y: 2)
            .opacity(item.isSold ? 0.7 : 1.0)

            // Bookmark icon
            Image(systemName: "bookmark.fill")
                .font(.caption)
                .foregroundStyle(Color.dinkrGreen)
                .padding(8)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "bookmark.slash")
                .font(.system(size: 52))
                .foregroundStyle(Color.dinkrNavy.opacity(0.25))

            Text("No items saved yet.")
                .font(.headline.weight(.bold))

            Text("Browse and bookmark items you love!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func removeItem(_ item: WatchlistItem) {
        withAnimation {
            items.removeAll { $0.id == item.id }
        }
    }

    private func categoryIcon(for category: MarketCategory) -> String {
        switch category {
        case .paddles:     return "figure.pickleball"
        case .balls:       return "circle.fill"
        case .bags:        return "bag.fill"
        case .apparel:     return "tshirt.fill"
        case .shoes:       return "shoeprints.fill"
        case .accessories: return "sparkles"
        case .courts:      return "sportscourt"
        case .other:       return "ellipsis.circle"
        }
    }
}

#Preview {
    MarketWatchlistView()
}

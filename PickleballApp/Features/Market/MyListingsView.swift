import SwiftUI

// MARK: - Mock data helpers (seller-specific)

private extension MarketListing {
    static let mockMyListings: [MarketListing] = [
        MarketListing(
            id: "my_001", sellerId: "user_me", sellerName: "Evan Cruz",
            category: .paddles, brand: "Selkirk", model: "Vanguard Power Air",
            condition: .likeNew, price: 185.00,
            description: "Used for 3 months. Small scuff on edge guard but plays perfectly.",
            photos: [], status: .active, location: "Austin, TX",
            createdAt: Date().addingTimeInterval(-86400), isFeatured: false, viewCount: 47
        ),
        MarketListing(
            id: "my_002", sellerId: "user_me", sellerName: "Evan Cruz",
            category: .bags, brand: "HEAD", model: "Tour Team Backpack",
            condition: .brandNew, price: 65.00,
            description: "Never used, gift received that doesn't fit my style.",
            photos: [], status: .active, location: "Austin, TX",
            createdAt: Date().addingTimeInterval(-172800), isFeatured: false, viewCount: 22
        ),
        MarketListing(
            id: "my_003", sellerId: "user_me", sellerName: "Evan Cruz",
            category: .shoes, brand: "K-Swiss", model: "Hypercourt Express 2",
            condition: .good, price: 55.00,
            description: "Size 10.5. One season of use.",
            photos: [], status: .sold, location: "Austin, TX",
            createdAt: Date().addingTimeInterval(-604800), isFeatured: false, viewCount: 61
        ),
        MarketListing(
            id: "my_004", sellerId: "user_me", sellerName: "Evan Cruz",
            category: .accessories, brand: "Gamma", model: "Overgrip 30-Pack",
            condition: .brandNew, price: 18.00,
            description: "Unopened.",
            photos: [], status: .sold, location: "Austin, TX",
            createdAt: Date().addingTimeInterval(-1209600), isFeatured: false, viewCount: 33
        ),
        MarketListing(
            id: "my_005", sellerId: "user_me", sellerName: "Evan Cruz",
            category: .balls, brand: "ONIX", model: "Pure 2 Outdoor 6-Pack",
            condition: .brandNew, price: 22.00,
            description: "Never opened.",
            photos: [], status: .expired, location: "Austin, TX",
            createdAt: Date().addingTimeInterval(-2592000), isFeatured: false, viewCount: 9
        ),
    ]
}

// MARK: - Offer mock data

private extension MarketOffer {
    static func mockOffers(for listingId: String) -> [MarketOffer] {
        [
            MarketOffer(
                id: "of_\(listingId)_1", listingId: listingId,
                listingTitle: "Your Listing", buyerId: "buyer_001",
                buyerName: "Jordan Smith", sellerId: "user_me",
                sellerName: "Evan Cruz", amount: 160.00,
                message: "Would you take $160? I can pick up today.",
                status: .pending, createdAt: Date().addingTimeInterval(-3600),
                respondedAt: nil
            ),
            MarketOffer(
                id: "of_\(listingId)_2", listingId: listingId,
                listingTitle: "Your Listing", buyerId: "buyer_002",
                buyerName: "Maria Chen", sellerId: "user_me",
                sellerName: "Evan Cruz", amount: 150.00,
                message: "Best I can do is $150, let me know!",
                status: .pending, createdAt: Date().addingTimeInterval(-7200),
                respondedAt: nil
            ),
            MarketOffer(
                id: "of_\(listingId)_3", listingId: listingId,
                listingTitle: "Your Listing", buyerId: "buyer_003",
                buyerName: "Taylor Kim", sellerId: "user_me",
                sellerName: "Evan Cruz", amount: 140.00,
                message: "Offering $140 firm.",
                status: .declined, createdAt: Date().addingTimeInterval(-86400),
                respondedAt: Date().addingTimeInterval(-82000)
            ),
        ]
    }
}

// MARK: - Status filter

private enum SellerStatusFilter: String, CaseIterable {
    case active = "Active"
    case sold = "Sold"
    case expired = "Expired"
    case all = "All"

    var listingStatus: ListingStatus? {
        switch self {
        case .active:  return .active
        case .sold:    return .sold
        case .expired: return .expired
        case .all:     return nil
        }
    }
}

// MARK: - MyListingsView

struct MyListingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var listings: [MarketListing] = MarketListing.mockMyListings
    @State private var filter: SellerStatusFilter = .all
    @State private var selectedListing: MarketListing? = nil
    @State private var showCreateListing = false

    private var activeCount: Int   { listings.filter { $0.status == .active }.count }
    private var soldCount: Int     { listings.filter { $0.status == .sold }.count }
    private var totalEarned: Double {
        listings.filter { $0.status == .sold }.reduce(0) { $0 + $1.price }
    }

    private var filtered: [MarketListing] {
        guard let status = filter.listingStatus else { return listings }
        return listings.filter { $0.status == status }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if listings.isEmpty {
                    // ── Empty state ────────────────────────────────────────
                    EmptyStateView(
                        icon: "storefront",
                        title: "You haven't listed anything yet",
                        message: "Sell gear you no longer need and earn money with the Dinkr community.",
                        actionLabel: "Sell an Item",
                        action: { showCreateListing = true }
                    )
                    .padding(.horizontal, 32)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {

                            // ── Header stats row ──────────────────────────
                            HStack(spacing: 10) {
                                SellerStatChip(
                                    label: "\(activeCount) Active",
                                    color: Color.dinkrGreen
                                )
                                SellerStatChip(
                                    label: "\(soldCount) Sold",
                                    color: Color.secondary
                                )
                                SellerStatChip(
                                    label: "$\(Int(totalEarned)) Earned",
                                    color: Color.dinkrNavy
                                )
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 12)
                            .padding(.bottom, 16)

                            // ── Status filter chips ───────────────────────
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(SellerStatusFilter.allCases, id: \.self) { f in
                                        let isSelected = filter == f
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                filter = f
                                            }
                                        } label: {
                                            Text(f.rawValue)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(isSelected ? .white : .primary)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(
                                                    isSelected
                                                    ? Color.dinkrGreen
                                                    : Color.secondary.opacity(0.12)
                                                )
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 16)
                            }

                            // ── Listing rows ──────────────────────────────
                            if filtered.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 40, weight: .light))
                                        .foregroundStyle(Color.secondary.opacity(0.4))
                                    Text("No \(filter.rawValue.lowercased()) listings")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                            } else {
                                LazyVStack(spacing: 0) {
                                    ForEach(filtered) { listing in
                                        Button {
                                            selectedListing = listing
                                        } label: {
                                            SellerListingRow(listing: listing) { updated in
                                                applyUpdate(updated)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            // Mark Sold
                                            if listing.status == .active {
                                                Button {
                                                    markSold(listing)
                                                } label: {
                                                    Label("Mark Sold", systemImage: "checkmark.seal.fill")
                                                }
                                                .tint(Color.dinkrGreen)
                                            }
                                            // Edit
                                            Button {
                                                // navigate to edit (stub)
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            .tint(Color.dinkrNavy)
                                        }

                                        Divider()
                                            .padding(.leading, 80)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("My Listings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.dinkrGreen)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateListing = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("List")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .tint(Color.dinkrCoral)
                }
            }
            .sheet(item: $selectedListing) { listing in
                MyListingDetailView(listing: listing) { updated in
                    applyUpdate(updated)
                }
            }
            .sheet(isPresented: $showCreateListing) {
                CreateListingView()
            }
        }
    }

    private func markSold(_ listing: MarketListing) {
        var updated = listing
        updated.status = .sold
        applyUpdate(updated)
    }

    private func applyUpdate(_ updated: MarketListing) {
        if let idx = listings.firstIndex(where: { $0.id == updated.id }) {
            withAnimation { listings[idx] = updated }
        }
    }
}

// MARK: - Seller stat chip

private struct SellerStatChip: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.caption.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - Seller listing row

private struct SellerListingRow: View {
    let listing: MarketListing
    let onUpdate: (MarketListing) -> Void

    private var pendingOffers: [MarketOffer] {
        MarketOffer.mockOffers(for: listing.id).filter { $0.status == .pending }
    }

    private var totalOffers: [MarketOffer] {
        MarketOffer.mockOffers(for: listing.id)
    }

    var body: some View {
        HStack(spacing: 12) {

            // ── Photo placeholder ──────────────────────────────────────
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(categoryTint.opacity(0.15))
                    .frame(width: 60, height: 60)
                Image(systemName: categoryIcon)
                    .font(.system(size: 24))
                    .foregroundStyle(categoryTint.opacity(0.6))
            }

            // ── Title + price + stats ──────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                Text("\(listing.brand) \(listing.model)")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("$\(Int(listing.price))")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Color.dinkrGreen)

                HStack(spacing: 10) {
                    // View count
                    HStack(spacing: 3) {
                        Text("👁")
                            .font(.caption2)
                        Text("\(listing.viewCount) views")
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                    }
                    // Offer count
                    HStack(spacing: 3) {
                        Text("\(totalOffers.count) offers")
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                        if !pendingOffers.isEmpty {
                            Text("\(pendingOffers.count)")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(minWidth: 16, minHeight: 16)
                                .background(Color.dinkrCoral)
                                .clipShape(Circle())
                        }
                    }
                }
            }

            Spacer()

            // ── Status badge ───────────────────────────────────────────
            VStack(alignment: .trailing, spacing: 4) {
                Text(statusLabel)
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.13))
                    .clipShape(Capsule())

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.secondary.opacity(0.4))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private var statusLabel: String {
        switch listing.status {
        case .active:   return "Active"
        case .sold:     return "Sold"
        case .reserved: return "Pending"
        case .expired:  return "Expired"
        }
    }

    private var statusColor: Color {
        switch listing.status {
        case .active:   return Color.dinkrGreen
        case .sold:     return Color.secondary
        case .reserved: return Color.dinkrAmber
        case .expired:  return Color.dinkrCoral
        }
    }

    private var categoryTint: Color {
        switch listing.category {
        case .paddles:     return Color.dinkrCoral
        case .balls:       return Color.dinkrAmber
        case .bags:        return Color.dinkrSky
        case .apparel:     return .purple
        case .shoes:       return .teal
        case .accessories: return .pink
        case .courts:      return Color.dinkrGreen
        case .other:       return Color.dinkrNavy
        }
    }

    private var categoryIcon: String {
        switch listing.category {
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

// MARK: - MyListingDetailView

struct MyListingDetailView: View {
    let listing: MarketListing
    let onUpdate: (MarketListing) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var offers: [MarketOffer] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // ── Listing mini-card ──────────────────────────────
                    ListingMiniCard(listing: listing)
                        .padding(.horizontal)
                        .padding(.top, 4)

                    // ── Offers section ─────────────────────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Offers")
                                .font(.headline.weight(.bold))
                            if offers.isEmpty == false {
                                Text("\(offers.count)")
                                    .font(.caption.weight(.heavy))
                                    .foregroundStyle(.white)
                                    .frame(minWidth: 20, minHeight: 20)
                                    .background(Color.dinkrGreen)
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        .padding(.horizontal)

                        if offers.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "envelope.open")
                                        .font(.system(size: 32, weight: .light))
                                        .foregroundStyle(Color.secondary.opacity(0.35))
                                    Text("No offers yet")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.secondary)
                                }
                                .padding(.vertical, 24)
                                Spacer()
                            }
                        } else {
                            VStack(spacing: 0) {
                                ForEach(offers) { offer in
                                    OfferManagementRow(offer: offer) { action in
                                        handleOffer(offer, action: action)
                                    }
                                    if offer.id != offers.last?.id {
                                        Divider().padding(.leading, 56)
                                    }
                                }
                            }
                            .background(Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                    }

                    // ── Views over time chart ──────────────────────────
                    ViewsBarChart(viewCount: listing.viewCount)
                        .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("\(listing.brand) \(listing.model)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
            .onAppear {
                offers = MarketOffer.mockOffers(for: listing.id)
            }
        }
    }

    private func handleOffer(_ offer: MarketOffer, action: OfferAction) {
        if let idx = offers.firstIndex(where: { $0.id == offer.id }) {
            var updated = offers[idx]
            switch action {
            case .accept:
                updated.status = .accepted
                // Also mark listing as reserved/sold
                var updatedListing = listing
                updatedListing.status = .reserved
                onUpdate(updatedListing)
            case .decline:
                updated.status = .declined
            }
            withAnimation { offers[idx] = updated }
        }
    }
}

private enum OfferAction { case accept, decline }

// MARK: - Listing mini-card (seller sheet header)

private struct ListingMiniCard: View {
    let listing: MarketListing

    var body: some View {
        HStack(spacing: 14) {
            // Photo placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.dinkrGreen.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "figure.pickleball")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.dinkrGreen.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(listing.brand)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.secondary)
                Text(listing.model)
                    .font(.headline.weight(.bold))
                Text("$\(Int(listing.price))")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Color.dinkrGreen)
                Label(listing.location, systemImage: "mappin")
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(listing.status.rawValue.capitalized)
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(listing.status == .active ? Color.dinkrGreen : Color.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (listing.status == .active ? Color.dinkrGreen : Color.secondary).opacity(0.12)
                    )
                    .clipShape(Capsule())

                HStack(spacing: 3) {
                    Text("👁")
                        .font(.caption2)
                    Text("\(listing.viewCount)")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Offer management row

private struct OfferManagementRow: View {
    let offer: MarketOffer
    let onAction: (OfferAction) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Buyer avatar
            ZStack {
                Circle()
                    .fill(Color.dinkrSky.opacity(0.2))
                    .frame(width: 40, height: 40)
                Text(offer.buyerName.prefix(1))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.dinkrNavy)
            }

            // Buyer info
            VStack(alignment: .leading, spacing: 2) {
                Text(offer.buyerName)
                    .font(.subheadline.weight(.semibold))
                if !offer.message.isEmpty {
                    Text(offer.message)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(2)
                }
                Text(offer.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(Color.secondary.opacity(0.7))
            }

            Spacer()

            // Amount + action buttons
            VStack(alignment: .trailing, spacing: 6) {
                Text("$\(Int(offer.amount))")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(Color.dinkrNavy)

                if offer.status == .pending {
                    HStack(spacing: 6) {
                        Button {
                            onAction(.decline)
                        } label: {
                            Text("Decline")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.dinkrCoral)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.dinkrCoral.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            onAction(.accept)
                        } label: {
                            Text("Accept")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.dinkrGreen)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Text(offer.status.rawValue.capitalized)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(offer.status == .accepted ? Color.dinkrGreen : Color.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            (offer.status == .accepted ? Color.dinkrGreen : Color.secondary).opacity(0.12)
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Views bar chart (no external framework)

private struct ViewsBarChart: View {
    let viewCount: Int

    // Generate 7 synthetic daily values ending at viewCount
    private var bars: [Int] {
        let peak = max(viewCount, 1)
        let seed: [Double] = [0.15, 0.25, 0.40, 0.60, 0.75, 0.88, 1.0]
        return seed.map { Int(Double(peak) * $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Views Over Time")
                    .font(.headline.weight(.bold))
                Spacer()
                Text("7 days")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(bars.enumerated()), id: \.offset) { index, value in
                    let maxVal = bars.max() ?? 1
                    let height = CGFloat(value) / CGFloat(maxVal) * 80

                    VStack(spacing: 4) {
                        // Bar
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                index == bars.count - 1
                                ? Color.dinkrGreen
                                : Color.dinkrGreen.opacity(0.35)
                            )
                            .frame(height: max(height, 6))
                            .frame(maxWidth: .infinity)

                        // Day label
                        let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
                        Text(dayLabels[index % dayLabels.count])
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    MyListingsView()
}

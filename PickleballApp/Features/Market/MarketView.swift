import SwiftUI

struct MarketView: View {
    @State private var viewModel = MarketViewModel()
    @State private var showMyOffers = false
    @State private var showMyListings = false
    @State private var showWatchlist = false
    @State private var showInsights = false
    @State private var showFilterSheet = false

    var hotListings: [MarketListing] {
        viewModel.filteredListings.filter { $0.viewCount > 30 }
    }

    private let sevenDaysAgo = Date().addingTimeInterval(-86400 * 7)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // ── Search bar ───────────────────────────────────────
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 15, weight: .medium))
                        TextField("Search paddles, gear…", text: $viewModel.searchText)
                            .font(.subheadline)
                            .onChange(of: viewModel.searchText) { _, _ in viewModel.applyFilter() }
                        Spacer()
                        if !viewModel.searchText.isEmpty {
                            Button {
                                viewModel.searchText = ""
                                viewModel.applyFilter()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        Divider()
                            .frame(height: 20)
                        // Filter button — dot badge when price filter active
                        Button {
                            showFilterSheet = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "slider.horizontal.3")
                                    .foregroundStyle(Color.dinkrNavy)
                                    .font(.system(size: 15, weight: .medium))
                                if viewModel.minPrice != nil || viewModel.maxPrice != nil {
                                    Circle()
                                        .fill(Color.dinkrCoral)
                                        .frame(width: 7, height: 7)
                                        .offset(x: 4, y: -4)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 12)

                    // ── For Sale / Free toggle ────────────────────────────
                    MarketListingTypeToggle(showFreeOnly: $viewModel.showFreeOnly)
                        .onChange(of: viewModel.showFreeOnly) { _, _ in viewModel.applyFilter() }
                        .padding(.bottom, 12)

                    // ── Active filter chips row ─────────────────────────
                    HStack(spacing: 8) {
                        // Sold filter toggle chip
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.showSoldItems.toggle()
                            }
                            viewModel.applyFilter()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: viewModel.showSoldItems ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Sold Items")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(viewModel.showSoldItems ? .white : Color.dinkrCoral)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(viewModel.showSoldItems ? Color.dinkrCoral : Color.dinkrCoral.opacity(0.10))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.dinkrCoral.opacity(viewModel.showSoldItems ? 0 : 0.4), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        // Price range chip (shown only when a range is set)
                        if viewModel.minPrice != nil || viewModel.maxPrice != nil {
                            Button {
                                viewModel.minPrice = nil
                                viewModel.maxPrice = nil
                                viewModel.applyFilter()
                            } label: {
                                HStack(spacing: 4) {
                                    let priceLabel: String = {
                                        switch (viewModel.minPrice, viewModel.maxPrice) {
                                        case let (min?, max?): return "$\(Int(min))–$\(Int(max))"
                                        case let (min?, nil):  return "≥$\(Int(min))"
                                        case let (nil, max?):  return "≤$\(Int(max))"
                                        default:               return ""
                                        }
                                    }()
                                    Text(priceLabel)
                                        .font(.system(size: 12, weight: .semibold))
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9, weight: .bold))
                                }
                                .foregroundStyle(Color.dinkrNavy)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color.dinkrNavy.opacity(0.10))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 14)

                    // ── Category grid ─────────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Browse Categories")
                                .font(.headline.weight(.bold))
                            Spacer()
                        }
                        .padding(.horizontal)

                        PremiumMarketCategoryGrid(selectedCategory: $viewModel.selectedCategory)
                            .onChange(of: viewModel.selectedCategory) { _, _ in viewModel.applyFilter() }
                    }
                    .padding(.bottom, 14)

                    // ── Condition filter chips ─────────────────────────────
                    ConditionFilterChips(selectedCondition: $viewModel.selectedCondition)
                        .onChange(of: viewModel.selectedCondition) { _, _ in viewModel.applyFilter() }
                        .padding(.bottom, 20)

                    // ── Hot Items row (hidden when sold filter is active) ──
                    if !hotListings.isEmpty && viewModel.selectedCategory == nil
                        && viewModel.searchText.isEmpty && !viewModel.showSoldItems {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                HStack(spacing: 6) {
                                    Text("🔥")
                                        .font(.headline)
                                    Text("HOT RIGHT NOW")
                                        .font(.system(size: 13, weight: .heavy))
                                        .foregroundStyle(Color.dinkrCoral)
                                }
                                Spacer()
                                Text("See all →")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.dinkrGreen)
                            }
                            .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(hotListings.prefix(6)) { listing in
                                        NavigationLink {
                                            ListingDetailView(listing: listing)
                                        } label: {
                                            ListingCardView(
                                                listing: listing,
                                                showSoldBanner: false,
                                                isNewThisWeek: listing.createdAt >= sevenDaysAgo
                                            )
                                            .frame(width: 162)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.bottom, 4)

                        // Section divider with label
                        HStack(spacing: 10) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.15))
                                .frame(height: 1)
                            Text("ALL LISTINGS")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(.secondary)
                            Rectangle()
                                .fill(Color.secondary.opacity(0.15))
                                .frame(height: 1)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 14)
                    }

                    // ── Main listing grid ──────────────────────────────────
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        if viewModel.isLoading {
                            ProgressView().gridCellColumns(2).padding(.top, 40)
                        } else if viewModel.filteredListings.isEmpty {
                            MarketEmptyStateView(
                                searchText: viewModel.searchText,
                                selectedCategory: viewModel.selectedCategory,
                                selectedCondition: viewModel.selectedCondition,
                                showFreeOnly: viewModel.showFreeOnly,
                                showSoldItems: viewModel.showSoldItems,
                                onClearFilters: {
                                    viewModel.searchText = ""
                                    viewModel.selectedCategory = nil
                                    viewModel.selectedCondition = nil
                                    viewModel.showFreeOnly = false
                                    viewModel.minPrice = nil
                                    viewModel.maxPrice = nil
                                    viewModel.applyFilter()
                                },
                                onCreateListing: { viewModel.showCreateListing = true }
                            )
                            .gridCellColumns(2)
                            .padding(.top, 40)
                        } else {
                            ForEach(viewModel.filteredListings) { listing in
                                NavigationLink {
                                    ListingDetailView(listing: listing)
                                } label: {
                                    ListingCardView(
                                        listing: listing,
                                        showSoldBanner: viewModel.showSoldItems && listing.status == .sold,
                                        isNewThisWeek: listing.createdAt >= sevenDaysAgo && listing.status != .sold
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, viewModel.recentlySoldListings.isEmpty || viewModel.showSoldItems ? 32 : 0)

                    // ── Recently Sold section (bottom, only in default view) ──
                    if !viewModel.recentlySoldListings.isEmpty && !viewModel.showSoldItems {
                        recentlySoldSection
                            .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Market")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 14) {
                        Button {
                            showMyOffers = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "tag")
                                Text("My Offers")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .tint(Color.dinkrNavy)

                        Button {
                            showMyListings = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "storefront")
                                Text("My Listings")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .tint(Color.dinkrGreen)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 6) {
                        Button {
                            showInsights = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chart.bar.xaxis")
                                Text("Insights")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .tint(Color.dinkrSky)

                        Button {
                            showWatchlist = true
                        } label: {
                            Image(systemName: "bookmark")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .tint(Color.dinkrNavy)

                        Button {
                            viewModel.showCreateListing = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("Sell")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .tint(Color.dinkrCoral)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showCreateListing) {
            CreateListingView()
        }
        .sheet(isPresented: $showInsights) {
            MarketInsightsView()
        }
        .sheet(isPresented: $showMyOffers) {
            MyOffersView(userId: User.mockCurrentUser.id)
        }
        .sheet(isPresented: $showMyListings) {
            MyListingsView()
        }
        .sheet(isPresented: $showWatchlist) {
            MarketWatchlistView()
        }
        .sheet(isPresented: $showFilterSheet) {
            PriceRangeFilterSheet(minPrice: $viewModel.minPrice, maxPrice: $viewModel.maxPrice) {
                viewModel.applyFilter()
            }
        }
        .task { await viewModel.load() }
    }

    // MARK: - Recently Sold Section

    private var recentlySoldSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(height: 1)
                Text("RECENTLY SOLD")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.secondary)
                Rectangle()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(height: 1)
            }
            .padding(.horizontal)
            .padding(.top, 24)

            ForEach(viewModel.recentlySoldListings) { listing in
                RecentlySoldRow(listing: listing)
                    .padding(.horizontal)
            }
        }
    }
}

// MARK: - Recently Sold Row

private struct RecentlySoldRow: View {
    let listing: MarketListing

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.dinkrCoral.opacity(0.10))
                    .frame(width: 44, height: 44)
                Image(systemName: categoryIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color.dinkrCoral.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(listing.brand) \(listing.model)")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(listing.sellerName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(Int(listing.price))")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(Color.dinkrCoral)
                Text("Final price")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text("SOLD")
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.dinkrCoral)
                .clipShape(Capsule())
        }
        .padding(12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
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

// MARK: - Price Range Filter Sheet

struct PriceRangeFilterSheet: View {
    @Binding var minPrice: Double?
    @Binding var maxPrice: Double?
    let onApply: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var minText: String = ""
    @State private var maxText: String = ""

    private let presets: [(label: String, min: Double?, max: Double?)] = [
        ("Under $25",    nil,   25),
        ("$25 – $75",     25,   75),
        ("$75 – $150",    75,  150),
        ("$150 – $300",  150,  300),
        ("Over $300",    300,  nil),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Filter by Price")
                        .font(.title3.weight(.bold))
                    Text("Enter a minimum, maximum, or both to narrow results.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)

                // Min / Max fields
                HStack(spacing: 14) {
                    PriceInputField(label: "Min Price", placeholder: "e.g. 20", text: $minText)
                    Text("to")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    PriceInputField(label: "Max Price", placeholder: "e.g. 200", text: $maxText)
                }

                // Quick presets
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quick Presets")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(presets, id: \.label) { preset in
                            let isActive = minText == (preset.min.map { String(Int($0)) } ?? "")
                                        && maxText == (preset.max.map { String(Int($0)) } ?? "")
                            Button {
                                minText = preset.min.map { String(Int($0)) } ?? ""
                                maxText = preset.max.map { String(Int($0)) } ?? ""
                            } label: {
                                Text(preset.label)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(isActive ? .white : Color.dinkrNavy)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(isActive ? Color.dinkrNavy : Color.dinkrNavy.opacity(0.07))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer()

                // Action buttons
                VStack(spacing: 10) {
                    Button {
                        minPrice = Double(minText.trimmingCharacters(in: .whitespaces))
                        maxPrice = Double(maxText.trimmingCharacters(in: .whitespaces))
                        onApply()
                        dismiss()
                    } label: {
                        Text("Apply Filter")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.dinkrGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button {
                        minText = ""
                        maxText = ""
                        minPrice = nil
                        maxPrice = nil
                        onApply()
                        dismiss()
                    } label: {
                        Text("Clear Filter")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .tint(Color.dinkrNavy)
                }
            }
        }
        .onAppear {
            minText = minPrice.map { String(Int($0)) } ?? ""
            maxText = maxPrice.map { String(Int($0)) } ?? ""
        }
    }
}

// MARK: - Price Input Field

private struct PriceInputField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Text("$")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.dinkrGreen)
                TextField(placeholder, text: $text)
                    .keyboardType(.numberPad)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - For Sale / Free Toggle

private struct MarketListingTypeToggle: View {
    @Binding var showFreeOnly: Bool

    var body: some View {
        HStack(spacing: 0) {
            toggleButton(
                label: "For Sale",
                icon: "tag.fill",
                isSelected: !showFreeOnly,
                selectedColor: Color.dinkrNavy
            ) { showFreeOnly = false }

            toggleButton(
                label: "Free",
                icon: "gift.fill",
                isSelected: showFreeOnly,
                selectedColor: Color.dinkrGreen
            ) { showFreeOnly = true }
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func toggleButton(
        label: String,
        icon: String,
        isSelected: Bool,
        selectedColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(label)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : .primary.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? selectedColor : Color.clear)
                    .padding(3)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Condition Filter Chips

private struct ConditionFilterChips: View {
    @Binding var selectedCondition: ListingCondition?

    private let options: [(label: String, condition: ListingCondition?, color: Color)] = [
        ("All",        nil,          Color.dinkrNavy),
        ("Brand New",  .brandNew,    Color.dinkrGreen),
        ("Like New",   .likeNew,     Color.dinkrSky),
        ("Good",       .good,        Color.dinkrAmber),
        ("Fair",       .fair,        Color.dinkrCoral),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Condition")
                .font(.headline.weight(.bold))
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.label) { option in
                        let isSelected = selectedCondition == option.condition
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                                selectedCondition = option.condition
                            }
                        } label: {
                            Text(option.label)
                                .font(.subheadline.weight(isSelected ? .bold : .regular))
                                .foregroundStyle(isSelected ? .white : option.color)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .background(
                                    isSelected
                                        ? option.color
                                        : option.color.opacity(0.10)
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(isSelected ? Color.clear : option.color.opacity(0.30), lineWidth: 1)
                                )
                                .shadow(
                                    color: isSelected ? option.color.opacity(0.35) : .clear,
                                    radius: 6, x: 0, y: 2
                                )
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isSelected)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Market Enhanced Empty State

private struct MarketEmptyStateView: View {
    let searchText: String
    let selectedCategory: MarketCategory?
    let selectedCondition: ListingCondition?
    let showFreeOnly: Bool
    let showSoldItems: Bool
    let onClearFilters: () -> Void
    let onCreateListing: () -> Void

    private var hasActiveFilters: Bool {
        !searchText.isEmpty || selectedCategory != nil || selectedCondition != nil || showFreeOnly
    }

    private var headline: String {
        if showSoldItems { return "No Sold Items" }
        if !searchText.isEmpty { return "No results for \u{201C}\(searchText)\u{201D}" }
        if showFreeOnly { return "No free items right now" }
        if let cat = selectedCategory { return "No \(cat.rawValue.capitalized) listings" }
        if let cond = selectedCondition { return "No \u{201C}\(cond.rawValue)\u{201D} items" }
        return "No Listings Yet"
    }

    private var subheadline: String {
        if showSoldItems { return "No items have sold in the marketplace yet." }
        if hasActiveFilters { return "Try adjusting your filters or broadening your search." }
        return "Be the first to list gear for sale in the community!"
    }

    private var iconName: String {
        if showSoldItems { return "tag.slash" }
        if hasActiveFilters { return "magnifyingglass" }
        return "tag"
    }

    var body: some View {
        VStack(spacing: 22) {
            // Icon in a circle
            ZStack {
                Circle()
                    .fill(Color.dinkrNavy.opacity(0.07))
                    .frame(width: 100, height: 100)
                Image(systemName: iconName)
                    .font(.system(size: 38, weight: .light))
                    .foregroundStyle(Color.dinkrNavy.opacity(0.35))
            }

            VStack(spacing: 8) {
                Text(headline)
                    .font(.headline.weight(.bold))
                    .multilineTextAlignment(.center)
                Text(subheadline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // Active filter summary pills
            if hasActiveFilters {
                HStack(spacing: 6) {
                    if !searchText.isEmpty {
                        filterPill(label: "\u{201C}\(searchText)\u{201D}", color: Color.dinkrNavy)
                    }
                    if let cat = selectedCategory {
                        filterPill(label: cat.rawValue.capitalized, color: Color.dinkrSky)
                    }
                    if let cond = selectedCondition {
                        filterPill(label: cond.rawValue, color: Color.dinkrAmber)
                    }
                    if showFreeOnly {
                        filterPill(label: "Free only", color: Color.dinkrGreen)
                    }
                }
                .flexibleWrapping()

                Button(action: onClearFilters) {
                    Label("Clear All Filters", systemImage: "xmark.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(Color.dinkrNavy)
                        .clipShape(Capsule())
                        .shadow(color: Color.dinkrNavy.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)
            } else if !showSoldItems {
                Button(action: onCreateListing) {
                    Label("List an Item", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(Color.dinkrCoral)
                        .clipShape(Capsule())
                        .shadow(color: Color.dinkrCoral.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 20)
    }

    private func filterPill(label: String, color: Color) -> some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - Flexible Wrapping layout helper (simple HStack fallback)

private extension View {
    @ViewBuilder func flexibleWrapping() -> some View {
        self
    }
}

// MARK: - Premium Category Grid

struct PremiumMarketCategoryGrid: View {
    @Binding var selectedCategory: MarketCategory?

    let categories: [(category: MarketCategory?, icon: String, label: String, accent: Color)] = [
        (nil,          "square.grid.2x2",   "All",         Color.dinkrGreen),
        (.paddles,     "figure.pickleball", "Paddles",     Color.dinkrCoral),
        (.balls,       "circle.fill",       "Balls",       Color.dinkrAmber),
        (.bags,        "bag.fill",          "Bags",        Color.dinkrSky),
        (.apparel,     "tshirt.fill",       "Apparel",     .purple),
        (.shoes,       "shoeprints.fill",   "Shoes",       .teal),
        (.accessories, "sparkles",          "Accessories", .pink),
        (.other,       "ellipsis.circle",   "Other",       Color.dinkrNavy),
    ]

    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(categories, id: \.label) { item in
                let isSelected = selectedCategory == item.category
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedCategory = item.category
                    }
                } label: {
                    VStack(spacing: 7) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    isSelected
                                    ? Color.dinkrGreen.opacity(0.12)
                                    : Color(.secondarySystemBackground)
                                )
                                .frame(width: 58, height: 58)
                            Image(systemName: item.icon)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(isSelected ? Color.dinkrGreen : item.accent)
                        }
                        Text(item.label)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(isSelected ? Color.dinkrGreen : .primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    MarketView()
}

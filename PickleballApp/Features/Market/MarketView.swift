import SwiftUI

struct MarketView: View {
    @State private var viewModel = MarketViewModel()

    var hotListings: [MarketListing] {
        viewModel.filteredListings.filter { $0.viewCount > 30 }
    }

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
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(Color.dinkrNavy)
                            .font(.system(size: 15, weight: .medium))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 16)

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
                    .padding(.bottom, 20)

                    // ── Hot Items row ─────────────────────────────────────
                    if !hotListings.isEmpty && viewModel.selectedCategory == nil && viewModel.searchText.isEmpty {
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
                                            ListingCardView(listing: listing)
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
                            EmptyStateView(
                                icon: "tag",
                                title: "No Listings",
                                message: "Be the first to list gear for sale!",
                                actionLabel: "List an Item",
                                action: { viewModel.showCreateListing = true }
                            )
                            .gridCellColumns(2)
                            .padding(.top, 40)
                        } else {
                            ForEach(viewModel.filteredListings) { listing in
                                NavigationLink {
                                    ListingDetailView(listing: listing)
                                } label: {
                                    ListingCardView(listing: listing)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Market")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
        .sheet(isPresented: $viewModel.showCreateListing) {
            CreateListingView()
        }
        .task { await viewModel.load() }
    }
}

// MARK: - Premium Category Grid

struct PremiumMarketCategoryGrid: View {
    @Binding var selectedCategory: MarketCategory?

    let categories: [(category: MarketCategory?, icon: String, label: String, gradient: [Color])] = [
        (nil,          "square.grid.2x2",   "All",         [Color.dinkrGreen,  Color.dinkrGreen.opacity(0.6)]),
        (.paddles,     "figure.pickleball", "Paddles",     [Color.dinkrCoral,  Color.dinkrAmber.opacity(0.8)]),
        (.balls,       "circle.fill",       "Balls",       [Color.dinkrAmber,  Color.dinkrAmber.opacity(0.6)]),
        (.bags,        "bag.fill",          "Bags",        [Color.dinkrSky,    Color.dinkrNavy.opacity(0.7)]),
        (.apparel,     "tshirt.fill",       "Apparel",     [.purple,           .purple.opacity(0.6)]),
        (.shoes,       "shoeprints.fill",   "Shoes",       [.teal,             Color.dinkrSky.opacity(0.7)]),
        (.accessories, "sparkles",          "Accessories", [.pink,             .pink.opacity(0.6)]),
        (.other,       "ellipsis.circle",   "Other",       [Color.dinkrNavy,   Color.dinkrNavy.opacity(0.6)]),
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
                                    ? LinearGradient(colors: item.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [item.gradient[0].opacity(0.12), item.gradient[0].opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .frame(width: 58, height: 58)
                                .shadow(
                                    color: isSelected ? item.gradient[0].opacity(0.4) : .clear,
                                    radius: 8, x: 0, y: 4
                                )
                            Image(systemName: item.icon)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(isSelected ? .white : item.gradient[0])
                                .scaleEffect(isSelected ? 1.1 : 1.0)
                        }
                        Text(item.label)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(isSelected ? item.gradient[0] : .primary)
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

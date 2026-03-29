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
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        TextField("Search paddles, gear...", text: $viewModel.searchText)
                            .onChange(of: viewModel.searchText) { _, _ in viewModel.applyFilter() }
                    }
                    .padding(10)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                    // Category icon grid
                    MarketCategoryGrid(selectedCategory: $viewModel.selectedCategory)
                        .onChange(of: viewModel.selectedCategory) { _, _ in viewModel.applyFilter() }
                        .padding(.bottom, 12)

                    Divider()

                    // Hot Items horizontal row
                    if !hotListings.isEmpty && viewModel.selectedCategory == nil && viewModel.searchText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("🔥 HOT ITEMS")
                                    .font(.system(size: 11, weight: .heavy))
                                    .foregroundStyle(Color.dinkrCoral)
                                Spacer()
                                Text("See all →")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.dinkrCoral)
                            }
                            .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(hotListings.prefix(6)) { listing in
                                        NavigationLink {
                                            ListingDetailView(listing: listing)
                                        } label: {
                                            ListingCardView(listing: listing)
                                                .frame(width: 150)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                        Divider()
                            .padding(.vertical, 8)
                    }

                    // Main grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
                        Label("Sell", systemImage: "plus.circle.fill")
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

#Preview {
    MarketView()
}

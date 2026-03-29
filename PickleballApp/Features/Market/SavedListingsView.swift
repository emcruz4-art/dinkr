import SwiftUI

// MARK: - Saved Listings View

struct SavedListingsView: View {
    // In a real app, persist with @AppStorage JSON encoding.
    // Using @State with mock initial data here.
    @State private var savedIds: Set<String> = ["ml_001", "ml_002", "ml_006", "ml_009"]
    @State private var selectedSegment: SavedSegment = .all
    @State private var showSortSheet = false
    @State private var sortOption: SavedSortOption = .recentlyAdded

    enum SavedSegment: String, CaseIterable {
        case all = "All"
        case paddles = "Paddles"
        case gear = "Gear"
    }

    enum SavedSortOption: String, CaseIterable, Identifiable {
        case recentlyAdded = "Recently Added"
        case priceLowHigh = "Price: Low to High"
        case endingSoon = "Ending Soon"
        var id: String { rawValue }
    }

    var savedListings: [MarketListing] {
        MarketListing.mockListings.filter { savedIds.contains($0.id) }
    }

    var filteredListings: [MarketListing] {
        let base: [MarketListing]
        switch selectedSegment {
        case .all:
            base = savedListings
        case .paddles:
            base = savedListings.filter { $0.category == .paddles }
        case .gear:
            base = savedListings.filter { $0.category != .paddles }
        }
        switch sortOption {
        case .recentlyAdded:
            return base.sorted { $0.createdAt > $1.createdAt }
        case .priceLowHigh:
            return base.sorted { $0.price < $1.price }
        case .endingSoon:
            return base.sorted { $0.createdAt < $1.createdAt }
        }
    }

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 12)]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment control
                Picker("Filter", selection: $selectedSegment) {
                    ForEach(SavedSegment.allCases, id: \.self) { seg in
                        Text(seg.rawValue).tag(seg)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 10)

                Divider()

                if filteredListings.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(filteredListings) { listing in
                                SavedListingCard(
                                    listing: listing,
                                    isSaved: savedIds.contains(listing.id),
                                    onToggleSave: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            if savedIds.contains(listing.id) {
                                                savedIds.remove(listing.id)
                                            } else {
                                                savedIds.insert(listing.id)
                                            }
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Saved Items (\(savedIds.count))")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSortSheet = true
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .tint(Color.dinkrCoral)
                }
            }
            .confirmationDialog("Sort By", isPresented: $showSortSheet, titleVisibility: .visible) {
                ForEach(SavedSortOption.allCases) { option in
                    Button(option.rawValue) {
                        withAnimation { sortOption = option }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "heart.slash")
                .font(.system(size: 52))
                .foregroundStyle(Color.dinkrCoral.opacity(0.4))
            Text("No saved items yet")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
            Text("Heart listings in the Market to save them here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            NavigationLink {
                MarketView()
            } label: {
                Text("Browse Market")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(Color.dinkrCoral)
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }
}

// MARK: - SavedListingCard

struct SavedListingCard: View {
    let listing: MarketListing
    let isSaved: Bool
    let onToggleSave: () -> Void

    @State private var messageTapped = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Category icon area
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.dinkrCoral.opacity(0.12))
                    .frame(height: 100)
                    .overlay {
                        Image(systemName: categoryIcon)
                            .font(.system(size: 38))
                            .foregroundStyle(Color.dinkrCoral.opacity(0.45))
                    }

                // Heart save button
                Button(action: onToggleSave) {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isSaved ? Color.dinkrCoral : Color.secondary)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .scaleEffect(isSaved ? 1.15 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: isSaved)
                }
                .padding(8)
            }

            // Details
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(listing.condition.rawValue)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(conditionColor)
                        .clipShape(Capsule())
                    Spacer()
                }

                Text(listing.brand)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(listing.model)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                Text("$\(String(format: "%.0f", listing.price))")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.dinkrCoral)

                // Message Seller button
                Button {
                    withAnimation(.spring(response: 0.2)) { messageTapped = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        messageTapped = false
                    }
                } label: {
                    Text(messageTapped ? "Message Sent!" : "Message Seller")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(messageTapped ? Color.dinkrGreen : Color.dinkrSky)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(messageTapped ? Color.dinkrGreen : Color.dinkrSky, lineWidth: 1.2)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
                .animation(.easeInOut(duration: 0.2), value: messageTapped)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    var categoryIcon: String {
        switch listing.category {
        case .paddles: return "figure.pickleball"
        case .balls: return "circle.fill"
        case .bags: return "bag.fill"
        case .apparel: return "tshirt.fill"
        case .shoes: return "shoeprints.fill"
        case .accessories: return "sparkles"
        case .courts: return "sportscourt"
        case .other: return "ellipsis.circle"
        }
    }

    var conditionColor: Color {
        switch listing.condition {
        case .brandNew: return Color.dinkrGreen
        case .likeNew: return Color.dinkrSky
        case .good: return Color.dinkrAmber
        case .fair: return Color.dinkrCoral
        case .forParts: return .secondary
        }
    }
}

// MARK: - Preview

#Preview {
    SavedListingsView()
}

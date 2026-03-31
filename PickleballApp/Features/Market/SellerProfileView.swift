import SwiftUI

struct SellerProfileView: View {
    let sellerName: String
    let userId: String

    // Mock data constants
    private let listingsSold   = 47
    private let avgResponse    = "< 1 hr"
    private let rating         = 4.9
    private let reviewCount    = 31
    private let isVerified     = true

    private let ratingBreakdown: [(stars: Int, count: Int)] = [
        (5, 26),
        (4, 3),
        (3, 1),
        (2, 1),
        (1, 0)
    ]

    private let mockReviews: [(reviewer: String, stars: Int, date: String, body: String)] = [
        ("Alex R.", 5, "Mar 2026", "Super fast shipping and item was exactly as described. Would buy from again!"),
        ("Dana W.", 5, "Feb 2026", "Great communication and a fair deal. Paddle was in perfect condition."),
        ("Priya N.", 4, "Jan 2026", "Good seller, slight delay in responding but worked out fine in the end.")
    ]

    var activeListings: [MarketListing] {
        MarketListing.mockListings.filter { $0.sellerId == userId }
    }

    @State private var messageSent = false
    @State private var showReport  = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── Header ────────────────────────────────────────────────
                headerSection
                    .padding(.bottom, 24)

                // ── Stats row ─────────────────────────────────────────────
                statsRow
                    .padding(.horizontal)
                    .padding(.bottom, 24)

                // ── Rating breakdown ──────────────────────────────────────
                ratingBreakdownSection
                    .padding(.horizontal)
                    .padding(.bottom, 28)

                // ── Active Listings ───────────────────────────────────────
                activeListingsSection
                    .padding(.bottom, 28)

                // ── Reviews ───────────────────────────────────────────────
                reviewsSection
                    .padding(.horizontal)
                    .padding(.bottom, 24)

                // ── CTA buttons ───────────────────────────────────────────
                ctaButtons
                    .padding(.horizontal)
                    .padding(.bottom, 40)
            }
        }
        .navigationTitle("Seller Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Report Submitted", isPresented: $showReport) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Thank you. Our team will review this report.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.55)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 130)

                ZStack {
                    Circle()
                        .fill(Color.dinkrNavy)
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                    Text(String(sellerName.prefix(1)).uppercased())
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(.white)
                }
                .offset(y: 40)
            }

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text(sellerName)
                        .font(.title2.weight(.bold))
                    if isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Color.dinkrGreen)
                            .font(.title3)
                    }
                }
                .padding(.top, 48)

                Text("Member since 2023")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 4)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(value: "\(listingsSold)", label: "Sold")
            statDivider
            statCell(value: avgResponse, label: "Response")
            statDivider
            statCell(value: String(format: "%.1f ★", rating), label: "Rating", valueColor: Color.dinkrAmber)
            statDivider
            statCell(value: "\(reviewCount)", label: "Reviews")
        }
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private func statCell(value: String, label: String, valueColor: Color = .primary) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(valueColor)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.15))
            .frame(width: 1, height: 32)
    }

    // MARK: - Rating Breakdown

    private var ratingBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rating Breakdown")
                .font(.headline.weight(.bold))

            VStack(spacing: 8) {
                ForEach(ratingBreakdown, id: \.stars) { row in
                    HStack(spacing: 10) {
                        Text("\(row.stars)")
                            .font(.caption.weight(.semibold))
                            .frame(width: 12, alignment: .trailing)
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.dinkrAmber)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.12))
                                let fillFraction = reviewCount > 0
                                    ? CGFloat(row.count) / CGFloat(reviewCount)
                                    : 0
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.dinkrGreen)
                                    .frame(width: geo.size.width * fillFraction)
                            }
                        }
                        .frame(height: 8)

                        Text("\(row.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 22, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Active Listings

    private var activeListingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Listings")
                    .font(.headline.weight(.bold))
                Spacer()
                Text("\(activeListings.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            if activeListings.isEmpty {
                Text("No active listings right now.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 12
                ) {
                    ForEach(activeListings) { listing in
                        NavigationLink {
                            ListingDetailView(listing: listing)
                        } label: {
                            sellerListingCard(listing)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func sellerListingCard(_ listing: MarketListing) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.cardBackground)
                    .frame(height: 100)
                Image(systemName: categoryIcon(for: listing.category))
                    .font(.system(size: 36))
                    .foregroundStyle(Color.dinkrCoral.opacity(0.35))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("\(listing.brand) \(listing.model)")
                    .font(.caption.weight(.semibold))
                    .lineLimit(2)
                Text("$\(Int(listing.price))")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(Color.dinkrCoral)
                Text(listing.condition.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 6)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 2)
    }

    // MARK: - Reviews

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Reviews")
                    .font(.headline.weight(.bold))
                Spacer()
                Text("See all \(reviewCount)")
                    .font(.caption)
                    .foregroundStyle(Color.dinkrGreen)
            }

            VStack(spacing: 10) {
                ForEach(mockReviews, id: \.reviewer) { review in
                    reviewCard(review)
                }
            }
        }
    }

    private func reviewCard(_ review: (reviewer: String, stars: Int, date: String, body: String)) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Reviewer avatar
                Circle()
                    .fill(Color.dinkrSky.opacity(0.25))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(review.reviewer.prefix(1)))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.dinkrSky)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(review.reviewer)
                        .font(.caption.weight(.semibold))
                    HStack(spacing: 2) {
                        ForEach(0..<5) { i in
                            Image(systemName: i < review.stars ? "star.fill" : "star")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.dinkrAmber)
                        }
                    }
                }

                Spacer()

                Text(review.date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(review.body)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - CTA Buttons

    private var ctaButtons: some View {
        VStack(spacing: 10) {
            Button {
                messageSent = true
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    messageSent = false
                }
            } label: {
                Text(messageSent ? "Message Sent ✓" : "Message Seller")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(messageSent ? Color.dinkrSky : Color.dinkrGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Button {
                showReport = true
            } label: {
                Text("Report Seller")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

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
    NavigationStack {
        SellerProfileView(sellerName: "Chris Park", userId: "user_005")
    }
}

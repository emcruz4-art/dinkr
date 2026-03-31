import SwiftUI

// MARK: - Mock review model (local to this feature)
private struct PaddleReview: Identifiable {
    let id = UUID()
    let reviewerName: String
    let rating: Int
    let text: String
    let date: String
    let skillLevel: String
}

// MARK: - Mock price history point

private struct PricePoint: Identifiable {
    let id = UUID()
    let label: String   // e.g. "Oct", "Nov", "Dec"
    let price: Double
}

struct ListingDetailView: View {
    let listing: MarketListing
    @State private var showMakeOffer = false
    @State private var messageSent = false
    @State private var showWriteReview = false
    @State private var showPriceAlert = false
    @State private var priceAlert: PriceAlert? = nil

    // BookmarkService for watchlist
    @State private var bookmarks = BookmarkService.shared

    // Mock reviews — in a real app these would come from Firestore
    private let mockReviews: [PaddleReview] = [
        PaddleReview(reviewerName: "Jordan S.", rating: 5,
                     text: "Great power but a little heavy for dinking at the kitchen. Absolutely rips on drives though.",
                     date: "Mar 18, 2026", skillLevel: "3.5"),
        PaddleReview(reviewerName: "Alexis M.", rating: 4,
                     text: "Solid control and spin. Edge guard shows wear after 2 months but the face is still perfect.",
                     date: "Feb 27, 2026", skillLevel: "4.0"),
        PaddleReview(reviewerName: "Devon K.", rating: 5,
                     text: "Best paddle I've ever used at this price point. Highly recommend for intermediate to advanced players.",
                     date: "Jan 9, 2026", skillLevel: "4.5"),
    ]

    private var averageRating: Double {
        Double(mockReviews.reduce(0) { $0 + $1.rating }) / Double(mockReviews.count)
    }

    private func starCount(for stars: Int) -> Int {
        mockReviews.filter { $0.rating == stars }.count
    }

    // Fake price history — starts a bit higher, works down to current price
    private var priceHistory: [PricePoint] {
        let base = listing.price
        return [
            PricePoint(label: "Oct", price: base * 1.30),
            PricePoint(label: "Nov", price: base * 1.18),
            PricePoint(label: "Dec", price: base * 1.10),
            PricePoint(label: "Jan", price: base * 1.05),
            PricePoint(label: "Feb", price: base * 1.02),
            PricePoint(label: "Now", price: base),
        ]
    }

    // Similar listings from mock data — same category, different id
    private var similarListings: [MarketListing] {
        MarketListing.mockListings
            .filter { $0.category == listing.category && $0.id != listing.id && $0.status == .active }
            .prefix(4)
            .map { $0 }
    }

    // Share URL placeholder
    private var shareURL: URL {
        URL(string: "https://dinkr.app/listings/\(listing.id)") ?? URL(string: "https://dinkr.app")!
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Photo placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.cardBackground)
                        .frame(height: 280)
                    Image(systemName: categoryIcon)
                        .font(.system(size: 80))
                        .foregroundStyle(Color.dinkrCoral.opacity(0.3))
                }

                VStack(alignment: .leading, spacing: 16) {
                    // Title + price
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(listing.brand + " " + listing.model)
                                .font(.title2.weight(.bold))
                            Text(listing.category.rawValue.capitalized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(listing.price == 0 ? "Free" : "$\(Int(listing.price))")
                                .font(.title.weight(.heavy))
                                .foregroundStyle(listing.price == 0 ? Color.dinkrGreen : Color.dinkrCoral)
                            Text(listing.condition.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Stats row
                    HStack(spacing: 16) {
                        Label(listing.location, systemImage: "mappin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Label("\(listing.viewCount) views", systemImage: "eye")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if listing.isFeatured {
                            Label("Featured", systemImage: "star.fill")
                                .font(.caption)
                                .foregroundStyle(Color.dinkrAmber)
                        }
                    }

                    Divider()

                    // Description
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Description")
                            .font(.headline)
                        Text(listing.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Condition breakdown explanation
                    conditionBreakdownCard

                    Divider()

                    // Seller card — tap to open full profile
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Seller")
                            .font(.headline)

                        NavigationLink {
                            SellerProfileView(
                                sellerName: listing.sellerName,
                                userId: listing.sellerId
                            )
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.dinkrGreen.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Text(String(listing.sellerName.prefix(1)))
                                            .font(.title3.weight(.bold))
                                            .foregroundStyle(Color.dinkrGreen)
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(listing.sellerName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    HStack(spacing: 4) {
                                        HStack(spacing: 2) {
                                            ForEach(0..<5) { i in
                                                Image(systemName: i < 4 ? "star.fill" : "star.leadinghalf.filled")
                                                    .font(.caption2)
                                                    .foregroundStyle(Color.dinkrAmber)
                                            }
                                        }
                                        Text("4.8 · Verified Seller")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Text("Member since 2023 · 12 sales")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }

                    Divider()

                    // Price History section
                    priceHistorySection

                    Divider()

                    // Reviews section
                    reviewsSummarySection

                    Divider()

                    // CTA buttons — improved layout
                    improvedActionButtons

                    Divider()

                    // Similar Listings section
                    if !similarListings.isEmpty {
                        similarListingsSection
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(listing.model)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 4) {
                    // Save to Watchlist bookmark button
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                            bookmarks.toggle(listingId: listing.id)
                        }
                    } label: {
                        Image(systemName: bookmarks.isSaved(listingId: listing.id) ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(
                                bookmarks.isSaved(listingId: listing.id)
                                    ? Color.dinkrGreen
                                    : Color.dinkrNavy
                            )
                            .scaleEffect(bookmarks.isSaved(listingId: listing.id) ? 1.1 : 1.0)
                    }
                    .buttonStyle(.plain)

                    // Share button
                    ShareLink(
                        item: shareURL,
                        subject: Text("\(listing.brand) \(listing.model) on Dinkr"),
                        message: Text("Check out this \(listing.condition.rawValue.lowercased()) \(listing.brand) \(listing.model) for \(listing.price == 0 ? "free" : "$\(Int(listing.price))") on Dinkr!")
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.dinkrNavy)
                    }
                }
            }
        }
        .sheet(isPresented: $showMakeOffer) {
            MakeOfferView(listing: listing)
        }
        .sheet(isPresented: $showPriceAlert) {
            PriceDropAlertView(listing: listing, currentAlert: $priceAlert)
        }
        .sheet(isPresented: $showWriteReview) {
            PaddleReviewView(itemName: listing.brand + " " + listing.model)
        }
    }

    // MARK: - Condition Breakdown Card

    @ViewBuilder
    private var conditionBreakdownCard: some View {
        let info = conditionInfo(for: listing.condition)
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: info.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(info.color)
                Text("What \u{201C}\(listing.condition.rawValue)\u{201D} Means")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(info.color)
                Spacer()
                Text(listing.condition.rawValue)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(info.color)
                    .clipShape(Capsule())
            }
            Text(info.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Usage indicator dots
            HStack(spacing: 4) {
                ForEach(0..<5) { i in
                    Circle()
                        .fill(i < info.usageDots ? info.color : Color.secondary.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
                Text(info.usageLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(info.color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(info.color.opacity(0.20), lineWidth: 1)
        )
    }

    private struct ConditionInfo {
        let icon: String
        let color: Color
        let description: String
        let usageDots: Int    // how many of 5 dots filled (more = more used)
        let usageLabel: String
    }

    private func conditionInfo(for condition: ListingCondition) -> ConditionInfo {
        switch condition {
        case .brandNew:
            return ConditionInfo(
                icon: "sparkles",
                color: Color.dinkrGreen,
                description: "Never used. Original packaging, tags, and grip intact. No marks, dents, or wear of any kind. Essentially store-bought.",
                usageDots: 0,
                usageLabel: "Never used"
            )
        case .likeNew:
            return ConditionInfo(
                icon: "checkmark.seal.fill",
                color: Color.dinkrSky,
                description: "Minimal use — typically 1 to 4 sessions. Surface face is pristine; possible micro-scuff on edge guard only. Original grip may be replaced. Plays like new.",
                usageDots: 1,
                usageLabel: "Light use"
            )
        case .good:
            return ConditionInfo(
                icon: "hand.thumbsup.fill",
                color: Color.dinkrAmber,
                description: "Regularly used for one or more seasons. Visible edge guard wear and minor surface marks. Full performance intact — no chips, cracks, or delamination.",
                usageDots: 3,
                usageLabel: "Regular use"
            )
        case .fair:
            return ConditionInfo(
                icon: "exclamationmark.triangle.fill",
                color: Color.dinkrCoral,
                description: "Heavy use — scratches, edge dings, and grip replacement visible. Core performance may be slightly affected. Best value for casual or practice play.",
                usageDots: 5,
                usageLabel: "Heavy use"
            )
        case .forParts:
            return ConditionInfo(
                icon: "wrench.fill",
                color: .secondary,
                description: "Sold as-is for parts or crafts. May have cracks, broken edge guard, or delaminated face. Not suitable for regular play.",
                usageDots: 5,
                usageLabel: "For parts"
            )
        }
    }

    // MARK: - Price History Section

    @ViewBuilder
    private var priceHistorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Price History")
                    .font(.headline)
                Spacer()
                // Drop percentage badge
                let first = priceHistory.first?.price ?? listing.price
                let drop = Int(((first - listing.price) / first) * 100)
                if drop > 0 {
                    Label("\(drop)% lower than listed", systemImage: "arrow.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.dinkrGreen)
                        .clipShape(Capsule())
                }
            }

            PriceHistoryChart(points: priceHistory, accentColor: Color.dinkrSky)
                .frame(height: 90)
                .padding(.vertical, 4)
        }
    }

    // MARK: - Reviews Section

    @ViewBuilder
    private var reviewsSummarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header row
            HStack {
                Text("Reviews")
                    .font(.headline)
                Spacer()
                Button {
                    showWriteReview = true
                } label: {
                    Label("Write a Review", systemImage: "pencil.and.list.clipboard")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.dinkrGreen)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            // Rating summary
            HStack(alignment: .top, spacing: 18) {
                // Big average number
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", averageRating))
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.dinkrNavy)
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(averageRating.rounded()) ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundStyle(Color.dinkrAmber)
                        }
                    }
                    Text("\(mockReviews.count) reviews")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Star distribution bars
                VStack(spacing: 5) {
                    ForEach([5, 4, 3, 2, 1], id: \.self) { stars in
                        HStack(spacing: 6) {
                            Text("\(stars)\u{2605}")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 22, alignment: .leading)

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.secondary.opacity(0.12))
                                    let fraction = mockReviews.isEmpty ? 0.0 : CGFloat(starCount(for: stars)) / CGFloat(mockReviews.count)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.dinkrAmber)
                                        .frame(width: max(0, geo.size.width * fraction))
                                }
                            }
                            .frame(height: 6)

                            Text("\(starCount(for: stars))")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 14, alignment: .trailing)
                        }
                    }
                }
            }

            Divider()

            // Individual review rows
            ForEach(mockReviews) { review in
                ReviewRowView(review: review)
                if review.id != mockReviews.last?.id {
                    Divider()
                }
            }
        }
    }

    // MARK: - Improved Action Buttons

    @ViewBuilder
    private var improvedActionButtons: some View {
        VStack(spacing: 12) {

            // Primary: Message Seller (full width, prominent)
            Button {
                Task {
                    _ = await DMService.shared.startConversation(
                        currentUserId: User.mockCurrentUser.id,
                        currentUserName: User.mockCurrentUser.displayName,
                        targetUserId: listing.sellerId,
                        targetUserName: listing.sellerName
                    )
                    messageSent = true
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    messageSent = false
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: messageSent ? "checkmark.circle.fill" : "message.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text(messageSent ? "Message Sent!" : "Message Seller")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(messageSent ? Color.dinkrSky : Color.dinkrGreen)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(
                    color: (messageSent ? Color.dinkrSky : Color.dinkrGreen).opacity(0.35),
                    radius: 8, x: 0, y: 4
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: messageSent)
            }
            .buttonStyle(.plain)

            // Secondary row: Make Offer + Set Price Alert side-by-side
            HStack(spacing: 10) {
                Button {
                    showMakeOffer = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "dollarsign.circle")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Make Offer")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Color.dinkrCoral)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.dinkrCoral.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.dinkrCoral.opacity(0.35), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    showPriceAlert = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: priceAlert != nil ? "bell.fill" : "bell")
                            .font(.system(size: 15, weight: .semibold))
                        Text(priceAlert != nil ? "Alert Set" : "Price Alert")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(priceAlert != nil ? Color.dinkrAmber : Color.dinkrNavy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(priceAlert != nil ? Color.dinkrAmber.opacity(0.10) : Color.dinkrNavy.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                priceAlert != nil ? Color.dinkrAmber.opacity(0.35) : Color.dinkrNavy.opacity(0.18),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Similar Listings Section

    @ViewBuilder
    private var similarListingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Similar Listings")
                    .font(.headline)
                Spacer()
                Text("in \(listing.category.rawValue.capitalized)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrSky)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(similarListings) { similar in
                        NavigationLink {
                            ListingDetailView(listing: similar)
                        } label: {
                            ListingCardView(listing: similar)
                                .frame(width: 158)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 4)
            }
        }
    }

    // MARK: - Category Icon

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
}

// MARK: - Price History Chart

private struct PriceHistoryChart: View {
    let points: [PricePoint]
    let accentColor: Color

    var body: some View {
        GeometryReader { geo in
            let prices = points.map(\.price)
            let minP = (prices.min() ?? 0) * 0.92
            let maxP = (prices.max() ?? 1) * 1.04
            let range = maxP - minP
            let w = geo.size.width
            let h = geo.size.height
            let labelH: CGFloat = 20
            let chartH = h - labelH

            // Build point positions
            let positions: [CGPoint] = points.enumerated().map { idx, pt in
                let x = points.count <= 1
                    ? w / 2
                    : (CGFloat(idx) / CGFloat(points.count - 1)) * w
                let y = range == 0 ? chartH / 2 : chartH - ((pt.price - minP) / range) * chartH
                return CGPoint(x: x, y: y)
            }

            ZStack(alignment: .bottom) {
                // Gradient area fill under line
                if positions.count >= 2 {
                    Path { path in
                        path.move(to: CGPoint(x: positions[0].x, y: chartH))
                        path.addLine(to: positions[0])
                        for p in positions.dropFirst() {
                            path.addLine(to: p)
                        }
                        path.addLine(to: CGPoint(x: positions.last!.x, y: chartH))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.18), accentColor.opacity(0.01)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: chartH)
                }

                // Line path
                if positions.count >= 2 {
                    Path { path in
                        path.move(to: positions[0])
                        for p in positions.dropFirst() {
                            path.addLine(to: p)
                        }
                    }
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(height: chartH)
                }

                // Dots at each point
                ForEach(Array(zip(positions, points)), id: \.1.id) { pos, pt in
                    let isLast = pt.id == points.last?.id
                    ZStack {
                        Circle()
                            .fill(isLast ? Color.dinkrCoral : accentColor)
                            .frame(width: isLast ? 10 : 7, height: isLast ? 10 : 7)
                            .shadow(color: (isLast ? Color.dinkrCoral : accentColor).opacity(0.4), radius: 4, x: 0, y: 2)

                        if isLast {
                            // Price label above final dot
                            Text("$\(Int(pt.price))")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(Color.dinkrCoral)
                                .offset(y: -18)
                        }
                    }
                    .position(x: pos.x, y: pos.y)
                    .frame(width: geo.size.width, height: chartH)
                }

                // X-axis labels
                HStack(spacing: 0) {
                    ForEach(points) { pt in
                        Text(pt.label)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: labelH)
            }
        }
    }
}

// MARK: - Review Row

private struct ReviewRowView: View {
    let review: PaddleReview

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                // Avatar
                Circle()
                    .fill(Color.dinkrNavy.opacity(0.12))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(review.reviewerName.prefix(1)))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.dinkrNavy)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(review.reviewerName)
                        .font(.subheadline.weight(.semibold))
                    HStack(spacing: 4) {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= review.rating ? "star.fill" : "star")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.dinkrAmber)
                            }
                        }
                        Text("\u{00B7}")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(review.skillLevel + " player")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(review.date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(review.text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}

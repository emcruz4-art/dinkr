import SwiftUI
import MapKit

// MARK: - CourtDetailView

struct CourtDetailView: View {
    let venue: CourtVenue

    @State private var mapPosition: MapCameraPosition
    @State private var showGoogleMapsAlert = false
    @State private var allReviews: [CourtReview] = []
    @State private var showWriteReview = false
    @State private var showBooking = false

    init(venue: CourtVenue) {
        self.venue = venue
        self._mapPosition = State(initialValue: .region(MKCoordinateRegion(
            center: venue.coordinates.clLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }

    private var courtReviews: [CourtReview] {
        allReviews.filter { $0.courtId == venue.id }
    }

    private var featuredReviews: [CourtReview] {
        let featured = courtReviews.filter(\.isFeatured)
        if featured.isEmpty {
            return Array(courtReviews.sorted { $0.helpfulCount > $1.helpfulCount }.prefix(2))
        }
        return Array(featured.prefix(2))
    }

    private var averageRating: Double {
        guard !courtReviews.isEmpty else { return venue.rating }
        return courtReviews.map(\.overallRating).reduce(0, +) / Double(courtReviews.count)
    }

    private var isOpen: Bool {
        !venue.openPlaySchedule.lowercased().contains("closed")
    }

    private var amenityGridItems: [(icon: String, label: String)] {
        var items: [(String, String)] = []
        if venue.hasLighting { items.append(("flashlight.on.fill", "Lights")) }
        if venue.isIndoor { items.append(("building.2.fill", "Covered")) }
        for amenity in venue.amenities {
            switch amenity {
            case "Restrooms": items.append(("figure.walk", "Restrooms"))
            case "Parking": items.append(("car.fill", "Parking"))
            case "Water Fountains": items.append(("drop.fill", "Water"))
            case "Pro Shop": items.append(("bag.fill", "Pro Shop"))
            case "Locker Rooms": items.append(("lock.fill", "Lockers"))
            case "Coaching", "Lessons": items.append(("person.fill.checkmark", "Coaching"))
            case "Gym": items.append(("dumbbell.fill", "Gym"))
            default: items.append(("checkmark.circle.fill", amenity))
            }
        }
        return items
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Map Hero
                Map(position: $mapPosition) {
                    Annotation(venue.name, coordinate: venue.coordinates.clLocation) {
                        ZStack {
                            Circle()
                                .fill(Color.dinkrGreen)
                                .frame(width: 38, height: 38)
                                .shadow(color: Color.dinkrGreen.opacity(0.4), radius: 6)
                            Image(systemName: "sportscourt")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 0))
                .ignoresSafeArea(edges: .top)

                // MARK: Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(venue.name)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Color.dinkrNavy)

                            HStack(spacing: 6) {
                                StarRatingDisplay(rating: venue.rating, size: 14)
                                Text(String(format: "%.1f", venue.rating))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.dinkrNavy)
                                Text("(\(venue.reviewCount) reviews)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        PillTag(
                            text: venue.isIndoor ? "Indoor" : "Outdoor"
                        )
                    }

                    // Address
                    Label(venue.address, systemImage: "mappin.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Stats row
                    HStack(spacing: 12) {
                        StatChip(icon: "sportscourt", value: "\(venue.courtCount)", label: "Courts")
                        StatChip(icon: "rays", value: venue.surface.rawValue.capitalized, label: "Surface")
                        if venue.hasLighting {
                            StatChip(icon: "flashlight.on.fill", value: "Yes", label: "Lighting")
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // MARK: Book a Court Button
                Button {
                    showBooking = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.subheadline.weight(.semibold))
                        Text("Book a Court")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.dinkrGreen.opacity(0.3), radius: 6, y: 3)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .sheet(isPresented: $showBooking) {
                    CourtBookingView(courtName: venue.name)
                }

                Divider().padding(.vertical, 16).padding(.horizontal, 20)

                // MARK: Directions Buttons
                VStack(alignment: .leading, spacing: 10) {
                    Text("Get Directions")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.6)

                    HStack(spacing: 12) {
                        Button(action: openInAppleMaps) {
                            HStack(spacing: 6) {
                                Image(systemName: "map.fill")
                                Text("Apple Maps")
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.dinkrGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button(action: openInGoogleMaps) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                Text("Google Maps")
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                            .foregroundStyle(Color.dinkrNavy)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.dinkrNavy.opacity(0.2), lineWidth: 1.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, 20)

                Divider().padding(.vertical, 16).padding(.horizontal, 20)

                // MARK: Reviews Section
                VStack(alignment: .leading, spacing: 14) {
                    // Section header with rating summary
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reviews")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.6)
                            HStack(spacing: 6) {
                                StarRatingDisplay(rating: averageRating, size: 14)
                                Text(String(format: "%.1f", averageRating))
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Color.dinkrNavy)
                                Text("(\(courtReviews.isEmpty ? venue.reviewCount : courtReviews.count) reviews)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        NavigationLink(destination: CourtReviewsView(court: venue)) {
                            Text("See All →")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.dinkrGreen)
                        }
                    }

                    // Featured review cards (top 2)
                    if !featuredReviews.isEmpty {
                        VStack(spacing: 10) {
                            ForEach(featuredReviews) { review in
                                CompactReviewCard(review: review)
                            }
                        }
                    } else {
                        Text("Be the first to review this court!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    }

                    // Write a Review button
                    Button {
                        showWriteReview = true
                    } label: {
                        Label("Write a Review", systemImage: "square.and.pencil")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.dinkrGreen.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.dinkrGreen.opacity(0.35), lineWidth: 1.5)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .sheet(isPresented: $showWriteReview) {
                    WriteCourtReviewView(court: venue) { newReview in
                        allReviews.insert(newReview, at: 0)
                    }
                }
                .onAppear {
                    if allReviews.isEmpty {
                        allReviews = CourtReview.mockReviews
                    }
                }

                Divider().padding(.vertical, 16).padding(.horizontal, 20)

                // MARK: Regular Players Section
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.dinkrGreen)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Regulars Here")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.6)
                            Text("Players who frequent this court")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(Array(User.mockPlayers.prefix(5))) { player in
                                NavigationLink(destination: UserProfileView(user: player, currentUserId: "user_001")) {
                                    VStack(spacing: 6) {
                                        AvatarView(urlString: player.avatarURL, displayName: player.displayName, size: 44)
                                        Text(player.displayName.components(separatedBy: " ").first ?? player.displayName)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(Color.primary)
                                            .lineLimit(1)
                                        SkillBadge(level: player.skillLevel, compact: true)
                                    }
                                    .frame(width: 72)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, -20)
                }
                .padding(.horizontal, 20)

                Divider().padding(.vertical, 16).padding(.horizontal, 20)
                CourtConditionsWidget(court: venue)
                    .padding(.horizontal, 20)

                Divider().padding(.vertical, 16).padding(.horizontal, 20)

                // MARK: Today's Open Play Schedule
                VStack(alignment: .leading, spacing: 10) {
                    Text("Open Play Schedule")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.6)

                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(isOpen ? Color.dinkrGreen.opacity(0.12) : Color.dinkrCoral.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: isOpen ? "clock.fill" : "clock.badge.xmark.fill")
                                .font(.title3)
                                .foregroundStyle(isOpen ? Color.dinkrGreen : Color.dinkrCoral)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(isOpen ? "Open Now" : "Currently Closed")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(isOpen ? Color.dinkrGreen : Color.dinkrCoral)
                            Text(venue.openPlaySchedule)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(14)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    if let phone = venue.phoneNumber {
                        Button {
                            if let url = URL(string: "tel://\(phone.filter { $0.isNumber })") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label(phone, systemImage: "phone.fill")
                                .font(.subheadline)
                                .foregroundStyle(Color.dinkrSky)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 20)

                Divider().padding(.vertical, 16).padding(.horizontal, 20)

                // MARK: Amenities Grid (2-column)
                if !amenityGridItems.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Amenities")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.6)

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)
                            ],
                            spacing: 10
                        ) {
                            ForEach(amenityGridItems, id: \.label) { item in
                                AmenityCell(icon: item.icon, label: item.label)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle(venue.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Directions helpers

    private func openInAppleMaps() {
        let coord = venue.coordinates.clLocation
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coord))
        mapItem.name = venue.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    private func openInGoogleMaps() {
        let coord = venue.coordinates.clLocation
        let urlString = "comgooglemaps://?daddr=\(coord.latitude),\(coord.longitude)&directionsmode=driving"
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            let webString = "https://www.google.com/maps/dir/?api=1&destination=\(coord.latitude),\(coord.longitude)"
            if let webURL = URL(string: webString) {
                UIApplication.shared.open(webURL)
            }
        }
    }
}

// MARK: - CompactReviewCard

private struct CompactReviewCard: View {
    let review: CourtReview

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                AuthorInitialCircle(name: review.authorName)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(review.authorName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrNavy)
                        if review.isVerifiedPlayer {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.dinkrGreen)
                        }
                    }
                    StarRatingDisplay(rating: review.overallRating, size: 11)
                }
                Spacer()
                Text(review.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(review.body)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(2)

            if !review.tags.isEmpty {
                HStack(spacing: 5) {
                    ForEach(review.tags.prefix(3), id: \.self) { tag in
                        Text(tag.rawValue)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.dinkrSky.opacity(0.12))
                            .foregroundStyle(Color.dinkrSky)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    review.isFeatured ? Color.dinkrGreen.opacity(0.4) : Color.clear,
                    lineWidth: 1.5
                )
        )
    }
}

// MARK: - AmenityCell

private struct AmenityCell: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.dinkrGreen)
                .frame(width: 22)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.dinkrNavy)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - StatChip

struct StatChip: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.dinkrGreen)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.dinkrNavy)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width + spacing > maxWidth && rowWidth > 0 {
                height += rowHeight + spacing
                rowWidth = size.width + spacing
                rowHeight = size.height
            } else {
                rowWidth += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
        }
        height += rowHeight
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var rowX: CGFloat = bounds.minX
        var rowY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowX + size.width > bounds.maxX && rowX > bounds.minX {
                rowX = bounds.minX
                rowY += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: rowX, y: rowY), proposal: ProposedViewSize(size))
            rowX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CourtDetailView(venue: CourtVenue.mockVenues[0])
    }
}

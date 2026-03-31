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
    @State private var showPhotoGallery = false
    @State private var showAvailability = false
    @State private var showHostGame = false
    @State private var occupancyPulse = false

    init(venue: CourtVenue) {
        self.venue = venue
        self._mapPosition = State(initialValue: .region(MKCoordinateRegion(
            center: venue.coordinates.clLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        )))
    }

    // MARK: - Derived state

    private var courtReviews: [CourtReview] {
        allReviews.filter { $0.courtId == venue.id }
    }

    private var recentReviews: [CourtReview] {
        Array(courtReviews.sorted { $0.createdAt > $1.createdAt }.prefix(3))
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

    /// Heuristic: open if the schedule text doesn't say "closed" and it's within a typical window.
    private var isOpen: Bool {
        let schedule = venue.openPlaySchedule.lowercased()
        if schedule.contains("closed") || schedule.contains("members only") { return false }
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 6 && hour < 21
    }

    /// Mock occupancy: derive from reviewCount as a stable pseudo-random seed.
    private var occupiedCourts: Int {
        max(1, venue.reviewCount % venue.courtCount)
    }

    private var nearbyVenues: [CourtVenue] {
        CourtVenue.mockVenues.filter { $0.id != venue.id }.prefix(3).map { $0 }
    }

    private var upcomingSessions: [GameSession] {
        GameSession.mockSessions
            .filter { $0.courtId == venue.id && $0.dateTime > Date() }
            .sorted { $0.dateTime < $1.dateTime }
            .prefix(3)
            .map { $0 }
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

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── 1. Hero Map ──────────────────────────────────────────────
                heroSection

                // ── 2. Quick Info Strip ──────────────────────────────────────
                quickInfoStrip
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                Divider().padding(.vertical, 16).padding(.horizontal, 20)

                // ── 3. Court Occupancy ───────────────────────────────────────
                occupancySection
                    .padding(.horizontal, 20)

                Divider().padding(.vertical, 16).padding(.horizontal, 20)

                // ── 4. Action Buttons ────────────────────────────────────────
                actionButtonsSection
                    .padding(.horizontal, 20)

                Divider().padding(.vertical, 16).padding(.horizontal, 20)

                // ── 5. Upcoming Games ────────────────────────────────────────
                upcomingGamesSection
                    .padding(.horizontal, 20)

                Divider().padding(.vertical, 16).padding(.horizontal, 20)

                // ── 6. Reviews ───────────────────────────────────────────────
                reviewsSection
                    .padding(.horizontal, 20)
                    .sheet(isPresented: $showWriteReview) {
                        WriteCourtReviewView(court: venue) { newReview in
                            allReviews.insert(newReview, at: 0)
                        }
                    }

                Divider().padding(.vertical, 16).padding(.horizontal, 20)

                // ── 7. Regulars ──────────────────────────────────────────────
                regularsSection
                    .padding(.horizontal, 20)

                Divider().padding(.vertical, 16).padding(.horizontal, 20)

                // ── Court Conditions ─────────────────────────────────────────
                CourtConditionsWidget(court: venue)
                    .padding(.horizontal, 20)

                Divider().padding(.vertical, 16).padding(.horizontal, 20)

                // ── Open Play Schedule ───────────────────────────────────────
                openPlaySection
                    .padding(.horizontal, 20)

                Divider().padding(.vertical, 16).padding(.horizontal, 20)

                // ── Amenities Grid ───────────────────────────────────────────
                if !amenityGridItems.isEmpty {
                    amenitiesSection
                        .padding(.horizontal, 20)
                }

                Divider().padding(.vertical, 16).padding(.horizontal, 20)

                // ── 8. Nearby Courts ─────────────────────────────────────────
                nearbyCourtsSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
        }
        .navigationTitle(venue.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if allReviews.isEmpty {
                allReviews = CourtReview.mockReviews
            }
        }
        .sheet(isPresented: $showBooking) {
            CourtBookingView(courtName: venue.name)
        }
        .sheet(isPresented: $showAvailability) {
            CourtAvailabilityView(venueName: venue.name, maxCourts: venue.courtCount)
        }
        .fullScreenCover(isPresented: $showPhotoGallery) {
            CourtPhotoGalleryView(courtName: venue.name)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            // Map thumbnail
            Map(position: $mapPosition, interactionModes: []) {
                Annotation(venue.name, coordinate: venue.coordinates.clLocation) {
                    ZStack {
                        Circle()
                            .fill(Color.dinkrGreen)
                            .frame(width: 42, height: 42)
                            .shadow(color: Color.dinkrGreen.opacity(0.5), radius: 8)
                        Image(systemName: "sportscourt.fill")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(height: 260)
            .ignoresSafeArea(edges: .top)

            // Gradient scrim overlay
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.65)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 260)
            .ignoresSafeArea(edges: .top)

            // Court name + rating + open/closed badge over the map
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(venue.name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4)

                        HStack(spacing: 6) {
                            StarRatingDisplay(rating: averageRating, size: 13)
                            Text(String(format: "%.1f", averageRating))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("(\(courtReviews.isEmpty ? venue.reviewCount : courtReviews.count))")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    Spacer()
                    // Open/Closed badge
                    HStack(spacing: 5) {
                        Circle()
                            .fill(isOpen ? Color.dinkrGreen : Color.dinkrCoral)
                            .frame(width: 8, height: 8)
                            .overlay {
                                if isOpen {
                                    Circle()
                                        .stroke(Color.dinkrGreen.opacity(0.4), lineWidth: 3)
                                        .scaleEffect(occupancyPulse ? 1.8 : 1.0)
                                        .opacity(occupancyPulse ? 0 : 0.8)
                                        .animation(
                                            .easeOut(duration: 1.4).repeatForever(autoreverses: false),
                                            value: occupancyPulse
                                        )
                                }
                            }
                        Text(isOpen ? "Open Now" : "Closed")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isOpen ? Color.dinkrGreen : Color.dinkrCoral)
                    )
                }

                Label(venue.address, systemImage: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .onAppear { occupancyPulse = true }
    }

    // MARK: - Quick Info Strip

    private var quickInfoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CourtInfoChip(icon: "location.fill",
                         label: "~1.2 mi",
                         color: Color.dinkrSky)
                CourtInfoChip(icon: "square.fill",
                         label: venue.surface.rawValue.capitalized,
                         color: Color.dinkrNavy)
                CourtInfoChip(icon: venue.isIndoor ? "building.2.fill" : "sun.max.fill",
                         label: venue.isIndoor ? "Indoor" : "Outdoor",
                         color: venue.isIndoor ? Color.dinkrAmber : Color.dinkrGreen)
                CourtInfoChip(icon: "sportscourt.fill",
                         label: "\(venue.courtCount) courts",
                         color: Color.dinkrGreen)
                CourtInfoChip(icon: venue.hasLighting ? "flashlight.on.fill" : "flashlight.slash.fill",
                         label: venue.hasLighting ? "Lit" : "No lights",
                         color: venue.hasLighting ? Color.dinkrAmber : .secondary)
            }
            .padding(.horizontal, 1) // avoids clipping shadow
        }
    }

    // MARK: - Occupancy Section

    private var occupancySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section label
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.dinkrGreen)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Court Occupancy")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.6)
                    Text("Mock real-time · updated just now")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                // Live pill
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.dinkrCoral)
                        .frame(width: 5, height: 5)
                        .scaleEffect(occupancyPulse ? 1.5 : 0.8)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: occupancyPulse)
                    Text("LIVE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.dinkrCoral)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.dinkrCoral.opacity(0.12))
                .clipShape(Capsule())
            }

            // Occupancy card
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(occupiedCourts)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.dinkrNavy)
                    Text("of \(venue.courtCount) courts in use")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 2)
                    Spacer()
                    Text("\(venue.courtCount - occupiedCourts) free")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color.dinkrGreen.opacity(0.12))
                        .clipShape(Capsule())
                }

                // Dot progress row
                OccupancyDotRow(occupied: occupiedCourts, total: venue.courtCount)
            }
            .padding(14)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: 10) {
            // Primary: Get Directions row (Apple + Google side by side)
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text("Get Directions")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.6)
                } icon: {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                        .foregroundStyle(Color.dinkrGreen)
                        .font(.caption)
                }

                HStack(spacing: 10) {
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

            // Book a Court — primary CTA
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

            // Check Availability — secondary
            Button {
                showAvailability = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.subheadline.weight(.semibold))
                    Text("Check Availability")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Color.dinkrGreen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.dinkrGreen.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.dinkrGreen.opacity(0.35), lineWidth: 1.5)
                )
            }

            // Photos + Hours in a side-by-side row
            HStack(spacing: 10) {
                // View Photos
                Button {
                    showPhotoGallery = true
                } label: {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(Color.dinkrSky.opacity(0.15))
                                .frame(width: 30, height: 30)
                            Image(systemName: "photo.stack.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.dinkrSky)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("View Photos")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.dinkrNavy)
                            Text("6 photos")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Hours & Details
                NavigationLink(destination: CourtHoursView(venue: venue)) {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(Color.dinkrGreen.opacity(0.12))
                                .frame(width: 30, height: 30)
                            Image(systemName: "clock.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.dinkrGreen)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Hours & Details")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.dinkrNavy)
                            Text(isOpen ? "Open now" : "Closed")
                                .font(.caption2)
                                .foregroundStyle(isOpen ? Color.dinkrGreen : Color.dinkrCoral)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Upcoming Games Section

    private var upcomingGamesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upcoming Games Here")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.6)
                    if upcomingSessions.isEmpty {
                        Text("No games scheduled yet")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Next \(upcomingSessions.count) session\(upcomingSessions.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                // Host here button
                Button {
                    showHostGame = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption.weight(.semibold))
                        Text("Host here")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Color.dinkrGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.dinkrGreen.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showHostGame) {
                    HostGameView()
                }
            }

            if upcomingSessions.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.dinkrGreen.opacity(0.5))
                    Text("Be the first to host a game here!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                VStack(spacing: 8) {
                    ForEach(upcomingSessions) { session in
                        NavigationLink(destination: GameSessionDetailView(session: session, viewModel: PlayViewModel())) {
                            CompactGameCard(session: session)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Reviews Section

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header row
            HStack(alignment: .top) {
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

            // Star breakdown bars
            if !courtReviews.isEmpty {
                reviewBreakdownBars
            }

            // Recent review cards (up to 3)
            if !recentReviews.isEmpty {
                VStack(spacing: 10) {
                    ForEach(recentReviews) { review in
                        CourtDetailReviewCard(review: review)
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
    }

    private var reviewBreakdownBars: some View {
        HStack(alignment: .center, spacing: 16) {
            // Big number
            VStack(spacing: 2) {
                Text(String(format: "%.1f", averageRating))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dinkrNavy)
                StarRatingDisplay(rating: averageRating, size: 12)
                Text("\(courtReviews.count) reviews")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80)

            // 5→1 star bars
            VStack(spacing: 5) {
                ForEach([5, 4, 3, 2, 1], id: \.self) { star in
                    HStack(spacing: 6) {
                        Text("\(star)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 8, alignment: .trailing)
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(Color.dinkrAmber)
                        RatingBar(filled: starFraction(for: star), color: Color.dinkrGreen)
                        Text("\(starCount(for: star))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 18, alignment: .trailing)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func starCount(for star: Int) -> Int {
        courtReviews.filter { Int($0.overallRating.rounded()) == star }.count
    }

    private func starFraction(for star: Int) -> Double {
        guard !courtReviews.isEmpty else { return 0 }
        return Double(starCount(for: star)) / Double(courtReviews.count)
    }

    // MARK: - Regulars Section

    private var regularsSection: some View {
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
    }

    // MARK: - Open Play Schedule Section

    private var openPlaySection: some View {
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
    }

    // MARK: - Amenities Section

    private var amenitiesSection: some View {
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
    }

    // MARK: - Nearby Courts Section

    private var nearbyCourtsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Nearby Courts")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                Spacer()
                Text("Within ~2 mi")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                ForEach(nearbyVenues) { nearby in
                    NavigationLink(destination: CourtDetailView(venue: nearby)) {
                        NearbyCourtRow(venue: nearby)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Directions helpers

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

// MARK: - InfoChip (Quick Info Strip)

private struct CourtInfoChip: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.dinkrNavy)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(color.opacity(0.10))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(color.opacity(0.20), lineWidth: 1)
        )
    }
}

// MARK: - OccupancyDotRow

private struct OccupancyDotRow: View {
    let occupied: Int
    let total: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0 ..< total, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(index < occupied ? Color.dinkrCoral : Color(UIColor.systemGray5))
                    .frame(height: 8)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - CompactGameCard

private struct CompactGameCard: View {
    let session: GameSession

    private var formatColor: Color {
        switch session.format {
        case .doubles:     return Color.dinkrGreen
        case .singles:     return Color.dinkrSky
        case .openPlay:    return Color.dinkrAmber
        case .mixed:       return Color.dinkrCoral
        case .round_robin: return Color.dinkrNavy
        }
    }

    private var countdownText: String {
        let diff = session.dateTime.timeIntervalSinceNow
        if diff < 0 { return "Started" }
        if diff < 3600 { return "In \(Int(diff / 60))m" }
        if diff < 86400 {
            return "In \(Int(diff / 3600))h \(Int((diff.truncatingRemainder(dividingBy: 3600)) / 60))m"
        }
        return session.dateTime.friendlyDateString
    }

    var body: some View {
        HStack(spacing: 12) {
            // Color accent bar + format icon
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(formatColor)
                    .frame(width: 4)
            }
            .frame(height: 52)
            .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(session.format.displayLabel)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(formatColor)
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(session.skillRange.lowerBound.rawValue + "–" + session.skillRange.upperBound.rawValue)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(countdownText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(session.dateTime.timeIntervalSinceNow < 3600 ? Color.dinkrCoral : Color.dinkrNavy)
                }

                Text("Hosted by \(session.hostName)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.dinkrNavy)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Label("\(session.rsvps.count)/\(session.totalSpots) joined",
                          systemImage: "person.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if session.isFull {
                        Text("Full")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.dinkrCoral)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.dinkrCoral.opacity(0.12))
                            .clipShape(Capsule())
                    } else {
                        Text("\(session.spotsRemaining) spot\(session.spotsRemaining == 1 ? "" : "s") left")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.dinkrGreen.opacity(0.10))
                            .clipShape(Capsule())
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - CourtDetailReviewCard (avatar + stars + text + date)

private struct CourtDetailReviewCard: View {
    let review: CourtReview

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
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

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f", review.overallRating))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.dinkrAmber)
                    Text(review.createdAt.relativeString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(review.body)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(3)

            if !review.tags.isEmpty {
                HStack(spacing: 5) {
                    ForEach(review.tags.prefix(3), id: \.self) { tag in
                        ReviewTagPill(label: tag.rawValue)
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

// MARK: - NearbyCourtRow

private struct NearbyCourtRow: View {
    let venue: CourtVenue

    var body: some View {
        HStack(spacing: 12) {
            // Court icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.dinkrGreen.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.dinkrGreen)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(venue.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dinkrNavy)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    StarRatingDisplay(rating: venue.rating, size: 10)
                    Text(String(format: "%.1f", venue.rating))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(venue.courtCount) courts")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(venue.isIndoor ? "Indoor" : "Outdoor")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("~\(Int.random(in: 1...2)) mi")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.dinkrSky)
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
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

private struct CourtFlowLayout: Layout {
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

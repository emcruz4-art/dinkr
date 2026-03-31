import SwiftUI
import MapKit

// MARK: - CourtListView

/// Full-featured court discovery list with search, filter chips, sort, and map toggle.
struct CourtListView: View {

    // Seed venues from PlayViewModel (falls back to mock if empty)
    let venues: [CourtVenue]

    // MARK: - State

    @State private var searchText: String = ""
    @State private var activeFilter: CourtFilter = .all
    @State private var sortMode: CourtSortMode = .nearest
    @State private var showMap = false
    @State private var isRefreshing = false

    // MARK: - Filter & Sort Models

    enum CourtFilter: String, CaseIterable, Identifiable {
        case all     = "All"
        case indoor  = "Indoor"
        case outdoor = "Outdoor"
        case covered = "Covered"
        case lit     = "Lit"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .all:     return "square.grid.2x2"
            case .indoor:  return "building.2"
            case .outdoor: return "sun.max"
            case .covered: return "umbrella"
            case .lit:     return "flashlight.on.fill"
            }
        }
    }

    enum CourtSortMode: String, CaseIterable, Identifiable {
        case nearest   = "Nearest"
        case rating    = "Rating"
        case available = "Available Courts"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .nearest:   return "location.fill"
            case .rating:    return "star.fill"
            case .available: return "sportscourt.fill"
            }
        }
    }

    // MARK: - Computed Data

    private var allVenues: [CourtVenue] {
        venues.isEmpty ? CourtListMock.venues : venues
    }

    private var filteredVenues: [CourtVenue] {
        var result = allVenues

        // Text search
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(q) ||
                $0.address.lowercased().contains(q)
            }
        }

        // Filter chips
        switch activeFilter {
        case .all:     break
        case .indoor:  result = result.filter { $0.isIndoor }
        case .outdoor: result = result.filter { !$0.isIndoor }
        case .covered: result = result.filter { $0.isIndoor || $0.amenities.contains("Covered") }
        case .lit:     result = result.filter { $0.hasLighting }
        }

        // Sort
        switch sortMode {
        case .nearest:
            // Use seeded mock distances (index order approximates proximity)
            break
        case .rating:
            result.sort { $0.rating > $1.rating }
        case .available:
            result.sort { $0.courtCount > $1.courtCount }
        }

        return result
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if showMap {
                mapView
            } else {
                listView
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showMap)
    }

    // MARK: - List View

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Search bar
                searchBarSection
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                // Filter chips + sort + map toggle
                controlsRow
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)

                // Result count
                if !searchText.isEmpty || activeFilter != .all {
                    HStack {
                        Text("\(filteredVenues.count) court\(filteredVenues.count == 1 ? "" : "s") found")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                }

                if filteredVenues.isEmpty {
                    emptyState
                        .padding(.top, 60)
                } else {
                    ForEach(Array(filteredVenues.enumerated()), id: \.element.id) { index, venue in
                        NavigationLink(destination: CourtDetailView(venue: venue)) {
                            CourtListRow(
                                venue: venue,
                                distanceLabel: CourtListMock.distance(for: venue.id),
                                openCount: CourtListMock.openCourts(for: venue.id),
                                totalCount: venue.courtCount
                            )
                            .padding(.horizontal, 16)
                            .padding(.bottom, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer(minLength: 32)
            }
        }
        .background(Color.appBackground)
        .refreshable {
            // Simulate refresh
            try? await Task.sleep(nanoseconds: 600_000_000)
        }
    }

    // MARK: - Map View

    private var mapView: some View {
        ZStack(alignment: .top) {
            NearbyCourtMapView()

            // Map overlay controls
            HStack {
                searchBarSection
                    .frame(maxWidth: .infinity)

                mapToggleButton(isMap: true)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    // MARK: - Search Bar

    private var searchBarSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.secondary)
            TextField("Search courts or addresses…", text: $searchText)
                .font(.subheadline)
                .foregroundStyle(Color.primary)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.dinkrNavy.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Controls Row (filter chips + sort + map toggle)

    private var controlsRow: some View {
        HStack(spacing: 0) {
            // Horizontally scrolling filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(CourtFilter.allCases) { filter in
                        filterChip(filter)
                    }
                }
                .padding(.trailing, 8)
            }

            Divider()
                .frame(height: 24)
                .padding(.horizontal, 8)

            // Sort menu
            Menu {
                ForEach(CourtSortMode.allCases) { mode in
                    Button {
                        sortMode = mode
                    } label: {
                        Label(mode.rawValue, systemImage: mode.icon)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 11, weight: .semibold))
                    Text(sortMode.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(Color.dinkrNavy)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.dinkrNavy.opacity(0.07), in: Capsule())
            }

            // Map / List toggle
            mapToggleButton(isMap: false)
                .padding(.leading, 6)
        }
    }

    @ViewBuilder
    private func filterChip(_ filter: CourtFilter) -> some View {
        let isActive = activeFilter == filter
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                activeFilter = filter
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: filter.icon)
                    .font(.system(size: 10, weight: isActive ? .bold : .regular))
                Text(filter.rawValue)
                    .font(.system(size: 12, weight: isActive ? .bold : .regular))
            }
            .foregroundStyle(isActive ? .white : Color.secondary)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(
                isActive ? Color.dinkrGreen : Color.clear,
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isActive ? Color.clear : Color.secondary.opacity(0.25),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func mapToggleButton(isMap: Bool) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                showMap.toggle()
            }
        } label: {
            Image(systemName: showMap ? "list.bullet" : "map")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.dinkrGreen)
                .frame(width: 34, height: 34)
                .background(Color.dinkrGreen.opacity(0.10), in: Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.dinkrSky.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "mappin.slash")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.dinkrSky)
            }
            Text("No courts found")
                .font(.headline)
                .foregroundStyle(Color.dinkrNavy)
            Text("Try adjusting your search or filters.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                searchText = ""
                activeFilter = .all
            } label: {
                Text("Clear Filters")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dinkrGreen)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.dinkrGreen.opacity(0.10), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - CourtListRow

struct CourtListRow: View {
    let venue: CourtVenue
    let distanceLabel: String
    let openCount: Int
    let totalCount: Int

    @State private var showBooking = false
    @State private var showReview = false

    private var isOpen: Bool {
        !venue.openPlaySchedule.lowercased().contains("closed")
    }

    private var availabilityColor: Color {
        let ratio = Double(openCount) / Double(max(totalCount, 1))
        if ratio > 0.5 { return Color.dinkrGreen }
        if ratio > 0.2 { return Color.dinkrAmber }
        return Color.dinkrCoral
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Top row ──────────────────────────────────────────────
            HStack(alignment: .top, spacing: 12) {

                // Court icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.dinkrSky.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.dinkrSky)
                }

                // Name + address + rating
                VStack(alignment: .leading, spacing: 3) {
                    Text(venue.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.dinkrNavy)
                        .lineLimit(1)

                    Text(venue.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        StarRatingDisplay(rating: venue.rating, size: 11)
                        Text(String(format: "%.1f", venue.rating))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrAmber)
                        Text("(\(venue.reviewCount))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 4)

                // Distance + Open/Closed badges (right column)
                VStack(alignment: .trailing, spacing: 5) {
                    Text(distanceLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.dinkrNavy.opacity(0.07), in: Capsule())

                    Text(isOpen ? "Open" : "Closed")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(isOpen ? Color.dinkrGreen : Color.dinkrCoral, in: Capsule())
                }
            }

            // ── Chips row ─────────────────────────────────────────────
            HStack(spacing: 6) {
                // Surface badge
                surfaceBadge

                // Indoor / Outdoor badge
                indoorBadge

                // Lit badge
                if venue.hasLighting {
                    CourtBadge(icon: "flashlight.on.fill", label: "Lit", color: Color.dinkrAmber)
                }

                Spacer()

                // Available courts count
                availabilityBadge
            }
            .padding(.top, 10)

            // ── Quick action buttons ───────────────────────────────────
            HStack(spacing: 8) {
                // Navigate
                CourtActionButton(
                    icon: "arrow.triangle.turn.up.right.circle.fill",
                    label: "Navigate",
                    foreground: Color.dinkrGreen,
                    background: Color.dinkrGreen.opacity(0.10)
                ) {
                    openInMaps(venue)
                }

                // Book
                CourtActionButton(
                    icon: "calendar.badge.plus",
                    label: "Book",
                    foreground: Color.dinkrNavy,
                    background: Color.dinkrNavy.opacity(0.07)
                ) {
                    showBooking = true
                }

                // Review
                CourtActionButton(
                    icon: "star.bubble",
                    label: "Review",
                    foreground: Color.dinkrCoral,
                    background: Color.dinkrCoral.opacity(0.08)
                ) {
                    showReview = true
                }
            }
            .padding(.top, 10)
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showBooking) {
            CourtBookingView(courtName: venue.name)
        }
        .sheet(isPresented: $showReview) {
            WriteCourtReviewView(court: venue) { _ in }
        }
    }

    // MARK: Badges

    private var surfaceBadge: some View {
        let (label, color) = surfaceLabelAndColor(venue.surface)
        return CourtBadge(icon: "rays", label: label, color: color)
    }

    private var indoorBadge: some View {
        CourtBadge(
            icon: venue.isIndoor ? "building.2" : "sun.max",
            label: venue.isIndoor ? "Indoor" : "Outdoor",
            color: venue.isIndoor ? Color.dinkrSky : Color.dinkrGreen
        )
    }

    private var availabilityBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(availabilityColor)
                .frame(width: 6, height: 6)
            Text("\(openCount)/\(totalCount) available")
                .font(.caption.weight(.semibold))
                .foregroundStyle(availabilityColor)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(availabilityColor.opacity(0.10), in: Capsule())
    }

    // MARK: Helpers

    private func surfaceLabelAndColor(_ surface: CourtSurface) -> (String, Color) {
        switch surface {
        case .hardcourt: return ("Hardcourt", Color.dinkrSky)
        case .concrete:  return ("Concrete", Color.secondary)
        case .asphalt:   return ("Asphalt", Color.secondary)
        case .indoor:    return ("Indoor", Color.dinkrSky)
        case .clay:      return ("Clay", Color.dinkrAmber)
        }
    }

    private func openInMaps(_ venue: CourtVenue) {
        let coord = venue.coordinates.clLocation
        let item = MKMapItem(placemark: MKPlacemark(coordinate: coord))
        item.name = venue.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

// MARK: - CourtBadge

private struct CourtBadge: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
            Text(label)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.10), in: Capsule())
    }
}

// MARK: - CourtActionButton

private struct CourtActionButton: View {
    let icon: String
    let label: String
    let foreground: Color
    let background: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(background, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - CourtListMock (extended mock data)

enum CourtListMock {
    /// Superset of CourtVenue.mockVenues with additional entries for a richer list.
    static let venues: [CourtVenue] = CourtVenue.mockVenues + [
        CourtVenue(
            id: "court_004",
            name: "Barton Creek Greenbelt Courts",
            address: "3755 S Capital of Texas Hwy, Austin, TX 78704",
            coordinates: GeoPoint(latitude: 30.2310, longitude: -97.8003),
            courtCount: 8,
            surface: .hardcourt,
            hasLighting: false,
            isIndoor: false,
            openPlaySchedule: "Daily 7am–7pm",
            amenities: ["Restrooms", "Parking", "Water Fountains"],
            rating: 4.2,
            reviewCount: 112,
            websiteURL: nil,
            phoneNumber: nil
        ),
        CourtVenue(
            id: "court_005",
            name: "North Loop Indoor Sports",
            address: "7500 N Loop Blvd, Austin, TX 78751",
            coordinates: GeoPoint(latitude: 30.3411, longitude: -97.7205),
            courtCount: 10,
            surface: .indoor,
            hasLighting: true,
            isIndoor: true,
            openPlaySchedule: "Mon–Fri 5:30am–11pm, Sat–Sun 7am–10pm",
            amenities: ["Locker Rooms", "Pro Shop", "Coaching", "Gym", "Restrooms", "Parking"],
            rating: 4.8,
            reviewCount: 307,
            websiteURL: nil,
            phoneNumber: "512-555-0505"
        ),
        CourtVenue(
            id: "court_006",
            name: "Zilker Park Pickleball",
            address: "2100 Barton Springs Rd, Austin, TX 78746",
            coordinates: GeoPoint(latitude: 30.2634, longitude: -97.7685),
            courtCount: 6,
            surface: .concrete,
            hasLighting: true,
            isIndoor: false,
            openPlaySchedule: "Daily 6am–10pm",
            amenities: ["Restrooms", "Parking", "Water Fountains"],
            rating: 4.5,
            reviewCount: 189,
            websiteURL: nil,
            phoneNumber: nil
        ),
        CourtVenue(
            id: "court_007",
            name: "Domain Athletic Club",
            address: "11601 Century Oaks Terrace, Austin, TX 78758",
            coordinates: GeoPoint(latitude: 30.4014, longitude: -97.7241),
            courtCount: 4,
            surface: .indoor,
            hasLighting: true,
            isIndoor: true,
            openPlaySchedule: "Closed — Members Only",
            amenities: ["Locker Rooms", "Parking", "Gym", "Pro Shop"],
            rating: 3.9,
            reviewCount: 54,
            websiteURL: nil,
            phoneNumber: "512-555-0707"
        ),
        CourtVenue(
            id: "court_008",
            name: "East Austin Community Park",
            address: "979 Springdale Rd, Austin, TX 78702",
            coordinates: GeoPoint(latitude: 30.2705, longitude: -97.6952),
            courtCount: 4,
            surface: .asphalt,
            hasLighting: false,
            isIndoor: false,
            openPlaySchedule: "Daily sunrise–sunset",
            amenities: ["Parking"],
            rating: 3.6,
            reviewCount: 41,
            websiteURL: nil,
            phoneNumber: nil
        ),
    ]

    /// Mock distances keyed by court ID.
    static func distance(for id: String) -> String {
        let table: [String: String] = [
            "court_001": "0.4 mi",
            "court_002": "1.2 mi",
            "court_003": "0.8 mi",
            "court_004": "2.1 mi",
            "court_005": "3.5 mi",
            "court_006": "1.6 mi",
            "court_007": "5.2 mi",
            "court_008": "4.0 mi",
        ]
        return table[id] ?? "—"
    }

    /// Mock open-court counts keyed by court ID.
    static func openCourts(for id: String) -> Int {
        let table: [String: Int] = [
            "court_001": 8,
            "court_002": 2,
            "court_003": 4,
            "court_004": 5,
            "court_005": 7,
            "court_006": 3,
            "court_007": 0,
            "court_008": 4,
        ]
        return table[id] ?? 0
    }
}

// MARK: - Preview

#Preview("Court List — default") {
    NavigationStack {
        CourtListView(venues: [])
    }
}

#Preview("Court List — with venues") {
    NavigationStack {
        CourtListView(venues: CourtVenue.mockVenues)
    }
}

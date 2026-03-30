import SwiftUI
import MapKit
import CoreLocation

// MARK: - CourtMapViewModel

@Observable
final class CourtMapViewModel {
    var venues: [CourtVenue] = []
    var selectedVenue: CourtVenue?
    var userLocation: CLLocationCoordinate2D?
    var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    var searchRadius: Double = 10
    var showList: Bool = false
    var isLoading: Bool = false

    func load() async {
        isLoading = true
        defer { isLoading = false }
        // Firestore fetch would go here; falls back to mock data
        venues = CourtVenue.mockVenues
    }

    func openInMaps(_ venue: CourtVenue) {
        let coord = venue.coordinates.clLocation
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coord))
        mapItem.name = venue.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    func openInGoogleMaps(_ venue: CourtVenue) {
        let coord = venue.coordinates.clLocation
        let urlString = "comgooglemaps://?daddr=\(coord.latitude),\(coord.longitude)&directionsmode=driving"
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Fallback to Google Maps web
            let webString = "https://www.google.com/maps/dir/?api=1&destination=\(coord.latitude),\(coord.longitude)"
            if let webURL = URL(string: webString) {
                UIApplication.shared.open(webURL)
            }
        }
    }
}

// MARK: - CourtDiscoveryView

struct CourtDiscoveryView: View {
    // Accepts venues from PlayViewModel but owns its own map VM
    let venues: [CourtVenue]

    @State private var vm = CourtMapViewModel()
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    @State private var showVenueSheet = false

    var body: some View {
        ZStack(alignment: .top) {
            if vm.showList {
                listContent
            } else {
                mapContent
            }

            // Toggle — top-right overlay
            viewToggle
                .padding(.top, 8)
                .padding(.trailing, 12)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .task {
            // Seed from parent if available, otherwise load
            if !venues.isEmpty {
                vm.venues = venues
            } else {
                await vm.load()
            }
        }
    }

    // MARK: Map Content

    private var mapContent: some View {
        ZStack(alignment: .bottom) {
            Map(position: $mapPosition) {
                UserAnnotation()
                ForEach(vm.venues) { venue in
                    Annotation(venue.name, coordinate: venue.coordinates.clLocation) {
                        VenueAnnotationPin(
                            venue: venue,
                            isSelected: vm.selectedVenue?.id == venue.id
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                vm.selectedVenue = venue
                                showVenueSheet = true
                            }
                        }
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea(edges: .bottom)

            // Bottom sheet when venue selected
            if let venue = vm.selectedVenue, showVenueSheet {
                VenueDetailCard(
                    venue: venue,
                    onDismiss: {
                        withAnimation(.spring(response: 0.3)) {
                            showVenueSheet = false
                            vm.selectedVenue = nil
                        }
                    },
                    onDirections: { vm.openInMaps(venue) }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
            }
        }
    }

    // MARK: List Content

    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(vm.venues) { venue in
                    NavigationLink(destination: CourtDetailView(venue: venue)) {
                        CourtVenueRow(
                            venue: venue,
                            onDirections: { vm.openInMaps(venue) }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 52) // offset for toggle bar
            .padding(.bottom, 24)
        }
        .background(Color.appBackground)
    }

    // MARK: Toggle

    private var viewToggle: some View {
        Picker("View", selection: $vm.showList) {
            Label("Map", systemImage: "map").tag(false)
            Label("List", systemImage: "list.bullet").tag(true)
        }
        .pickerStyle(.segmented)
        .frame(width: 160)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - VenueAnnotationPin

private struct VenueAnnotationPin: View {
    let venue: CourtVenue
    let isSelected: Bool

    private var pinColor: Color {
        // Use dinkrCoral if closed (simple heuristic: schedule contains "closed" keyword)
        venue.openPlaySchedule.lowercased().contains("closed") ? Color.dinkrCoral : Color.dinkrGreen
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(pinColor)
                    .frame(width: isSelected ? 42 : 34, height: isSelected ? 42 : 34)
                    .shadow(color: pinColor.opacity(0.4), radius: isSelected ? 6 : 3, y: 2)
                Image(systemName: "sportscourt")
                    .font(.system(size: isSelected ? 18 : 15, weight: .bold))
                    .foregroundStyle(.white)
            }
            if isSelected {
                Text(venue.name)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.dinkrNavy)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

// MARK: - VenueDetailCard (bottom sheet)

struct VenueDetailCard: View {
    let venue: CourtVenue
    let onDismiss: () -> Void
    let onDirections: () -> Void

    private var isOpen: Bool {
        !venue.openPlaySchedule.lowercased().contains("closed")
    }

    private var amenityIcons: [(String, String)] {
        var result: [(String, String)] = []
        if venue.hasLighting { result.append(("flashlight.on.fill", "Lights")) }
        if venue.isIndoor { result.append(("building.2.fill", "Covered")) }
        if venue.amenities.contains("Restrooms") { result.append(("figure.walk", "Restrooms")) }
        if venue.amenities.contains("Parking") { result.append(("car.fill", "Parking")) }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color(UIColor.systemGray4))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 14)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(venue.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.dinkrNavy)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        StarRatingDisplay(rating: venue.rating, size: 13)
                        Text(String(format: "%.1f", venue.rating))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrNavy)
                        Text("(\(venue.reviewCount))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color(UIColor.systemGray3))
                }
            }
            .padding(.horizontal, 20)

            Divider().padding(.vertical, 12)

            // Address row
            Label(venue.address, systemImage: "mappin.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            // Hours
            HStack(spacing: 6) {
                Image(systemName: isOpen ? "clock.fill" : "clock.badge.xmark.fill")
                    .foregroundStyle(isOpen ? Color.dinkrGreen : Color.dinkrCoral)
                    .font(.subheadline)
                Text(isOpen ? "Open · \(venue.openPlaySchedule)" : "Closed")
                    .font(.subheadline)
                    .foregroundStyle(isOpen ? Color.dinkrGreen : Color.dinkrCoral)
                    .lineLimit(1)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            // Amenity pills
            if !amenityIcons.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(amenityIcons, id: \.0) { icon, label in
                            HStack(spacing: 4) {
                                Image(systemName: icon)
                                    .font(.caption.weight(.semibold))
                                Text(label)
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundStyle(Color.dinkrSky)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.dinkrSky.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 16)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: onDirections) {
                    Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.dinkrGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                NavigationLink(destination: CourtDetailView(venue: venue)) {
                    Text("View Details")
                        .font(.subheadline.weight(.semibold))
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
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color.appBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 20, y: -4)
        .padding(.horizontal, 0)
    }
}

// MARK: - CourtVenueRow (list view)

struct CourtVenueRow: View {
    let venue: CourtVenue
    let onDirections: () -> Void

    private var isOpen: Bool {
        !venue.openPlaySchedule.lowercased().contains("closed")
    }

    private var amenityIconList: [String] {
        var icons: [String] = []
        if venue.hasLighting { icons.append("flashlight.on.fill") }
        if venue.isIndoor { icons.append("building.2.fill") }
        if venue.amenities.contains("Restrooms") { icons.append("figure.walk") }
        if venue.amenities.contains("Parking") { icons.append("car.fill") }
        if venue.amenities.contains("Pro Shop") { icons.append("bag.fill") }
        return icons
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(Color.dinkrSky.opacity(0.15))
                        .frame(width: 46, height: 46)
                    Image(systemName: "sportscourt")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.dinkrSky)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(venue.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)
                        .lineLimit(1)

                    Text(venue.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        StarRatingDisplay(rating: venue.rating, size: 11)
                        Text(String(format: "%.1f", venue.rating))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrAmber)
                        Text("(\(venue.reviewCount))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    // Distance mock
                    Text("0.8 mi")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.dinkrNavy.opacity(0.07))
                        .clipShape(Capsule())

                    // Open/Closed badge
                    Text(isOpen ? "Open" : "Closed")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(isOpen ? Color.dinkrGreen : Color.dinkrCoral)
                        .clipShape(Capsule())
                }
            }

            // Amenity icons row
            if !amenityIconList.isEmpty {
                HStack(spacing: 10) {
                    ForEach(amenityIconList, id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundStyle(Color.dinkrSky)
                    }
                    Spacer()

                    // Directions button
                    Button(action: onDirections) {
                        Label("Directions", systemImage: "arrow.triangle.turn.up.right.circle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Preview

#Preview("Court Discovery - Map") {
    NavigationStack {
        CourtDiscoveryView(venues: CourtVenue.mockVenues)
    }
}

#Preview("Court Discovery - List") {
    NavigationStack {
        CourtDiscoveryView(venues: CourtVenue.mockVenues)
    }
}

#Preview("Venue Detail Card") {
    ZStack(alignment: .bottom) {
        Color.gray.opacity(0.2).ignoresSafeArea()
        VenueDetailCard(
            venue: CourtVenue.mockVenues[0],
            onDismiss: {},
            onDirections: {}
        )
    }
}

#Preview("Court Venue Row") {
    CourtVenueRow(venue: CourtVenue.mockVenues[0], onDirections: {})
        .padding()
}

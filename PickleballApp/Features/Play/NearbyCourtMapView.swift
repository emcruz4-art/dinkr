import SwiftUI
import MapKit

// MARK: - Mock Court Data

private struct MockCourt: Identifiable {
    let id: String
    let name: String
    let address: String
    let surface: CourtSurface
    let isBusy: Bool
    let coordinate: CLLocationCoordinate2D
    let courtCount: Int
    let hasLighting: Bool
}

private let mockCourts: [MockCourt] = [
    MockCourt(
        id: "mc_001",
        name: "Westside Pickleball Complex",
        address: "4501 W 35th St, Austin, TX",
        surface: .hardcourt,
        isBusy: true,
        coordinate: CLLocationCoordinate2D(latitude: 30.2889, longitude: -97.7681),
        courtCount: 12,
        hasLighting: true
    ),
    MockCourt(
        id: "mc_002",
        name: "Mueller Recreation Center",
        address: "4730 Mueller Blvd, Austin, TX",
        surface: .hardcourt,
        isBusy: false,
        coordinate: CLLocationCoordinate2D(latitude: 30.3042, longitude: -97.7024),
        courtCount: 6,
        hasLighting: true
    ),
    MockCourt(
        id: "mc_003",
        name: "South Lamar Sports Club",
        address: "1600 S Lamar Blvd, Austin, TX",
        surface: .indoor,
        isBusy: false,
        coordinate: CLLocationCoordinate2D(latitude: 30.2473, longitude: -97.7528),
        courtCount: 4,
        hasLighting: true
    ),
    MockCourt(
        id: "mc_004",
        name: "Barton Creek Greenbelt Courts",
        address: "3755 S Capital of Texas Hwy, Austin, TX",
        surface: .concrete,
        isBusy: true,
        coordinate: CLLocationCoordinate2D(latitude: 30.2318, longitude: -97.7985),
        courtCount: 3,
        hasLighting: false
    ),
    MockCourt(
        id: "mc_005",
        name: "North Loop Community Park",
        address: "910 E 51st St, Austin, TX",
        surface: .asphalt,
        isBusy: false,
        coordinate: CLLocationCoordinate2D(latitude: 30.3195, longitude: -97.7102),
        courtCount: 2,
        hasLighting: false
    ),
]

private let austinCenter = CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431)
private let defaultRegion = MKCoordinateRegion(
    center: austinCenter,
    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
)

// MARK: - NearbyCourtMapView

struct NearbyCourtMapView: View {
    // Camera / position state
    @State private var cameraPosition: MapCameraPosition = .region(defaultRegion)
    @State private var visibleRegionCenter: CLLocationCoordinate2D? = nil

    // Selection + UI state
    @State private var selectedCourt: MockCourt? = nil
    @State private var mapStyle: MapStyleMode = .standard
    @State private var searchText: String = ""
    @State private var showRecenter: Bool = false

    // Book sheet
    @State private var showBookSheet: Bool = false

    // MARK: Filtered courts

    private var filteredCourts: [MockCourt] {
        guard !searchText.isEmpty else { return mockCourts }
        return mockCourts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: Body

    var body: some View {
        ZStack(alignment: .top) {
            mapLayer
            searchOverlay
        }
        .safeAreaInset(edge: .bottom) {
            bottomContent
        }
        .sheet(isPresented: $showBookSheet) {
            if let court = selectedCourt {
                BookingStubSheet(court: court)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: Map Layer

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            ForEach(filteredCourts) { court in
                Annotation(court.name, coordinate: court.coordinate) {
                    CourtMapPin(
                        court: court,
                        isSelected: selectedCourt?.id == court.id
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                            if selectedCourt?.id == court.id {
                                selectedCourt = nil
                            } else {
                                selectedCourt = court
                            }
                        }
                    }
                }
            }
            UserAnnotation()
        }
        .mapStyle(mapStyle == .standard ? .standard : .hybrid)
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange { context in
            let center = context.region.center
            let dist = distance(from: center, to: austinCenter)
            showRecenter = dist > 4000 // show recenter when >4 km from default center
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                // Recenter button
                if showRecenter {
                    Button {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            cameraPosition = .region(defaultRegion)
                            showRecenter = false
                        }
                    } label: {
                        Label("Recenter", systemImage: "location.fill")
                            .labelStyle(.iconOnly)
                    }
                    .tint(Color.dinkrGreen)
                }

                // Map style toggle
                Button {
                    withAnimation {
                        mapStyle = mapStyle == .standard ? .hybrid : .standard
                    }
                } label: {
                    Label(
                        mapStyle == .standard ? "Hybrid" : "Standard",
                        systemImage: mapStyle == .standard ? "globe.americas.fill" : "map"
                    )
                    .labelStyle(.iconOnly)
                }
                .tint(Color.dinkrGreen)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: Search Overlay

    private var searchOverlay: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.secondary)
                .font(.subheadline)
            TextField("Search courts…", text: $searchText)
                .font(.subheadline)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.secondary)
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: Bottom Content

    @ViewBuilder
    private var bottomContent: some View {
        if let court = selectedCourt {
            CourtBottomCard(
                court: court,
                onDismiss: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCourt = nil
                    }
                },
                onBook: {
                    showBookSheet = true
                },
                onDirections: {
                    openDirections(to: court)
                }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.35, dampingFraction: 0.78), value: selectedCourt?.id)
        }
    }

    // MARK: Helpers

    private func openDirections(to court: MockCourt) {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: court.coordinate))
        mapItem.name = court.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func distance(
        from a: CLLocationCoordinate2D,
        to b: CLLocationCoordinate2D
    ) -> Double {
        let locA = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let locB = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return locA.distance(from: locB)
    }
}

// MARK: - Map Style Mode

private enum MapStyleMode {
    case standard, hybrid
}

// MARK: - CourtMapPin

private struct CourtMapPin: View {
    let court: MockCourt
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen)
                    .frame(
                        width: isSelected ? 46 : 36,
                        height: isSelected ? 46 : 36
                    )
                    .shadow(
                        color: Color.dinkrGreen.opacity(isSelected ? 0.55 : 0.3),
                        radius: isSelected ? 8 : 4,
                        y: 2
                    )

                Image(systemName: "figure.pickleball")
                    .font(.system(size: isSelected ? 20 : 15, weight: .bold))
                    .foregroundStyle(.white)
            }

            if isSelected {
                Text(court.name)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial, in: Capsule())
                    .fixedSize()
            }
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - CourtBottomCard

private struct CourtBottomCard: View {
    let court: MockCourt
    let onDismiss: () -> Void
    let onBook: () -> Void
    let onDirections: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color(UIColor.systemGray4))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 14)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(court.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        // Surface badge
                        Text(court.surface.rawValue.capitalized)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrSky)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.dinkrSky.opacity(0.12))
                            .clipShape(Capsule())

                        // Busy / Open indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(court.isBusy ? Color.dinkrCoral : Color.dinkrGreen)
                                .frame(width: 6, height: 6)
                            Text(court.isBusy ? "Busy" : "Open")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(court.isBusy ? Color.dinkrCoral : Color.dinkrGreen)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            (court.isBusy ? Color.dinkrCoral : Color.dinkrGreen).opacity(0.1)
                        )
                        .clipShape(Capsule())
                    }

                    // Address
                    Label(court.address, systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color(UIColor.systemGray3))
                }
            }
            .padding(.horizontal, 20)

            // Court count + lighting
            HStack(spacing: 12) {
                Label("\(court.courtCount) courts", systemImage: "sportscourt")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if court.hasLighting {
                    Label("Lit", systemImage: "flashlight.on.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 16)

            // Action buttons
            HStack(spacing: 12) {
                Button(action: onBook) {
                    Label("Book", systemImage: "calendar.badge.plus")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.dinkrGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button(action: onDirections) {
                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.dinkrNavy.opacity(0.2), lineWidth: 1.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .background(Color.appBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 20, y: -4)
    }
}

// MARK: - BookingStubSheet

private struct BookingStubSheet: View {
    let court: MockCourt
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 54, weight: .light))
                    .foregroundStyle(Color.dinkrGreen)

                VStack(spacing: 6) {
                    Text("Book a Court")
                        .font(.title2.weight(.bold))
                    Text(court.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Text("Online booking coming soon. Call the venue or visit their website to reserve a court.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button {
                    dismiss()
                } label: {
                    Text("Got it")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.dinkrGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(UIColor.systemGray3))
                            .font(.title2)
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.45)])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview("Nearby Court Map") {
    NavigationStack {
        NearbyCourtMapView()
            .navigationTitle("Courts")
            .navigationBarTitleDisplayMode(.inline)
    }
}

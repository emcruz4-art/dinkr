import SwiftUI
import MapKit

// MARK: - FavoriteCourt Model

struct FavoriteCourt: Identifiable, Equatable {
    let id: String
    let name: String
    let address: String
    let surface: CourtSurface
    let hasLighting: Bool
    let isIndoor: Bool
    let rating: Double
    let reviewCount: Int
    let courtCount: Int
    let distanceMiles: Double
    let coordinate: CLLocationCoordinate2D
    var occupancyStatus: CourtOccupancy

    static func == (lhs: FavoriteCourt, rhs: FavoriteCourt) -> Bool {
        lhs.id == rhs.id
    }
}

enum CourtOccupancy {
    case open, busy, full

    var label: String {
        switch self {
        case .open: return "Open"
        case .busy: return "Getting Busy"
        case .full: return "Full"
        }
    }

    var color: Color {
        switch self {
        case .open: return Color.dinkrGreen
        case .busy: return Color.dinkrAmber
        case .full: return Color.dinkrCoral
        }
    }

    var icon: String {
        switch self {
        case .open: return "checkmark.circle.fill"
        case .busy: return "exclamationmark.circle.fill"
        case .full: return "xmark.circle.fill"
        }
    }
}

// MARK: - Mock Favorite Courts

extension FavoriteCourt {
    static let mockFavorites: [FavoriteCourt] = [
        FavoriteCourt(
            id: "fav_001",
            name: "Westside Pickleball Complex",
            address: "4501 W 35th St, Austin, TX",
            surface: .hardcourt,
            hasLighting: true,
            isIndoor: false,
            rating: 4.7,
            reviewCount: 234,
            courtCount: 12,
            distanceMiles: 1.2,
            coordinate: CLLocationCoordinate2D(latitude: 30.2889, longitude: -97.7681),
            occupancyStatus: .busy
        ),
        FavoriteCourt(
            id: "fav_002",
            name: "Mueller Recreation Center",
            address: "4730 Mueller Blvd, Austin, TX",
            surface: .hardcourt,
            hasLighting: true,
            isIndoor: false,
            rating: 4.4,
            reviewCount: 178,
            courtCount: 6,
            distanceMiles: 2.8,
            coordinate: CLLocationCoordinate2D(latitude: 30.3042, longitude: -97.7024),
            occupancyStatus: .open
        ),
        FavoriteCourt(
            id: "fav_003",
            name: "South Lamar Sports Club",
            address: "1600 S Lamar Blvd, Austin, TX",
            surface: .indoor,
            hasLighting: true,
            isIndoor: true,
            rating: 4.9,
            reviewCount: 89,
            courtCount: 4,
            distanceMiles: 3.5,
            coordinate: CLLocationCoordinate2D(latitude: 30.2473, longitude: -97.7528),
            occupancyStatus: .full
        ),
        FavoriteCourt(
            id: "fav_004",
            name: "Barton Springs Athletic Park",
            address: "2201 Barton Springs Rd, Austin, TX",
            surface: .concrete,
            hasLighting: false,
            isIndoor: false,
            rating: 4.2,
            reviewCount: 56,
            courtCount: 3,
            distanceMiles: 4.1,
            coordinate: CLLocationCoordinate2D(latitude: 30.2639, longitude: -97.7704),
            occupancyStatus: .open
        ),
        FavoriteCourt(
            id: "fav_005",
            name: "North Austin Pickleball Club",
            address: "9901 Burnet Rd, Austin, TX",
            surface: .hardcourt,
            hasLighting: true,
            isIndoor: false,
            rating: 4.6,
            reviewCount: 112,
            courtCount: 8,
            distanceMiles: 6.3,
            coordinate: CLLocationCoordinate2D(latitude: 30.3905, longitude: -97.7203),
            occupancyStatus: .open
        )
    ]
}

// MARK: - FavoriteCourtListView

struct FavoriteCourtListView: View {
    @State private var favorites: [FavoriteCourt] = FavoriteCourt.mockFavorites
    @State private var showMap = false
    @State private var showBooking = false
    @State private var bookingCourtName = ""
    @State private var editMode: EditMode = .inactive
    @State private var removingID: String? = nil

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if favorites.isEmpty {
                emptyState
            } else {
                courtList
            }
        }
        .navigationTitle("My Courts")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 4) {
                    EditButton()
                        .tint(Color.dinkrGreen)
                    Button {
                        showMap = true
                    } label: {
                        Image(systemName: "map.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                }
            }
        }
        .environment(\.editMode, $editMode)
        .sheet(isPresented: $showMap) {
            NearbyCourtMapView()
        }
        .sheet(isPresented: $showBooking) {
            CourtBookingView(courtName: bookingCourtName)
        }
    }

    // MARK: - Court List

    private var courtList: some View {
        List {
            ForEach($favorites) { $court in
                NavigationLink(destination: CourtDetailView(venue: CourtVenue.mockVenues.first(where: { $0.id == court.id.replacingOccurrences(of: "fav_", with: "court_") }) ?? CourtVenue.mockVenues[0])) {
                    FavoriteCourtRow(court: court)
                }
                .listRowBackground(Color.cardBackground)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        removeFavorite(court)
                    } label: {
                        Label("Unfavorite", systemImage: "star.slash.fill")
                    }
                    .tint(Color.dinkrAmber)
                }
                .contextMenu {
                    Button {
                        openDirections(for: court)
                    } label: {
                        Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                    }

                    Button {
                        bookingCourtName = court.name
                        showBooking = true
                    } label: {
                        Label("Book a Court", systemImage: "calendar.badge.plus")
                    }

                    Divider()

                    Button(role: .destructive) {
                        removeFavorite(court)
                    } label: {
                        Label("Unfavorite", systemImage: "star.slash.fill")
                    }
                }
            }
            .onMove { source, destination in
                favorites.move(fromOffsets: source, toOffset: destination)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.10))
                    .frame(width: 96, height: 96)
                Image(systemName: "star.slash")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Color.dinkrGreen.opacity(0.6))
            }

            VStack(spacing: 8) {
                Text("No favorite courts yet.")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.dinkrNavy)
                Text("Explore courts to add some! 🏓")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showMap = true
            } label: {
                Label("Explore Courts", systemImage: "map.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 13)
                    .background(Color.dinkrGreen)
                    .clipShape(Capsule())
                    .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 8, y: 4)
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Helpers

    private func removeFavorite(_ court: FavoriteCourt) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            favorites.removeAll { $0.id == court.id }
        }
        HapticManager.selection()
    }

    private func openDirections(for court: FavoriteCourt) {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: court.coordinate))
        mapItem.name = court.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - FavoriteCourtRow

private struct FavoriteCourtRow: View {
    let court: FavoriteCourt

    var body: some View {
        HStack(spacing: 12) {

            // Map thumbnail
            CourtMapThumbnail(coordinate: court.coordinate)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(court.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.dinkrNavy)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    SurfaceBadge(surface: court.surface)
                    Text("·")
                        .foregroundStyle(.secondary)
                        .font(.caption2)
                    Text(String(format: "%.1f mi", court.distanceMiles))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 6) {
                    StarMiniRow(rating: court.rating)
                    Text("(\(court.reviewCount))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            // Status + courts count
            VStack(alignment: .trailing, spacing: 6) {
                OccupancyBadge(status: court.occupancyStatus)
                Text("\(court.courtCount) courts")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - CourtMapThumbnail

private struct CourtMapThumbnail: View {
    let coordinate: CLLocationCoordinate2D

    @State private var mapPosition: MapCameraPosition

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self._mapPosition = State(initialValue: .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )))
    }

    var body: some View {
        Map(position: $mapPosition, interactionModes: []) {
            Annotation("", coordinate: coordinate) {
                Circle()
                    .fill(Color.dinkrGreen)
                    .frame(width: 10, height: 10)
                    .shadow(color: Color.dinkrGreen.opacity(0.5), radius: 3)
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .disabled(true)
        .allowsHitTesting(false)
    }
}

// MARK: - SurfaceBadge

private struct SurfaceBadge: View {
    let surface: CourtSurface

    private var color: Color {
        switch surface {
        case .hardcourt: return Color.dinkrSky
        case .concrete:  return Color.dinkrNavy.opacity(0.8)
        case .asphalt:   return .gray
        case .indoor:    return Color.dinkrAmber
        case .clay:      return Color.dinkrCoral
        }
    }

    private var label: String {
        switch surface {
        case .hardcourt: return "Hard"
        case .concrete:  return "Concrete"
        case .asphalt:   return "Asphalt"
        case .indoor:    return "Indoor"
        case .clay:      return "Clay"
        }
    }

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - OccupancyBadge

private struct OccupancyBadge: View {
    let status: CourtOccupancy

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption2.weight(.bold))
            Text(status.label)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(status.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - StarMiniRow

private struct StarMiniRow: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                let filled = Double(i) + 1.0 <= rating
                Image(systemName: filled ? "star.fill" : "star")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(filled ? Color.dinkrAmber : Color.secondary.opacity(0.4))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FavoriteCourtListView()
    }
}

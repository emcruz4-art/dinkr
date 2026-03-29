import SwiftUI
import MapKit

struct CourtDetailView: View {
    let venue: CourtVenue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Map
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: venue.coordinates.clLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))) {
                    Marker(venue.name, coordinate: venue.coordinates.clLocation)
                        .tint(Color.pickleballGreen)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 16) {
                    // Rating + review count
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill").foregroundStyle(.yellow)
                            Text(String(format: "%.1f", venue.rating)).font(.headline)
                            Text("(\(venue.reviewCount) reviews)").font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        PillTag(text: venue.isIndoor ? "Indoor" : "Outdoor")
                    }

                    // Address
                    Label(venue.address, systemImage: "mappin")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Stats
                    HStack(spacing: 16) {
                        StatChip(icon: "sportscourt", value: "\(venue.courtCount)", label: "Courts")
                        StatChip(icon: "rays", value: venue.surface.rawValue, label: "Surface")
                        if venue.hasLighting {
                            StatChip(icon: "lightbulb.fill", value: "Yes", label: "Lighting")
                        }
                    }

                    Divider()

                    // Schedule
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Open Play Schedule").font(.subheadline.weight(.semibold))
                        Text(venue.openPlaySchedule).font(.subheadline).foregroundStyle(.secondary)
                    }

                    // Amenities
                    if !venue.amenities.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amenities").font(.subheadline.weight(.semibold))
                            FlowLayout(spacing: 8) {
                                ForEach(venue.amenities, id: \.self) { amenity in
                                    PillTag(text: amenity, color: .courtBlue.opacity(0.1), textColor: .courtBlue)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(venue.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct StatChip: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.title3).foregroundStyle(Color.pickleballGreen)
            Text(value).font(.subheadline.weight(.semibold))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

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

#Preview {
    NavigationStack {
        CourtDetailView(venue: CourtVenue.mockVenues[0])
    }
}

import SwiftUI
import MapKit

struct EventDetailView: View {
    let event: Event

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Banner
                LinearGradient(colors: [.pickleballGreen, .courtBlue], startPoint: .leading, endPoint: .trailing)
                    .frame(height: 120)
                    .overlay {
                        VStack(spacing: 8) {
                            EventTypeBadge(type: event.type)
                            Text(event.title)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }

                VStack(alignment: .leading, spacing: 16) {
                    // Date / Location
                    HStack(spacing: 16) {
                        InfoChip(icon: "calendar", label: event.dateTime.shortDateString)
                        InfoChip(icon: "clock", label: event.dateTime.timeString)
                    }
                    Label(event.location, systemImage: "mappin.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Map if coordinates available
                    if let coords = event.coordinates {
                        Map(initialPosition: .region(MKCoordinateRegion(
                            center: coords.clLocation,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))) {
                            Marker(event.title, coordinate: coords.clLocation)
                                .tint(Color.pickleballGreen)
                        }
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Divider()

                    // Details
                    Text("About").font(.headline)
                    Text(event.description).font(.subheadline).foregroundStyle(.secondary)

                    // Stats row
                    HStack(spacing: 12) {
                        if let fee = event.entryFee {
                            StatChip(icon: "dollarsign.circle", value: String(format: "$%.0f", fee), label: "Entry")
                        }
                        if let max = event.maxParticipants {
                            StatChip(icon: "person.2", value: "\(event.currentParticipants)/\(max)", label: "Registered")
                        }
                        if let prize = event.prizePool {
                            StatChip(icon: "trophy", value: prize, label: "Prize Pool")
                        }
                    }

                    // Tags
                    if !event.tags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(event.tags, id: \.self) { tag in
                                PillTag(text: "#\(tag)")
                            }
                        }
                    }

                    // CTA
                    Button("Register / Learn More") {}
                        .primaryButton()
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TournamentView: View {
    var tournaments: [Event] { Event.mockEvents.filter { $0.type == .tournament } }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(tournaments) { event in
                    NavigationLink {
                        EventDetailView(event: event)
                    } label: {
                        EventCardView(event: event).padding(.horizontal)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Tournaments")
    }
}

#Preview {
    NavigationStack {
        EventDetailView(event: Event.mockEvents[0])
    }
}

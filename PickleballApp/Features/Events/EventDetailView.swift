import SwiftUI
import MapKit

struct EventDetailView: View {
    let event: Event
    @State private var showBracketBuilder = false

    private var mockBracket: Bracket? {
        Bracket.mock.eventId == event.id ? Bracket.mock : nil
    }

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

                    Divider()

                    // MARK: Bracket Section
                    bracketSection
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBracketBuilder) {
            BracketBuilderView()
        }
    }

    // MARK: - Bracket Section

    @ViewBuilder
    private var bracketSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bracket.square.fill")
                    .foregroundStyle(Color.dinkrGreen)
                Text("Bracket")
                    .font(.headline)
                Spacer()
            }

            if let bracket = mockBracket {
                // Condensed first-round preview
                let firstRound = bracket.rounds.first ?? []
                let previewMatches = Array(firstRound.prefix(4))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(previewMatches) { match in
                        compactMatchCard(match)
                    }
                }

                NavigationLink {
                    BracketView(bracket: bracket)
                } label: {
                    HStack {
                        Text("View Full Bracket")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("No bracket published yet.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }

            // Organizer: Create Bracket button
            Button {
                showBracketBuilder = true
            } label: {
                Label("Create Bracket", systemImage: "plus.circle")
            }
            .secondaryButton()
        }
    }

    // MARK: - Compact Match Card

    @ViewBuilder
    private func compactMatchCard(_ match: NewBracketMatch) -> some View {
        VStack(spacing: 0) {
            compactPlayerRow(
                name: match.participantAName ?? "TBD",
                score: match.scoreA,
                isWinner: match.isComplete && match.winnerId == match.participantAId,
                isTBD: match.participantAId == nil
            )
            Divider()
            compactPlayerRow(
                name: match.participantBName ?? "TBD",
                score: match.scoreB,
                isWinner: match.isComplete && match.winnerId == match.participantBId,
                isTBD: match.participantBId == nil
            )
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    @ViewBuilder
    private func compactPlayerRow(name: String, score: String, isWinner: Bool, isTBD: Bool) -> some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(isWinner ? Color.dinkrGreen : Color.clear)
                .frame(width: 3)
            Text(isTBD ? "TBD" : name)
                .font(.system(size: 11, weight: isWinner ? .bold : .regular))
                .foregroundStyle(isTBD ? Color.secondary : Color.primary)
                .lineLimit(1)
            Spacer(minLength: 2)
            if !score.isEmpty {
                Text(score)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isWinner ? Color.dinkrGreen : Color.secondary)
            }
        }
        .padding(.trailing, 6)
        .frame(height: 26)
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

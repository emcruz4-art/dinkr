import SwiftUI

struct EventCardView: View {
    let event: Event

    var registrationProgress: Double {
        guard let max = event.maxParticipants, max > 0 else { return 0 }
        return Double(event.currentParticipants) / Double(max)
    }

    var daysUntilDeadline: Int? {
        guard let deadline = event.registrationDeadline else { return nil }
        let diff = Calendar.current.dateComponents([.day], from: Date(), to: deadline)
        return diff.day
    }

    var body: some View {
        PickleballCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        // Type + Women Only badges
                        HStack(spacing: 6) {
                            Text(event.type.rawValue.capitalized)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(eventTypeColor)
                                .clipShape(Capsule())
                            if event.isWomenOnly {
                                Text("Women Only")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(.pink)
                                    .clipShape(Capsule())
                            }
                        }

                        Text(event.title)
                            .font(.headline.weight(.bold))
                            .lineLimit(2)
                    }
                    Spacer()

                    // Countdown chip
                    if let days = daysUntilDeadline {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(days) days left")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(days <= 3 ? Color.dinkrCoral : Color.dinkrAmber)
                                .clipShape(Capsule())
                        }
                    }
                }

                // Location + date
                HStack(spacing: 12) {
                    Label(event.location, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 12) {
                    Label(event.dateTime.formatted(.dateTime.weekday().month().day().hour().minute()),
                          systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    if let fee = event.entryFee {
                        Text(fee == 0 ? "Free" : "$\(Int(fee))")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(fee == 0 ? Color.dinkrGreen : Color.dinkrAmber)
                    }
                }

                // Registration progress bar
                if event.maxParticipants != nil {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(event.currentParticipants) registered")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if let max = event.maxParticipants {
                                Text("of \(max)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(eventTypeColor.opacity(0.15))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(eventTypeColor)
                                    .frame(width: geo.size.width * registrationProgress)
                            }
                        }
                        .frame(height: 5)
                    }
                }
            }
            .padding(14)
        }
    }

    var eventTypeColor: Color {
        switch event.type {
        case .tournament: return Color.dinkrCoral
        case .clinic: return Color.dinkrSky
        case .openPlay: return Color.dinkrGreen
        case .social: return Color.dinkrAmber
        case .womenOnly: return .pink
        case .fundraiser: return .purple
        }
    }
}

struct EventTypeBadge: View {
    let type: EventType

    var body: some View {
        Text(type.rawValue)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12), in: Capsule())
    }

    var color: Color {
        switch type {
        case .tournament: return Color.courtOrange
        case .clinic: return Color.courtBlue
        case .openPlay: return Color.pickleballGreen
        case .social: return .purple
        case .womenOnly: return .pink
        case .fundraiser: return .teal
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(Event.mockEvents) { event in
            EventCardView(event: event)
        }
    }
    .padding()
}

import SwiftUI

struct EventCardView: View {
    let event: Event
    @State private var isBookmarked: Bool = false

    // MARK: - Computed helpers

    var registrationProgress: Double {
        guard let max = event.maxParticipants, max > 0 else { return 0 }
        return Double(event.currentParticipants) / Double(max)
    }

    var daysUntilDeadline: Int? {
        guard let deadline = event.registrationDeadline else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: deadline).day
    }

    /// Days until the event itself starts (nil if in the past)
    var daysUntilEvent: Int? {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: event.dateTime).day ?? 0
        return days >= 0 ? days : nil
    }

    var eventTypeColor: Color {
        switch event.type {
        case .tournament: return Color.dinkrCoral
        case .clinic:     return Color.dinkrSky
        case .openPlay:   return Color.dinkrGreen
        case .social:     return Color.dinkrAmber
        case .womenOnly:  return .pink
        case .fundraiser: return .purple
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Gradient color accent banner (120pt) ──────────────────────
            ZStack(alignment: .bottomLeading) {
                // Base gradient using event type color
                LinearGradient(
                    colors: [eventTypeColor, eventTypeColor.opacity(0.55)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 120)

                // Subtle sport net/court pattern (~8% opacity)
                Canvas { context, size in
                    let lineColor = Color.white.opacity(0.08)
                    var path = Path()

                    let hSpacing: CGFloat = 18
                    var y: CGFloat = 0
                    while y <= size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        y += hSpacing
                    }

                    let vSpacing: CGFloat = 24
                    var x: CGFloat = 0
                    while x <= size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        x += vSpacing
                    }

                    var centerPath = Path()
                    centerPath.move(to: CGPoint(x: size.width / 2, y: 0))
                    centerPath.addLine(to: CGPoint(x: size.width / 2, y: size.height))

                    context.stroke(path, with: .color(lineColor), lineWidth: 0.8)
                    context.stroke(centerPath, with: .color(Color.white.opacity(0.12)), lineWidth: 1.5)
                }
                .frame(height: 120)

                // Bottom scrim for readability
                LinearGradient(
                    colors: [Color.black.opacity(0.0), Color.black.opacity(0.25)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)

                // Top-right: bookmark + Women Only badge
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button {
                            isBookmarked.toggle()
                        } label: {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(isBookmarked ? Color.dinkrAmber : .white)
                                .padding(8)
                                .background(.black.opacity(0.25))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 10)
                        .padding(.trailing, 10)
                    }
                    if event.isWomenOnly {
                        HStack {
                            Spacer()
                            Text("Women Only")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.pink.opacity(0.85))
                                .clipShape(Capsule())
                                .padding(.trailing, 12)
                        }
                    }
                    Spacer()
                }
                .frame(height: 120)

                // Bottom row: date chip (left) + urgency/deadline chip (right)
                HStack {
                    // Date chip
                    Text(event.dateTime.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.dinkrNavy)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.10), radius: 4, y: 2)
                        .padding(.leading, 14)
                        .padding(.bottom, 12)

                    Spacer()

                    // Urgency: event < 3 days away takes priority, then deadline countdown
                    if let eventDays = daysUntilEvent, eventDays < 3 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text(eventDays == 0 ? "Today!" : "\(eventDays)d left")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.dinkrCoral)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.12), radius: 4, y: 2)
                        .padding(.trailing, 14)
                        .padding(.bottom, 12)
                    } else if let days = daysUntilDeadline {
                        Text("\(days)d left")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(days <= 3 ? Color.dinkrCoral : Color.dinkrAmber)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.12), radius: 4, y: 2)
                            .padding(.trailing, 14)
                            .padding(.bottom, 12)
                    }
                }
            }
            .clipShape(
                .rect(
                    topLeadingRadius: 18,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 18
                )
            )

            // ── Card body ─────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 10) {

                // Type badge + title row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(event.type.rawValue.capitalized)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(eventTypeColor)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3)
                            .background(eventTypeColor.opacity(0.12))
                            .clipShape(Capsule())

                        Text(event.title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 8)

                    // "Registered ✓" badge — shown when user is already registered
                    if event.isRegistered {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("Registered")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(Color.dinkrGreen)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.dinkrGreen.opacity(0.12), in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.dinkrGreen.opacity(0.30), lineWidth: 1))
                    }
                }

                // Urgency chip — shown when event is < 7 days away (but not already red-urgent)
                if let days = daysUntilEvent, days >= 3, days < 7 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 10))
                        Text("\(days) day\(days == 1 ? "" : "s") left to register")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.dinkrCoral)
                    .clipShape(Capsule())
                }

                // Location
                Label {
                    Text(event.location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } icon: {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption2)
                        .foregroundStyle(Color.dinkrCoral)
                }

                // Organizer row: avatar + name
                HStack(spacing: 7) {
                    AvatarView(
                        displayName: event.organizer.isEmpty ? "Dinkr" : event.organizer,
                        size: 22
                    )
                    Text(event.organizer.isEmpty ? "Dinkr Community" : event.organizer)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Registration progress bar
                if event.maxParticipants != nil {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(event.currentParticipants) registered")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                            Spacer()
                            if let max = event.maxParticipants {
                                Text("\(Int(registrationProgress * 100))% of \(max) spots")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(
                                        registrationProgress >= 0.90
                                            ? Color.dinkrCoral
                                            : eventTypeColor
                                    )
                            }
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.dinkrGreen.opacity(0.12))
                                LinearGradient(
                                    colors: registrationProgress >= 0.90
                                        ? [Color.dinkrCoral, Color.dinkrAmber]
                                        : [Color.dinkrGreen, Color.dinkrSky],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .frame(width: geo.size.width * min(registrationProgress, 1.0))
                            }
                        }
                        .frame(height: 5)
                    }
                }

                // Bottom CTA row: fee pill + register / registered button
                HStack(spacing: 10) {
                    if let fee = event.entryFee {
                        Text(fee == 0 ? "Free" : "$\(Int(fee))")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(fee == 0 ? Color.dinkrGreen : .white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                fee == 0
                                    ? Color.dinkrGreen.opacity(0.15)
                                    : Color.dinkrAmber
                            )
                            .clipShape(Capsule())
                    }

                    Spacer()

                    if event.isRegistered {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                            Text("Registered")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(Color.dinkrGreen)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.dinkrGreen.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.dinkrGreen, lineWidth: 1.5))
                    } else {
                        Text("Register →")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color.dinkrGreen)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(14)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(
            color: eventTypeColor.opacity(0.20),
            radius: 12, x: 0, y: 6
        )
    }
}

// MARK: - EventTypeBadge (kept unchanged)

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
        case .tournament: return Color.dinkrCoral
        case .clinic:     return Color.dinkrSky
        case .openPlay:   return Color.dinkrGreen
        case .social:     return Color.dinkrAmber
        case .womenOnly:  return .pink
        case .fundraiser: return .purple
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 14) {
            ForEach(Event.mockEvents) { event in
                EventCardView(event: event)
            }
        }
        .padding()
    }
}

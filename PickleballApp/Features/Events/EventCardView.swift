import SwiftUI

struct EventCardView: View {
    let event: Event

    // MARK: - Computed helpers

    var registrationProgress: Double {
        guard let max = event.maxParticipants, max > 0 else { return 0 }
        return Double(event.currentParticipants) / Double(max)
    }

    var daysUntilDeadline: Int? {
        guard let deadline = event.registrationDeadline else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: deadline).day
    }

    // Keep existing eventTypeColor exactly as-is
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

            // ── Gradient banner (120pt) with court-pattern overlay + date chip ──
            ZStack(alignment: .bottomLeading) {
                // Base gradient
                LinearGradient(
                    colors: [eventTypeColor, eventTypeColor.opacity(0.55)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 120)

                // Subtle sport net/court pattern drawn with Canvas (~8% opacity)
                Canvas { context, size in
                    let lineColor = Color.white.opacity(0.08)
                    var path = Path()

                    // Horizontal net lines
                    let hSpacing: CGFloat = 18
                    var y: CGFloat = 0
                    while y <= size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        y += hSpacing
                    }

                    // Vertical court lines
                    let vSpacing: CGFloat = 24
                    var x: CGFloat = 0
                    while x <= size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        x += vSpacing
                    }

                    // Center court line (thicker accent)
                    var centerPath = Path()
                    centerPath.move(to: CGPoint(x: size.width / 2, y: 0))
                    centerPath.addLine(to: CGPoint(x: size.width / 2, y: size.height))

                    context.stroke(
                        path,
                        with: .color(lineColor),
                        lineWidth: 0.8
                    )
                    context.stroke(
                        centerPath,
                        with: .color(Color.white.opacity(0.12)),
                        lineWidth: 1.5
                    )
                }
                .frame(height: 120)

                // Bottom scrim for readability
                LinearGradient(
                    colors: [Color.black.opacity(0.0), Color.black.opacity(0.25)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)

                // Women Only badge (top-right corner)
                if event.isWomenOnly {
                    VStack {
                        HStack {
                            Spacer()
                            Text("Women Only")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.pink.opacity(0.85))
                                .clipShape(Capsule())
                                .padding(.top, 10)
                                .padding(.trailing, 12)
                        }
                        Spacer()
                    }
                    .frame(height: 120)
                }

                // Date chip floating on the banner
                HStack {
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

                    // Deadline countdown on the banner
                    if let days = daysUntilDeadline {
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

                // Type badge + title
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

                // Organizer chip (using hostName / organizer id as stub)
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.dinkrSky)
                    Text("Organized by \(event.organizer.isEmpty ? "Dinkr Community" : event.organizer)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Registration progress (gradient bar)
                if event.maxParticipants != nil {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(event.currentParticipants) registered")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                            Spacer()
                            if let max = event.maxParticipants {
                                Text("\(Int(registrationProgress * 100))% of \(max)")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(eventTypeColor)
                            }
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.dinkrGreen.opacity(0.12))
                                LinearGradient(
                                    colors: [Color.dinkrGreen, Color.dinkrSky],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .frame(width: geo.size.width * registrationProgress)
                            }
                        }
                        .frame(height: 5)
                    }
                }

                // Bottom CTA row: fee pill + register button
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

                    Text("Register →")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.dinkrGreen)
                        .clipShape(Capsule())
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

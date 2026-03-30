import SwiftUI

struct EventsView: View {
    @State private var viewModel = EventsViewModel()
    @State private var calendarFilter = EventCalendarStrip.CalendarFilter.all

    var filteredByCalendar: [Event] {
        let now = Date()
        let cal = Calendar.current
        return viewModel.filteredEvents.filter { event in
            switch calendarFilter {
            case .today:
                return cal.isDateInToday(event.dateTime)
            case .thisWeek:
                return event.dateTime >= now &&
                       event.dateTime <= (cal.date(byAdding: .day, value: 7, to: now) ?? now)
            case .thisMonth:
                return event.dateTime >= now &&
                       event.dateTime <= (cal.date(byAdding: .month, value: 1, to: now) ?? now)
            case .all:
                return true
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Calendar strip
                EventCalendarStrip(selectedFilter: $calendarFilter)

                // Type filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: viewModel.selectedFilter == nil) {
                            viewModel.selectedFilter = nil
                            viewModel.applyFilter()
                        }
                        FilterChip(label: "Women Only", isSelected: viewModel.showWomenOnly, color: .pink) {
                            viewModel.showWomenOnly.toggle()
                            viewModel.applyFilter()
                        }
                        ForEach(EventType.allCases, id: \.self) { type in
                            FilterChip(label: type.rawValue, isSelected: viewModel.selectedFilter == type) {
                                viewModel.selectedFilter = viewModel.selectedFilter == type ? nil : type
                                viewModel.applyFilter()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .padding(.bottom, 4)
                }

                // Subtle gradient separator below filter bar
                LinearGradient(
                    colors: [Color.dinkrGreen.opacity(0.10), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 5)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        if viewModel.isLoading {
                            ProgressView().padding(.top, 40)
                        } else if filteredByCalendar.isEmpty {
                            EmptyStateView(
                                icon: "calendar.badge.exclamationmark",
                                title: "No Events Found",
                                message: "Try changing your filters or check back later."
                            )
                            .padding(.top, 40)
                        } else {

                            // ── Featured hero — upgraded ───────────────────
                            if let featured = filteredByCalendar.first {
                                VStack(alignment: .leading, spacing: 10) {
                                    // Section header
                                    HStack {
                                        Rectangle()
                                            .fill(Color.dinkrCoral)
                                            .frame(width: 4, height: 18)
                                            .clipShape(Capsule())
                                        Text("FEATURED EVENT")
                                            .font(.system(size: 11, weight: .heavy))
                                            .foregroundStyle(Color.dinkrNavy)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 12)

                                    NavigationLink {
                                        EventDetailView(event: featured)
                                    } label: {
                                        FeaturedEventHeroBanner(event: featured)
                                            .padding(.horizontal)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            // ── Remaining events with section header ───────
                            if filteredByCalendar.count > 1 {
                                HStack {
                                    Rectangle()
                                        .fill(Color.dinkrGreen)
                                        .frame(width: 4, height: 18)
                                        .clipShape(Capsule())
                                    Text("UPCOMING EVENTS")
                                        .font(.system(size: 11, weight: .heavy))
                                        .foregroundStyle(Color.dinkrNavy)
                                    Spacer()
                                    Text("\(filteredByCalendar.count - 1) events")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.top, 18)
                                .padding(.bottom, 4)
                            }

                            ForEach(filteredByCalendar.dropFirst()) { event in
                                NavigationLink {
                                    EventDetailView(event: event)
                                } label: {
                                    EventCardView(event: event)
                                        .padding(.horizontal)
                                        .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.bottom, 16)
                }
                .refreshable { await viewModel.load() }
            }
            .navigationTitle("Events")
        }
        .task { await viewModel.load() }
    }
}

// MARK: - Featured Event Hero Banner

struct FeaturedEventHeroBanner: View {
    let event: Event

    var registrationProgress: Double {
        guard let max = event.maxParticipants, max > 0 else { return 0 }
        return Double(event.currentParticipants) / Double(max)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Tall gradient image area (160pt) with canvas sport pattern ──
            ZStack(alignment: .bottomLeading) {
                // Rich gradient — navy base with event type color accent
                LinearGradient(
                    colors: [
                        Color.dinkrNavy,
                        Color.dinkrNavy.opacity(0.85),
                        eventTypeColor.opacity(0.75)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 160)

                // Subtle net/court pattern overlay
                Canvas { context, size in
                    let lineColor = Color.white.opacity(0.07)
                    var gridPath = Path()

                    let hSpacing: CGFloat = 22
                    var y: CGFloat = 0
                    while y <= size.height {
                        gridPath.move(to: CGPoint(x: 0, y: y))
                        gridPath.addLine(to: CGPoint(x: size.width, y: y))
                        y += hSpacing
                    }

                    let vSpacing: CGFloat = 30
                    var x: CGFloat = 0
                    while x <= size.width {
                        gridPath.move(to: CGPoint(x: x, y: 0))
                        gridPath.addLine(to: CGPoint(x: x, y: size.height))
                        x += vSpacing
                    }

                    context.stroke(gridPath, with: .color(lineColor), lineWidth: 0.7)

                    // Center-court highlight line
                    var centerLine = Path()
                    centerLine.move(to: CGPoint(x: size.width / 2, y: 0))
                    centerLine.addLine(to: CGPoint(x: size.width / 2, y: size.height))
                    context.stroke(centerLine, with: .color(Color.white.opacity(0.10)), lineWidth: 2)

                    // Kitchen line (non-volley zone)
                    let kitchenY = size.height * 0.72
                    var kitchenPath = Path()
                    kitchenPath.move(to: CGPoint(x: 0, y: kitchenY))
                    kitchenPath.addLine(to: CGPoint(x: size.width, y: kitchenY))
                    context.stroke(kitchenPath, with: .color(Color.white.opacity(0.13)), lineWidth: 1.5)
                }
                .frame(height: 160)

                // Scrim for text legibility
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.50)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)

                // Text overlay at bottom of image area
                VStack(alignment: .leading, spacing: 6) {
                    // Event type badge
                    HStack(spacing: 6) {
                        Text(event.type.rawValue.capitalized)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(eventTypeColor)
                            .clipShape(Capsule())

                        if event.isWomenOnly {
                            Text("Women Only")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(.pink)
                                .clipShape(Capsule())
                        }
                    }

                    Text(event.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                }
                .padding(16)
            }
            .clipShape(
                .rect(
                    topLeadingRadius: 20,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 20
                )
            )

            // ── Card body ─────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 10) {

                // Location + date row
                HStack(spacing: 16) {
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

                    Spacer()

                    Text(event.dateTime.formatted(.dateTime.month().day()))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)
                }

                // Registration progress bar (dinkrGreen → dinkrSky gradient)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(event.currentParticipants) registered")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(registrationProgress * 100))% full")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen)
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

                // Bottom CTA row
                HStack(spacing: 10) {
                    if let fee = event.entryFee {
                        Text(fee == 0 ? "Free" : "$\(Int(fee))")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(fee == 0 ? Color.dinkrGreen : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                fee == 0
                                    ? Color.dinkrGreen.opacity(0.15)
                                    : Color.dinkrAmber
                            )
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Text("Register →")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.dinkrGreen)
                        .clipShape(Capsule())
                }
            }
            .padding(16)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(
            color: eventTypeColor.opacity(0.22),
            radius: 14, x: 0, y: 7
        )
    }
}

// MARK: - FilterChip (kept unchanged)

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = Color.dinkrGreen
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : color.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    EventsView()
}

import SwiftUI

// MARK: - Tab Filter

enum EventTabFilter: String, CaseIterable {
    case all       = "All"
    case upcoming  = "Upcoming"
    case thisWeek  = "This Week"
    case tournaments = "Tournaments"
    case clinics   = "Clinics"
    case openPlay  = "Open Play"
    case myEvents  = "My Events"
}

// MARK: - Sort Option

enum EventSortOption: String, CaseIterable {
    case date     = "Date"
    case distance = "Distance"
    case price    = "Price"
}

// MARK: - EventsView

struct EventsView: View {
    @State private var viewModel = EventsViewModel()
    @Environment(AuthService.self) private var authService
    @State private var calendarFilter = EventCalendarStrip.CalendarFilter.all
    @State private var tabFilter: EventTabFilter = .all
    @State private var sortOption: EventSortOption = .date
    @State private var showCreateEvent = false
    @State private var showSearch = false

    // MARK: - Filtering pipeline

    var baseEvents: [Event] {
        let now = Date()
        let cal = Calendar.current
        let afterCalendar = viewModel.filteredEvents.filter { event in
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
        return afterCalendar
    }

    var filteredEvents: [Event] {
        let now = Date()
        let cal = Calendar.current
        let source = baseEvents

        let tabFiltered: [Event]
        switch tabFilter {
        case .all:
            tabFiltered = source
        case .upcoming:
            tabFiltered = source.filter { $0.dateTime >= now }
        case .thisWeek:
            let weekOut = cal.date(byAdding: .day, value: 7, to: now) ?? now
            tabFiltered = source.filter { $0.dateTime >= now && $0.dateTime <= weekOut }
        case .tournaments:
            tabFiltered = source.filter { $0.type == .tournament }
        case .clinics:
            tabFiltered = source.filter { $0.type == .clinic }
        case .openPlay:
            tabFiltered = source.filter { $0.type == .openPlay }
        case .myEvents:
            tabFiltered = source.filter { $0.isRegistered }
        }

        switch sortOption {
        case .date:
            return tabFiltered.sorted { $0.dateTime < $1.dateTime }
        case .distance:
            // Distance sort stub — falls back to date order until real location is wired
            return tabFiltered.sorted { $0.dateTime < $1.dateTime }
        case .price:
            return tabFiltered.sorted {
                ($0.entryFee ?? 0) < ($1.entryFee ?? 0)
            }
        }
    }

    /// First tournament from the full unfiltered mock/live set — used for the hero banner
    var featuredTournament: Event? {
        viewModel.events.first { $0.type == .tournament }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Calendar strip
                EventCalendarStrip(selectedFilter: $calendarFilter)

                // ── Tab filter row ─────────────────────────────────────────
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(EventTabFilter.allCases, id: \.self) { tab in
                            TabFilterChip(
                                label: tab.rawValue,
                                isSelected: tabFilter == tab
                            ) {
                                tabFilter = tab
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .padding(.bottom, 4)
                }

                // Sort toolbar
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Sort:")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    Menu {
                        ForEach(EventSortOption.allCases, id: \.self) { option in
                            Button {
                                sortOption = option
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(sortOption.rawValue)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.dinkrGreen)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(Color.dinkrGreen)
                        }
                    }

                    Spacer()

                    if tabFilter == .myEvents {
                        Text("\(filteredEvents.count) registered")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(filteredEvents.count) events")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)

                // Subtle gradient separator
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
                        } else if filteredEvents.isEmpty {
                            EmptyStateView(
                                icon: tabFilter == .myEvents
                                    ? "ticket.fill"
                                    : "calendar.badge.exclamationmark",
                                title: tabFilter == .myEvents
                                    ? "No Registered Events"
                                    : "No Events Found",
                                message: tabFilter == .myEvents
                                    ? "Events you register for will appear here."
                                    : "Try changing your filters or check back later."
                            )
                            .padding(.top, 40)
                        } else {

                            // ── Featured Hero Banner (always shown at top, uses first tournament) ──
                            if tabFilter != .myEvents, let hero = featuredTournament {
                                VStack(alignment: .leading, spacing: 10) {
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
                                        EventDetailView(event: hero) { evt in
                                            await viewModel.register(event: evt)
                                        }
                                    } label: {
                                        FeaturedEventHeroBanner(event: hero)
                                            .padding(.horizontal)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            // ── My Events section header ──────────────────
                            if tabFilter == .myEvents {
                                HStack {
                                    Rectangle()
                                        .fill(Color.dinkrGreen)
                                        .frame(width: 4, height: 18)
                                        .clipShape(Capsule())
                                    Text("MY REGISTERED EVENTS")
                                        .font(.system(size: 11, weight: .heavy))
                                        .foregroundStyle(Color.dinkrNavy)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.top, 16)
                                .padding(.bottom, 4)
                            }

                            // ── Upcoming section header (non-myEvents) ────
                            if tabFilter != .myEvents && filteredEvents.count > 1 {
                                HStack {
                                    Rectangle()
                                        .fill(Color.dinkrGreen)
                                        .frame(width: 4, height: 18)
                                        .clipShape(Capsule())
                                    Text("UPCOMING EVENTS")
                                        .font(.system(size: 11, weight: .heavy))
                                        .foregroundStyle(Color.dinkrNavy)
                                    Spacer()
                                    Text("\(filteredEvents.count) events")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.top, 18)
                                .padding(.bottom, 4)
                            }

                            ForEach(filteredEvents) { event in
                                NavigationLink {
                                    EventDetailView(event: event) { evt in
                                        await viewModel.register(event: evt)
                                    }
                                } label: {
                                    ZStack(alignment: .topLeading) {
                                        EventCardView(event: event)

                                        // Countdown chip overlay for My Events
                                        if tabFilter == .myEvents {
                                            let days = Calendar.current
                                                .dateComponents([.day], from: Date(), to: event.dateTime).day ?? 0
                                            Text(days == 0 ? "Today!" : "In \(days) day\(days == 1 ? "" : "s")")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(days <= 3 ? Color.dinkrCoral : Color.dinkrGreen)
                                                .clipShape(Capsule())
                                                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                                                .offset(x: 14, y: 14)
                                        }
                                    }
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .tint(Color.dinkrNavy)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateEvent = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Host Event")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.dinkrNavy)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $showCreateEvent) {
                CreateEventView()
            }
            .sheet(isPresented: $showSearch) {
                SearchView()
            }
        }
        .task {
            viewModel.currentUserId = authService.currentUser?.id
            await viewModel.load()
        }
    }
}

// MARK: - Tab Filter Chip

struct TabFilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(isSelected ? .white : Color.dinkrGreen)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.dinkrGreen : Color.dinkrGreen.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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

            // ── Gradient image area (160pt) ──────────────────────────────
            ZStack(alignment: .bottomLeading) {
                // Clean two-tone hero background
                LinearGradient(
                    colors: [Color.dinkrNavy, Color.dinkrNavy.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 160)

                // "FEATURED EVENT" pill chip top-left
                VStack {
                    HStack {
                        Text("FEATURED EVENT")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(Color.dinkrNavy)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.92))
                            .clipShape(Capsule())
                            .padding(.top, 14)
                            .padding(.leading, 16)
                        Spacer()
                    }
                    Spacer()
                }
                .frame(height: 160)

                // Text overlay at bottom
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(event.type.rawValue.capitalized)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(eventTypeColor)
                            .clipShape(Capsule())
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

            // ── Card body ────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 10) {

                // Date + location row
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

                    Text(event.dateTime.formatted(.dateTime.month().day().hour().minute()))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)
                }

                // Registration progress bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(event.currentParticipants) registered")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let max = event.maxParticipants {
                            Text("\(Int(registrationProgress * 100))% of \(max) spots")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color.dinkrGreen)
                        }
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.dinkrGreen.opacity(0.12))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.dinkrGreen)
                                .frame(width: geo.size.width * registrationProgress)
                        }
                    }
                    .frame(height: 5)
                }

                // CTA row
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

                    Text("Register Now →")
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
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - FilterChip (legacy — kept for any remaining callers)

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

import SwiftUI

// MARK: - GroupEventsView

struct GroupEventsView: View {
    let group: DinkrGroup

    @State private var filterMode: EventFilterMode = .upcoming
    @State private var calendarViewActive = false
    @State private var showCreateEvent = false
    @State private var exportedEventId: String? = nil

    private let allEvents: [Event] = Event.mockEvents

    // MARK: - Filtered Events

    private var filteredEvents: [Event] {
        switch filterMode {
        case .upcoming:
            return allEvents
                .filter { $0.dateTime >= Date() }
                .sorted { $0.dateTime < $1.dateTime }
        case .past:
            return allEvents
                .filter { $0.dateTime < Date() }
                .sorted { $0.dateTime > $1.dateTime }
        case .recurring:
            // Mock: tag-based detection
            return allEvents
                .filter { $0.tags.contains("openplay") || $0.tags.contains("monthly") || $0.tags.contains("weekly") }
                .sorted { $0.dateTime < $1.dateTime }
        }
    }

    // MARK: - Calendar month grouping

    private var calendarDays: [CalendarEventDay] {
        let cal = Calendar.current
        let now = Date()
        guard let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)),
              let range = cal.range(of: .day, in: .month, for: startOfMonth) else { return [] }

        return range.map { dayNum -> CalendarEventDay in
            let components = DateComponents(year: cal.component(.year, from: now),
                                           month: cal.component(.month, from: now),
                                           day: dayNum)
            let date = cal.date(from: components) ?? now
            let dayEvents = allEvents.filter { cal.isDate($0.dateTime, inSameDayAs: date) }
            return CalendarEventDay(date: date, dayNumber: dayNum, events: dayEvents)
        }
    }

    private var monthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Date())
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            // ── Toolbar row ─────────────────────────────────────────────
            toolbarRow
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            // ── Filter chips ────────────────────────────────────────────
            filterChips
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

            Divider()

            // ── Content ─────────────────────────────────────────────────
            if calendarViewActive {
                calendarView
            } else {
                listView
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCreateEvent) {
            CreateAvailabilityPollView()
        }
    }

    // MARK: - Toolbar Row

    private var toolbarRow: some View {
        HStack(spacing: 10) {
            // Create DinkrGroup Event button
            Button {
                HapticManager.medium()
                showCreateEvent = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Create Event")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.dinkrGreen)
                .clipShape(Capsule())
                .shadow(color: Color.dinkrGreen.opacity(0.4), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)

            Spacer()

            // Calendar / list toggle
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    calendarViewActive.toggle()
                }
                HapticManager.selection()
            } label: {
                Image(systemName: calendarViewActive ? "list.bullet" : "calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.dinkrNavy)
                    .frame(width: 36, height: 36)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        HStack(spacing: 8) {
            ForEach(EventFilterMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        filterMode = mode
                    }
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(mode.label)
                            .font(.system(size: 13, weight: filterMode == mode ? .bold : .regular))
                    }
                    .foregroundStyle(filterMode == mode ? .white : Color.primary.opacity(0.7))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(filterMode == mode ? Color.dinkrNavy : Color.cardBackground)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(filterMode == mode ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: filterMode)
            }
            Spacer()
        }
    }

    // MARK: - List View

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if filteredEvents.isEmpty {
                    emptyState
                        .padding(.top, 48)
                } else {
                    ForEach(filteredEvents) { event in
                        GroupEventCard(
                            event: event,
                            isExported: exportedEventId == event.id
                        ) {
                            withAnimation {
                                exportedEventId = event.id
                            }
                            HapticManager.success()
                            // reset after 3s
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                if exportedEventId == event.id {
                                    exportedEventId = nil
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }

    // MARK: - Calendar View

    private var calendarView: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Month header
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.dinkrNavy)
                    Text(monthLabel)
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Day-of-week headers
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                    ForEach(["S","M","T","W","T","F","S"], id: \.self) { label in
                        Text(label)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)

                // Calendar grid
                let firstWeekday = firstWeekdayOfMonth()
                let days = calendarDays
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                    // leading blanks
                    ForEach(0..<firstWeekday, id: \.self) { _ in
                        Color.clear.frame(height: 48)
                    }

                    ForEach(days) { day in
                        CalendarDayEventCell(day: day)
                    }
                }
                .padding(.horizontal, 16)

                Divider().padding(.horizontal, 16)

                // Event legend for this month
                let thisMonthEvents = allEvents.filter { event in
                    Calendar.current.isDate(event.dateTime, equalTo: Date(), toGranularity: .month)
                }
                if thisMonthEvents.isEmpty {
                    Text("No events this month")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                } else {
                    VStack(spacing: 8) {
                        HStack {
                            Text("This Month")
                                .font(.system(size: 14, weight: .bold))
                            Spacer()
                        }
                        .padding(.horizontal, 16)

                        ForEach(thisMonthEvents) { event in
                            GroupEventCard(
                                event: event,
                                isExported: exportedEventId == event.id
                            ) {
                                withAnimation { exportedEventId = event.id }
                                HapticManager.success()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    if exportedEventId == event.id { exportedEventId = nil }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.dinkrNavy.opacity(0.08))
                    .frame(width: 72, height: 72)
                Image(systemName: filterMode.emptyIcon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.dinkrNavy.opacity(0.4))
            }
            Text(filterMode.emptyTitle)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(filterMode.emptyMessage(groupName: group.name))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func firstWeekdayOfMonth() -> Int {
        let cal = Calendar.current
        let now = Date()
        guard let start = cal.date(from: cal.dateComponents([.year, .month], from: now)) else { return 0 }
        return cal.component(.weekday, from: start) - 1  // 0=Sun
    }
}

// MARK: - DinkrGroup Event Card

struct GroupEventCard: View {
    let event: Event
    let isExported: Bool
    let onExport: () -> Void

    @State private var isRSVPed: Bool
    @State private var rsvpCount: Int

    init(event: Event, isExported: Bool, onExport: @escaping () -> Void) {
        self.event = event
        self.isExported = isExported
        self.onExport = onExport
        self._isRSVPed = State(initialValue: event.isRegistered)
        self._rsvpCount = State(initialValue: event.currentParticipants)
    }

    private var accentColor: Color {
        switch event.type {
        case .tournament:  return Color.dinkrCoral
        case .clinic:      return Color.dinkrSky
        case .openPlay:    return Color.dinkrGreen
        case .social:      return Color.dinkrAmber
        case .womenOnly:   return .pink
        case .fundraiser:  return .purple
        }
    }

    private var typeLabel: String {
        switch event.type {
        case .tournament:  return "Tournament"
        case .clinic:      return "Clinic"
        case .openPlay:    return "Open Play"
        case .social:      return "Social"
        case .womenOnly:   return "Women's"
        case .fundraiser:  return "Fundraiser"
        }
    }

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: event.dateTime)
    }

    private var timeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: event.dateTime)
    }

    private var monthAbbrev: String {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f.string(from: event.dateTime).uppercased()
    }

    private var dayNum: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: event.dateTime)
    }

    private var capacityRatio: Double {
        guard let max = event.maxParticipants, max > 0 else { return 0 }
        return Double(rsvpCount) / Double(max)
    }

    private var capacityLabel: String {
        if let max = event.maxParticipants {
            return "\(rsvpCount)/\(max)"
        }
        return "\(rsvpCount) going"
    }

    var body: some View {
        HStack(spacing: 0) {

            // ── Accent strip ────────────────────────────────────────────
            RoundedRectangle(cornerRadius: 3)
                .fill(accentColor)
                .frame(width: 5)

            HStack(spacing: 12) {

                // Date block
                VStack(alignment: .center, spacing: 2) {
                    Text(monthAbbrev)
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(accentColor)
                    Text(dayNum)
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(.primary)
                }
                .frame(width: 38)

                // Event details
                VStack(alignment: .leading, spacing: 5) {
                    // Title + type chip
                    HStack(spacing: 6) {
                        Text(event.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(typeLabel)
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(accentColor.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    // Date / time / host
                    HStack(spacing: 6) {
                        Label(dateLabel, systemImage: "calendar")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("·")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Label(timeLabel, systemImage: "clock")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 5) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Text(event.organizer)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    // RSVP count bar
                    HStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(accentColor.opacity(0.12))
                                    .frame(height: 4)
                                Capsule()
                                    .fill(capacityRatio > 0.85 ? Color.dinkrCoral : accentColor)
                                    .frame(width: max(4, geo.size.width * min(1.0, capacityRatio)), height: 4)
                            }
                        }
                        .frame(height: 4)

                        Text(capacityLabel)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(capacityRatio > 0.85 ? Color.dinkrCoral : .secondary)
                            .monospacedDigit()
                    }

                    // Fee + export button row
                    HStack(spacing: 8) {
                        if let fee = event.entryFee {
                            Text(fee == 0 ? "Free" : String(format: "$%.0f", fee))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(fee == 0 ? Color.dinkrGreen : Color.dinkrAmber)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background((fee == 0 ? Color.dinkrGreen : Color.dinkrAmber).opacity(0.1))
                                .clipShape(Capsule())
                        }

                        Spacer()

                        // Export to calendar
                        Button {
                            onExport()
                        } label: {
                            HStack(spacing: 4) {
                                if isExported {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.dinkrGreen)
                                    Text("Added ✅")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(Color.dinkrGreen)
                                } else {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                    Text("Add to Calendar")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isExported ? Color.dinkrGreen.opacity(0.1) : Color.secondary.opacity(0.08))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isExported)
                    }
                }

                // RSVP button
                VStack(spacing: 0) {
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            let wasRSVPed = isRSVPed
                            isRSVPed.toggle()
                            rsvpCount += wasRSVPed ? -1 : 1
                        }
                        HapticManager.medium()
                    } label: {
                        Text(isRSVPed ? "Going ✓" : "RSVP")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(isRSVPed ? Color.dinkrSky : accentColor)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRSVPed)
                    Spacer()
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Calendar Day Event Cell

private struct CalendarDayEventCell: View {
    let day: CalendarEventDay

    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }

    var body: some View {
        VStack(spacing: 3) {
            Text("\(day.dayNumber)")
                .font(.system(size: 13, weight: isToday ? .bold : .regular))
                .foregroundStyle(isToday ? .white : .primary)
                .frame(width: 26, height: 26)
                .background(isToday ? Color.dinkrGreen : Color.clear)
                .clipShape(Circle())

            // event dots (up to 3)
            HStack(spacing: 2) {
                ForEach(day.events.prefix(3)) { event in
                    Circle()
                        .fill(eventDotColor(for: event.type))
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(
            day.events.isEmpty ? Color.clear : Color.dinkrGreen.opacity(0.04),
            in: RoundedRectangle(cornerRadius: 8)
        )
    }

    private func eventDotColor(for type: EventType) -> Color {
        switch type {
        case .tournament:  return Color.dinkrCoral
        case .clinic:      return Color.dinkrSky
        case .openPlay:    return Color.dinkrGreen
        case .social:      return Color.dinkrAmber
        case .womenOnly:   return .pink
        case .fundraiser:  return .purple
        }
    }
}

// MARK: - Supporting Types

enum EventFilterMode: CaseIterable {
    case upcoming, past, recurring

    var label: String {
        switch self {
        case .upcoming:  return "Upcoming"
        case .past:      return "Past"
        case .recurring: return "Recurring"
        }
    }

    var icon: String {
        switch self {
        case .upcoming:  return "arrow.right.circle"
        case .past:      return "clock.arrow.circlepath"
        case .recurring: return "repeat"
        }
    }

    var emptyIcon: String {
        switch self {
        case .upcoming:  return "calendar.badge.exclamationmark"
        case .past:      return "clock.arrow.circlepath"
        case .recurring: return "repeat.circle"
        }
    }

    var emptyTitle: String {
        switch self {
        case .upcoming:  return "No Upcoming Events"
        case .past:      return "No Past Events"
        case .recurring: return "No Recurring Events"
        }
    }

    func emptyMessage(groupName: String) -> String {
        switch self {
        case .upcoming:  return "\(groupName) hasn't scheduled any upcoming events yet."
        case .past:      return "No past events on record for \(groupName)."
        case .recurring: return "\(groupName) has no recurring events set up yet."
        }
    }
}

struct CalendarEventDay: Identifiable {
    let date: Date
    let dayNumber: Int
    let events: [Event]

    var id: Int { dayNumber }
}

// MARK: - Backwards-compat GroupEventRow (kept for any callers)

struct GroupEventRow: View {
    let event: Event
    @State private var isRSVPed = false

    var body: some View {
        PickleballCard {
            HStack(spacing: 12) {
                VStack(alignment: .center, spacing: 2) {
                    Text(event.dateTime, format: .dateTime.month(.abbreviated))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                        .textCase(.uppercase)
                    Text(event.dateTime, format: .dateTime.day())
                        .font(.title2.weight(.heavy))
                }
                .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(event.location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        if let fee = event.entryFee {
                            Text(fee == 0 ? "Free" : "$\(Int(fee))")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(fee == 0 ? Color.dinkrGreen : Color.dinkrAmber)
                        }
                        Text("\(event.currentParticipants) going")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isRSVPed.toggle()
                    }
                    HapticManager.medium()
                } label: {
                    Text(isRSVPed ? "Going ✓" : "RSVP")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isRSVPed ? Color.dinkrSky : Color.dinkrGreen)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(14)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GroupEventsView(group: DinkrGroup.mockGroups[0])
    }
}

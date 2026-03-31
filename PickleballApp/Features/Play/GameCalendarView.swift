import SwiftUI

// MARK: - GameCalendarView

struct GameCalendarView: View {
    let sessions: [GameSession]
    var viewModel: PlayViewModel

    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())
    @State private var selectedDate: Date? = Calendar.current.startOfDay(for: Date())
    @State private var isWeekMode: Bool = false
    @State private var expandedWeek: Bool = false

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    // MARK: - Date helpers

    private var today: Date { calendar.startOfDay(for: Date()) }

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    /// All day-cells to display for the current grid (leading/trailing padding days included as nil).
    private var monthDays: [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: displayedMonth).weekday
        else { return [] }

        let leadingEmpties = (firstWeekday - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: leadingEmpties)
        for day in monthRange {
            var comps = calendar.dateComponents([.year, .month], from: displayedMonth)
            comps.day = day
            if let date = calendar.date(from: comps) {
                days.append(date)
            }
        }
        // Pad to complete last row
        let remainder = days.count % 7
        if remainder != 0 {
            days += Array(repeating: nil, count: 7 - remainder)
        }
        return days
    }

    /// The week row (7 days) that contains today, for week-strip mode.
    private var currentWeekDays: [Date?] {
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: weekStart)
        }
    }

    private var activeDays: [Date?] {
        isWeekMode ? currentWeekDays : monthDays
    }

    private var selectedDaySessions: [GameSession] {
        guard let date = selectedDate else { return [] }
        return sessions.filter { calendar.isDate($0.dateTime, inSameDayAs: date) }
    }

    // MARK: - Session dot color logic

    private func dotColor(for date: Date) -> Color? {
        let daySessions = sessions.filter { calendar.isDate($0.dateTime, inSameDayAs: date) }
        guard !daySessions.isEmpty else { return nil }
        if daySessions.allSatisfy({ $0.isFull }) { return Color.dinkrCoral }
        if daySessions.contains(where: { Double($0.rsvps.count) / Double($0.totalSpots) >= 0.75 }) {
            return Color.dinkrAmber
        }
        return Color.dinkrGreen
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            calendarHeader
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 6)

            weekdayLabels
                .padding(.horizontal, 8)

            Divider()
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

            dayGrid
                .padding(.horizontal, 8)
                .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 16)

            selectedDaySection
        }
    }

    // MARK: - Subviews

    private var calendarHeader: some View {
        HStack(spacing: 12) {
            // Week/Month toggle pill
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isWeekMode.toggle()
                    HapticManager.selection()
                }
            } label: {
                Text(isWeekMode ? "Week" : "Month")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.dinkrGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.dinkrGreen.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            // Back arrow
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    stepMonth(by: -1)
                    HapticManager.light()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 32, height: 32)
                    .background(Color(UIColor.tertiarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)

            Text(monthTitle)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)
                .frame(minWidth: 140, alignment: .center)

            // Forward arrow
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    stepMonth(by: 1)
                    HapticManager.light()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 32, height: 32)
                    .background(Color(UIColor.tertiarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            // "Today" button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayedMonth = calendar.startOfMonth(for: today)
                    selectedDate = today
                    HapticManager.light()
                }
            } label: {
                Text("Today")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.dinkrSky)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.dinkrSky.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var weekdayLabels: some View {
        let symbols = calendar.veryShortWeekdaySymbols
        let ordered = reorderedWeekdays(symbols)
        return HStack(spacing: 0) {
            ForEach(ordered, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
    }

    private var dayGrid: some View {
        let days = activeDays
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(0..<days.count, id: \.self) { index in
                if let date = days[index] {
                    DayCell(
                        date: date,
                        isToday: calendar.isDate(date, inSameDayAs: today),
                        isSelected: selectedDate.map { calendar.isDate(date, inSameDayAs: $0) } ?? false,
                        dotColor: dotColor(for: date)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDate = date
                            HapticManager.selection()
                        }
                    }
                } else {
                    Color.clear
                        .frame(height: 42)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isWeekMode)
    }

    @ViewBuilder
    private var selectedDaySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack {
                if let date = selectedDate {
                    Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                } else {
                    Text("Select a date")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !selectedDaySessions.isEmpty {
                    Text("\(selectedDaySessions.count) game\(selectedDaySessions.count == 1 ? "" : "s")")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.dinkrGreen)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color.dinkrGreen.opacity(0.12), in: Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            if selectedDaySessions.isEmpty {
                emptyDayState
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(selectedDaySessions) { session in
                        NavigationLink {
                            GameSessionDetailView(session: session, viewModel: viewModel)
                        } label: {
                            CalendarGameRow(session: session)
                                .padding(.horizontal, 16)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }

    private var emptyDayState: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 28))
                .foregroundStyle(Color.dinkrGreen.opacity(0.45))
            Text("No games this day")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Button {
                viewModel.showHostGame = true
            } label: {
                Text("Host a Game")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.dinkrGreen)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.dinkrGreen.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Helpers

    private func stepMonth(by value: Int) {
        guard let next = calendar.date(byAdding: .month, value: value, to: displayedMonth) else { return }
        displayedMonth = next
        // If navigating month and current selection is outside new month, clear it
        if let sel = selectedDate,
           !calendar.isDate(sel, equalTo: next, toGranularity: .month) {
            selectedDate = nil
        }
    }

    private func reorderedWeekdays(_ symbols: [String]) -> [String] {
        let firstWeekday = calendar.firstWeekday // 1 = Sunday
        let offset = firstWeekday - 1
        if offset == 0 { return symbols }
        return Array(symbols[offset...] + symbols[..<offset])
    }
}

// MARK: - DayCell

private struct DayCell: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let dotColor: Color?
    let onTap: () -> Void

    private var dayNumber: String {
        String(Calendar.current.component(.day, from: date))
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                ZStack {
                    // Today outline ring
                    if isToday && !isSelected {
                        Circle()
                            .strokeBorder(Color.dinkrGreen.opacity(0.55), lineWidth: 1.5)
                            .frame(width: 30, height: 30)
                    }
                    // Selected fill
                    if isSelected {
                        Circle()
                            .fill(Color.dinkrGreen)
                            .frame(width: 30, height: 30)
                    }
                    Text(dayNumber)
                        .font(.system(size: 13, weight: isToday || isSelected ? .bold : .regular))
                        .foregroundStyle(isSelected ? .white : (isToday ? Color.dinkrGreen : .primary))
                }
                .frame(width: 30, height: 30)

                // Dot indicator
                if let color = dotColor {
                    Circle()
                        .fill(color)
                        .frame(width: 5, height: 5)
                } else {
                    Color.clear.frame(width: 5, height: 5)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - CalendarGameRow

private struct CalendarGameRow: View {
    let session: GameSession

    private var fillRatio: Double {
        guard session.totalSpots > 0 else { return 0 }
        return Double(session.rsvps.count) / Double(session.totalSpots)
    }

    private var statusColor: Color {
        if session.isFull { return Color.dinkrCoral }
        if fillRatio >= 0.75 { return Color.dinkrAmber }
        return Color.dinkrGreen
    }

    private var timeText: String {
        session.dateTime.formatted(.dateTime.hour().minute())
    }

    var body: some View {
        HStack(spacing: 12) {
            // Colored left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(statusColor)
                .frame(width: 3)
                .frame(height: 52)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(session.courtName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Spacer()
                    Text(timeText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 6) {
                    Text(session.format.rawValue.capitalized)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.12), in: Capsule())

                    Text("\(session.rsvps.count)/\(session.totalSpots) spots")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if session.isFull {
                        Text("Full")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.dinkrCoral)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.dinkrCoral.opacity(0.12), in: Capsule())
                    } else if session.spotsRemaining <= 2 {
                        Text("\(session.spotsRemaining) left")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.dinkrAmber)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.dinkrAmber.opacity(0.12), in: Capsule())
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.secondary.opacity(0.5))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Calendar extension helper

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScrollView {
            GameCalendarView(
                sessions: GameSession.mockSessions,
                viewModel: PlayViewModel()
            )
        }
    }
}

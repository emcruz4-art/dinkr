import SwiftUI

// MARK: - AvailabilityPollView

struct AvailabilityPollView: View {
    let group: DinkrGroup
    let currentUserId: String

    // 14-day calendar state
    @State private var selectedDayIndex: Int? = nil
    @State private var selectedSlots: Set<DaySlotKey> = []
    @State private var showScheduleGame = false
    @State private var showScheduledConfirmation = false

    // Simulated member availability data (keyed by day offset + slot)
    private let memberCount = 12
    private let simulatedVotes: [DaySlotKey: Int] = Self.buildMockVotes()

    // Countdown timer
    @State private var secondsRemaining: Int = 72 * 3600  // 72h poll window
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Derived

    private var calendarDays: [CalendarDay] {
        (0..<14).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: Date()))!
            return CalendarDay(offset: offset, date: date)
        }
    }

    private var bestSlot: (day: CalendarDay, slot: TimeSlotKind, votes: Int)? {
        var best: (day: CalendarDay, slot: TimeSlotKind, votes: Int)? = nil
        for day in calendarDays {
            for slot in TimeSlotKind.allCases {
                let key = DaySlotKey(dayOffset: day.offset, slot: slot)
                let votes = (simulatedVotes[key] ?? 0) + (selectedSlots.contains(key) ? 1 : 0)
                if votes > (best?.votes ?? 0) {
                    best = (day: day, slot: slot, votes: votes)
                }
            }
        }
        return best
    }

    private var expiryLabel: String {
        let h = secondsRemaining / 3600
        let m = (secondsRemaining % 3600) / 60
        let s = secondsRemaining % 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        return String(format: "%02dm %02ds", m, s)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // ── Header ────────────────────────────────────────────
                    pollHeader

                    // ── Expiry countdown ──────────────────────────────────
                    expiryBanner
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    // ── Best time recommendation ──────────────────────────
                    if let best = bestSlot, best.votes > 0 {
                        bestTimeBanner(best: best)
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                    }

                    // ── 14-day calendar grid ──────────────────────────────
                    calendarGrid
                        .padding(.top, 16)

                    // ── Time slot selector ────────────────────────────────
                    if let dayIndex = selectedDayIndex {
                        timeSlotsPanel(for: calendarDays[dayIndex])
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // ── Schedule Game CTA ─────────────────────────────────
                    scheduleGameButton
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Availability Poll")
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(timer) { _ in
                if secondsRemaining > 0 { secondsRemaining -= 1 }
            }
            .sheet(isPresented: $showScheduleGame) {
                scheduleGameSheet
            }
        }
    }

    // MARK: - Header

    private var pollHeader: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color.dinkrNavy, Color.dinkrGreen.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 140)

            // watermark
            Image(systemName: "calendar")
                .font(.system(size: 100, weight: .black))
                .foregroundStyle(.white.opacity(0.05))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("📅")
                        .font(.title3)
                    Text("When can you play?")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }
                Text(group.name)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.80))
                Text("Select days + time slots below — results update in real time")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.60))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
    }

    // MARK: - Expiry Banner

    private var expiryBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(secondsRemaining < 3600 ? Color.dinkrCoral : Color.dinkrAmber)
            Text("Poll closes in")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(expiryLabel)
                .font(.caption.weight(.bold))
                .foregroundStyle(secondsRemaining < 3600 ? Color.dinkrCoral : Color.dinkrAmber)
                .monospacedDigit()
            Spacer()
            Text("\(memberCount) members")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            (secondsRemaining < 3600 ? Color.dinkrCoral : Color.dinkrAmber).opacity(0.08),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke((secondsRemaining < 3600 ? Color.dinkrCoral : Color.dinkrAmber).opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Best Time Banner

    private func bestTimeBanner(best: (day: CalendarDay, slot: TimeSlotKind, votes: Int)) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "star.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.dinkrGreen)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Best time")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(Color.dinkrGreen)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Text("\(best.day.weekdayLabel) · \(best.slot.label) · \(best.votes)/\(memberCount) members available")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            Spacer()

            Button {
                HapticManager.medium()
                showScheduleGame = true
            } label: {
                Text("Schedule")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.dinkrGreen)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.dinkrGreen.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.dinkrGreen.opacity(0.25), lineWidth: 1.5)
        )
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.dinkrNavy)
                Text("Next 14 Days")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Text("Tap a day to select time slots")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)

            // 7-column grid, 2 rows
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(calendarDays) { day in
                    CalendarDayCell(
                        day: day,
                        isSelected: selectedDayIndex == day.offset,
                        hasSelection: hasAnySlotSelected(for: day),
                        availabilityHeat: heatScore(for: day)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDayIndex = selectedDayIndex == day.offset ? nil : day.offset
                        }
                        HapticManager.selection()
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Time Slots Panel

    private func timeSlotsPanel(for day: CalendarDay) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.dinkrNavy)
                Text("\(day.weekdayLabel), \(day.monthDayLabel)")
                    .font(.system(size: 14, weight: .bold))
            }

            VStack(spacing: 10) {
                ForEach(TimeSlotKind.allCases, id: \.self) { slot in
                    let key = DaySlotKey(dayOffset: day.offset, slot: slot)
                    let memberVotes = (simulatedVotes[key] ?? 0)
                    let myVote = selectedSlots.contains(key)
                    let totalVotes = memberVotes + (myVote ? 1 : 0)

                    TimeSlotRow(
                        slot: slot,
                        memberVotes: memberVotes,
                        memberCount: memberCount,
                        isSelected: myVote,
                        totalVotes: totalVotes
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                            if selectedSlots.contains(key) {
                                selectedSlots.remove(key)
                            } else {
                                selectedSlots.insert(key)
                            }
                        }
                        HapticManager.selection()
                    }
                }
            }
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.dinkrGreen.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: - Schedule Game Button

    private var scheduleGameButton: some View {
        Button {
            HapticManager.medium()
            showScheduleGame = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.plus")
                    .font(.subheadline.weight(.semibold))
                Text("Schedule Game")
                    .font(.headline.weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.dinkrGreen.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .opacity(bestSlot?.votes ?? 0 > 0 ? 1 : 0.5)
    }

    // MARK: - Schedule Sheet

    private var scheduleGameSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let best = bestSlot {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.dinkrGreen)

                        Text("Ready to Schedule")
                            .font(.title2.weight(.bold))

                        VStack(spacing: 6) {
                            Text("Best time slot:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(best.day.weekdayLabel), \(best.day.monthDayLabel)")
                                .font(.title3.weight(.bold))
                            Text(best.slot.timeRange)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: "person.2.fill")
                                    .font(.caption)
                                Text("\(best.votes) of \(memberCount) members available")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(Color.dinkrGreen)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.dinkrGreen.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 20)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        HapticManager.success()
                        showScheduleGame = false
                        showScheduledConfirmation = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar.badge.plus")
                            Text("Create Game Session")
                                .font(.headline.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.dinkrGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.dinkrGreen.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)

                    Button("Cancel") { showScheduleGame = false }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 32)
            }
            .padding(.top, 32)
            .background(Color.appBackground)
            .navigationTitle("Schedule Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Dismiss") { showScheduleGame = false }
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func hasAnySlotSelected(for day: CalendarDay) -> Bool {
        TimeSlotKind.allCases.contains { slot in
            selectedSlots.contains(DaySlotKey(dayOffset: day.offset, slot: slot))
        }
    }

    private func heatScore(for day: CalendarDay) -> Double {
        // sum of mock votes across all 3 slots for this day, normalized to 0–1
        let total = TimeSlotKind.allCases.reduce(0) { sum, slot in
            sum + (simulatedVotes[DaySlotKey(dayOffset: day.offset, slot: slot)] ?? 0)
        }
        let max = Double(memberCount) * 3
        return max > 0 ? Double(total) / max : 0
    }

    private static func buildMockVotes() -> [DaySlotKey: Int] {
        var votes: [DaySlotKey: Int] = [:]
        let highDays = [0, 1, 5, 6, 7, 12, 13]  // today, tomorrow, weekend, next weekend
        for offset in 0..<14 {
            for slot in TimeSlotKind.allCases {
                let base: Int = highDays.contains(offset) ? Int.random(in: 4...10) : Int.random(in: 0...4)
                votes[DaySlotKey(dayOffset: offset, slot: slot)] = base
            }
        }
        return votes
    }
}

// MARK: - Calendar Day Cell

private struct CalendarDayCell: View {
    let day: CalendarDay
    let isSelected: Bool
    let hasSelection: Bool
    let availabilityHeat: Double
    let onTap: () -> Void

    private var heatColor: Color {
        if availabilityHeat >= 0.6 { return Color.dinkrGreen }
        if availabilityHeat >= 0.3 { return Color.dinkrAmber }
        return Color.dinkrCoral.opacity(0.7)
    }

    private var isToday: Bool { day.offset == 0 }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                Text(day.weekdayAbbrev)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .textCase(.uppercase)

                Text(day.dayNumber)
                    .font(.system(size: 14, weight: isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? .white : .primary)

                // heat dot
                Circle()
                    .fill(isSelected ? .white.opacity(0.9) : heatColor)
                    .frame(width: 5, height: 5)
                    .opacity(availabilityHeat > 0 ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        Color.dinkrGreen
                    } else if isToday {
                        Color.dinkrGreen.opacity(0.12)
                    } else {
                        Color.cardBackground
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? Color.clear :
                        (hasSelection ? Color.dinkrGreen.opacity(0.6) :
                        (isToday ? Color.dinkrGreen.opacity(0.3) : Color.secondary.opacity(0.12))),
                        lineWidth: isSelected ? 0 : (hasSelection ? 1.5 : 1)
                    )
            )
            .shadow(color: isSelected ? Color.dinkrGreen.opacity(0.35) : .clear, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Time Slot Row

private struct TimeSlotRow: View {
    let slot: TimeSlotKind
    let memberVotes: Int
    let memberCount: Int
    let isSelected: Bool
    let totalVotes: Int
    let onTap: () -> Void

    private var heatColor: Color {
        let ratio = Double(memberVotes) / Double(max(memberCount, 1))
        if ratio >= 0.6 { return Color.dinkrGreen }
        if ratio >= 0.3 { return Color.dinkrAmber }
        return Color.dinkrCoral
    }

    private var fillRatio: Double {
        Double(totalVotes) / Double(max(memberCount, 1))
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Slot icon + label
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(slot.iconBackground)
                        .frame(width: 36, height: 36)
                    Image(systemName: slot.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(slot.iconColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(slot.label)
                            .font(.subheadline.weight(isSelected ? .bold : .semibold))
                            .foregroundStyle(isSelected ? heatColor : .primary)
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(heatColor)
                        }
                    }
                    Text(slot.timeRange)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Member count + heat bar
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(totalVotes)/\(memberCount)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(heatColor)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.12))
                                .frame(height: 5)
                            Capsule()
                                .fill(heatColor)
                                .frame(width: max(4, geo.size.width * fillRatio), height: 5)
                                .animation(.easeInOut(duration: 0.35), value: fillRatio)
                        }
                    }
                    .frame(width: 60, height: 5)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                isSelected ? heatColor.opacity(0.08) : Color.appBackground,
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? heatColor.opacity(0.4) : Color.secondary.opacity(0.12),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
    }
}

// MARK: - Supporting Types

struct CalendarDay: Identifiable {
    let offset: Int
    let date: Date

    var id: Int { offset }

    private static let weekdayFull: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f
    }()
    private static let monthDay: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f
    }()
    private static let dayNum: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d"; return f
    }()
    private static let weekdayFull2: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEEE"; return f
    }()

    var weekdayAbbrev: String { Self.weekdayFull.string(from: date) }
    var dayNumber: String { Self.dayNum.string(from: date) }
    var monthDayLabel: String { Self.monthDay.string(from: date) }
    var weekdayLabel: String { Self.weekdayFull2.string(from: date) }
}

enum TimeSlotKind: String, CaseIterable {
    case morning   = "Morning"
    case afternoon = "Afternoon"
    case evening   = "Evening"

    var label: String { rawValue }

    var timeRange: String {
        switch self {
        case .morning:   return "6:00 AM – 12:00 PM"
        case .afternoon: return "12:00 PM – 5:00 PM"
        case .evening:   return "5:00 PM – 10:00 PM"
        }
    }

    var icon: String {
        switch self {
        case .morning:   return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening:   return "moon.stars.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .morning:   return Color.dinkrAmber
        case .afternoon: return Color.dinkrCoral
        case .evening:   return Color.dinkrNavy
        }
    }

    var iconBackground: Color {
        switch self {
        case .morning:   return Color.dinkrAmber.opacity(0.12)
        case .afternoon: return Color.dinkrCoral.opacity(0.12)
        case .evening:   return Color.dinkrNavy.opacity(0.10)
        }
    }
}

struct DaySlotKey: Hashable {
    let dayOffset: Int
    let slot: TimeSlotKind
}

// MARK: - AvailabilityPollCard (kept for GroupDetailView / GroupFeedView use)

struct AvailabilityPollCard: View {
    let poll: AvailabilityPoll
    let currentUserId: String

    @State private var localPoll: AvailabilityPoll
    @State private var showScheduleConfirm = false

    init(poll: AvailabilityPoll, currentUserId: String) {
        self.poll = poll
        self.currentUserId = currentUserId
        self._localPoll = State(initialValue: poll)
    }

    private var maxVotes: Int {
        localPoll.timeSlots.map(\.voteCount).max() ?? 1
    }

    private var hoursUntilClose: Int {
        max(0, Int(localPoll.closesAt.timeIntervalSince(Date()) / 3600))
    }

    private var minutesUntilClose: Int {
        let total = max(0, Int(localPoll.closesAt.timeIntervalSince(Date())))
        return (total % 3600) / 60
    }

    private var expiryLabel: String {
        let h = hoursUntilClose
        if h >= 1 { return "Closes in \(h)h \(minutesUntilClose)m" }
        return "Closes in \(minutesUntilClose)m"
    }

    private var timeAgoText: String {
        let interval = Date().timeIntervalSince(localPoll.createdAt)
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }

    private var isCreator: Bool { localPoll.createdByUserId == currentUserId }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ─────────────────────────────────────────────────
            HStack(spacing: 10) {
                Text("📅")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(localPoll.question)
                        .font(.subheadline.weight(.bold))
                    Text("by \(localPoll.createdByName) · \(timeAgoText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if localPoll.isOpen {
                    Text("OPEN")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color.dinkrGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.dinkrGreen.opacity(0.12))
                        .clipShape(Capsule())
                } else {
                    Text("CLOSED")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider().padding(.horizontal, 16)

            // ── Time slot rows ──────────────────────────────────────────
            VStack(spacing: 0) {
                ForEach(localPoll.timeSlots) { slot in
                    PollSlotRow(
                        slot: slot,
                        maxVotes: maxVotes,
                        isWinner: localPoll.winningSlot?.id == slot.id,
                        currentUserId: currentUserId,
                        isOpen: localPoll.isOpen
                    ) {
                        toggleVote(for: slot)
                    }
                    Divider().padding(.leading, 16)
                }
            }

            // ── Schedule This Time button (winner) ──────────────────────
            if !localPoll.isOpen || isCreator, let winner = localPoll.winningSlot {
                Button {
                    HapticManager.medium()
                    showScheduleConfirm = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.subheadline.weight(.semibold))
                        Text("Schedule This Time")
                            .font(.subheadline.weight(.bold))
                        Spacer()
                        Text(slotFormattedDate(winner.dateTime))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen.opacity(0.8))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.dinkrGreen)
                }
                .buttonStyle(.plain)
            }

            // ── Footer ──────────────────────────────────────────────────
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(localPoll.totalVotes) voters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if localPoll.isOpen {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(expiryLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.dinkrGreen.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        .alert("Schedule Game", isPresented: $showScheduleConfirm) {
            Button("Schedule", role: .none) { HapticManager.medium() }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let winner = localPoll.winningSlot {
                Text("Create a session for \(slotFormattedDate(winner.dateTime))?")
            }
        }
    }

    private func toggleVote(for slot: PollTimeSlot) {
        guard localPoll.isOpen else { return }
        HapticManager.selection()
        if let idx = localPoll.timeSlots.firstIndex(where: { $0.id == slot.id }) {
            if localPoll.timeSlots[idx].votes.contains(currentUserId) {
                localPoll.timeSlots[idx].votes.removeAll { $0 == currentUserId }
            } else {
                localPoll.timeSlots[idx].votes.append(currentUserId)
            }
        }
    }

    private func slotFormattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d · h:mm a"
        return f.string(from: date)
    }
}

// MARK: - Poll Slot Row

private struct PollSlotRow: View {
    let slot: PollTimeSlot
    let maxVotes: Int
    let isWinner: Bool
    let currentUserId: String
    let isOpen: Bool
    let onTap: () -> Void

    private var hasVoted: Bool { slot.votes.contains(currentUserId) }
    private var barRatio: Double {
        guard maxVotes > 0 else { return 0 }
        return Double(slot.voteCount) / Double(maxVotes)
    }

    private var formattedDateTime: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d · h:mm a"
        return f.string(from: slot.dateTime)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedDateTime)
                        .font(.subheadline.weight(isWinner ? .bold : .regular))
                        .foregroundStyle(isWinner ? Color.dinkrGreen : Color.primary)
                }
                .frame(minWidth: 160, alignment: .leading)

                Spacer()

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.1))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isWinner ? Color.dinkrGreen : Color.dinkrSky.opacity(0.7))
                            .frame(width: geo.size.width * barRatio, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: barRatio)
                    }
                }
                .frame(height: 8)

                Text("\(slot.voteCount)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isWinner ? Color.dinkrGreen : Color.secondary)
                    .frame(minWidth: 20)

                Image(systemName: hasVoted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(hasVoted ? Color.dinkrGreen : Color.secondary.opacity(0.4))
                    .font(.system(size: 18))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: hasVoted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isOpen)
    }
}

// MARK: - CreateAvailabilityPollView

struct CreateAvailabilityPollView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var question = "When should we play?"
    @State private var timeSlots: [Date] = [
        Calendar.current.date(byAdding: .day, value: 1,
            to: Calendar.current.startOfDay(for: Date()))
            .flatMap { Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: $0) }
            ?? Date()
    ]
    @State private var closeDurationIndex = 0

    private let closeDurations = ["24 hours", "48 hours", "1 week"]
    private let maxSlots = 6

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // ── Question field ─────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Question", systemImage: "questionmark.bubble.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        TextField("When should we play?", text: $question)
                            .padding(12)
                            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.dinkrGreen.opacity(0.25), lineWidth: 1)
                            )
                    }

                    // ── Time slots ──────────────────────────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Time Slots", systemImage: "calendar")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            Spacer()
                            if timeSlots.count < maxSlots {
                                Button {
                                    HapticManager.selection()
                                    let next = Calendar.current.date(
                                        byAdding: .day, value: 1,
                                        to: timeSlots.last ?? Date()
                                    ) ?? Date()
                                    timeSlots.append(next)
                                } label: {
                                    Label("Add Slot", systemImage: "plus.circle.fill")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.dinkrGreen)
                                }
                            }
                        }

                        ForEach(timeSlots.indices, id: \.self) { idx in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.dinkrGreen.opacity(0.12))
                                        .frame(width: 28, height: 28)
                                    Text("\(idx + 1)")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.dinkrGreen)
                                }

                                DatePicker(
                                    "",
                                    selection: $timeSlots[idx],
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Button(role: .destructive) {
                                    HapticManager.selection()
                                    timeSlots.remove(at: idx)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundStyle(Color.dinkrCoral)
                                }
                                .disabled(timeSlots.count <= 1)
                                .opacity(timeSlots.count <= 1 ? 0.3 : 1)
                            }
                            .padding(12)
                            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                            )
                        }

                        if timeSlots.count >= maxSlots {
                            Text("Maximum \(maxSlots) slots reached")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // ── Poll duration ──────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Poll closes after", systemImage: "clock.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        Picker("Close after", selection: $closeDurationIndex) {
                            ForEach(closeDurations.indices, id: \.self) { i in
                                Text(closeDurations[i]).tag(i)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // ── Send button ────────────────────────────────────
                    Button {
                        HapticManager.medium()
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.fill")
                            Text("Send Poll")
                                .font(.headline.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.dinkrGreen.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .navigationTitle("Schedule a Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .background(Color.appBackground)
        }
    }
}

// MARK: - Preview

#Preview("Availability Poll View") {
    AvailabilityPollView(group: DinkrGroup.mockGroups[0], currentUserId: "user_001")
}

#Preview("Poll Card") {
    AvailabilityPollCard(poll: .mock, currentUserId: "user_001")
        .padding()
}

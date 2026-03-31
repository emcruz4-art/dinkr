import SwiftUI

// MARK: - CourtBookingView

struct CourtBookingView: View {
    let courtName: String

    @Environment(\.dismiss) private var dismiss

    // MARK: State
    @State private var selectedDateIndex: Int = 0
    @State private var selectedSlotIndex: Int? = nil
    @State private var selectedDuration: BookingDuration = .oneHour
    @State private var playerCount: Int = 2
    @State private var showSuccess = false

    // MARK: Constants
    private let hourlyRate: Double = 8.0

    // MARK: Derived dates
    private var availableDates: [Date] {
        let cal = Calendar.current
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: Date()) }
    }

    private var selectedDate: Date {
        availableDates[selectedDateIndex]
    }

    // MARK: Slot availability (seeded by court name hash — deterministic)
    private var takenSlots: Set<Int> {
        let seed = courtName.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        var taken = Set<Int>()
        var rng = seed
        for i in 0..<slotCount {
            rng = (rng &* 1664525 &+ 1013904223) & 0x7FFFFFFF
            if (rng % 100) < 60 {
                taken.insert(i)
            }
        }
        return taken
    }

    // 6am–10pm = 16 slots
    private let slotCount = 16
    private let startHour = 6

    private func slotLabel(_ index: Int) -> String {
        let hour = startHour + index
        let suffix = hour < 12 ? "AM" : "PM"
        let h = hour <= 12 ? hour : hour - 12
        let endHour = hour + 1
        let endSuffix = endHour < 12 ? "AM" : "PM"
        let eh = endHour <= 12 ? endHour : endHour - 12
        return "\(h)\(suffix)–\(eh)\(endSuffix)"
    }

    private func isSlotAvailable(_ index: Int) -> Bool {
        guard !takenSlots.contains(index) else { return false }
        // Check consecutive open slots for duration
        let needed = selectedDuration.slots
        for offset in 0..<needed {
            let idx = index + offset
            if idx >= slotCount || takenSlots.contains(idx) { return false }
        }
        return true
    }

    // MARK: Price
    private var totalPrice: Double {
        selectedDuration.hours * hourlyRate
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // MARK: Date Strip
                    dateSelectorSection
                        .padding(.top, 20)

                    // MARK: Duration
                    durationPickerSection
                        .padding(.top, 24)

                    // MARK: Time Slots
                    timeSlotGridSection
                        .padding(.top, 24)

                    // MARK: Players
                    playerCountSection
                        .padding(.top, 24)

                    // MARK: Summary
                    if selectedSlotIndex != nil {
                        summaryCard
                            .padding(.top, 24)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color.appBackground)
            .navigationTitle("Book a Court")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
            .sheet(isPresented: $showSuccess) {
                BookingSuccessSheet(
                    courtName: courtName,
                    date: selectedDate,
                    slotLabel: selectedSlotIndex.map { slotLabel($0) } ?? "",
                    duration: selectedDuration,
                    playerCount: playerCount
                ) {
                    showSuccess = false
                    dismiss()
                }
            }
            .animation(.easeInOut(duration: 0.25), value: selectedSlotIndex)
        }
    }

    // MARK: - Date Selector

    private var dateSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Select Date", icon: "calendar")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(availableDates.enumerated()), id: \.offset) { index, date in
                        DateChip(
                            date: date,
                            index: index,
                            isSelected: selectedDateIndex == index
                        ) {
                            selectedDateIndex = index
                            selectedSlotIndex = nil
                        }
                    }
                }
                .padding(.horizontal, 1)
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Duration Picker

    private var durationPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Duration", icon: "clock.fill")

            Picker("Duration", selection: $selectedDuration) {
                ForEach(BookingDuration.allCases) { dur in
                    Text(dur.label).tag(dur)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedDuration) { _, _ in
                // Deselect if selected slot no longer valid for new duration
                if let idx = selectedSlotIndex, !isSlotAvailable(idx) {
                    selectedSlotIndex = nil
                }
            }
        }
    }

    // MARK: - Time Slot Grid

    private var timeSlotGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Available Times", icon: "clock.badge.checkmark.fill")

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                ForEach(0..<slotCount, id: \.self) { index in
                    TimeSlotCard(
                        label: slotLabel(index),
                        state: slotState(index),
                        isSelected: selectedSlotIndex == index
                    ) {
                        if isSlotAvailable(index) {
                            selectedSlotIndex = (selectedSlotIndex == index) ? nil : index
                        }
                    }
                }
            }
        }
    }

    private func slotState(_ index: Int) -> TimeSlotState {
        if takenSlots.contains(index) { return .taken }
        if !isSlotAvailable(index) { return .taken } // consecutive slots unavailable
        return .available
    }

    // MARK: - Player Count

    private var playerCountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Players", icon: "person.2.fill")

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Number of Players")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.dinkrNavy)
                    Text("Min 2, Max 4")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Stepper(
                    value: $playerCount,
                    in: 2...4
                ) {
                    Text("\(playerCount)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.dinkrGreen)
                        .frame(minWidth: 32, alignment: .center)
                }
                .labelsHidden()
            }
            .padding(16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Booking Summary", icon: "doc.text.fill")

            VStack(spacing: 0) {
                SummaryRow(label: "Court", value: courtName)
                Divider().padding(.horizontal, 16)
                SummaryRow(label: "Date", value: selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                Divider().padding(.horizontal, 16)
                SummaryRow(label: "Time", value: selectedSlotIndex.map { slotLabel($0) } ?? "—")
                Divider().padding(.horizontal, 16)
                SummaryRow(label: "Duration", value: selectedDuration.label)
                Divider().padding(.horizontal, 16)
                SummaryRow(label: "Players", value: "\(playerCount)")
                Divider().padding(.horizontal, 16)

                HStack {
                    Text("Total")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)
                    Spacer()
                    Text(String(format: "$%.2f", totalPrice))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.dinkrGreen)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Text("$\(Int(hourlyRate))/hr per court")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Confirm button
            Button {
                showSuccess = true
            } label: {
                Text("Confirm Booking")
                    .font(.headline)
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
                    .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 8, y: 4)
            }
        }
    }

    // MARK: - Section Header Helper

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.6)
    }
}

// MARK: - DateChip

private struct DateChip: View {
    let date: Date
    let index: Int
    let isSelected: Bool
    let onTap: () -> Void

    private var dayLabel: String {
        switch index {
        case 0: return "Today"
        case 1: return "Tomorrow"
        default: return date.formatted(.dateTime.weekday(.abbreviated))
        }
    }

    private var dayNumber: String {
        date.formatted(.dateTime.day())
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(dayLabel)
                    .font(.caption.weight(.semibold))
                Text(dayNumber)
                    .font(.title3.weight(.bold))
            }
            .foregroundStyle(isSelected ? .white : Color.dinkrNavy)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.dinkrGreen : Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.dinkrNavy.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.dinkrGreen.opacity(0.3) : Color.clear, radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - TimeSlotState

private enum TimeSlotState {
    case available, taken
}

// MARK: - TimeSlotCard

private struct TimeSlotCard: View {
    let label: String
    let state: TimeSlotState
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .strikethrough(state == .taken)
                    .foregroundStyle(cardTextColor)

                statusChip
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? Color.dinkrGreen : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(state == .taken)
    }

    private var cardBackground: some View {
        ZStack {
            if isSelected {
                Color.dinkrGreen
            } else if state == .taken {
                Color(UIColor.systemGray5)
            } else {
                Color.cardBackground
            }
        }
    }

    private var cardTextColor: Color {
        if isSelected { return .white }
        if state == .taken { return .secondary }
        return Color.dinkrNavy
    }

    private var statusChip: some View {
        ZStack {
            if isSelected {
                Capsule()
                    .fill(Color.white.opacity(0.25))
                Text("Selected")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
            } else if state == .taken {
                Capsule()
                    .fill(Color.red.opacity(0.12))
                Text("Booked")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.red)
            } else {
                Capsule()
                    .fill(Color.dinkrGreen.opacity(0.12))
                Text("Open")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.dinkrGreen)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .fixedSize()
    }
}

// MARK: - SummaryRow

private struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.dinkrNavy)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - BookingDuration

enum BookingDuration: String, CaseIterable, Identifiable {
    case oneHour = "1hr"
    case oneAndHalf = "1.5hr"
    case twoHour = "2hr"

    var id: String { rawValue }

    var label: String { rawValue }

    var slots: Int {
        switch self {
        case .oneHour: return 1
        case .oneAndHalf: return 2   // rounds up — occupies 2 slots
        case .twoHour: return 2
        }
    }

    var hours: Double {
        switch self {
        case .oneHour: return 1.0
        case .oneAndHalf: return 1.5
        case .twoHour: return 2.0
        }
    }
}

// MARK: - BookingSuccessSheet

struct BookingSuccessSheet: View {
    let courtName: String
    let date: Date
    let slotLabel: String
    let duration: BookingDuration
    let playerCount: Int
    let onDone: () -> Void

    @State private var animateCheckmark = false

    private var confirmationNumber: String {
        "DKR-" + UUID().uuidString.prefix(8).uppercased()
    }

    // Generate once so it doesn't change on re-render
    @State private var confirmNumber: String = "DKR-" + UUID().uuidString.prefix(8).uppercased()

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 28)

            // Animated badge
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.12))
                    .frame(width: 100, height: 100)
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.2))
                    .frame(width: 75, height: 75)
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen)
                        .frame(width: 56, height: 56)
                    Image(systemName: animateCheckmark ? "checkmark" : "sportscourt")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(animateCheckmark ? 1.1 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: animateCheckmark)
                }
            }
            .padding(.bottom, 20)

            Text("Court Booked!")
                .font(.title.weight(.bold))
                .foregroundStyle(Color.dinkrNavy)
                .padding(.bottom, 6)

            Text(courtName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 28)

            // Details card
            VStack(spacing: 0) {
                SuccessDetailRow(icon: "calendar", label: "Date", value: date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                Divider().padding(.horizontal, 16)
                SuccessDetailRow(icon: "clock.fill", label: "Time", value: slotLabel)
                Divider().padding(.horizontal, 16)
                SuccessDetailRow(icon: "timer", label: "Duration", value: duration.label)
                Divider().padding(.horizontal, 16)
                SuccessDetailRow(icon: "person.2.fill", label: "Players", value: "\(playerCount)")
                Divider().padding(.horizontal, 16)
                SuccessDetailRow(icon: "number.circle.fill", label: "Confirmation", value: confirmNumber)
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)

            Spacer(minLength: 32)

            // Action buttons
            VStack(spacing: 12) {
                Button {
                    // Add to Calendar placeholder
                } label: {
                    Label("Add to Calendar", systemImage: "calendar.badge.plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.dinkrGreen.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.dinkrGreen.opacity(0.4), lineWidth: 1.5)
                        )
                }

                Button(action: onDone) {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.dinkrGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateCheckmark = true
            }
        }
    }
}

// MARK: - SuccessDetailRow

private struct SuccessDetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.dinkrGreen)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.dinkrNavy)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

// MARK: - Preview

#Preview {
    CourtBookingView(courtName: "Westside Pickleball Complex")
}

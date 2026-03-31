import SwiftUI

// MARK: - Availability Status

enum SlotAvailability {
    case available    // green — open, multiple spots
    case oneSpot      // amber — 1 spot left
    case full         // red — fully booked
    case closed       // grey — outside operating hours

    var color: Color {
        switch self {
        case .available: return Color.dinkrGreen
        case .oneSpot:   return Color.dinkrAmber
        case .full:      return Color.dinkrCoral
        case .closed:    return Color(UIColor.systemGray4)
        }
    }

    var label: String {
        switch self {
        case .available: return "Open"
        case .oneSpot:   return "1 Spot"
        case .full:      return "Full"
        case .closed:    return "Closed"
        }
    }

    var icon: String {
        switch self {
        case .available: return "checkmark.circle.fill"
        case .oneSpot:   return "exclamationmark.circle.fill"
        case .full:      return "xmark.circle.fill"
        case .closed:    return "minus.circle.fill"
        }
    }

    var isBookable: Bool {
        self == .available || self == .oneSpot
    }
}

// MARK: - CourtAvailabilityView

struct CourtAvailabilityView: View {
    let venueName: String
    let maxCourts: Int

    @Environment(\.dismiss) private var dismiss

    @State private var selectedDateIndex: Int = 0
    @State private var selectedCourtIndex: Int = 0
    @State private var showBooking = false
    @State private var preSelectedSlot: Int? = nil

    // 6AM to 10PM = 16 hour slots
    private let startHour = 6
    private let endHour = 22
    private var slotCount: Int { endHour - startHour }

    // Next 7 days
    private var availableDates: [Date] {
        let cal = Calendar.current
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: Date()) }
    }

    // Peak hours data for bar chart (relative busyness 0.0–1.0)
    private let peakHoursData: [(hour: String, level: Double)] = [
        ("6AM", 0.2), ("7AM", 0.35), ("8AM", 0.55), ("9AM", 0.75),
        ("10AM", 0.9), ("11AM", 0.85), ("12PM", 0.7), ("1PM", 0.65),
        ("2PM", 0.5), ("3PM", 0.6), ("4PM", 0.8), ("5PM", 1.0),
        ("6PM", 0.95), ("7PM", 0.85), ("8PM", 0.7), ("9PM", 0.45)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // MARK: Date Strip
                    dateSelectorSection
                        .padding(.top, 16)

                    // MARK: Court Chips
                    courtSelectorSection
                        .padding(.top, 20)

                    // MARK: Time Grid
                    timeGridSection
                        .padding(.top, 20)

                    // MARK: Legend
                    legendSection
                        .padding(.top, 20)

                    // MARK: Most Popular Times
                    popularTimesSection
                        .padding(.top, 24)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color.appBackground)
            .navigationTitle("Court Availability")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
            .sheet(isPresented: $showBooking) {
                CourtBookingView(
                    courtName: "\(venueName) — Court \(selectedCourtIndex + 1)",
                    preselectedSlotIndex: preSelectedSlot
                )
            }
        }
    }

    // MARK: - Date Selector

    private var dateSelectorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Select Date", icon: "calendar")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(availableDates.enumerated()), id: \.offset) { index, date in
                        AvailabilityDateChip(
                            date: date,
                            index: index,
                            isSelected: selectedDateIndex == index
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDateIndex = index
                            }
                        }
                    }
                }
                .padding(.horizontal, 1)
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Court Selector

    private var courtSelectorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Select Court", icon: "sportscourt")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<maxCourts, id: \.self) { i in
                        let isSelected = selectedCourtIndex == i
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCourtIndex = i
                            }
                        } label: {
                            Text("Court \(i + 1)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(isSelected ? .white : Color.dinkrNavy)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSelected ? Color.dinkrGreen : Color.cardBackground)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            isSelected ? Color.clear : Color.dinkrNavy.opacity(0.15),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: isSelected ? Color.dinkrGreen.opacity(0.3) : .clear, radius: 4, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 1)
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Time Slot Grid

    private var timeGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader("Availability", icon: "clock.fill")
                Spacer()
                Text("Tap an open slot to book")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ],
                spacing: 8
            ) {
                ForEach(0..<slotCount, id: \.self) { index in
                    let status = slotAvailability(dateIndex: selectedDateIndex, courtIndex: selectedCourtIndex, slotIndex: index)
                    AvailabilitySlotCell(
                        hour: slotHourLabel(index),
                        status: status
                    ) {
                        if status.isBookable {
                            preSelectedSlot = index
                            showBooking = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Legend

    private var legendSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Legend", icon: "info.circle")
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ],
                spacing: 8
            ) {
                ForEach([SlotAvailability.available, .oneSpot, .full, .closed], id: \.label) { status in
                    HStack(spacing: 8) {
                        Image(systemName: status.icon)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(status.color)
                        Text(status.label)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.dinkrNavy)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(status.color.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - Most Popular Times

    private var popularTimesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Most Popular Times", icon: "chart.bar.fill")

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(peakHoursData, id: \.hour) { entry in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(barColor(for: entry.level))
                                .frame(height: max(4, entry.level * 80))
                            Text(entry.hour)
                                .font(.system(size: 7, weight: .medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 100, alignment: .bottom)
                .padding(.horizontal, 4)

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.dinkrGreen)
                        .frame(width: 8, height: 8)
                    Text("Usually not busy")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Circle()
                        .fill(Color.dinkrAmber)
                        .frame(width: 8, height: 8)
                    Text("Moderate")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Circle()
                        .fill(Color.dinkrCoral)
                        .frame(width: 8, height: 8)
                    Text("Peak hours")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.6)
    }

    private func slotHourLabel(_ index: Int) -> String {
        let hour = startHour + index
        let suffix = hour < 12 ? "AM" : "PM"
        let h = hour == 0 ? 12 : (hour <= 12 ? hour : hour - 12)
        return "\(h)\(suffix)"
    }

    /// Deterministic pseudo-random availability seeded by date + court + slot
    private func slotAvailability(dateIndex: Int, courtIndex: Int, slotIndex: Int) -> SlotAvailability {
        // Operating hours: 6AM–10PM maps to slots 0–15 — all within range, no "closed" except edges
        // Mark very early (6–7AM) and very late (9–10PM) as potentially closed depending on court
        let isEdgeHour = slotIndex == 0 || slotIndex == slotCount - 1
        let seed = (dateIndex &* 31 &+ courtIndex &* 7 &+ slotIndex &* 13) &+ venueName.count
        let rng = abs((seed &* 1664525 &+ 1013904223) & 0x7FFFFFFF) % 100

        if isEdgeHour && rng < 30 { return .closed }

        switch rng {
        case 0..<45:   return .available
        case 45..<65:  return .full
        case 65..<78:  return .oneSpot
        default:       return .closed
        }
    }

    private func barColor(for level: Double) -> Color {
        switch level {
        case 0..<0.4:  return Color.dinkrGreen
        case 0.4..<0.7: return Color.dinkrAmber
        default:       return Color.dinkrCoral
        }
    }
}

// MARK: - AvailabilityDateChip

private struct AvailabilityDateChip: View {
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
            .shadow(color: isSelected ? Color.dinkrGreen.opacity(0.3) : .clear, radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AvailabilitySlotCell

private struct AvailabilitySlotCell: View {
    let hour: String
    let status: SlotAvailability
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(hour)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(foregroundColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                RoundedRectangle(cornerRadius: 3)
                    .fill(status.color.opacity(status == .closed ? 0.25 : 0.8))
                    .frame(height: 4)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(status.color.opacity(status == .closed ? 0.06 : 0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        status.isBookable ? status.color.opacity(0.4) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!status.isBookable)
    }

    private var foregroundColor: Color {
        switch status {
        case .available: return Color.dinkrGreen
        case .oneSpot:   return Color.dinkrAmber
        case .full:      return Color.dinkrCoral
        case .closed:    return Color(UIColor.systemGray3)
        }
    }
}

// MARK: - Preview

#Preview {
    CourtAvailabilityView(venueName: "Westside Pickleball Complex", maxCourts: 12)
}

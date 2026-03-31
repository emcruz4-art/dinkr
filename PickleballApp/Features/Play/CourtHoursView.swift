import SwiftUI

// MARK: - Supporting Types

private struct DaySchedule: Identifiable {
    let id = UUID()
    let day: String
    let shortDay: String
    var isOpen: Bool
    var openTime: String
    var closeTime: String

    var timeRange: String { "\(openTime) – \(closeTime)" }
}

private struct AmenityItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let available: Bool
}

private struct AccessibilityItem: Identifiable {
    let id = UUID()
    let systemImage: String
    let label: String
}

// MARK: - CourtHoursView

struct CourtHoursView: View {
    let venue: CourtVenue

    @State private var schedule: [DaySchedule] = [
        DaySchedule(day: "Monday",    shortDay: "Mon", isOpen: true,  openTime: "6:00 AM",  closeTime: "10:00 PM"),
        DaySchedule(day: "Tuesday",   shortDay: "Tue", isOpen: true,  openTime: "6:00 AM",  closeTime: "10:00 PM"),
        DaySchedule(day: "Wednesday", shortDay: "Wed", isOpen: true,  openTime: "6:00 AM",  closeTime: "10:00 PM"),
        DaySchedule(day: "Thursday",  shortDay: "Thu", isOpen: true,  openTime: "6:00 AM",  closeTime: "10:00 PM"),
        DaySchedule(day: "Friday",    shortDay: "Fri", isOpen: true,  openTime: "6:00 AM",  closeTime: "10:00 PM"),
        DaySchedule(day: "Saturday",  shortDay: "Sat", isOpen: true,  openTime: "7:00 AM",  closeTime: "8:00 PM"),
        DaySchedule(day: "Sunday",    shortDay: "Sun", isOpen: false,  openTime: "8:00 AM",  closeTime: "6:00 PM"),
    ]

    @State private var showSuggestAlert = false

    private var amenityItems: [AmenityItem] {
        let allAmenities = venue.amenities
        return [
            AmenityItem(icon: "car.fill",              label: "Parking",           available: allAmenities.contains("Parking")),
            AmenityItem(icon: "figure.walk",           label: "Restrooms",         available: allAmenities.contains("Restrooms")),
            AmenityItem(icon: "drop.fill",             label: "Water Fountain",    available: allAmenities.contains("Water Fountains")),
            AmenityItem(icon: "bag.fill",              label: "Pro Shop",          available: allAmenities.contains("Pro Shop")),
            AmenityItem(icon: "person.fill.checkmark", label: "Lessons Available", available: allAmenities.contains("Lessons") || allAmenities.contains("Coaching")),
            AmenityItem(icon: "lock.fill",             label: "Locker Room",       available: allAmenities.contains("Locker Rooms")),
        ]
    }

    private var accessibilityItems: [AccessibilityItem] {
        [
            AccessibilityItem(systemImage: "figure.roll",           label: "Wheelchair Accessible"),
            AccessibilityItem(systemImage: "parkingsign.circle",    label: "Accessible Parking"),
            AccessibilityItem(systemImage: "arrow.up.right.circle", label: "Ramp Access"),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Hours Section
                sectionHeader(icon: "clock.fill", title: "Hours")
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                VStack(spacing: 0) {
                    ForEach(Array(schedule.indices), id: \.self) { idx in
                        HStack {
                            Text(schedule[idx].day)
                                .font(.subheadline)
                                .foregroundStyle(Color.dinkrNavy)
                                .frame(width: 100, alignment: .leading)

                            Spacer()

                            if schedule[idx].isOpen {
                                Text(schedule[idx].timeRange)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.dinkrGreen)
                            } else {
                                Text("Closed")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.dinkrCoral)
                            }

                            Toggle("", isOn: $schedule[idx].isOpen)
                                .labelsHidden()
                                .tint(Color.dinkrGreen)
                                .scaleEffect(0.8)
                                .frame(width: 50)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.cardBackground)

                        if idx < schedule.count - 1 {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
                .padding(.horizontal, 20)

                // MARK: Surface Details Section
                sectionHeader(icon: "sportscourt.fill", title: "Surface Details")
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 10)

                VStack(spacing: 0) {
                    surfaceDetailRow(
                        label: "Surface Type",
                        content: AnyView(
                            Text(venue.surface.rawValue.capitalized)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.dinkrSky)
                                .clipShape(Capsule())
                        )
                    )
                    Divider().padding(.leading, 16)

                    surfaceDetailRow(
                        label: "Number of Courts",
                        content: AnyView(
                            Text("\(venue.courtCount)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.dinkrNavy)
                        )
                    )
                    Divider().padding(.leading, 16)

                    surfaceDetailRow(
                        label: "Setting",
                        content: AnyView(
                            Text(venue.isIndoor ? "Indoor" : "Outdoor")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(venue.isIndoor ? Color.dinkrNavy : Color.dinkrAmber)
                                .clipShape(Capsule())
                        )
                    )
                    Divider().padding(.leading, 16)

                    surfaceDetailRow(
                        label: "Lighting",
                        content: AnyView(
                            HStack(spacing: 5) {
                                Image(systemName: venue.hasLighting ? "flashlight.on.fill" : "flashlight.off.fill")
                                    .font(.caption.weight(.bold))
                                Text(venue.hasLighting ? "Yes" : "No")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(venue.hasLighting ? Color.dinkrAmber : .secondary)
                        )
                    )
                    Divider().padding(.leading, 16)

                    surfaceDetailRow(
                        label: "Net Type",
                        content: AnyView(
                            Text("Permanent")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.dinkrNavy)
                        )
                    )
                }
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
                .padding(.horizontal, 20)

                // MARK: Amenities Section
                sectionHeader(icon: "checkmark.seal.fill", title: "Amenities")
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 10)

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                    ],
                    spacing: 10
                ) {
                    ForEach(amenityItems) { item in
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(item.available ? Color.dinkrGreen.opacity(0.12) : Color.primary.opacity(0.06))
                                    .frame(width: 32, height: 32)
                                Image(systemName: item.icon)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(item.available ? Color.dinkrGreen : .secondary)
                            }

                            Text(item.label)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(item.available ? Color.dinkrNavy : .secondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer()

                            Image(systemName: item.available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(item.available ? Color.dinkrGreen : Color.dinkrCoral)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)

                // MARK: Accessibility Section
                sectionHeader(icon: "figure.roll", title: "Accessibility")
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 10)

                VStack(spacing: 0) {
                    ForEach(Array(accessibilityItems.enumerated()), id: \.element.id) { idx, item in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.dinkrSky.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: item.systemImage)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.dinkrSky)
                            }
                            Text(item.label)
                                .font(.subheadline)
                                .foregroundStyle(Color.dinkrNavy)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.dinkrGreen)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.cardBackground)

                        if idx < accessibilityItems.count - 1 {
                            Divider().padding(.leading, 64)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
                .padding(.horizontal, 20)

                // MARK: Suggest an Edit Row
                Button {
                    showSuggestAlert = true
                } label: {
                    HStack {
                        Image(systemName: "pencil.and.outline")
                            .foregroundStyle(Color.dinkrAmber)
                        Text("Suggest an Edit")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrNavy)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("Hours & Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Suggestion Received", isPresented: $showSuggestAlert) {
            Button("Done", role: .cancel) {}
        } message: {
            Text("Thank you! Your suggestion will be reviewed by our team.")
        }
    }

    // MARK: Helpers

    @ViewBuilder
    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.dinkrGreen)
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.6)
        }
    }

    @ViewBuilder
    private func surfaceDetailRow(label: String, content: AnyView) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CourtHoursView(venue: CourtVenue.mockVenues[0])
    }
}

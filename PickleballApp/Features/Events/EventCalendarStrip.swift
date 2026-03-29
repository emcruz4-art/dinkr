import SwiftUI

struct EventCalendarStrip: View {
    @Binding var selectedFilter: CalendarFilter

    enum CalendarFilter: String, CaseIterable {
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case all = "All"
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CalendarFilter.allCases, id: \.self) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        VStack(spacing: 4) {
                            Text(filter.rawValue)
                                .font(.caption.weight(selectedFilter == filter ? .bold : .medium))
                                .foregroundStyle(selectedFilter == filter ? .white : Color.dinkrGreen)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(selectedFilter == filter ? Color.dinkrGreen : Color.dinkrGreen.opacity(0.10))
                                .clipShape(Capsule())
                        }
                    }
                    .buttonStyle(.plain)
                }

                Divider().frame(height: 20)

                // Quick date chips for next 5 days
                ForEach(0..<5) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                    VStack(spacing: 2) {
                        Text(date, format: .dateTime.weekday(.narrow))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text(date, format: .dateTime.day())
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(offset == 0 ? Color.dinkrGreen : .primary)
                    }
                    .frame(width: 36, height: 48)
                    .background(offset == 0 ? Color.dinkrGreen.opacity(0.10) : Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

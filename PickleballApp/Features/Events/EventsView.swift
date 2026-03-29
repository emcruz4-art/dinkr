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
                return event.dateTime >= now && event.dateTime <= (cal.date(byAdding: .day, value: 7, to: now) ?? now)
            case .thisMonth:
                return event.dateTime >= now && event.dateTime <= (cal.date(byAdding: .month, value: 1, to: now) ?? now)
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

                Divider()

                ScrollView {
                    LazyVStack(spacing: 12) {
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
                            // Featured hero — first event
                            if let featured = filteredByCalendar.first {
                                NavigationLink {
                                    EventDetailView(event: featured)
                                } label: {
                                    FeaturedEventHeroBanner(event: featured)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                            }

                            // Remaining events
                            ForEach(filteredByCalendar.dropFirst()) { event in
                                NavigationLink {
                                    EventDetailView(event: event)
                                } label: {
                                    EventCardView(event: event)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .refreshable { await viewModel.load() }
            }
            .navigationTitle("Events")
        }
        .task { await viewModel.load() }
    }
}

struct FeaturedEventHeroBanner: View {
    let event: Event

    var registrationProgress: Double {
        guard let max = event.maxParticipants, max > 0 else { return 0 }
        return Double(event.currentParticipants) / Double(max)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color.dinkrNavy, Color.dinkrCoral.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(alignment: .leading, spacing: 8) {
                Text("🏆 FEATURED EVENT")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.8))
                Text(event.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Text(event.dateTime, format: .dateTime.month().day())
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                    if let fee = event.entryFee {
                        Text("$\(Int(fee))")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.dinkrAmber)
                    }
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.dinkrAmber)
                            .frame(width: geo.size.width * registrationProgress)
                    }
                }
                .frame(height: 5)

                Text("\(Int(registrationProgress * 100))% registered")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(16)
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = Color.pickleballGreen
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

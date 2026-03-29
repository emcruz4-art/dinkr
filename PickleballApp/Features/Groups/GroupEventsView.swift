import SwiftUI

struct GroupEventsView: View {
    let group: Group
    let events: [Event] = Event.mockEvents

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if events.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.exclamationmark",
                        title: "No Upcoming Events",
                        message: "This group hasn't scheduled any events yet."
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(events) { event in
                        GroupEventRow(event: event)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .navigationTitle("Group Events")
    }
}

struct GroupEventRow: View {
    let event: Event

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

                Button {} label: {
                    Text("RSVP")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.dinkrGreen)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(14)
        }
    }
}

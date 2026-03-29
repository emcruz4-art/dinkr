import SwiftUI

struct GameCardView: View {
    let session: GameSession

    var countdownText: String {
        let diff = session.dateTime.timeIntervalSinceNow
        if diff < 0 { return "Started" }
        if diff < 3600 { return "In \(Int(diff/60))m" }
        if diff < 86400 { return "In \(Int(diff/3600))h \(Int((diff.truncatingRemainder(dividingBy: 3600))/60))m" }
        return session.dateTime.formatted(.dateTime.weekday(.short).hour().minute())
    }

    var body: some View {
        PickleballCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.courtName)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text(session.format.rawValue.capitalized + " · " +
                             session.skillRange.lowerBound.label + "–" + session.skillRange.upperBound.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        // Countdown badge
                        Text(countdownText)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(session.dateTime.timeIntervalSinceNow < 3600 ? Color.dinkrCoral : Color.dinkrGreen)
                            .clipShape(Capsule())
                        Text("\(session.spotsRemaining) spot\(session.spotsRemaining == 1 ? "" : "s") left")
                            .font(.caption2)
                            .foregroundStyle(session.spotsRemaining <= 1 ? Color.dinkrCoral : .secondary)
                    }
                }

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(session.hostName)
                            .font(.caption)
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(Color.dinkrAmber)
                            Text("4.8")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(Color.dinkrAmber)
                        }
                    }
                    Spacer()
                    if let fee = session.fee {
                        Text(fee == 0 ? "Free" : "$\(Int(fee))")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(fee == 0 ? Color.dinkrGreen : Color.dinkrAmber)
                    }
                }

                // Spot progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.15))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(session.isFull ? Color.dinkrCoral : Color.dinkrGreen)
                            .frame(width: geo.size.width * Double(session.rsvps.count) / Double(session.totalSpots))
                    }
                }
                .frame(height: 4)

                if !session.notes.isEmpty {
                    Text(session.notes)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(14)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(GameSession.mockSessions) { session in
            GameCardView(session: session)
        }
    }
    .padding()
}

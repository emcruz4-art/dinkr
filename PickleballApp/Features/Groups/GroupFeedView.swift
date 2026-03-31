import SwiftUI

// MARK: - GroupFeedView

struct GroupFeedView: View {
    let group: DinkrGroup
    @State private var posts: [Post] = []
    @State private var pollSelection: Int? = nil

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {

                // ── Pinned admin announcement ─────────────────────────────
                PinnedAnnouncementCard()
                    .padding(.horizontal)
                    .padding(.top, 4)

                // ── Upcoming Games ────────────────────────────────────────
                UpcomingGamesBanner()
                    .padding(.horizontal)

                // ── Poll of the Week ──────────────────────────────────────
                PollOfTheWeekCard(selection: $pollSelection)
                    .padding(.horizontal)

                Divider()
                    .padding(.horizontal)
                    .padding(.vertical, 4)

                // ── Regular feed posts ────────────────────────────────────
                if posts.isEmpty {
                    EmptyStateView(
                        icon: "bubble.left.and.bubble.right",
                        title: "No Posts Yet",
                        message: "Be the first to post in \(group.name)!"
                    )
                    .padding(.top, 20)
                } else {
                    ForEach(posts) { post in
                        PostCardView(post: post, onLike: {}, onComment: {})
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .onAppear {
            // grp_001 posts are seeded with groupId in mock data
            posts = Post.mockPosts.filter { $0.groupId == group.id }
        }
    }
}

// MARK: - Pinned Announcement Card

struct PinnedAnnouncementCard: View {
    private let text = "Welcome to the group! Our next scheduled session is this Saturday at 8am. Courts will be reserved — bring a friend! Check the Events tab for full details."
    private let adminName = "Coach Ravi (Admin)"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "pin.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.dinkrAmber)
                    .rotationEffect(.degrees(45))

                Text("Pinned Announcement")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(Color.dinkrAmber)
                    .kerning(0.5)

                Spacer()

                Text("Admin")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.dinkrAmber)
                    .clipShape(Capsule())
            }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.dinkrAmber.opacity(0.8))
                Text(adminName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrAmber.opacity(0.9))
                Spacer()
                Text("2h ago")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            ZStack {
                Color.cardBackground
                Color.dinkrAmber.opacity(0.06)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.dinkrAmber.opacity(0.35), lineWidth: 1.5)
        )
        .shadow(color: Color.dinkrAmber.opacity(0.12), radius: 8, x: 0, y: 3)
        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Upcoming Games Banner

struct UpcomingGamesBanner: View {

    private struct Session: Identifiable {
        let id = UUID()
        let title: String
        let dateLabel: String
        let timeLabel: String
        let location: String
        let spotsLeft: Int
        let totalSpots: Int
        let accentColor: Color
    }

    private let sessions: [Session] = [
        Session(
            title: "Saturday Morning Doubles",
            dateLabel: "Sat, Apr 5",
            timeLabel: "8:00 – 10:00 AM",
            location: "Mueller Park Courts",
            spotsLeft: 4,
            totalSpots: 8,
            accentColor: Color.dinkrGreen
        ),
        Session(
            title: "Wednesday Drill Session",
            dateLabel: "Wed, Apr 9",
            timeLabel: "6:30 – 8:00 PM",
            location: "Westlake Rec Center",
            spotsLeft: 2,
            totalSpots: 6,
            accentColor: Color.dinkrSky
        ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.dinkrNavy)
                Text("Upcoming Games")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("See all")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dinkrGreen)
            }

            ForEach(sessions) { session in
                sessionRow(session)
            }
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.dinkrNavy.opacity(0.08), radius: 6, x: 0, y: 2)
        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
    }

    @ViewBuilder
    private func sessionRow(_ session: Session) -> some View {
        let fillFraction: Double = session.totalSpots > 0
            ? Double(session.totalSpots - session.spotsLeft) / Double(session.totalSpots)
            : 0

        HStack(spacing: 12) {
            // Accent bar
            RoundedRectangle(cornerRadius: 3)
                .fill(session.accentColor)
                .frame(width: 4)
                .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Label(session.dateLabel, systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Label(session.timeLabel, systemImage: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Text(session.location)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(session.accentColor.opacity(0.15))
                                .frame(height: 5)
                            Capsule()
                                .fill(session.accentColor)
                                .frame(width: max(8, geo.size.width * fillFraction), height: 5)
                        }
                    }
                    .frame(height: 5)

                    Text("\(session.spotsLeft) spot\(session.spotsLeft == 1 ? "" : "s") left")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(session.spotsLeft <= 2 ? Color.dinkrCoral : session.accentColor)
                }
            }

            Spacer()

            Text("RSVP")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(session.accentColor)
                .clipShape(Capsule())
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(session.accentColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Poll of the Week Card

struct PollOfTheWeekCard: View {
    @Binding var selection: Int?

    private struct PollOption: Identifiable {
        let id: Int
        let label: String
        let votes: Int
    }

    private let question = "What time works best for our weekend sessions?"
    private let totalVotes = 47
    private let options: [PollOption] = [
        PollOption(id: 0, label: "Saturday 7:00 AM", votes: 18),
        PollOption(id: 1, label: "Saturday 9:00 AM", votes: 15),
        PollOption(id: 2, label: "Sunday 8:00 AM",   votes: 10),
        PollOption(id: 3, label: "Sunday 10:00 AM",  votes: 4),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.dinkrSky.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.dinkrSky)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Poll of the Week")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(Color.dinkrSky)
                        .kerning(0.4)
                    Text("\(totalVotes) votes · Ends Sunday")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Text(question)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                ForEach(options) { option in
                    pollOptionRow(
                        option: option,
                        isSelected: selection == option.id,
                        hasVoted: selection != nil
                    )
                }
            }

            if selection == nil {
                Text("Tap an option to vote")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Text("Thanks for voting! 🎉")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrGreen)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.dinkrSky.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.dinkrSky.opacity(0.10), radius: 8, x: 0, y: 3)
        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
    }

    @ViewBuilder
    private func pollOptionRow(option: PollOption, isSelected: Bool, hasVoted: Bool) -> some View {
        let pct: Double = totalVotes > 0 ? Double(option.votes) / Double(totalVotes) : 0
        let pctLabel = String(format: "%.0f%%", pct * 100)

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selection = option.id
            }
        } label: {
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.dinkrGreen.opacity(0.12) : Color(.systemGray6))
                    .frame(height: 40)

                // Fill bar
                if hasVoted {
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? Color.dinkrGreen.opacity(0.22) : Color.dinkrSky.opacity(0.12))
                            .frame(width: max(8, geo.size.width * pct), height: 40)
                            .animation(.easeInOut(duration: 0.4), value: hasVoted)
                    }
                    .frame(height: 40)
                }

                // Label + percent overlay
                HStack {
                    HStack(spacing: 6) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.dinkrGreen)
                        }
                        Text(option.label)
                            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? Color.dinkrGreen : .primary)
                    }
                    .padding(.leading, 12)

                    Spacer()

                    if hasVoted {
                        Text(pctLabel)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(isSelected ? Color.dinkrGreen : .secondary)
                            .padding(.trailing, 12)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .frame(height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isSelected ? Color.dinkrGreen.opacity(0.55) : Color(.systemGray5),
                    lineWidth: isSelected ? 1.5 : 1
                )
        )
    }
}

// MARK: - Preview

#Preview {
    GroupFeedView(group: DinkrGroup.mockGroups[0])
}

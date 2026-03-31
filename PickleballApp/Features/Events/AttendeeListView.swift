import SwiftUI

// MARK: - AttendeeListView

struct AttendeeListView: View {
    let event: Event

    // Mock data: mockCurrentUser + mockPlayers form registered list;
    // last 2 mock players treated as waitlist.
    private let allRegistered: [User] = {
        var list = [User.mockCurrentUser]
        list.append(contentsOf: User.mockPlayers.prefix(6))
        return list
    }()

    private let waitlist: [User] = Array(User.mockPlayers.suffix(2))

    // Capacity numbers
    private let totalRegistered = 47
    private let capacity = 64

    @State private var searchText = ""
    @State private var selectedSegment: AttendeeSegment = .registered

    // MARK: - Filtered lists

    private var displayedUsers: [User] {
        let base = selectedSegment == .registered ? allRegistered : waitlist
        guard !searchText.isEmpty else { return base }
        let q = searchText.lowercased()
        return base.filter {
            $0.displayName.lowercased().contains(q) ||
            $0.username.lowercased().contains(q)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                capacityBar
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                Picker("Attendees", selection: $selectedSegment) {
                    ForEach(AttendeeSegment.allCases, id: \.self) { seg in
                        Text(seg.label(
                            registered: allRegistered.count,
                            waitlist: waitlist.count
                        ))
                        .tag(seg)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                List {
                    if displayedUsers.isEmpty {
                        ContentUnavailableView(
                            "No results",
                            systemImage: "person.slash",
                            description: Text("Try a different search term.")
                        )
                    } else {
                        ForEach(displayedUsers) { user in
                            AttendeeRow(user: user, event: event)
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search attendees")
            }
            .navigationTitle("Attendees")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(
                        item: URL(string: "https://dinkr.app/events/\(event.id)") ?? URL(string: "https://dinkr.app")!,
                        subject: Text(event.title),
                        message: Text("Check out this event on Dinkr!")
                    ) {
                        Label("Share Event", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    // MARK: - Capacity Progress Bar

    private var capacityBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(totalRegistered) / \(capacity) registered")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                let pct = Int(Double(totalRegistered) / Double(capacity) * 100)
                Text("\(pct)% full")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(progressColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.dinkrGreen.opacity(0.15))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color.dinkrGreen, Color.dinkrSky],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * Double(totalRegistered) / Double(capacity))
                }
            }
            .frame(height: 8)
        }
    }

    private var progressColor: Color {
        let ratio = Double(totalRegistered) / Double(capacity)
        if ratio >= 0.9 { return Color.dinkrCoral }
        if ratio >= 0.7 { return Color.dinkrAmber }
        return Color.dinkrGreen
    }
}

// MARK: - AttendeeSegment

private enum AttendeeSegment: CaseIterable {
    case registered, waitlist

    func label(registered: Int, waitlist: Int) -> String {
        switch self {
        case .registered: return "Registered (\(registered))"
        case .waitlist:   return "Waitlist (\(waitlist))"
        }
    }
}

// MARK: - AttendeeRow

private struct AttendeeRow: View {
    let user: User
    let event: Event
    @State private var inviteSent = false

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(
                urlString: user.avatarURL,
                displayName: user.displayName,
                size: 44
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(user.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if event.type == .tournament {
                    Text(divisionLabel(for: user))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.dinkrSky)
                }
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 6) {
                SkillBadge(level: user.skillLevel, compact: true)

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        inviteSent = true
                    }
                } label: {
                    Text(inviteSent ? "Sent ✓" : "Invite to Play")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(inviteSent ? Color.secondary : .white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            inviteSent ? Color.secondary.opacity(0.15) : Color.dinkrGreen,
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
                .disabled(inviteSent)
            }
        }
        .padding(.vertical, 4)
    }

    private func divisionLabel(for user: User) -> String {
        switch user.skillLevel {
        case .beginner20, .beginner25:        return "Beginner Division"
        case .intermediate30, .intermediate35: return "Intermediate Division"
        case .advanced40, .advanced45:         return "Advanced Division"
        case .pro50:                           return "Pro Division"
        }
    }
}

// MARK: - Preview

#Preview {
    AttendeeListView(event: Event.mockEvents[0])
}

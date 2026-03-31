import SwiftUI

// MARK: - My Sessions View

struct MySessionsView: View {
    var viewModel: PlayViewModel

    enum SessionsFilter: String, CaseIterable {
        case upcoming = "Upcoming"
        case past     = "Past"
        case hosting  = "Hosting"
    }

    @State private var selectedFilter: SessionsFilter = .upcoming
    @State private var showLogResult    = false
    @State private var logTargetSession: GameSession? = nil
    @State private var showShareSheet   = false
    @State private var showEditSheet    = false
    @State private var showCancelAlert  = false
    @State private var cancelTargetSession: GameSession? = nil
    @State private var showFindGame     = false
    @State private var showInviteSheet  = false
    @State private var inviteTargetSession: GameSession? = nil
    @State private var showMessageSheet = false
    @State private var messageTargetSession: GameSession? = nil
    @State private var showRSVPDetail   = false
    @State private var rsvpTargetSession: GameSession? = nil

    private let currentUserId = "user_001"

    // MARK: - Session partitioning

    private var upcomingSessions: [GameSession] {
        viewModel.mySessions.filter { $0.dateTime > Date() }
            .sorted { $0.dateTime < $1.dateTime }
    }

    private var pastSessions: [GameSession] {
        viewModel.mySessions.filter { $0.dateTime <= Date() }
            .sorted { $0.dateTime > $1.dateTime }
    }

    private var hostedSessions: [GameSession] {
        viewModel.myHostedSessions.sorted { $0.dateTime < $1.dateTime }
    }

    // DinkrGroup past sessions by calendar month
    private var pastSessionsByMonth: [(String, [GameSession])] {
        let all = GameSession.mockPastSessions + pastSessions
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        var grouped: [(String, [GameSession])] = []
        var seen: [String: Int] = [:]

        for session in all {
            let key = formatter.string(from: session.dateTime)
            if let idx = seen[key] {
                grouped[idx].1.append(session)
            } else {
                seen[key] = grouped.count
                grouped.append((key, [session]))
            }
        }
        return grouped
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── Segmented filter ─────────────────────────────────────
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(SessionsFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                // ── Content ──────────────────────────────────────────────
                switch selectedFilter {
                case .upcoming:
                    upcomingContent
                case .past:
                    pastContent
                case .hosting:
                    hostingContent
                }
            }
        }
        .sheet(isPresented: $showLogResult) {
            LogGameResultView()
        }
        .sheet(isPresented: $showShareSheet) {
            Text("Share this session")
                .font(.title2.weight(.bold))
                .padding()
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showEditSheet) {
            Text("Edit Session")
                .font(.title2.weight(.bold))
                .padding()
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showFindGame) {
            NearbyGamesView(viewModel: PlayViewModel())
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteFriendsSheet(session: inviteTargetSession)
        }
        .sheet(isPresented: $showMessageSheet) {
            MessagePlayersSheet(session: messageTargetSession)
        }
        .sheet(isPresented: $showRSVPDetail) {
            if let session = rsvpTargetSession {
                RSVPManagementSheet(session: session)
            }
        }
        .alert("Cancel Session?",
               isPresented: $showCancelAlert,
               presenting: cancelTargetSession) { session in
            Button("Cancel Session", role: .destructive) { /* Fire cancel action */ }
            Button("Keep It", role: .cancel) {}
        } message: { session in
            Text("This will remove \"\(session.courtName)\" and notify all RSVPs.")
        }
    }

    // MARK: - Upcoming Content

    @ViewBuilder
    private var upcomingContent: some View {
        if upcomingSessions.isEmpty {
            VStack(spacing: 20) {
                mySessionsEmptyState(
                    icon: "calendar.badge.plus",
                    title: "No Upcoming Games",
                    subtitle: "No upcoming games. Find your next game! 🏓",
                    tint: Color.dinkrGreen
                )
                Button {
                    showFindGame = true
                } label: {
                    Label("Find a Game", systemImage: "magnifyingglass")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.dinkrGreen)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                Spacer().frame(height: 24)
            }
        } else {
            VStack(spacing: 16) {
                ForEach(Array(upcomingSessions.enumerated()), id: \.element.id) { index, session in
                    UpcomingSessionCard(
                        session: session,
                        currentUserId: currentUserId,
                        isFirstCard: index == 0,
                        onInvite: {
                            inviteTargetSession = session
                            showInviteSheet = true
                        },
                        onCancelRSVP: {
                            // In production: call viewModel.rsvp(to:) to toggle off
                        }
                    )
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 4)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Past Content

    @ViewBuilder
    private var pastContent: some View {
        let grouped = pastSessionsByMonth
        if grouped.isEmpty {
            mySessionsEmptyState(
                icon: "clock.arrow.circlepath",
                title: "No Past Sessions Yet",
                subtitle: "Play in some games and they'll show up here with your results.",
                tint: Color.dinkrSky
            )
        } else {
            VStack(spacing: 24) {
                ForEach(grouped, id: \.0) { (month, sessions) in
                    VStack(alignment: .leading, spacing: 8) {

                        // Month section header
                        HStack(spacing: 6) {
                            Text(month.uppercased())
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(.secondary)
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 16)

                        // Sessions in this month
                        VStack(spacing: 0) {
                            ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                                PastSessionRow(session: session) {
                                    logTargetSession = session
                                    showLogResult = true
                                }
                                if index < sessions.count - 1 {
                                    Divider()
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Hosting Content

    @ViewBuilder
    private var hostingContent: some View {
        if hostedSessions.isEmpty {
            VStack(spacing: 20) {
                mySessionsEmptyState(
                    icon: "figure.mixed.cardio",
                    title: "You're Not Hosting Anything",
                    subtitle: "Tap the + button in the toolbar to host a new game.",
                    tint: Color.dinkrAmber
                )
            }
        } else {
            VStack(spacing: 16) {
                ForEach(hostedSessions) { session in
                    HostingDashboardCard(
                        session: session,
                        onRSVPManage: {
                            rsvpTargetSession = session
                            showRSVPDetail = true
                        },
                        onMessagePlayers: {
                            messageTargetSession = session
                            showMessageSheet = true
                        },
                        onShare: { showShareSheet = true },
                        onEdit: { showEditSheet = true },
                        onCancel: {
                            cancelTargetSession = session
                            showCancelAlert = true
                        }
                    )
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - Empty State Helper

    private func mySessionsEmptyState(
        icon: String,
        title: String,
        subtitle: String,
        tint: Color
    ) -> some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 48)
            ZStack {
                Circle()
                    .fill(tint.opacity(0.1))
                    .frame(width: 72, height: 72)
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(tint)
            }
            Text(title)
                .font(.headline.weight(.bold))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer().frame(height: 48)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Upcoming Session Card (full featured)

private struct UpcomingSessionCard: View {
    let session: GameSession
    let currentUserId: String
    let isFirstCard: Bool
    let onInvite: () -> Void
    let onCancelRSVP: () -> Void

    private var isHosting: Bool { session.hostId == currentUserId }

    private var countdownText: String {
        let diff = session.dateTime.timeIntervalSinceNow
        if diff < 0 { return "Started" }
        if diff < 3600 { return "In \(Int(diff/60))m" }
        if diff < 86400 { return "In \(Int(diff/3600))h \(Int((diff.truncatingRemainder(dividingBy: 3600))/60))m" }
        let days = Int(diff / 86400)
        return days == 1 ? "Tomorrow" : "In \(days)d"
    }

    private var isUrgent: Bool { session.dateTime.timeIntervalSinceNow < 3600 }

    private var formatAccentColor: Color {
        switch session.format {
        case .doubles:     return Color.dinkrGreen
        case .singles:     return Color.dinkrSky
        case .openPlay:    return Color.dinkrAmber
        case .mixed:       return Color.dinkrCoral
        case .round_robin: return Color.dinkrNavy
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // YOUR GAME banner (only when hosting)
            if isHosting {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10, weight: .heavy))
                    Text("YOUR GAME · HOSTING")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(1.0)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.dinkrAmber)
            }

            VStack(alignment: .leading, spacing: 12) {

                // Row 1: Court + countdown badge
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(session.courtName)
                                .font(.subheadline.weight(.bold))
                                .lineLimit(1)

                            // "YOUR GAME" badge for non-hosts who are attending
                            if !isHosting && session.rsvps.contains(currentUserId) {
                                Text("YOUR GAME")
                                    .font(.system(size: 9, weight: .heavy))
                                    .tracking(0.8)
                                    .foregroundStyle(Color.dinkrGreen)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Color.dinkrGreen.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }

                        Text(session.dateTime.formatted(.dateTime.weekday(.short).month(.abbreviated).day().hour().minute()))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Countdown badge
                    Text(countdownText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(isUrgent ? Color.dinkrCoral : Color.dinkrGreen)
                        .clipShape(Capsule())
                }

                // Row 2: Format + host info
                HStack(spacing: 8) {
                    Text(session.format.rawValue.capitalized)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(formatAccentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(formatAccentColor.opacity(0.12))
                        .clipShape(Capsule())

                    AvatarView(displayName: session.hostName, size: 18)

                    Text(session.hostName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer()

                    // Spots indicator
                    Text("\(session.rsvps.count)/\(session.totalSpots)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(session.isFull ? Color.dinkrCoral : Color.dinkrGreen)
                }

                Divider()

                // Quick actions row
                HStack(spacing: 8) {
                    QuickActionButton(
                        label: "Directions",
                        icon: "arrow.triangle.turn.up.right.circle.fill",
                        color: Color.dinkrNavy
                    ) {
                        // Open Maps with court address
                        if let url = URL(string: "maps://?q=\(session.courtName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                            UIApplication.shared.open(url)
                        }
                    }

                    QuickActionButton(
                        label: "Invite",
                        icon: "person.badge.plus",
                        color: Color.dinkrGreen
                    ) {
                        onInvite()
                    }

                    QuickActionButton(
                        label: "Cancel RSVP",
                        icon: "xmark.circle",
                        color: Color.dinkrCoral
                    ) {
                        onCancelRSVP()
                    }
                }
            }
            .padding(14)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    isHosting ? Color.dinkrAmber.opacity(0.4) : Color.dinkrGreen.opacity(0.25),
                    lineWidth: 1.5
                )
        )
        .shadow(
            color: (isHosting ? Color.dinkrAmber : Color.dinkrGreen).opacity(0.18),
            radius: 12, x: 0, y: 4
        )
    }
}

// MARK: - Quick Action Button

private struct QuickActionButton: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(0.09))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Past Session Row

struct PastSessionRow: View {
    let session: GameSession
    let onLogResult: () -> Void

    enum ResultKind { case win, loss, notLogged }

    // Mock result derived from session id for visual variety
    private var mockResult: ResultKind {
        switch session.id {
        case "gs_past1": return .win
        case "gs_past2": return .loss
        default:         return .notLogged
        }
    }

    // Mock DUPR change for logged sessions
    private var mockDUPRDelta: Double? {
        switch session.id {
        case "gs_past1": return +0.12
        case "gs_past2": return -0.08
        default:         return nil
        }
    }

    private var resultBadgeLabel: String {
        switch mockResult {
        case .win:       return "W"
        case .loss:      return "L"
        case .notLogged: return "N/A"
        }
    }

    private var resultColor: Color {
        switch mockResult {
        case .win:       return Color.dinkrGreen
        case .loss:      return Color.dinkrCoral
        case .notLogged: return Color.secondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {

            // Result badge (W / L / N/A)
            ZStack {
                Circle()
                    .fill(resultColor.opacity(0.14))
                    .frame(width: 36, height: 36)
                Text(resultBadgeLabel)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(resultColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(session.courtName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(session.dateTime.formatted(.dateTime.month(.abbreviated).day().year()))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(session.format.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                // DUPR change chip if logged
                if let delta = mockDUPRDelta {
                    let isPositive = delta > 0
                    Text("\(isPositive ? "+" : "")\(String(format: "%.2f", delta)) DUPR")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isPositive ? Color.dinkrGreen : Color.dinkrCoral)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background((isPositive ? Color.dinkrGreen : Color.dinkrCoral).opacity(0.1))
                        .clipShape(Capsule())
                }

                // Log Result button for unlogged sessions
                if mockResult == .notLogged {
                    Button(action: onLogResult) {
                        Text("Log Result")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.dinkrGreen)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.dinkrGreen.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(Color.dinkrGreen.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Hosting Dashboard Card

private struct HostingDashboardCard: View {
    let session: GameSession
    let onRSVPManage: () -> Void
    let onMessagePlayers: () -> Void
    let onShare: () -> Void
    let onEdit: () -> Void
    let onCancel: () -> Void

    // Confirmed vs total RSVP split (mock: first half are confirmed)
    private var confirmedCount: Int { max(1, session.rsvps.count / 2 + session.rsvps.count % 2) }
    private var waitlistCount: Int { session.waitlist.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.courtName)
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                    Text(session.dateTime.formatted(.dateTime.weekday(.short).month(.abbreviated).day().hour().minute()))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Label("Hosting", systemImage: "crown.fill")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(Color.dinkrAmber)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.dinkrAmber.opacity(0.12))
                    .clipShape(Capsule())
            }

            // Attendance summary: "3/4 confirmed"
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("ATTENDANCE SUMMARY")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Text("\(confirmedCount)/\(session.totalSpots) confirmed")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen)
                        if waitlistCount > 0 {
                            Text("·")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(waitlistCount) on waitlist")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.dinkrAmber)
                        }
                    }
                }

                Spacer()

                // Mini fill bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.dinkrGreen.opacity(0.12))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(session.isFull ? Color.dinkrCoral : Color.dinkrGreen)
                            .frame(width: geo.size.width * fillRatio)
                    }
                }
                .frame(width: 80, height: 5)
                .padding(.top, 10)
            }

            // RSVP avatar row + manage button
            if !session.rsvps.isEmpty {
                HStack(spacing: 0) {
                    HStack(spacing: -8) {
                        ForEach(Array(session.rsvps.prefix(6).enumerated()), id: \.element) { index, userId in
                            MiniAvatarCircle(userId: userId, index: index)
                        }
                        if session.rsvps.count > 6 {
                            ZStack {
                                Circle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 30, height: 30)
                                Text("+\(session.rsvps.count - 6)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.secondary)
                            }
                            .zIndex(Double(6))
                        }
                    }

                    Spacer()

                    Button(action: onRSVPManage) {
                        Text("Manage RSVPs")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.dinkrNavy)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.dinkrNavy.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            // Action buttons row
            HStack(spacing: 8) {
                // Message Players (prominent, primary action)
                Button(action: onMessagePlayers) {
                    Label("Message Players", systemImage: "message.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.dinkrGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.dinkrSky)
                        .frame(width: 44)
                        .padding(.vertical, 10)
                        .background(Color.dinkrSky.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.dinkrAmber)
                        .frame(width: 44)
                        .padding(.vertical, 10)
                        .background(Color.dinkrAmber.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button(action: onCancel) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.dinkrCoral)
                        .frame(width: 44)
                        .padding(.vertical, 10)
                        .background(Color.dinkrCoral.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.dinkrAmber.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.dinkrAmber.opacity(0.14), radius: 10, x: 0, y: 4)
    }

    private var fillRatio: Double {
        guard session.totalSpots > 0 else { return 0 }
        return Double(session.rsvps.count) / Double(session.totalSpots)
    }
}

// MARK: - Mini Avatar Circle

private struct MiniAvatarCircle: View {
    let userId: String
    let index: Int

    private var avatarColor: Color {
        let colors: [Color] = [
            Color.dinkrGreen, Color.dinkrSky, Color.dinkrAmber,
            Color.dinkrCoral, Color.dinkrNavy
        ]
        let hash = userId.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return colors[hash % colors.count]
    }

    private var initials: String {
        let trimmed = userId.replacingOccurrences(of: "user_", with: "")
        return "U\(trimmed.prefix(1))"
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(avatarColor.opacity(0.18))
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(Color.cardBackground, lineWidth: 2))
            Text(initials)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(avatarColor)
        }
        .zIndex(Double(10 - index))
    }
}

// MARK: - Invite Friends Sheet

private struct InviteFriendsSheet: View {
    let session: GameSession?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer().frame(height: 12)
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen.opacity(0.1))
                        .frame(width: 64, height: 64)
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Color.dinkrGreen)
                }
                Text("Invite Friends")
                    .font(.title3.weight(.bold))
                Text("Share this game with people you want to play with.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    HapticManager.success()
                    dismiss()
                } label: {
                    Label("Share Game Link", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.dinkrGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)

                Spacer()
            }
            .navigationTitle("Invite Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Message Players Sheet

private struct MessagePlayersSheet: View {
    let session: GameSession?
    @Environment(\.dismiss) private var dismiss
    @State private var messageText: String = ""
    @State private var sent = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if sent {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.dinkrGreen.opacity(0.1))
                            .frame(width: 72, height: 72)
                        Image(systemName: "checkmark.message.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                    Text("Message Sent!")
                        .font(.title3.weight(.bold))
                    Text("All RSVPs have been notified.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NOTIFY ALL RSVPs")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        TextEditor(text: $messageText)
                            .font(.subheadline)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    if let session = session {
                        HStack(spacing: 8) {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                                .foregroundStyle(Color.dinkrGreen)
                            Text("Sending to \(session.rsvps.count) player\(session.rsvps.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer()

                    Button {
                        guard !messageText.isEmpty else { return }
                        HapticManager.success()
                        withAnimation { sent = true }
                        Task {
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            dismiss()
                        }
                    } label: {
                        Label("Send to All Players", systemImage: "paperplane.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(messageText.isEmpty ? Color.secondary : Color.dinkrGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .disabled(messageText.isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Message Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - RSVP Management Sheet

private struct RSVPManagementSheet: View {
    let session: GameSession
    @Environment(\.dismiss) private var dismiss

    // Mock player names keyed by userId
    private let mockNames: [String: String] = [
        "user_001": "You",
        "user_002": "Maria Chen",
        "user_003": "Jordan Smith",
        "user_004": "Riley Torres",
        "user_005": "Chris Park",
        "user_006": "Taylor Kim"
    ]

    var body: some View {
        NavigationStack {
            List {
                if !session.rsvps.isEmpty {
                    Section {
                        ForEach(session.rsvps, id: \.self) { userId in
                            HStack(spacing: 12) {
                                MiniAvatarCircle(userId: userId, index: 0)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mockNames[userId] ?? userId)
                                        .font(.subheadline.weight(.semibold))
                                    Text(userId == session.hostId ? "Host" : "Confirmed")
                                        .font(.caption)
                                        .foregroundStyle(userId == session.hostId ? Color.dinkrAmber : Color.dinkrGreen)
                                }

                                Spacer()

                                if userId != session.hostId {
                                    Button {
                                        HapticManager.selection()
                                    } label: {
                                        Image(systemName: "xmark.circle")
                                            .font(.system(size: 18))
                                            .foregroundStyle(Color.dinkrCoral)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Label("Confirmed (\(session.rsvps.count))", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(Color.dinkrGreen)
                    }
                }

                if !session.waitlist.isEmpty {
                    Section {
                        ForEach(session.waitlist, id: \.self) { userId in
                            HStack(spacing: 12) {
                                MiniAvatarCircle(userId: userId, index: 0)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mockNames[userId] ?? userId)
                                        .font(.subheadline.weight(.semibold))
                                    Text("Waitlist")
                                        .font(.caption)
                                        .foregroundStyle(Color.dinkrAmber)
                                }

                                Spacer()

                                Button {
                                    HapticManager.success()
                                } label: {
                                    Text("Move Up")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color.dinkrGreen)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.dinkrGreen.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Label("Waitlist (\(session.waitlist.count))", systemImage: "clock.fill")
                            .foregroundStyle(Color.dinkrAmber)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Manage RSVPs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Mock Past Sessions

extension GameSession {
    static let mockPastSessions: [GameSession] = [
        GameSession(
            id: "gs_past1",
            hostId: "user_002",
            hostName: "Maria Chen",
            courtId: "court_001",
            courtName: "Westside Pickleball Complex",
            dateTime: Date().addingTimeInterval(-86400 * 3),
            format: .doubles,
            skillRange: .intermediate30 ... .intermediate35,
            totalSpots: 4,
            rsvps: ["user_001", "user_002", "user_003", "user_004"],
            waitlist: [],
            isPublic: true,
            notes: "Great match!",
            fee: nil
        ),
        GameSession(
            id: "gs_past2",
            hostId: "user_003",
            hostName: "Jordan Smith",
            courtId: "court_002",
            courtName: "Mueller Recreation Center",
            dateTime: Date().addingTimeInterval(-86400 * 7),
            format: .openPlay,
            skillRange: .beginner25 ... .advanced40,
            totalSpots: 12,
            rsvps: ["user_001", "user_003", "user_005"],
            waitlist: [],
            isPublic: true,
            notes: "Open play round",
            fee: nil
        ),
        GameSession(
            id: "gs_past3",
            hostId: "user_005",
            hostName: "Chris Park",
            courtId: "court_003",
            courtName: "South Lamar Sports Club",
            dateTime: Date().addingTimeInterval(-86400 * 14),
            format: .mixed,
            skillRange: .intermediate35 ... .advanced45,
            totalSpots: 8,
            rsvps: ["user_001", "user_005", "user_006"],
            waitlist: [],
            isPublic: false,
            notes: "Members session",
            fee: nil
        ),
        GameSession(
            id: "gs_past4",
            hostId: "user_004",
            hostName: "Riley Torres",
            courtId: "court_001",
            courtName: "Westside Pickleball Complex",
            dateTime: Date().addingTimeInterval(-86400 * 35),
            format: .singles,
            skillRange: .intermediate35 ... .advanced40,
            totalSpots: 2,
            rsvps: ["user_001", "user_004"],
            waitlist: [],
            isPublic: true,
            notes: "",
            fee: nil
        ),
    ]
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MySessionsView(viewModel: {
            let vm = PlayViewModel()
            vm.nearbySessions = GameSession.mockSessions
            return vm
        }())
        .navigationTitle("My Games")
    }
}

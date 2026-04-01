import SwiftUI
import UserNotifications
import MapKit

// MARK: - AttendeeListView (inline, no separate file needed)

private struct SessionAttendeeListView: View {
    let rsvps: [String]
    let waitlist: [String]

    var body: some View {
        NavigationStack {
            List {
                if !rsvps.isEmpty {
                    Section("Confirmed (\(rsvps.count))") {
                        ForEach(Array(rsvps.enumerated()), id: \.offset) { _, userId in
                            HStack(spacing: 12) {
                                AvatarView(displayName: "Player", size: 36)
                                Text(userId)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.primary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                if !waitlist.isEmpty {
                    Section("Waitlist (\(waitlist.count))") {
                        ForEach(Array(waitlist.enumerated()), id: \.offset) { _, userId in
                            HStack(spacing: 12) {
                                AvatarView(displayName: "Player", size: 36)
                                Text(userId)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                                Spacer()
                                Text("Waiting")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.dinkrAmber)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.dinkrAmber.opacity(0.12), in: Capsule())
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle("Players")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - GameSessionDetailView

struct GameSessionDetailView: View {
    let session: GameSession
    var viewModel: PlayViewModel

    @Environment(AuthService.self) private var authService

    // Local state
    @State private var reminderScheduled = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var showLogResult = false
    @State private var showLiveScoreEntry = false
    @State private var liveScoreSnapshot: GameSession.LiveScoreSnapshot?
    @State private var showInvite = false
    @State private var showReminderSheet = false
    @State private var showCancelRSVPConfirm = false
    @State private var showAttendees = false
    @State private var livePulse = false

    private var currentUserId: String { authService.currentUser?.id ?? "" }
    private var isRsvped: Bool { session.rsvps.contains(currentUserId) }
    private var isHost: Bool { session.hostId == currentUserId }

    // MARK: - Format accent colors (matches GameCardView)

    private var formatAccentColors: [Color] {
        switch session.format {
        case .doubles:     return [Color.dinkrGreen, Color.dinkrGreen.opacity(0.55)]
        case .singles:     return [Color.dinkrSky,   Color.dinkrSky.opacity(0.55)]
        case .openPlay:    return [Color.dinkrAmber,  Color.dinkrAmber.opacity(0.55)]
        case .mixed:       return [Color.dinkrCoral,  Color.dinkrCoral.opacity(0.55)]
        case .round_robin: return [Color.dinkrNavy,   Color.dinkrSky.opacity(0.65)]
        }
    }

    private var formatAccentPrimary: Color { formatAccentColors[0] }

    // MARK: - Countdown

    private var countdownText: String {
        let diff = session.dateTime.timeIntervalSinceNow
        if diff < 0 { return "Live Now" }
        if diff < 3600 { return "In \(Int(diff / 60))m" }
        if diff < 86400 {
            let h = Int(diff / 3600)
            let m = Int(diff.truncatingRemainder(dividingBy: 3600) / 60)
            return "In \(h)h \(m)m"
        }
        return session.dateTime.formatted(.dateTime.weekday(.short).hour().minute())
    }

    private var isLive: Bool {
        if let live = session.liveScore, !live.isComplete { return true }
        return session.dateTime.timeIntervalSinceNow < 0 && session.dateTime.timeIntervalSinceNow > -7200
    }

    private var isUrgent: Bool { session.dateTime.timeIntervalSinceNow < 3600 }

    // MARK: - Mock court lookup

    private var courtVenue: CourtVenue? {
        CourtVenue.mockVenues.first(where: { $0.id == session.courtId })
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroBanner
                    VStack(alignment: .leading, spacing: 16) {
                        quickInfoRow
                        if let live = session.liveScore {
                            liveScoreCard(live)
                        }
                        hostSection
                        playersSection
                        courtSection
                        if !session.notes.isEmpty {
                            notesCard
                        }
                        actionButtonsSection
                        liveScoreSection
                        Color.clear.frame(height: 96)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }

            // Sticky RSVP bar
            rsvpBar
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .background(
                    LinearGradient(
                        colors: [Color.appBackground.opacity(0), Color.appBackground],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .bottom)
                )
        }
        .navigationTitle("Game Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .task { await checkReminderStatus() }
        .overlay(alignment: .top) {
            if showToast {
                toastView
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showToast)
        .confirmationDialog(
            "Cancel your RSVP?",
            isPresented: $showCancelRSVPConfirm,
            titleVisibility: .visible
        ) {
            Button("Cancel RSVP", role: .destructive) {
                Task { await viewModel.rsvp(to: session, currentUserId: currentUserId) }
            }
            Button("Keep My Spot", role: .cancel) {}
        } message: {
            Text("You'll lose your spot and may not get it back if the game fills up.")
        }
        .sheet(isPresented: $showLogResult) {
            LogGameResultView()
        }
        .sheet(isPresented: $showInvite) {
            GameInviteView(session: session)
        }
        .sheet(isPresented: $showReminderSheet) {
            GameReminderView(session: session)
        }
        .sheet(isPresented: $showAttendees) {
            SessionAttendeeListView(rsvps: session.rsvps, waitlist: session.waitlist)
        }
        .onChange(of: showReminderSheet) { _, isPresented in
            if !isPresented { Task { await checkReminderStatus() } }
        }
        .fullScreenCover(isPresented: $showLiveScoreEntry) {
            LiveScoreEntryView(session: session, liveScore: $liveScoreSnapshot)
        }
        .onChange(of: showLiveScoreEntry) { _, isPresented in
            if !isPresented, let snapshot = liveScoreSnapshot {
                viewModel.startLiveScore(session: session, snapshot: snapshot)
            }
        }
        .onAppear {
            liveScoreSnapshot = session.liveScore
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                livePulse = true
            }
        }
    }

    // MARK: - Hero Banner

    private var heroBanner: some View {
        ZStack(alignment: .bottom) {
            // Gradient background
            LinearGradient(
                colors: [
                    formatAccentPrimary,
                    formatAccentPrimary.opacity(0.72),
                    Color.dinkrNavy.opacity(0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 220)

            // Subtle pattern overlay
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.06), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 220)

            // Content
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(session.courtName)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        Text(session.dateTime.formatted(
                            .dateTime.weekday(.wide).month(.wide).day().hour().minute()
                        ))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.82))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        if isLive {
                            liveBadge
                        } else {
                            countdownBadge
                        }
                        BookmarkButton(id: session.id, type: .game)
                    }
                }

                // RSVP progress visual
                rsvpProgressBar
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 20)
            .padding(.top, 12)
        }
    }

    private var liveBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color.white)
                .frame(width: 7, height: 7)
                .scaleEffect(livePulse ? 1.4 : 0.8)
            Text("LIVE")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 5)
        .background(Color.dinkrCoral)
        .clipShape(Capsule())
        .shadow(color: Color.dinkrCoral.opacity(0.5), radius: 6, x: 0, y: 2)
    }

    private var countdownBadge: some View {
        Text(countdownText)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(isUrgent ? Color.dinkrCoral : Color.white.opacity(0.22))
            .clipShape(Capsule())
    }

    private var rsvpProgressBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    Text("\(session.rsvps.count) joined")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Text(
                    session.isFull
                        ? "Full"
                        : "\(session.spotsRemaining) of \(session.totalSpots) spots left"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(session.isFull ? Color.dinkrCoral : .white.opacity(0.9))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 5)
                    Capsule()
                        .fill(session.isFull ? Color.dinkrCoral : Color.white)
                        .frame(
                            width: max(
                                6,
                                geo.size.width * min(1.0, Double(session.rsvps.count) / Double(max(1, session.totalSpots)))
                            ),
                            height: 5
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: session.rsvps.count)
                }
            }
            .frame(height: 5)

            if !session.waitlist.isEmpty {
                Text("\(session.waitlist.count) on waitlist")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Quick Info Row

    private var quickInfoRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Format chip
                infoChip(
                    icon: formatIcon,
                    text: session.format.rawValue.capitalized,
                    color: formatAccentPrimary
                )

                // Skill chip
                infoChip(
                    icon: "chart.bar.fill",
                    text: "\(session.skillRange.lowerBound.label) – \(session.skillRange.upperBound.label)",
                    color: Color.dinkrSky
                )

                // Fee chip
                if let fee = session.fee {
                    infoChip(
                        icon: "dollarsign.circle.fill",
                        text: fee == 0 ? "Free" : "$\(Int(fee))",
                        color: fee == 0 ? Color.dinkrGreen : Color.dinkrAmber
                    )
                } else {
                    infoChip(
                        icon: "dollarsign.circle.fill",
                        text: "Free",
                        color: Color.dinkrGreen
                    )
                }

                // Public/Private chip
                infoChip(
                    icon: session.isPublic ? "globe" : "lock.fill",
                    text: session.isPublic ? "Public" : "Private",
                    color: session.isPublic ? Color.dinkrGreen : Color.dinkrNavy
                )
            }
            .padding(.horizontal, 1)
        }
    }

    private var formatIcon: String {
        switch session.format {
        case .doubles:     return "person.2.fill"
        case .singles:     return "person.fill"
        case .openPlay:    return "sportscourt.fill"
        case .mixed:       return "person.2.wave.2.fill"
        case .round_robin: return "arrow.triangle.2.circlepath"
        }
    }

    private func infoChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(color.opacity(0.22), lineWidth: 1))
    }

    // MARK: - Live Score Card

    private func liveScoreCard(_ live: GameSession.LiveScoreSnapshot) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Circle()
                    .fill(live.isComplete ? Color.secondary : Color.dinkrCoral)
                    .frame(width: 7, height: 7)
                    .scaleEffect((!live.isComplete && livePulse) ? 1.4 : 1.0)
                Text(live.isComplete ? "Final Score" : "Live Score")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(live.isComplete ? .secondary : Color.dinkrCoral)
                Spacer()
                NavigationLink(destination: LiveScoreView(gameSessionId: session.id)) {
                    Text("Watch Live")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(live.isComplete ? Color.secondary.opacity(0.08) : Color.dinkrCoral.opacity(0.08))

            // Score body
            HStack(spacing: 0) {
                // Team A
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Text(live.teamAName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.primary)
                        if live.servingTeam == "A" && !live.isComplete {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(Color.dinkrGreen)
                        }
                    }
                    Text("\(live.scoreA)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.dinkrGreen)
                }
                .frame(maxWidth: .infinity)

                // Divider
                VStack(spacing: 2) {
                    Text("VS")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                    if !live.isComplete {
                        Text("Game to 11")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(width: 56)

                // Team B
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        if live.servingTeam == "B" && !live.isComplete {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(Color.dinkrGreen)
                        }
                        Text(live.teamBName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.primary)
                    }
                    Text("\(live.scoreB)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.dinkrCoral)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: (live.isComplete ? Color.black : Color.dinkrCoral).opacity(0.10), radius: 8, x: 0, y: 2)
    }

    // MARK: - Host Section

    private var hostSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Host", icon: "person.crop.circle")

            HStack(alignment: .top, spacing: 14) {
                NavigationLink(destination: UserProfileView(
                    user: User.mockPlayers.first(where: { $0.id == session.hostId })
                        ?? User.mockCurrentUser,
                    currentUserId: currentUserId
                )) {
                    AvatarView(displayName: session.hostName, size: 56)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 5) {
                    NavigationLink(destination: UserProfileView(
                        user: User.mockPlayers.first(where: { $0.id == session.hostId })
                            ?? User.mockCurrentUser,
                        currentUserId: currentUserId
                    )) {
                        Text(session.hostName)
                            .font(.headline)
                            .foregroundStyle(Color.primary)
                    }
                    .buttonStyle(.plain)

                    // Rating + game count
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.dinkrAmber)
                        Text("4.9")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.dinkrAmber)
                        Text("(47 games hosted)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("Hosted 12 games this month")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.dinkrSky)
                        Text("Verified Host")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrSky)
                    }
                }

                Spacer()
            }

            // Action buttons
            HStack(spacing: 10) {
                if !isHost {
                    FollowButton(
                        currentUserId: currentUserId,
                        targetUserId: session.hostId,
                        size: .compact
                    )
                }

                Button {
                    // Message host placeholder
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Message")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Color.dinkrGreen)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .strokeBorder(Color.dinkrGreen, lineWidth: 1.5)
                    )
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Players Section

    private var playersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Players", icon: "person.3.fill")

            if session.rsvps.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .foregroundStyle(Color.dinkrGreen.opacity(0.5))
                    Text("No one has joined yet — be the first!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Button {
                    showAttendees = true
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: -12) {
                            let visible = min(session.rsvps.count, 5)
                            let overflow = session.rsvps.count - visible

                            ForEach(0..<visible, id: \.self) { index in
                                AvatarView(
                                    displayName: "Player \(index + 1)",
                                    size: 40
                                )
                                .overlay(Circle().strokeBorder(Color.cardBackground, lineWidth: 2.5))
                                .zIndex(Double(visible - index))
                            }

                            if overflow > 0 {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.dinkrNavy, Color.dinkrNavy.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 40, height: 40)
                                    Text("+\(overflow)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .overlay(Circle().strokeBorder(Color.cardBackground, lineWidth: 2.5))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }

                        Text("\(session.rsvps.count) confirmed · Tap to see all")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            if !session.waitlist.isEmpty {
                Divider()
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundStyle(Color.dinkrAmber)
                    Text("\(session.waitlist.count) player\(session.waitlist.count == 1 ? "" : "s") on the waitlist")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrAmber)
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Court Section

    private var courtSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Court", icon: "sportscourt.fill")

            // Court name + directions
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(session.courtName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)

                    if let venue = courtVenue {
                        Text(venue.address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Austin, TX")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button {
                    openMapsDirections()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Directions")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Color.dinkrSky)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.dinkrSky.opacity(0.12), in: Capsule())
                }
            }

            // Map thumbnail placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.08))
                    .frame(height: 110)
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.secondary.opacity(0.12), lineWidth: 1)
                    .frame(height: 110)
                VStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.dinkrCoral)
                    Text(session.courtName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .onTapGesture { openMapsDirections() }

            // Court stats
            if let venue = courtVenue {
                HStack(spacing: 0) {
                    courtStat(
                        icon: "star.fill",
                        value: String(format: "%.1f", venue.rating),
                        label: "Rating",
                        color: Color.dinkrAmber
                    )
                    Divider().frame(height: 36)
                    courtStat(
                        icon: "rectangle.3.group.fill",
                        value: "\(venue.courtCount)",
                        label: "Courts",
                        color: Color.dinkrGreen
                    )
                    Divider().frame(height: 36)
                    courtStat(
                        icon: venue.isIndoor ? "building.2.fill" : "sun.max.fill",
                        value: venue.isIndoor ? "Indoor" : "Outdoor",
                        label: "Type",
                        color: venue.isIndoor ? Color.dinkrNavy : Color.dinkrAmber
                    )
                    Divider().frame(height: 36)
                    courtStat(
                        icon: "circle.grid.cross.fill",
                        value: surfaceLabel(venue.surface),
                        label: "Surface",
                        color: Color.dinkrSky
                    )
                }
                .padding(.vertical, 4)
            } else {
                // Fallback stats when no venue data
                HStack(spacing: 0) {
                    courtStat(icon: "star.fill", value: "4.5", label: "Rating", color: Color.dinkrAmber)
                    Divider().frame(height: 36)
                    courtStat(icon: "rectangle.3.group.fill", value: "8", label: "Courts", color: Color.dinkrGreen)
                    Divider().frame(height: 36)
                    courtStat(icon: "sun.max.fill", value: "Outdoor", label: "Type", color: Color.dinkrAmber)
                    Divider().frame(height: 36)
                    courtStat(icon: "circle.grid.cross.fill", value: "Hard", label: "Surface", color: Color.dinkrSky)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func courtStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func surfaceLabel(_ surface: CourtSurface) -> String {
        switch surface {
        case .hardcourt: return "Hard"
        case .concrete:  return "Concrete"
        case .asphalt:   return "Asphalt"
        case .indoor:    return "Indoor"
        case .clay:      return "Clay"
        }
    }

    // MARK: - Notes Card

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Host Notes", icon: "text.bubble.fill")
            HStack(alignment: .top, spacing: 10) {
                Text("📋")
                    .font(.title3)
                Text(session.notes)
                    .font(.subheadline)
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.dinkrGreen.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.dinkrGreen.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        HStack(spacing: 10) {
            // Reminder
            Button {
                showReminderSheet = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: reminderScheduled ? "bell.fill" : "bell")
                        .font(.system(size: 18))
                        .foregroundStyle(reminderScheduled ? Color.dinkrAmber : Color.dinkrGreen)
                    Text(reminderScheduled ? "Reminder Set" : "Reminder")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(reminderScheduled ? Color.dinkrAmber : Color.dinkrGreen)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            reminderScheduled ? Color.dinkrAmber : Color.dinkrGreen.opacity(0.3),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            }

            // Invite Friends
            Button {
                showInvite = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.dinkrGreen)
                    Text("Invite")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.dinkrGreen)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.dinkrGreen.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            }

            // Share
            ShareLink(item: "Join my pickleball game at \(session.courtName)!") {
                VStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.dinkrSky)
                    Text("Share")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.dinkrSky)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.dinkrSky.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            }

            // Log Result
            Button {
                showLogResult = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.dinkrCoral)
                    Text("Log Result")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.dinkrCoral)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.dinkrCoral.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            }
        }
    }

    // MARK: - Live Score Section (host controls)

    @ViewBuilder
    private var liveScoreSection: some View {
        if isHost {
            Button {
                liveScoreSnapshot = session.liveScore
                showLiveScoreEntry = true
            } label: {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.dinkrGreen.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: "sportscourt.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.liveScore == nil ? "Start Live Score" : "Update Live Score")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.primary)
                        Text("Share live score with players")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.dinkrGreen.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - RSVP Bar (sticky bottom)

    private var rsvpBar: some View {
        Group {
            if isRsvped {
                HStack(spacing: 12) {
                    // Cancel RSVP
                    Button {
                        showCancelRSVPConfirm = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.subheadline.weight(.semibold))
                            Text("Cancel RSVP")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(Color.dinkrCoral)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.dinkrCoral, lineWidth: 1.5)
                        )
                    }

                    // Share after RSVP
                    ShareLink(item: "I just joined a pickleball game at \(session.courtName)! Join me on Dinkr.") {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            } else if session.isFull {
                HStack(spacing: 12) {
                    Button {
                        Task { await viewModel.rsvp(to: session, currentUserId: currentUserId) }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .font(.subheadline.weight(.semibold))
                            Text("Join Waitlist")
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.dinkrAmber, Color.dinkrAmber.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .shadow(color: Color.dinkrAmber.opacity(0.35), radius: 8, x: 0, y: 4)
                    }

                    ShareLink(item: "Check out this pickleball game on Dinkr!") {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.dinkrAmber)
                            .frame(width: 52, height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.dinkrAmber, lineWidth: 1.5)
                            )
                    }
                }
            } else {
                HStack(spacing: 12) {
                    Button {
                        Task { await viewModel.rsvp(to: session, currentUserId: currentUserId) }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.subheadline.weight(.semibold))
                            Text("RSVP Now")
                                .font(.subheadline.weight(.bold))
                            if session.spotsRemaining <= 2 {
                                Text("· \(session.spotsRemaining) left!")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .shadow(color: Color.dinkrGreen.opacity(0.38), radius: 10, x: 0, y: 4)
                    }

                    ShareLink(item: "Join my pickleball game at \(session.courtName) on Dinkr!") {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.dinkrGreen)
                            .frame(width: 52, height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.dinkrGreen, lineWidth: 1.5)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 4) {
                // Bookmark
                BookmarkButton(id: session.id, type: .game)

                // Bell
                Button {
                    showReminderSheet = true
                } label: {
                    Image(systemName: reminderScheduled ? "bell.fill" : "bell")
                        .foregroundStyle(reminderScheduled ? Color.dinkrAmber : Color.dinkrGreen)
                }

                // Host: live score entry
                if isHost {
                    Button {
                        liveScoreSnapshot = session.liveScore
                        showLiveScoreEntry = true
                    } label: {
                        Image(systemName: "sportscourt")
                            .foregroundStyle(Color.dinkrGreen)
                    }
                }
            }
        }
    }

    // MARK: - Toast

    private var toastView: some View {
        Text(toastMessage)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.dinkrNavy.opacity(0.92), in: Capsule())
            .padding(.top, 12)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.dinkrGreen)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func openMapsDirections() {
        let name = session.courtName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?q=\(name)") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Reminder Logic

    private func checkReminderStatus() async {
        reminderScheduled = await LocalNotificationService.shared.isReminderScheduled(for: session.id)
    }

    private func presentToast(_ message: String) {
        toastMessage = message
        withAnimation { showToast = true }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation { showToast = false }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GameSessionDetailView(
            session: GameSession.mockSessions[0],
            viewModel: PlayViewModel()
        )
        .environment(AuthService())
    }
}

#Preview("Live Session") {
    NavigationStack {
        GameSessionDetailView(
            session: GameSession.mockSessions[8],
            viewModel: PlayViewModel()
        )
        .environment(AuthService())
    }
}

#Preview("Full Game") {
    NavigationStack {
        GameSessionDetailView(
            session: GameSession.mockSessions[2],
            viewModel: PlayViewModel()
        )
        .environment(AuthService())
    }
}

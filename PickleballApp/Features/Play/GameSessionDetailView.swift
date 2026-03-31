import SwiftUI
import UserNotifications

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

    private var currentUserId: String { authService.currentUser?.id ?? "user_001" }
    private var isRsvped: Bool { session.rsvps.contains(currentUserId) }

    // MARK: - Countdown

    private var countdownText: String {
        let diff = session.dateTime.timeIntervalSinceNow
        if diff < 0 { return "Started" }
        if diff < 3600 { return "In \(Int(diff / 60))m" }
        if diff < 86400 {
            let h = Int(diff / 3600)
            let m = Int(diff.truncatingRemainder(dividingBy: 3600) / 60)
            return "In \(h)h \(m)m"
        }
        return session.dateTime.formatted(.dateTime.weekday(.short).hour().minute())
    }

    private var countdownColor: Color {
        session.dateTime.timeIntervalSinceNow < 3600 ? Color.dinkrCoral : Color.dinkrGreen
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    detailsCard
                    hostSection
                    spotsSection
                    playersSection
                    if !session.notes.isEmpty {
                        notesCard
                    }
                    reminderButton
                    liveScoreSection
                    // Bottom padding so the RSVP button doesn't overlap content
                    Color.clear.frame(height: 88)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }

            rsvpButton
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            logResultButton
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
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
        .task { await checkReminderStatus() }
        .overlay(alignment: .top) {
            if showToast {
                toastView
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showToast)
        .sheet(isPresented: $showLogResult) {
            LogGameResultView()
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
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(session.courtName)
                .font(.title.weight(.bold))

            HStack(spacing: 8) {
                // Format + skill badge
                Text(session.format.rawValue.capitalized + " · " +
                     session.skillRange.lowerBound.label + "–" + session.skillRange.upperBound.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrNavy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.dinkrSky.opacity(0.18))
                    .clipShape(Capsule())

                // Countdown badge
                Text(countdownText)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(countdownColor)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Details")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.dinkrGreen)
                    .frame(width: 20)
                Text(session.dateTime.formatted(.dateTime.weekday().month().day().hour().minute()))
                    .font(.subheadline)
                Spacer()
            }

            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(Color.dinkrGreen)
                    .frame(width: 20)
                Text("\(session.courtName), Austin, TX")
                    .font(.subheadline)
                Spacer()
            }

            HStack(spacing: 12) {
                Image(systemName: "dollarsign.circle")
                    .foregroundStyle(Color.dinkrGreen)
                    .frame(width: 20)
                if let fee = session.fee {
                    Text(fee == 0 ? "Free" : "$\(Int(fee))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(fee == 0 ? Color.dinkrGreen : Color.dinkrAmber)
                } else {
                    Text("Free")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                }
                Spacer()
            }
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Host Section

    private var hostSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Host")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                AvatarView(displayName: session.hostName, size: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.hostName)
                        .font(.subheadline.weight(.semibold))
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.dinkrAmber)
                        Text("4.8")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrAmber)
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text("Verified Host")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.dinkrSky)
                    }
                }

                Spacer()

                Button {
                    // Message host — placeholder for messaging integration
                } label: {
                    Text("Message")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color.dinkrGreen, lineWidth: 1.5)
                        )
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Spots Section

    private var spotsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spots")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(0..<session.totalSpots, id: \.self) { index in
                    Image(systemName: index < session.rsvps.count ? "circle.fill" : "circle")
                        .font(.system(size: 14))
                        .foregroundStyle(index < session.rsvps.count ? Color.dinkrGreen : Color.secondary.opacity(0.4))
                }
                Spacer()
            }

            let remaining = session.spotsRemaining
            Text(
                session.isFull
                    ? "Game is full"
                    : "\(remaining) spot\(remaining == 1 ? "" : "s") remaining"
            )
            .font(.caption)
            .foregroundStyle(session.isFull ? Color.dinkrCoral : .secondary)
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Players Joined

    private var playersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Players Joined")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if session.rsvps.isEmpty {
                Text("No one has joined yet — be the first!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: -10) {
                    let visible = min(session.rsvps.count, 5)
                    let overflow = session.rsvps.count - visible

                    ForEach(0..<visible, id: \.self) { index in
                        AvatarView(
                            displayName: "Player \(index + 1)",
                            size: 36
                        )
                        .overlay(Circle().strokeBorder(Color.cardBackground, lineWidth: 2))
                        .zIndex(Double(visible - index))
                    }

                    if overflow > 0 {
                        ZStack {
                            Circle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 36, height: 36)
                            Text("+\(overflow)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        .overlay(Circle().strokeBorder(Color.cardBackground, lineWidth: 2))
                    }

                    Spacer()
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes from Host")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(session.notes)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Reminder Button

    private var reminderButton: some View {
        Button {
            Task { await toggleReminder() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: reminderScheduled ? "bell.fill" : "bell")
                    .foregroundStyle(reminderScheduled ? Color.dinkrAmber : Color.dinkrGreen)
                Text(reminderScheduled ? "Reminder Set ✅" : "Set Reminder 🔔")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(reminderScheduled ? Color.dinkrAmber : Color.dinkrGreen)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        reminderScheduled ? Color.dinkrAmber : Color.dinkrGreen,
                        lineWidth: 1.5
                    )
            )
        }
    }

    // MARK: - Live Score Section

    @ViewBuilder
    private var liveScoreSection: some View {
        // Active live game — show "Watch Live Score" for everyone
        if let live = session.liveScore, !live.isComplete {
            NavigationLink(destination: LiveScoreView(gameSessionId: session.id)) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("Watch Live Score")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("\(live.teamAName) \(live.scoreA)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.dinkrGreen)
                        Text("–")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(live.scoreB) \(live.teamBName)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.dinkrCoral)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(Color.dinkrGreen.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.dinkrGreen.opacity(0.3), lineWidth: 1)
                )
            }
        }

        // Host can always start score tracking
        if session.hostId == currentUserId {
            Button {
                liveScoreSnapshot = session.liveScore
                showLiveScoreEntry = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sportscourt.fill")
                        .foregroundStyle(Color.dinkrGreen)
                    Text(session.liveScore == nil ? "Start Live Score" : "Update Score")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.dinkrGreen, lineWidth: 1.5)
                )
            }
        }
    }

    // MARK: - Log Result Button

    private var logResultButton: some View {
        Button {
            showLogResult = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "square.and.pencil")
                    .font(.subheadline.weight(.semibold))
                Text("Log a Result")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(Color.dinkrGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.dinkrGreen, lineWidth: 1.5)
            )
        }
    }

    // MARK: - RSVP Button

    private var rsvpButton: some View {
        Button {
            Task {
                await viewModel.rsvp(to: session, currentUserId: currentUserId)
            }
        } label: {
            ZStack {
                if isRsvped {
                    Text("Leave Game")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrCoral)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.dinkrCoral, lineWidth: 1.5)
                        )
                } else {
                    Text(session.isFull ? "Join Waitlist" : "Join Game")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(session.isFull ? Color.dinkrAmber : Color.dinkrGreen)
                        )
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

    // MARK: - Reminder Logic

    private func checkReminderStatus() async {
        reminderScheduled = await NotificationService.shared.isReminderScheduled(for: session.id)
    }

    private func toggleReminder() async {
        if reminderScheduled {
            await NotificationService.shared.cancelGameReminder(for: session.id)
            reminderScheduled = false
        } else {
            await NotificationService.shared.requestPermission()
            await NotificationService.shared.scheduleGameReminder(for: session)
            let scheduled = await NotificationService.shared.isReminderScheduled(for: session.id)
            reminderScheduled = scheduled
            if scheduled {
                presentToast("Reminder set for 1 hour before")
            }
        }
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

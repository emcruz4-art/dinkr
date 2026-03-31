import SwiftUI

// MARK: - Attendance Confirmation Sheet

/// Full sheet: "Did everyone show up?" with player list to confirm or report.
struct AttendanceConfirmationView: View {
    let prompt: SessionConfirmationPrompt
    @Environment(\.dismiss) private var dismiss
    @State private var playerStates: [String: PlayerAttendanceState] = [:]
    @State private var isSubmitting = false
    @State private var didSubmit = false

    private var allPlayers: [AttendancePlayer] {
        prompt.rsvpUserIds.compactMap { uid in
            if uid == prompt.currentUserId { return nil }   // skip self
            let mock = User.mockPlayers.first { $0.id == uid }
            return AttendancePlayer(
                id: uid,
                name: mock?.displayName ?? "Player",
                username: mock?.username ?? uid,
                skill: mock?.skillLevel ?? .intermediate35
            )
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                if didSubmit {
                    successView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            sessionInfoCard
                            playerListSection
                            submitButton
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                    }
                }
            }
            .navigationTitle("Confirm Attendance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Later") {
                        NoShowService.shared.dismissPrompt(sessionId: prompt.sessionId)
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .onAppear {
                // Default all to "showed up"
                for uid in prompt.rsvpUserIds where uid != prompt.currentUserId {
                    playerStates[uid] = .present
                }
            }
        }
    }

    // MARK: - Session Info Card

    private var sessionInfoCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen.opacity(0.14))
                        .frame(width: 44, height: 44)
                    Image(systemName: "figure.pickleball")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.dinkrGreen)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(prompt.sessionCourtName)
                        .font(.subheadline.weight(.semibold))
                    Text("Ended \(prompt.timeAgoString) · hosted by \(prompt.hostName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundStyle(Color.dinkrAmber)
                Text("Confirmation closes in \(hoursLeft) hours")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(UIColor.separator).opacity(0.3), lineWidth: 1)
        )
    }

    private var hoursLeft: Int {
        max(0, Int(prompt.deadline.timeIntervalSinceNow / 3600))
    }

    // MARK: - Player List

    private var playerListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Who showed up?")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 8) {
                ForEach(allPlayers) { player in
                    AttendancePlayerRow(
                        player: player,
                        state: playerStates[player.id] ?? .present
                    ) { newState in
                        withAnimation(.easeInOut(duration: 0.18)) {
                            playerStates[player.id] = newState
                            HapticManager.selection()
                        }
                    }
                }
            }

            Text("Two or more no-show reports reduces a player's reliability score.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button {
            submit()
        } label: {
            HStack(spacing: 8) {
                if isSubmitting {
                    ProgressView().tint(.white).scaleEffect(0.8)
                }
                Text(isSubmitting ? "Submitting…" : "Submit Attendance")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(isSubmitting ? Color.dinkrGreen.opacity(0.6) : Color.dinkrGreen,
                        in: RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isSubmitting)
    }

    private func submit() {
        isSubmitting = true
        Task {
            // Confirm own attendance
            await NoShowService.shared.confirmAttendance(
                sessionId: prompt.sessionId,
                userId: prompt.currentUserId
            )
            // File no-show reports
            for (uid, state) in playerStates where state == .absent {
                await NoShowService.shared.reportNoShow(
                    sessionId: prompt.sessionId,
                    absentUserId: uid,
                    reportedByUserId: prompt.currentUserId
                )
            }
            HapticManager.success()
            withAnimation { didSubmit = true }
            isSubmitting = false
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            dismiss()
        }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.dinkrGreen)
            }
            VStack(spacing: 8) {
                Text("Attendance Confirmed")
                    .font(.title3.weight(.bold))
                Text("Thanks for keeping the community reliable.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Player Row

private struct AttendancePlayerRow: View {
    let player: AttendancePlayer
    let state: PlayerAttendanceState
    let onChange: (PlayerAttendanceState) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Avatar placeholder
            ZStack {
                Circle()
                    .fill(Color.dinkrNavy.opacity(0.12))
                    .frame(width: 40, height: 40)
                Text(player.name.prefix(1))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.dinkrNavy)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.subheadline.weight(.semibold))
                Text("@\(player.username) · \(player.skill.label)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Present / Absent toggle
            HStack(spacing: 6) {
                attendanceChip(label: "Here", icon: "checkmark", stateValue: .present,
                               activeColor: Color.dinkrGreen)
                attendanceChip(label: "No-show", icon: "xmark", stateValue: .absent,
                               activeColor: Color.dinkrCoral)
            }
        }
        .padding(12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    state == .absent ? Color.dinkrCoral.opacity(0.4) :
                    state == .present ? Color.dinkrGreen.opacity(0.3) :
                    Color.clear,
                    lineWidth: 1
                )
        )
    }

    @ViewBuilder
    private func attendanceChip(label: String, icon: String,
                                 stateValue: PlayerAttendanceState, activeColor: Color) -> some View {
        let isActive = state == stateValue
        Button {
            onChange(stateValue)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(isActive ? .white : Color.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                isActive ? activeColor : Color(UIColor.tertiarySystemBackground),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: state)
    }
}

// MARK: - Supporting Types

private struct AttendancePlayer: Identifiable {
    let id: String
    let name: String
    let username: String
    let skill: SkillLevel
}

enum PlayerAttendanceState {
    case present, absent
}

// MARK: - Attendance Banner (inline prompt on Home / Play)

struct AttendanceBanner: View {
    let prompt: SessionConfirmationPrompt

    @State private var showSheet      = false
    @State private var didAnswer      = false
    @State private var didPlay: Bool? = nil          // nil = not answered yet
    @State private var showLogResult  = false
    @State private var swipeOffset: CGFloat = 0
    @State private var isDismissed    = false

    // Readable relative time: "Yesterday at 2 PM", "Today at 3:30 PM", "2 hours ago"
    private var relativeDateLabel: String {
        let cal = Calendar.current
        let dt = prompt.sessionDateTime
        let now = Date()
        let interval = now.timeIntervalSince(dt)

        if cal.isDateInToday(dt) {
            let hours = Int(interval / 3600)
            if hours < 1 { return "Just ended" }
            if hours == 1 { return "1 hour ago" }
            return "\(hours) hours ago"
        }
        if cal.isDateInYesterday(dt) {
            let timeStr = dt.formatted(.dateTime.hour().minute())
            return "Yesterday at \(timeStr)"
        }
        return dt.formatted(.dateTime.weekday(.short).month(.abbreviated).day().hour().minute())
    }

    // Player avatars from the RSVP list (up to 2 others)
    private var otherPlayerIds: [String] {
        prompt.rsvpUserIds.filter { $0 != prompt.currentUserId }.prefix(2).map { $0 }
    }

    var body: some View {
        if isDismissed { EmptyView() } else {
            bannerContent
                .offset(x: swipeOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Only allow leftward swipe
                            if value.translation.width < 0 {
                                swipeOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if value.translation.width < -80 {
                                // Swipe left to dismiss (mark as skipped)
                                withAnimation(.easeOut(duration: 0.25)) {
                                    swipeOffset = -UIScreen.main.bounds.width
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    NoShowService.shared.dismissPrompt(sessionId: prompt.sessionId)
                                    isDismissed = true
                                }
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    swipeOffset = 0
                                }
                            }
                        }
                )
                .sheet(isPresented: $showSheet) {
                    AttendanceConfirmationView(prompt: prompt)
                }
                .sheet(isPresented: $showLogResult) {
                    LogGameResultView()
                }
        }
    }

    // MARK: - Banner Body

    @ViewBuilder
    private var bannerContent: some View {
        ZStack(alignment: .leading) {

            // Amber gradient background
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.dinkrAmber.opacity(0.22),
                            Color.dinkrAmber.opacity(0.08)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.dinkrAmber.opacity(0.45), lineWidth: 1.5)

            VStack(alignment: .leading, spacing: 10) {

                // Top row: avatars + court + time
                HStack(spacing: 10) {

                    // Player avatar stack
                    HStack(spacing: -10) {
                        ForEach(Array(otherPlayerIds.enumerated()), id: \.element) { index, uid in
                            BannerAvatarCircle(userId: uid, index: index)
                        }
                        // Current user avatar on top
                        BannerAvatarCircle(userId: prompt.currentUserId, index: otherPlayerIds.count)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Did you play?")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.primary)
                        Text("\(prompt.sessionCourtName) · \(relativeDateLabel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Swipe hint
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.dinkrAmber.opacity(0.5))
                }

                // Inline Yes / No / Log Score buttons
                if !didAnswer {
                    HStack(spacing: 8) {
                        // Yes
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                                didPlay = true
                                didAnswer = true
                                HapticManager.success()
                            }
                            // Open confirmation sheet after brief delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showSheet = true
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Yes")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(Color.dinkrGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)

                        // No
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                                didPlay = false
                                didAnswer = true
                                HapticManager.selection()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                NoShowService.shared.dismissPrompt(sessionId: prompt.sessionId)
                                isDismissed = true
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .bold))
                                Text("No")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(Color.dinkrCoral)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(Color.dinkrCoral.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.dinkrCoral.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        // Log Score
                        Button {
                            HapticManager.medium()
                            showLogResult = true
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "pencil.line")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Log Score")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(Color.dinkrAmber)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(Color.dinkrAmber.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.dinkrAmber.opacity(0.35), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    // Answered state
                    HStack(spacing: 8) {
                        Image(systemName: didPlay == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(didPlay == true ? Color.dinkrGreen : Color.dinkrCoral)
                        Text(didPlay == true ? "Opening attendance confirmation…" : "Got it, skipping this one.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Banner Avatar Circle

private struct BannerAvatarCircle: View {
    let userId: String
    let index: Int

    private var color: Color {
        let palette: [Color] = [Color.dinkrGreen, Color.dinkrSky, Color.dinkrAmber, Color.dinkrCoral, Color.dinkrNavy]
        let hash = userId.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palette[hash % palette.count]
    }

    private var initials: String {
        let trimmed = userId.replacingOccurrences(of: "user_", with: "")
        return "U\(trimmed.prefix(1))"
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.22))
                .frame(width: 34, height: 34)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.8), lineWidth: 2)
                )
            Text(initials)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
        }
        .zIndex(Double(10 - index))
    }
}

// MARK: - Preview

#Preview("Confirmation Sheet") {
    AttendanceConfirmationView(prompt: SessionConfirmationPrompt(
        sessionId: "gs1",
        sessionCourtName: "Westside Pickleball Complex",
        sessionDateTime: Date().addingTimeInterval(-5400),
        hostId: "user_002",
        hostName: "Maria Chen",
        rsvpUserIds: ["user_001", "user_002", "user_003", "user_004"],
        currentUserId: "user_001",
        deadline: Date().addingTimeInterval(77400)
    ))
}

#Preview("Banner") {
    ScrollView {
        VStack(spacing: 16) {
            // Default (unanswered)
            AttendanceBanner(prompt: SessionConfirmationPrompt(
                sessionId: "gs1",
                sessionCourtName: "Westside Pickleball Complex",
                sessionDateTime: Date().addingTimeInterval(-5400),
                hostId: "user_002",
                hostName: "Maria Chen",
                rsvpUserIds: ["user_001", "user_002", "user_003", "user_004"],
                currentUserId: "user_001",
                deadline: Date().addingTimeInterval(77400)
            ))

            // Yesterday session
            AttendanceBanner(prompt: SessionConfirmationPrompt(
                sessionId: "gs2",
                sessionCourtName: "Mueller Recreation Center",
                sessionDateTime: Calendar.current.date(byAdding: .hour, value: -26, to: Date())!,
                hostId: "user_003",
                hostName: "Jordan Smith",
                rsvpUserIds: ["user_001", "user_003"],
                currentUserId: "user_001",
                deadline: Date().addingTimeInterval(50000)
            ))
        }
        .padding()
    }
}

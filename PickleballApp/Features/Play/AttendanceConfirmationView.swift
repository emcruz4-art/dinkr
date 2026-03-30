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
    @State private var showSheet = false

    var body: some View {
        Button { showSheet = true } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.dinkrAmber.opacity(0.16))
                        .frame(width: 38, height: 38)
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.dinkrAmber)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Did everyone show up?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                    Text("\(prompt.sessionCourtName) · \(prompt.timeAgoString)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text("Confirm")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.dinkrAmber, in: Capsule())
            }
            .padding(14)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.dinkrAmber.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) {
            AttendanceConfirmationView(prompt: prompt)
        }
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
    .padding()
}

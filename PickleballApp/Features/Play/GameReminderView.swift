import SwiftUI
import UserNotifications

// MARK: - GameReminderView

/// Bottom sheet for setting or removing a local notification reminder for a game session.
struct GameReminderView: View {

    // MARK: Input

    let session: GameSession

    // MARK: Environment / Services

    @Environment(\.dismiss) private var dismiss
    private var notificationService: LocalNotificationService { LocalNotificationService.shared }

    // MARK: State

    /// Minutes before the game to fire the reminder (15, 30, 60, 120).
    @State private var selectedMinutes: Int = 30

    // Sub-option toggles
    @State private var remindPackBag: Bool = false
    @State private var remindLeave: Bool = false
    @State private var remindWarmUp: Bool = false

    /// Whether a reminder is already set for this session.
    @State private var reminderAlreadySet: Bool = false

    /// Drives the confirmation state after tapping "Set Reminder".
    @State private var showConfirmation: Bool = false

    /// Animates the bell icon on confirmation.
    @State private var bellScale: CGFloat = 1.0

    // MARK: Reminder Chip Options

    private let timeOptions: [(label: String, minutes: Int)] = [
        ("15 min", 15),
        ("30 min", 30),
        ("1 hour", 60),
        ("2 hours", 120),
    ]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 18)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerRow
                    gameInfoCard
                    timeChipRow
                    subOptionsSection
                    actionButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .presentationDetents([.height(340)])
        .presentationDragIndicator(.hidden) // We draw our own above
        .task { await checkExistingReminder() }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.dinkrGreen)
                .scaleEffect(bellScale)
                .animation(.spring(response: 0.35, dampingFraction: 0.5), value: bellScale)

            Text("Set Reminder")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.dinkrNavy)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
        }
    }

    // MARK: - Game Info Card

    private var gameInfoCard: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.dinkrGreen.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.dinkrGreen)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(session.courtName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                Text(session.dateTime.formatted(.dateTime.weekday(.short).month(.abbreviated).day().hour().minute()))
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Time Chip Row

    private var timeChipRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Remind me")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)

            HStack(spacing: 8) {
                ForEach(timeOptions, id: \.minutes) { option in
                    TimeChip(
                        label: option.label,
                        isSelected: selectedMinutes == option.minutes
                    ) {
                        selectedMinutes = option.minutes
                    }
                }
            }
        }
    }

    // MARK: - Sub-Options Section

    private var subOptionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Also remind me to:")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)

            SubOptionToggle(
                icon: "bag.fill",
                iconColor: Color.dinkrAmber,
                label: "Pack your paddle bag",
                isOn: $remindPackBag
            )
            SubOptionToggle(
                icon: "car.fill",
                iconColor: Color.dinkrSky,
                label: "Leave for court",
                isOn: $remindLeave
            )
            SubOptionToggle(
                icon: "figure.flexibility",
                iconColor: Color.dinkrCoral,
                label: "Warm up stretches",
                isOn: $remindWarmUp
            )
        }
    }

    // MARK: - Action Button

    @ViewBuilder
    private var actionButton: some View {
        if showConfirmation {
            // Confirmation state
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.dinkrGreen)
                Text("Reminder set! ✅")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dinkrGreen)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.dinkrGreen.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        } else if reminderAlreadySet {
            // Remove reminder
            Button {
                notificationService.cancelReminder(sessionId: session.id)
                reminderAlreadySet = false
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bell.slash.fill")
                        .foregroundStyle(Color.dinkrCoral)
                    Text("Remove Reminder")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrCoral)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.dinkrCoral, lineWidth: 1.5)
                )
            }
        } else {
            // Set reminder
            Button {
                Task { await setReminder() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bell.fill")
                    Text("Set Reminder")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Actions

    private func checkExistingReminder() async {
        reminderAlreadySet = await notificationService.isReminderScheduled(for: session.id)
    }

    private func setReminder() async {
        let granted = await notificationService.requestPermission()
        guard granted else { return }

        await notificationService.scheduleGameReminder(
            session: session,
            minutesBefore: selectedMinutes,
            remindPackBag: remindPackBag,
            remindLeave: remindLeave,
            remindWarmUp: remindWarmUp
        )

        reminderAlreadySet = await notificationService.isReminderScheduled(for: session.id)
        guard reminderAlreadySet else { return }

        // Trigger bell animation + confirmation banner
        withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
            bellScale = 1.4
            showConfirmation = true
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.25)) {
            bellScale = 1.0
        }

        // Auto-dismiss after showing confirmation
        Task {
            try? await Task.sleep(for: .seconds(1.8))
            dismiss()
        }
    }
}

// MARK: - TimeChip

private struct TimeChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : Color.dinkrGreen)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? AnyShapeStyle(Color.dinkrGreen)
                        : AnyShapeStyle(Color.dinkrGreen.opacity(0.12))
                    , in: Capsule()
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : Color.dinkrGreen.opacity(0.3), lineWidth: 1)
                )
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - SubOptionToggle

private struct SubOptionToggle: View {
    let icon: String
    let iconColor: Color
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.primary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.dinkrGreen)
        }
    }
}

// MARK: - Preview

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            GameReminderView(session: GameSession.mockSessions[0])
        }
}

import SwiftUI

// MARK: - AvailabilityPollCard

struct AvailabilityPollCard: View {
    let poll: AvailabilityPoll
    let currentUserId: String

    @State private var localPoll: AvailabilityPoll
    @State private var showScheduleConfirm = false

    init(poll: AvailabilityPoll, currentUserId: String) {
        self.poll = poll
        self.currentUserId = currentUserId
        self._localPoll = State(initialValue: poll)
    }

    private var maxVotes: Int {
        localPoll.timeSlots.map(\.voteCount).max() ?? 1
    }

    private var hoursUntilClose: Int {
        max(0, Int(localPoll.closesAt.timeIntervalSince(Date()) / 3600))
    }

    private var timeAgoText: String {
        let interval = Date().timeIntervalSince(localPoll.createdAt)
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }

    private var isCreator: Bool { localPoll.createdByUserId == currentUserId }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ────────────────────────────────────────────────────
            HStack(spacing: 10) {
                Text("📅")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(localPoll.question)
                        .font(.subheadline.weight(.bold))
                    Text("by \(localPoll.createdByName) · \(timeAgoText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if localPoll.isOpen {
                    Text("OPEN")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color.dinkrGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.dinkrGreen.opacity(0.12))
                        .clipShape(Capsule())
                } else {
                    Text("CLOSED")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider().padding(.horizontal, 16)

            // ── Time slot rows ────────────────────────────────────────────
            VStack(spacing: 0) {
                ForEach(localPoll.timeSlots) { slot in
                    PollSlotRow(
                        slot: slot,
                        maxVotes: maxVotes,
                        isWinner: localPoll.winningSlot?.id == slot.id,
                        currentUserId: currentUserId,
                        isOpen: localPoll.isOpen
                    ) {
                        toggleVote(for: slot)
                    }
                    Divider().padding(.leading, 16)
                }
            }

            // ── Schedule This Time button (winner) ────────────────────────
            if !localPoll.isOpen || isCreator, let winner = localPoll.winningSlot {
                Button {
                    HapticManager.medium()
                    showScheduleConfirm = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.subheadline.weight(.semibold))
                        Text("Schedule This Time")
                            .font(.subheadline.weight(.bold))
                        Spacer()
                        Text(slotFormattedDate(winner.dateTime))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen.opacity(0.8))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.dinkrGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 0))
                }
                .buttonStyle(.plain)
            }

            // ── Footer ────────────────────────────────────────────────────
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(localPoll.totalVotes) voters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if localPoll.isOpen {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Closes in \(hoursUntilClose)h")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.dinkrGreen.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        .alert("Schedule Game", isPresented: $showScheduleConfirm) {
            Button("Schedule", role: .none) { HapticManager.medium() }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let winner = localPoll.winningSlot {
                Text("Create a session for \(slotFormattedDate(winner.dateTime))?")
            }
        }
    }

    private func toggleVote(for slot: PollTimeSlot) {
        guard localPoll.isOpen else { return }
        HapticManager.selection()
        if let idx = localPoll.timeSlots.firstIndex(where: { $0.id == slot.id }) {
            if localPoll.timeSlots[idx].votes.contains(currentUserId) {
                localPoll.timeSlots[idx].votes.removeAll { $0 == currentUserId }
            } else {
                localPoll.timeSlots[idx].votes.append(currentUserId)
            }
        }
    }

    private func slotFormattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d · h:mm a"
        return f.string(from: date)
    }
}

// MARK: - Poll Slot Row

private struct PollSlotRow: View {
    let slot: PollTimeSlot
    let maxVotes: Int
    let isWinner: Bool
    let currentUserId: String
    let isOpen: Bool
    let onTap: () -> Void

    private var hasVoted: Bool { slot.votes.contains(currentUserId) }
    private var barRatio: Double {
        guard maxVotes > 0 else { return 0 }
        return Double(slot.voteCount) / Double(maxVotes)
    }

    private var formattedDateTime: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d · h:mm a"
        return f.string(from: slot.dateTime)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Date/time label
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedDateTime)
                        .font(.subheadline.weight(isWinner ? .bold : .regular))
                        .foregroundStyle(isWinner ? Color.dinkrGreen : Color.primary)
                }
                .frame(minWidth: 160, alignment: .leading)

                Spacer()

                // Vote bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.1))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isWinner ? Color.dinkrGreen : Color.dinkrSky.opacity(0.7))
                            .frame(width: geo.size.width * barRatio, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: barRatio)
                    }
                }
                .frame(height: 8)

                // Vote count bubble
                Text("\(slot.voteCount)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isWinner ? Color.dinkrGreen : Color.secondary)
                    .frame(minWidth: 20)

                // Checkmark if voted
                Image(systemName: hasVoted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(hasVoted ? Color.dinkrGreen : Color.secondary.opacity(0.4))
                    .font(.system(size: 18))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: hasVoted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isOpen)
    }
}

// MARK: - CreateAvailabilityPollView

struct CreateAvailabilityPollView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var question = "When should we play?"
    @State private var timeSlots: [Date] = [
        Calendar.current.date(byAdding: .day, value: 1,
            to: Calendar.current.startOfDay(for: Date()))
            .flatMap { Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: $0) }
            ?? Date()
    ]
    @State private var closeDurationIndex = 0

    private let closeDurations = ["24 hours", "48 hours", "1 week"]
    private let maxSlots = 6

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // ── Question field ────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Question", systemImage: "questionmark.bubble.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        TextField("When should we play?", text: $question)
                            .padding(12)
                            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.dinkrGreen.opacity(0.25), lineWidth: 1)
                            )
                    }

                    // ── Time slots ─────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Time Slots", systemImage: "calendar")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            Spacer()
                            if timeSlots.count < maxSlots {
                                Button {
                                    HapticManager.selection()
                                    let next = Calendar.current.date(
                                        byAdding: .day, value: 1,
                                        to: timeSlots.last ?? Date()
                                    ) ?? Date()
                                    timeSlots.append(next)
                                } label: {
                                    Label("Add Slot", systemImage: "plus.circle.fill")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.dinkrGreen)
                                }
                            }
                        }

                        ForEach(timeSlots.indices, id: \.self) { idx in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.dinkrGreen.opacity(0.12))
                                        .frame(width: 28, height: 28)
                                    Text("\(idx + 1)")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.dinkrGreen)
                                }

                                DatePicker(
                                    "",
                                    selection: $timeSlots[idx],
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Button(role: .destructive) {
                                    HapticManager.selection()
                                    timeSlots.remove(at: idx)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundStyle(Color.dinkrCoral)
                                }
                                .disabled(timeSlots.count <= 1)
                                .opacity(timeSlots.count <= 1 ? 0.3 : 1)
                            }
                            .padding(12)
                            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                            )
                        }

                        if timeSlots.count >= maxSlots {
                            Text("Maximum \(maxSlots) slots reached")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // ── Poll duration ─────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Poll closes after", systemImage: "clock.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        Picker("Close after", selection: $closeDurationIndex) {
                            ForEach(closeDurations.indices, id: \.self) { i in
                                Text(closeDurations[i]).tag(i)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // ── Send button ───────────────────────────────────────
                    Button {
                        HapticManager.medium()
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.fill")
                            Text("Send Poll")
                                .font(.headline.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.dinkrGreen.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .navigationTitle("Schedule a Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .background(Color.appBackground)
        }
    }
}

// MARK: - Preview

#Preview {
    AvailabilityPollCard(poll: .mock, currentUserId: "user_001")
        .padding()
}

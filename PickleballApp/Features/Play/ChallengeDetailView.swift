import SwiftUI

// MARK: - Mock pre-match chat messages

private struct TrashTalkMessage: Identifiable {
    let id: String
    let senderId: String
    let senderName: String
    let text: String
    let sentAt: Date
}

private extension TrashTalkMessage {
    static func mock(for challenge: GameChallenge) -> [TrashTalkMessage] {
        let now = Date()
        return [
            TrashTalkMessage(
                id: "msg_1",
                senderId: challenge.challengerId,
                senderName: challenge.challengerName,
                text: challenge.message.isEmpty ? "Challenge accepted or what? 👀" : challenge.message,
                sentAt: challenge.createdAt
            ),
            TrashTalkMessage(
                id: "msg_2",
                senderId: challenge.challengeeId,
                senderName: challenge.challengeeName,
                text: "You sure you're ready for this? Last time didn't end well for you 😅",
                sentAt: challenge.createdAt.addingTimeInterval(600)
            ),
            TrashTalkMessage(
                id: "msg_3",
                senderId: challenge.challengerId,
                senderName: challenge.challengerName,
                text: "I've been putting in reps. See you on the court.",
                sentAt: challenge.createdAt.addingTimeInterval(900)
            ),
            TrashTalkMessage(
                id: "msg_4",
                senderId: challenge.challengeeId,
                senderName: challenge.challengeeName,
                text: "Let's lock in the court. Mueller open Saturday morning?",
                sentAt: now.addingTimeInterval(-1800)
            ),
        ]
    }
}

// MARK: - ChallengeDetailView

struct ChallengeDetailView: View {
    let challenge: GameChallenge
    let currentUserId: String

    @State private var messages: [TrashTalkMessage] = []
    @State private var newMessage = ""
    @State private var showReschedule = false
    @State private var rescheduleDate = Date()
    @State private var localStatus: GameChallengeStatus
    @State private var showDeclineConfirm = false

    // Mock match result for completed challenges
    private let mockResult = (scoreA: 11, scoreB: 7)

    init(challenge: GameChallenge, currentUserId: String = "user_001") {
        self.challenge = challenge
        self.currentUserId = currentUserId
        _localStatus = State(initialValue: challenge.status)
    }

    private var isIncoming: Bool {
        challenge.challengeeId == currentUserId
    }

    private var opponentName: String {
        isIncoming ? challenge.challengerName : challenge.challengeeName
    }

    private var opponentId: String {
        isIncoming ? challenge.challengerId : challenge.challengeeId
    }

    private var myName: String {
        currentUserId == "user_001" ? "Alex Rivera" : "You"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                statusBanner
                playersSection
                matchDetailsCard
                chatSection
                if localStatus == .completed {
                    matchResultSection
                }
                actionButtons
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .padding(.bottom, 32)
        }
        .background(Color.appBackground)
        .navigationTitle("Challenge Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            messages = TrashTalkMessage.mock(for: challenge)
        }
        .sheet(isPresented: $showReschedule) {
            rescheduleSheet
        }
        .confirmationDialog(
            "Decline this challenge?",
            isPresented: $showDeclineConfirm,
            titleVisibility: .visible
        ) {
            Button("Decline", role: .destructive) {
                withAnimation { localStatus = .declined }
                HapticManager.medium()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Status Banner

    private var statusBanner: some View {
        let config = statusConfig(localStatus)
        return HStack(spacing: 8) {
            Image(systemName: config.icon)
                .font(.subheadline)
                .foregroundStyle(config.color)
            Text(config.label)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(config.color)
            Spacer()
            if localStatus == .pending {
                Text("Awaiting response")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if localStatus == .accepted {
                Text("Match confirmed")
                    .font(.caption)
                    .foregroundStyle(Color.dinkrGreen)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(config.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(config.color.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Players Section

    private var playersSection: some View {
        HStack(spacing: 12) {
            playerCard(
                name: challenge.challengerName,
                userId: challenge.challengerId,
                isChallenger: true
            )

            VStack(spacing: 4) {
                Text("VS")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Color.dinkrNavy)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 40)

            playerCard(
                name: challenge.challengeeName,
                userId: challenge.challengeeId,
                isChallenger: false
            )
        }
    }

    @ViewBuilder
    private func playerCard(name: String, userId: String, isChallenger: Bool) -> some View {
        let initial = String(name.prefix(1)).uppercased()
        // Pull DUPR + win rate from mock players
        let mockPlayer = User.mockPlayers.first(where: { $0.id == userId })
            ?? (userId == "user_001" ? User.mockCurrentUser : nil)
        let duprText = mockPlayer?.duprRating.map { String(format: "%.2f DUPR", $0) } ?? "No DUPR"
        let winRate = mockPlayer.map { Int($0.winRate * 100) } ?? 0

        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        isChallenger
                            ? Color.dinkrGreen.opacity(0.15)
                            : Color.dinkrCoral.opacity(0.15)
                    )
                    .frame(width: 56, height: 56)
                Text(initial)
                    .font(.title2.weight(.black))
                    .foregroundStyle(isChallenger ? Color.dinkrGreen : Color.dinkrCoral)
                if isChallenger {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.dinkrAmber)
                        .offset(x: 22, y: -20)
                }
            }

            Text(name)
                .font(.subheadline.weight(.bold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(duprText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.dinkrSky)

            HStack(spacing: 3) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(Color.dinkrGreen)
                Text("\(winRate)% Win Rate")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.dinkrGreen)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Match Details Card

    private var matchDetailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MATCH DETAILS")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(.secondary)

            detailRow(icon: "figure.pickleball", label: "Format", value: challenge.format.rawValue, color: Color.dinkrGreen)
            Divider()
            detailRow(
                icon: "calendar",
                label: "Proposed Date",
                value: formattedDate(challenge.proposedDate),
                color: Color.dinkrSky
            )
            Divider()
            detailRow(icon: "mappin.circle.fill", label: "Court", value: "TBD — to be arranged", color: Color.dinkrCoral)
            Divider()
            detailRow(icon: "dollarsign.circle.fill", label: "Wager", value: "No wager", color: Color.dinkrAmber)
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func detailRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 22)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Chat Section

    private var chatSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundStyle(Color.dinkrNavy)
                Text("PRE-MATCH CHAT")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(messages.count) messages")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                ForEach(messages) { msg in
                    chatBubble(msg)
                }
            }

            // Compose row
            if localStatus != .declined {
                HStack(spacing: 10) {
                    TextField("Say something bold…", text: $newMessage)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color.appBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        guard !newMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let msg = TrashTalkMessage(
                            id: UUID().uuidString,
                            senderId: currentUserId,
                            senderName: myName,
                            text: newMessage,
                            sentAt: Date()
                        )
                        withAnimation { messages.append(msg) }
                        newMessage = ""
                        HapticManager.selection()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(Color.dinkrGreen)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private func chatBubble(_ msg: TrashTalkMessage) -> some View {
        let isMe = msg.senderId == currentUserId
        HStack(alignment: .bottom, spacing: 6) {
            if isMe { Spacer(minLength: 40) }

            if !isMe {
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Text(String(msg.senderName.prefix(1)).uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.dinkrGreen)
                }
            }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 3) {
                if !isMe {
                    Text(msg.senderName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                Text(msg.text)
                    .font(.subheadline)
                    .foregroundStyle(isMe ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isMe ? Color.dinkrGreen : Color.appBackground)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                Text(shortTime(msg.sentAt))
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            if isMe {
                ZStack {
                    Circle()
                        .fill(Color.dinkrSky.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Text(String(myName.prefix(1)).uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.dinkrSky)
                }
            }
            if !isMe { Spacer(minLength: 40) }
        }
    }

    // MARK: - Match Result Section (completed)

    private var matchResultSection: some View {
        let winner = mockResult.scoreA > mockResult.scoreB
            ? challenge.challengerName
            : challenge.challengeeName

        return VStack(spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Color.dinkrAmber)
                Text("MATCH RESULT")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .center, spacing: 20) {
                VStack(spacing: 4) {
                    Text(challenge.challengerName.components(separatedBy: " ").first ?? "")
                        .font(.subheadline.weight(.bold))
                    if winner == challenge.challengerName {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(Color.dinkrAmber)
                    }
                }
                .frame(maxWidth: .infinity)

                Text("\(mockResult.scoreA)  –  \(mockResult.scoreB)")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(Color.primary)

                VStack(spacing: 4) {
                    Text(challenge.challengeeName.components(separatedBy: " ").first ?? "")
                        .font(.subheadline.weight(.bold))
                    if winner == challenge.challengeeName {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(Color.dinkrAmber)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Text("\(winner) wins!")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.dinkrGreen)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.dinkrAmber.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.dinkrAmber.opacity(0.25), lineWidth: 1)
                )
        )
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        switch localStatus {
        case .pending where isIncoming:
            VStack(spacing: 10) {
                Button {
                    withAnimation { localStatus = .accepted }
                    HapticManager.success()
                } label: {
                    Label("Accept Challenge", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.dinkrGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                HStack(spacing: 10) {
                    Button {
                        showDeclineConfirm = true
                    } label: {
                        Text("Decline")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrCoral)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.dinkrCoral, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        rescheduleDate = challenge.proposedDate
                        showReschedule = true
                    } label: {
                        Text("Reschedule")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrSky)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.dinkrSky, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

        case .pending where !isIncoming:
            Button {
                showDeclineConfirm = true
            } label: {
                Text("Cancel Challenge")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dinkrCoral)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.dinkrCoral, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)

        case .accepted:
            HStack(spacing: 10) {
                Button {
                    rescheduleDate = challenge.proposedDate
                    showReschedule = true
                } label: {
                    Label("Reschedule", systemImage: "calendar.badge.clock")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrSky)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.dinkrSky, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation { localStatus = .declined }
                    HapticManager.medium()
                } label: {
                    Text("Cancel")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrCoral)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.dinkrCoral, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }

        case .completed:
            Button {
                // Stub: share result
                HapticManager.success()
            } label: {
                Label("Share Result", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.dinkrNavy)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

        default:
            EmptyView()
        }
    }

    // MARK: - Reschedule Sheet

    private var rescheduleSheet: some View {
        NavigationStack {
            Form {
                Section("New Date & Time") {
                    DatePicker(
                        "Proposed Date",
                        selection: $rescheduleDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .tint(Color.dinkrGreen)
                }
            }
            .navigationTitle("Reschedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showReschedule = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send Request") {
                        HapticManager.success()
                        showReschedule = false
                    }
                    .tint(Color.dinkrGreen)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Helpers

    private func statusConfig(_ status: GameChallengeStatus) -> (label: String, icon: String, color: Color) {
        switch status {
        case .pending:   return ("Pending Response", "clock.fill", Color.dinkrAmber)
        case .accepted:  return ("Accepted · In Progress", "checkmark.circle.fill", Color.dinkrGreen)
        case .declined:  return ("Declined", "xmark.circle.fill", Color.dinkrCoral)
        case .completed: return ("Completed", "flag.checkered", Color.dinkrSky)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    private func shortTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }
}

#Preview {
    NavigationStack {
        ChallengeDetailView(challenge: GameChallenge.mockChallenges.first!)
    }
}

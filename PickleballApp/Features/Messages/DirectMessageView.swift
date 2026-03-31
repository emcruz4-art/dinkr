import SwiftUI

// MARK: - DirectMessage Models

enum DMBubbleType {
    case text
    case gameInvite(courtName: String, date: Date, format: String)
}

struct DirectMessage: Identifiable {
    var id: String
    var senderId: String          // "me" = current user
    var text: String
    var timestamp: Date
    var isRead: Bool
    var reaction: String?
    var bubbleType: DMBubbleType

    init(
        id: String,
        senderId: String,
        text: String,
        timestamp: Date,
        isRead: Bool,
        reaction: String? = nil,
        bubbleType: DMBubbleType = .text
    ) {
        self.id = id
        self.senderId = senderId
        self.text = text
        self.timestamp = timestamp
        self.isRead = isRead
        self.reaction = reaction
        self.bubbleType = bubbleType
    }
}

// MARK: - Mock Data

private extension DirectMessage {
    static func mockThread(for conversationId: String, otherUserId: String) -> [DirectMessage] {
        let now = Date()
        func ago(_ minutes: Int) -> Date {
            Calendar.current.date(byAdding: .minute, value: -minutes, to: now) ?? now
        }

        return [
            DirectMessage(
                id: "\(conversationId)_1",
                senderId: otherUserId,
                text: "Hey! Are you free this weekend for a match?",
                timestamp: ago(70),
                isRead: true
            ),
            DirectMessage(
                id: "\(conversationId)_2",
                senderId: "me",
                text: "Yeah, Saturday works! What time?",
                timestamp: ago(65),
                isRead: true
            ),
            DirectMessage(
                id: "\(conversationId)_3",
                senderId: otherUserId,
                text: "How about 9am? I know a great court.",
                timestamp: ago(60),
                isRead: true
            ),
            DirectMessage(
                id: "\(conversationId)_4",
                senderId: otherUserId,
                text: "Game Invite",
                timestamp: ago(58),
                isRead: true,
                bubbleType: .gameInvite(
                    courtName: "Zilker Park Courts",
                    date: Calendar.current.date(byAdding: .day, value: 2, to: now) ?? now,
                    format: "Doubles • 4.0+"
                )
            ),
            DirectMessage(
                id: "\(conversationId)_5",
                senderId: "me",
                text: "Accepted! Bringing my A-game 🏓",
                timestamp: ago(54),
                isRead: true
            ),
            DirectMessage(
                id: "\(conversationId)_6",
                senderId: otherUserId,
                text: "Ha! You'll need it. My dink game has been on fire.",
                timestamp: ago(50),
                isRead: true,
                reaction: "🔥"
            ),
            DirectMessage(
                id: "\(conversationId)_7",
                senderId: "me",
                text: "Challenge accepted. Should we grab coffee after?",
                timestamp: ago(3),
                isRead: true
            ),
            DirectMessage(
                id: "\(conversationId)_8",
                senderId: otherUserId,
                text: "Definitely. There's a great spot right by the courts.",
                timestamp: ago(1),
                isRead: false
            ),
        ]
    }
}

// MARK: - DirectMessageView

struct DirectMessageView: View {
    let conversationId: String
    let otherUserName: String
    let otherUserInitial: String
    let isOnline: Bool

    @State private var messages: [DirectMessage] = []
    @State private var inputText: String = ""
    @State private var showEmojiPicker: String? = nil
    @State private var inviteStates: [String: InviteResponse] = [:]

    private let quickReplies = ["Want to play?", "Great game!", "Count me in 🏓", "Can't make it"]
    private let emojis = ["❤️", "🔥", "😂", "👏", "🎯", "🏓"]

    enum InviteResponse { case accepted, declined }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                messageScrollView
                Divider()
                quickReplyBar
                inputBar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { navToolbar }
        .onAppear {
            messages = DirectMessage.mockThread(
                for: conversationId,
                otherUserId: conversationId
            )
        }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 0) }
    }

    // MARK: - Message Scroll

    private var messageScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                        // Timestamp divider: show when gap > 5 minutes from previous
                        if shouldShowTimestamp(at: index) {
                            TimestampDivider(date: message.timestamp)
                                .padding(.vertical, 8)
                        }

                        DMBubbleRow(
                            message: message,
                            isFromMe: message.senderId == "me",
                            initial: otherUserInitial,
                            inviteState: inviteStates[message.id],
                            onLongPress: {
                                withAnimation(.spring(response: 0.3)) {
                                    showEmojiPicker = showEmojiPicker == message.id ? nil : message.id
                                }
                            },
                            onAcceptInvite: {
                                withAnimation { inviteStates[message.id] = .accepted }
                            },
                            onDeclineInvite: {
                                withAnimation { inviteStates[message.id] = .declined }
                            }
                        )
                        .id(message.id)

                        if showEmojiPicker == message.id {
                            DMEmojiPickerRow(emojis: emojis) { emoji in
                                applyReaction(emoji, to: message.id)
                            }
                            .transition(.scale.combined(with: .opacity))
                            .padding(.horizontal, message.senderId == "me" ? 0 : 60)
                            .frame(
                                maxWidth: .infinity,
                                alignment: message.senderId == "me" ? .trailing : .leading
                            )
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onAppear {
                scrollToBottom(proxy: proxy, animated: false)
            }
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy: proxy, animated: true)
            }
            .onTapGesture {
                withAnimation { showEmojiPicker = nil }
            }
        }
    }

    // MARK: - Quick Reply Bar

    private var quickReplyBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickReplies, id: \.self) { reply in
                    Button {
                        sendMessage(reply)
                    } label: {
                        Text(reply)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.dinkrGreen)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.dinkrGreen.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message \(otherUserName)...", text: $inputText, axis: .vertical)
                .padding(10)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .lineLimit(1...5)

            Button {
                let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                sendMessage(trimmed)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(
                        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color.secondary
                            : Color.dinkrGreen
                    )
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Navigation Toolbar

    @ToolbarContentBuilder
    private var navToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(spacing: 1) {
                HStack(spacing: 6) {
                    Text(otherUserName)
                        .font(.headline)
                    if isOnline {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
                }
                Text(isOnline ? "Online now" : "Last seen recently")
                    .font(.caption2)
                    .foregroundStyle(isOnline ? Color.green : Color.secondary)
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button { } label: {
                Image(systemName: "phone")
                    .foregroundStyle(Color.dinkrGreen)
            }
            Button { } label: {
                Image(systemName: "video.fill")
                    .foregroundStyle(Color.dinkrGreen)
            }
        }
    }

    // MARK: - Helpers

    private func shouldShowTimestamp(at index: Int) -> Bool {
        guard index > 0 else { return true }
        let prev = messages[index - 1]
        let curr = messages[index]
        return curr.timestamp.timeIntervalSince(prev.timestamp) > 300 // 5 min
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        guard let last = messages.last else { return }
        if animated {
            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
        } else {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }

    private func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        inputText = ""
        showEmojiPicker = nil
        let msg = DirectMessage(
            id: UUID().uuidString,
            senderId: "me",
            text: trimmed,
            timestamp: Date(),
            isRead: false
        )
        withAnimation { messages.append(msg) }
    }

    private func applyReaction(_ emoji: String, to messageId: String) {
        if let idx = messages.firstIndex(where: { $0.id == messageId }) {
            messages[idx].reaction = messages[idx].reaction == emoji ? nil : emoji
        }
        withAnimation { showEmojiPicker = nil }
    }
}

// MARK: - DMBubbleRow

private struct DMBubbleRow: View {
    let message: DirectMessage
    let isFromMe: Bool
    let initial: String
    let inviteState: DirectMessageView.InviteResponse?
    let onLongPress: () -> Void
    let onAcceptInvite: () -> Void
    let onDeclineInvite: () -> Void

    var body: some View {
        VStack(alignment: isFromMe ? .trailing : .leading, spacing: 2) {
            HStack(alignment: .bottom, spacing: 8) {
                if !isFromMe {
                    Circle()
                        .fill(Color.dinkrGreen.opacity(0.18))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text(initial)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.dinkrGreen)
                        )
                }

                bubbleContent
                    .frame(maxWidth: 280, alignment: isFromMe ? .trailing : .leading)
                    .contentShape(Rectangle())
                    .onLongPressGesture { onLongPress() }
            }
            .frame(maxWidth: .infinity, alignment: isFromMe ? .trailing : .leading)

            // Reaction badge
            if let reaction = message.reaction {
                Text(reaction)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cardBackground)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                    .padding(.leading, isFromMe ? 0 : 38)
            }

            // Read receipt for sent messages
            if isFromMe {
                HStack(spacing: 2) {
                    Image(systemName: message.isRead ? "checkmark" : "checkmark")
                        .font(.system(size: 9, weight: .bold))
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .offset(x: -5)
                }
                .foregroundStyle(message.isRead ? Color.dinkrSky : Color.secondary)
                .padding(.trailing, 2)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var bubbleContent: some View {
        switch message.bubbleType {
        case .text:
            Text(message.text)
                .font(.subheadline)
                .foregroundStyle(isFromMe ? Color.white : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isFromMe ? Color.dinkrGreen : Color.cardBackground)
                .clipShape(DMBubbleShape(isFromMe: isFromMe))

        case let .gameInvite(courtName, date, format):
            GameInviteCard(
                courtName: courtName,
                date: date,
                format: format,
                isFromMe: isFromMe,
                state: inviteState,
                onAccept: onAcceptInvite,
                onDecline: onDeclineInvite
            )
        }
    }
}

// MARK: - GameInviteCard

private struct GameInviteCard: View {
    let courtName: String
    let date: Date
    let format: String
    let isFromMe: Bool
    let state: DirectMessageView.InviteResponse?
    let onAccept: () -> Void
    let onDecline: () -> Void

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "E, MMM d • h:mm a"
        return f.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header strip
            HStack(spacing: 8) {
                Image(systemName: "sportscourt.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                Text("Game Invite")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.dinkrGreen)

            // Body
            VStack(alignment: .leading, spacing: 6) {
                Text(courtName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                    Text(dateString)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                    Text(format)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }

                if let state = state {
                    // Already responded
                    HStack(spacing: 6) {
                        Image(systemName: state == .accepted ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(state == .accepted ? Color.dinkrGreen : Color.dinkrCoral)
                        Text(state == .accepted ? "You accepted" : "You declined")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(state == .accepted ? Color.dinkrGreen : Color.dinkrCoral)
                    }
                    .padding(.top, 2)
                } else if !isFromMe {
                    // Show accept/decline for received invites only
                    HStack(spacing: 8) {
                        Button(action: onDecline) {
                            Text("Decline")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.dinkrCoral)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .background(Color.dinkrCoral.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        Button(action: onAccept) {
                            Text("Accept")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .background(Color.dinkrGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.top, 4)
                } else {
                    // Invite sent by me — show waiting state
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                        Text("Waiting for response")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(12)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.dinkrGreen.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

// MARK: - TimestampDivider

private struct TimestampDivider: View {
    let date: Date

    private var label: String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            return date.timeString
        } else if cal.isDateInYesterday(date) {
            return "Yesterday \(date.timeString)"
        } else {
            return date.dateTimeString
        }
    }

    var body: some View {
        Text(label)
            .font(.caption2)
            .foregroundStyle(Color.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.08))
            .clipShape(Capsule())
            .frame(maxWidth: .infinity)
    }
}

// MARK: - DMBubbleShape

private struct DMBubbleShape: Shape {
    let isFromMe: Bool
    private let radius: CGFloat = 18
    private let tail: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(radius, rect.height / 2)

        if isFromMe {
            path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
                        radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - tail))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - tail, y: rect.maxY),
                              control: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
                        radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
            path.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r),
                        radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        } else {
            path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
                        radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
            path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
                        radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX + tail, y: rect.maxY))
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - tail),
                              control: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
            path.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r),
                        radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - DMEmojiPickerRow

private struct DMEmojiPickerRow: View {
    let emojis: [String]
    let onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(emojis, id: \.self) { emoji in
                Button { onSelect(emoji) } label: {
                    Text(emoji)
                        .font(.title3)
                        .frame(width: 36, height: 36)
                        .background(Color.cardBackground)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.cardBackground)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview("Direct Message") {
    NavigationStack {
        DirectMessageView(
            conversationId: "conv_001",
            otherUserName: "Maria Chen",
            otherUserInitial: "M",
            isOnline: true
        )
    }
}

#Preview("Offline User") {
    NavigationStack {
        DirectMessageView(
            conversationId: "conv_002",
            otherUserName: "Jordan Smith",
            otherUserInitial: "J",
            isOnline: false
        )
    }
}

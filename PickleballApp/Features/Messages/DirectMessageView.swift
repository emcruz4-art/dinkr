import SwiftUI

// MARK: - DirectMessage Models

enum DMBubbleType {
    case text
    case gameInvite(courtName: String, date: Date, format: String)
    case locationShare(venueName: String, address: String)
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
                id: "\(conversationId)_loc",
                senderId: otherUserId,
                text: "Location",
                timestamp: ago(20),
                isRead: true,
                bubbleType: .locationShare(
                    venueName: "Westside Pickleball Complex",
                    address: "4201 W Parmer Ln, Austin TX"
                )
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
    @State private var isTyping: Bool = false
    @State private var showAttachmentMenu: Bool = false
    @State private var showGameInviteSheet: Bool = false
    @State private var typingSimTimer: Timer? = nil

    private let quickReplies = ["Want to play?", "Great game!", "Count me in 🏓", "Can't make it"]
    private let emojis = ["❤️", "😂", "🏓", "🔥", "👍", "😤"]

    enum InviteResponse { case accepted, declined }

    // The last message sent by me — used for read receipt
    private var lastSentMessage: DirectMessage? {
        messages.last(where: { $0.senderId == "me" })
    }

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
            // Simulate other user typing after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { isTyping = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    withAnimation { isTyping = false }
                }
            }
        }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 0) }
        .sheet(isPresented: $showGameInviteSheet) {
            GameInviteComposeSheet { courtName, date, format in
                let invite = DirectMessage(
                    id: UUID().uuidString,
                    senderId: "me",
                    text: "Game Invite",
                    timestamp: Date(),
                    isRead: false,
                    bubbleType: .gameInvite(courtName: courtName, date: date, format: format)
                )
                withAnimation { messages.append(invite) }
            }
        }
        .confirmationDialog("Add Attachment", isPresented: $showAttachmentMenu, titleVisibility: .visible) {
            Button("Photo") { }
            Button("Game Invite") { showGameInviteSheet = true }
            Button("Share Location") { sendLocationMessage() }
            Button("GIF") { }
            Button("Cancel", role: .cancel) { }
        }
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
                            isLastSent: message.id == lastSentMessage?.id,
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
                            },
                            onAvatarTap: { }   // Profile navigation placeholder
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

                    // Typing indicator
                    if isTyping {
                        TypingIndicator(initial: otherUserInitial)
                            .id("typing")
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .padding(.leading, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
            .onChange(of: isTyping) { _, typing in
                if typing {
                    withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                }
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
            // Attachment (+) button
            Button {
                showAttachmentMenu = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.dinkrGreen)
                }
            }

            TextField("Message \(otherUserName)...", text: $inputText, axis: .vertical)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .lineLimit(1...5)
                .onChange(of: inputText) { _, newVal in
                    // Simulate typing indicator feedback
                    isTyping = !newVal.isEmpty
                    typingSimTimer?.invalidate()
                    if !newVal.isEmpty {
                        typingSimTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: false) { _ in
                            DispatchQueue.main.async { isTyping = false }
                        }
                    }
                }

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
            Button {
                // Navigate to profile — placeholder
            } label: {
                VStack(spacing: 1) {
                    HStack(spacing: 6) {
                        Text(otherUserName)
                            .font(.headline)
                            .foregroundStyle(Color.primary)
                        if isOnline {
                            Circle()
                                .fill(Color.dinkrGreen)
                                .frame(width: 8, height: 8)
                        }
                    }
                    Text(isOnline ? "Online now" : "Last seen recently")
                        .font(.caption2)
                        .foregroundStyle(isOnline ? Color.dinkrGreen : Color.secondary)
                }
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
        isTyping = false
        showEmojiPicker = nil
        let msg = DirectMessage(
            id: UUID().uuidString,
            senderId: "me",
            text: trimmed,
            timestamp: Date(),
            isRead: false
        )
        withAnimation { messages.append(msg) }

        // Simulate read receipt after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if let idx = messages.firstIndex(where: { $0.id == msg.id }) {
                messages[idx].isRead = true
            }
        }
    }

    private func sendLocationMessage() {
        let msg = DirectMessage(
            id: UUID().uuidString,
            senderId: "me",
            text: "Location",
            timestamp: Date(),
            isRead: false,
            bubbleType: .locationShare(
                venueName: "Westside Pickleball Complex",
                address: "4201 W Parmer Ln, Austin TX"
            )
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

// MARK: - TypingIndicator

private struct TypingIndicator: View {
    let initial: String
    @State private var animPhase: Int = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Circle()
                .fill(Color.dinkrGreen.opacity(0.18))
                .frame(width: 30, height: 30)
                .overlay(
                    Text(initial)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.dinkrGreen)
                )

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.secondary.opacity(0.6))
                        .frame(width: 7, height: 7)
                        .scaleEffect(animPhase == i ? 1.4 : 1.0)
                        .offset(y: animPhase == i ? -3 : 0)
                        .animation(
                            .easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15),
                            value: animPhase
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.cardBackground)
            .clipShape(DMBubbleShape(isFromMe: false))
        }
        .padding(.vertical, 4)
        .onAppear {
            withAnimation { animPhase = 2 }
            // Cycle the phase to keep all dots bouncing
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { t in
                withAnimation { animPhase = (animPhase + 1) % 3 }
            }
        }
    }
}

// MARK: - DMBubbleRow

struct DMBubbleRow: View {
    let message: DirectMessage
    let isFromMe: Bool
    let initial: String
    let inviteState: DirectMessageView.InviteResponse?
    let isLastSent: Bool
    let onLongPress: () -> Void
    let onAcceptInvite: () -> Void
    let onDeclineInvite: () -> Void
    let onAvatarTap: () -> Void

    var body: some View {
        VStack(alignment: isFromMe ? .trailing : .leading, spacing: 2) {
            HStack(alignment: .bottom, spacing: 8) {
                if !isFromMe {
                    Button(action: onAvatarTap) {
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
                    .padding(.trailing, isFromMe ? 4 : 0)
            }

            // Read receipt for last sent message
            if isFromMe && isLastSent {
                HStack(spacing: 2) {
                    if message.isRead {
                        Text("Read \(message.timestamp.timeString)")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.dinkrSky)
                    } else {
                        HStack(spacing: -4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(Color.secondary)
                    }
                }
                .padding(.trailing, 4)
                .transition(.opacity)
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

        case let .locationShare(venueName, address):
            LocationShareCard(venueName: venueName, address: address, isFromMe: isFromMe)
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
                    HStack(spacing: 6) {
                        Image(systemName: state == .accepted ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(state == .accepted ? Color.dinkrGreen : Color.dinkrCoral)
                        Text(state == .accepted ? "You accepted" : "You declined")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(state == .accepted ? Color.dinkrGreen : Color.dinkrCoral)
                    }
                    .padding(.top, 2)
                } else if !isFromMe {
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
        .frame(maxWidth: 260)
    }
}

// MARK: - LocationShareCard

private struct LocationShareCard: View {
    let venueName: String
    let address: String
    let isFromMe: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Map placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 0)
                    .fill(
                        LinearGradient(
                            colors: [Color.dinkrSky.opacity(0.3), Color.dinkrNavy.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 80)
                VStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.dinkrCoral)
                    Text("Map")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(venueName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
                Text(address)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)

                Button { } label: {
                    Text("Open in Maps")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrSky)
                }
                .padding(.top, 2)
            }
            .padding(10)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.dinkrSky.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        .frame(maxWidth: 240)
    }
}

// MARK: - GameInviteComposeSheet

private struct GameInviteComposeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSend: (String, Date, String) -> Void

    @State private var courtName: String = "Zilker Park Courts"
    @State private var selectedDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var format: String = "Doubles • 4.0+"

    private let formats = ["Doubles • 4.0+", "Singles • Open", "Mixed Doubles • 3.5+", "Casual • All levels"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Court") {
                    TextField("Court name", text: $courtName)
                }
                Section("Date & Time") {
                    DatePicker("When", selection: $selectedDate, in: Date()...)
                }
                Section("Format") {
                    Picker("Format", selection: $format) {
                        ForEach(formats, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Send Game Invite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Send") {
                        onSend(courtName, selectedDate, format)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.dinkrGreen)
                    .disabled(courtName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
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

struct DMBubbleShape: Shape {
    let isFromMe: Bool
    private let radius: CGFloat = 18
    private let tail: CGFloat = 7

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(radius, rect.height / 2)

        if isFromMe {
            // Top-left round
            path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
            // Top-right round
            path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
                        radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            // Right side down to tail
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - tail - 2))
            // Tail curve (pointy, concave for natural look)
            path.addCurve(
                to: CGPoint(x: rect.maxX - tail, y: rect.maxY),
                control1: CGPoint(x: rect.maxX, y: rect.maxY - 1),
                control2: CGPoint(x: rect.maxX - tail + 2, y: rect.maxY)
            )
            // Bottom-left round
            path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
                        radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            // Left side up
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
            path.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r),
                        radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        } else {
            // Leading (left) tail
            path.move(to: CGPoint(x: rect.minX + tail, y: rect.minY))
            // Top-right round
            path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
                        radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            // Bottom-right round
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
            path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
                        radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            // Bottom-left: tail
            path.addLine(to: CGPoint(x: rect.minX + tail, y: rect.maxY))
            path.addCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - tail - 2),
                control1: CGPoint(x: rect.minX + tail - 2, y: rect.maxY),
                control2: CGPoint(x: rect.minX, y: rect.maxY - 1)
            )
            // Left side up to top-left arc
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
                        .frame(width: 38, height: 38)
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

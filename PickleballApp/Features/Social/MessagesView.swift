import SwiftUI

// MARK: - MessagesView

struct MessagesView: View {
    @State private var searchText = ""
    @State private var conversations: [DMConversation] = DMConversation.mockConversations
    @State private var showNewMessage = false

    var filteredConversations: [DMConversation] {
        if searchText.isEmpty { return conversations }
        return conversations.filter {
            $0.otherUserName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var onlinePlayers: [DMConversation] {
        conversations.filter { $0.isOnline }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.secondary)
                    TextField("Search messages", text: $searchText)
                        .autocorrectionDisabled()
                }
                .padding(10)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // Online now strip
                if !onlinePlayers.isEmpty && searchText.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Online Now")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.secondary)
                            .padding(.horizontal, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(onlinePlayers) { player in
                                    NavigationLink(destination: DMChatView(conversation: player)) {
                                        OnlineAvatarPill(conversation: player)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 4)
                        }
                    }
                    .padding(.bottom, 4)

                    Divider()
                }

                // Conversation list
                List {
                    ForEach(filteredConversations) { conversation in
                        NavigationLink(destination: DMChatView(conversation: conversation)) {
                            ConversationRow(conversation: conversation)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteConversation(conversation)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(Color.dinkrCoral)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                archiveConversation(conversation)
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                            .tint(Color.dinkrSky)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewMessage = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.dinkrGreen)
                    }
                }
            }
            .sheet(isPresented: $showNewMessage) {
                NewMessageSheet { selected in
                    showNewMessage = false
                }
            }
        }
    }

    private func deleteConversation(_ conversation: DMConversation) {
        withAnimation {
            conversations.removeAll { $0.id == conversation.id }
        }
    }

    private func archiveConversation(_ conversation: DMConversation) {
        withAnimation {
            conversations.removeAll { $0.id == conversation.id }
        }
    }
}

// MARK: - OnlineAvatarPill

private struct OnlineAvatarPill: View {
    let conversation: DMConversation

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.18))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(conversation.otherUserInitial)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.dinkrGreen)
                    )

                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.appBackground, lineWidth: 2))
            }

            Text(conversation.otherUserName.components(separatedBy: " ").first ?? "")
                .font(.caption2)
                .foregroundStyle(Color.primary)
                .lineLimit(1)
        }
        .frame(width: 56)
    }
}

// MARK: - ConversationRow

private struct ConversationRow: View {
    let conversation: DMConversation

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.18))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Text(conversation.otherUserInitial)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.dinkrGreen)
                    )

                if conversation.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 13, height: 13)
                        .overlay(Circle().stroke(Color.appBackground, lineWidth: 2))
                }
            }

            // Text content
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(conversation.otherUserName)
                        .font(.subheadline)
                        .fontWeight(conversation.unreadCount > 0 ? .bold : .regular)
                        .foregroundStyle(Color.primary)

                    Spacer()

                    Text(relativeTime(from: conversation.lastMessageTime))
                        .font(.caption2)
                        .foregroundStyle(conversation.unreadCount > 0 ? Color.dinkrGreen : Color.secondary)
                }

                HStack(alignment: .center) {
                    Text(conversation.lastMessage)
                        .font(.subheadline)
                        .foregroundStyle(conversation.unreadCount > 0 ? Color.primary : Color.secondary)
                        .lineLimit(1)
                        .fontWeight(conversation.unreadCount > 0 ? .medium : .regular)

                    Spacer()

                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.dinkrGreen)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func relativeTime(from date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        if diff < 60 { return "now" }
        if diff < 3600 { return "\(Int(diff / 60))m" }
        if diff < 86400 { return "\(Int(diff / 3600))h" }
        let days = Int(diff / 86400)
        if days == 1 { return "Yesterday" }
        return "\(days)d"
    }
}

// MARK: - DMChatView

struct DMChatView: View {
    let conversation: DMConversation

    @State private var messages: [DMMessage] = []
    @State private var inputText = ""
    @State private var showEmojiPicker: String? = nil  // message id
    @State private var scrollProxy: ScrollViewProxy? = nil

    private let emojis = ["❤️", "🔥", "😂", "👏", "🎯", "🏓"]
    private let quickReplies = ["Want to play?", "Great game!", "Count me in 🏓", "Can't make it"]

    var body: some View {
        VStack(spacing: 0) {
            // Message scroll area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                            SwiftUI.Group {
                                // Centered timestamp every 4 messages
                                if index % 4 == 0 {
                                    Text(timestampLabel(message.timestamp))
                                        .font(.caption2)
                                        .foregroundStyle(Color.secondary)
                                        .padding(.vertical, 6)
                                        .frame(maxWidth: .infinity)
                                }

                                MessageBubbleView(
                                    message: message,
                                    isFromMe: message.senderId == "me",
                                    initial: conversation.otherUserInitial,
                                    onLongPress: {
                                        withAnimation(.spring(response: 0.3)) {
                                            showEmojiPicker = showEmojiPicker == message.id ? nil : message.id
                                        }
                                    }
                                )
                                .id(message.id)

                                // Emoji picker overlay
                                if showEmojiPicker == message.id {
                                    EmojiPickerRow(emojis: emojis) { emoji in
                                        applyReaction(emoji, to: message.id)
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                    .padding(.horizontal, message.senderId == "me" ? 0 : 60)
                                    .frame(maxWidth: .infinity,
                                           alignment: message.senderId == "me" ? .trailing : .leading)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .onAppear {
                    messages = DMMessage.mockMessages(for: conversation.id)
                    scrollProxy = proxy
                    scrollToBottom(proxy: proxy, animated: false)
                }
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom(proxy: proxy, animated: true)
                }
                .onTapGesture {
                    showEmojiPicker = nil
                }
            }

            Divider()

            // Quick reply chips
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

            // Input bar
            HStack(spacing: 10) {
                TextField("Message \(conversation.otherUserName)...", text: $inputText, axis: .vertical)
                    .padding(10)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .lineLimit(1...4)

                Button {
                    guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    sendMessage(inputText)
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
        .navigationTitle(conversation.otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(conversation.otherUserName)
                        .font(.headline)
                    Text(conversation.isOnline ? "Online now" : "Last seen 2h ago")
                        .font(.caption2)
                        .foregroundStyle(conversation.isOnline ? Color.green : Color.secondary)
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                } label: {
                    Image(systemName: "phone")
                        .foregroundStyle(Color.dinkrGreen)
                }
                Button {
                } label: {
                    Image(systemName: "video.fill")
                        .foregroundStyle(Color.dinkrGreen)
                }
                Button {
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
    }

    // MARK: Helpers

    private func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newMsg = DMMessage(
            id: UUID().uuidString,
            conversationId: conversation.id,
            senderId: "me",
            text: trimmed,
            timestamp: Date(),
            isRead: false,
            reaction: nil
        )
        withAnimation {
            messages.append(newMsg)
        }
        inputText = ""
        showEmojiPicker = nil
    }

    private func applyReaction(_ emoji: String, to messageId: String) {
        if let idx = messages.firstIndex(where: { $0.id == messageId }) {
            messages[idx].reaction = messages[idx].reaction == emoji ? nil : emoji
        }
        withAnimation {
            showEmojiPicker = nil
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        guard let last = messages.last else { return }
        if animated {
            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
        } else {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }

    private func timestampLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            formatter.timeStyle = .short
            formatter.dateStyle = .none
        } else if cal.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
        }
        return formatter.string(from: date)
    }
}

// MARK: - MessageBubbleView

private struct MessageBubbleView: View {
    let message: DMMessage
    let isFromMe: Bool
    let initial: String
    let onLongPress: () -> Void

    var body: some View {
        VStack(alignment: isFromMe ? .trailing : .leading, spacing: 2) {
            HStack(alignment: .bottom, spacing: 8) {
                if !isFromMe {
                    // Avatar for other person
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

                Text(message.text)
                    .font(.subheadline)
                    .foregroundStyle(isFromMe ? Color.white : Color.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isFromMe ? Color.dinkrGreen : Color.cardBackground)
                    .clipShape(BubbleShape(isFromMe: isFromMe))
                    .frame(maxWidth: 280, alignment: isFromMe ? .trailing : .leading)
                    .contentShape(Rectangle())
                    .onLongPressGesture {
                        onLongPress()
                    }

                if isFromMe {
                    Spacer().frame(width: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: isFromMe ? .trailing : .leading)

            // Emoji reaction badge
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
        }
        .padding(.vertical, 2)
    }
}

// MARK: - BubbleShape

private struct BubbleShape: Shape {
    let isFromMe: Bool
    private let radius: CGFloat = 18
    private let tail: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(radius, rect.height / 2)

        if isFromMe {
            // Rounded rect with small notch bottom-right
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
            // Rounded rect with small notch bottom-left
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

// MARK: - EmojiPickerRow

private struct EmojiPickerRow: View {
    let emojis: [String]
    let onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(emojis, id: \.self) { emoji in
                Button {
                    onSelect(emoji)
                } label: {
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

// MARK: - NewMessageSheet

struct NewMessageSheet: View {
    let onSelect: (DMConversation) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var navigateToChat: DMConversation? = nil

    private var allPlayers: [User] { User.mockPlayers }

    private var filteredPlayers: [User] {
        if searchText.isEmpty { return allPlayers }
        return allPlayers.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
            || $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredPlayers) { player in
                    Button {
                        let conv = conversationFor(player: player)
                        onSelect(conv)
                        navigateToChat = conv
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.dinkrGreen.opacity(0.18))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text(String(player.displayName.prefix(1)))
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.dinkrGreen)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(player.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.primary)

                                HStack(spacing: 4) {
                                    Text("@\(player.username)")
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)

                                    Text("·")
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)

                                    Text(player.skillLevel.label)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.dinkrGreen)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search players")
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
            .navigationDestination(item: $navigateToChat) { conv in
                DMChatView(conversation: conv)
            }
        }
    }

    private func conversationFor(player: User) -> DMConversation {
        // Return existing conversation if one exists, otherwise create a stub
        if let existing = DMConversation.mockConversations.first(where: { $0.otherUserId == player.id }) {
            return existing
        }
        return DMConversation(
            id: "new_\(player.id)",
            otherUserId: player.id,
            otherUserName: player.displayName,
            otherUserInitial: String(player.displayName.prefix(1)),
            lastMessage: "",
            lastMessageTime: Date(),
            unreadCount: 0,
            isOnline: false
        )
    }
}

// MARK: - Preview

#Preview("Messages") {
    MessagesView()
}

#Preview("Chat") {
    NavigationStack {
        DMChatView(conversation: DMConversation.mockConversations[0])
    }
}

#Preview("New Message") {
    NewMessageSheet { _ in }
}

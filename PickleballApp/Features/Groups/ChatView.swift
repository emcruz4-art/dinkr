import SwiftUI

struct ChatView: View {
    let threadId: String
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { message in
                            MessageBubble(message: message, isFromCurrentUser: message.senderId == "user_001")
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            Divider()

            HStack(spacing: 12) {
                TextField("Message...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(4)
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(inputText.isEmpty ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.pickleballGreen))
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .onAppear { loadMessages() }
    }

    private func loadMessages() {
        // Mock messages for preview
        messages = [
            ChatMessage(id: "m1", senderId: "user_002", senderName: "Maria Chen",
                        content: "Hey everyone! Who's playing Thursday?", type: .text,
                        sentAt: Date().addingTimeInterval(-7200), isRead: true, mediaURL: nil),
            ChatMessage(id: "m2", senderId: "user_001", senderName: "Alex Rivera",
                        content: "I'm in! What time?", type: .text,
                        sentAt: Date().addingTimeInterval(-3600), isRead: true, mediaURL: nil),
            ChatMessage(id: "m3", senderId: "user_003", senderName: "Jordan Smith",
                        content: "Courts open at 6:30 tomorrow", type: .text,
                        sentAt: Date().addingTimeInterval(-1800), isRead: true, mediaURL: nil),
        ]
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let msg = ChatMessage(id: UUID().uuidString, senderId: "user_001", senderName: "Alex Rivera",
                               content: text, type: .text, sentAt: Date(), isRead: true, mediaURL: nil)
        messages.append(msg)
        inputText = ""
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 60) }
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                if !isFromCurrentUser {
                    Text(message.senderName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
                Text(message.content)
                    .font(.subheadline)
                    .foregroundStyle(isFromCurrentUser ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isFromCurrentUser ? Color.pickleballGreen : Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                Text(message.sentAt.timeString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
    }
}

#Preview {
    ChatView(threadId: "chat_001")
}

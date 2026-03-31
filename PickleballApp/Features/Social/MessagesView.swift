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
                                    NavigationLink {
                                        DirectMessageView(
                                            conversationId: player.id,
                                            otherUserName: player.otherUserName,
                                            otherUserInitial: player.otherUserInitial,
                                            isOnline: player.isOnline
                                        )
                                    } label: {
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
                        NavigationLink {
                            DirectMessageView(
                                conversationId: conversation.id,
                                otherUserName: conversation.otherUserName,
                                otherUserInitial: conversation.otherUserInitial,
                                isOnline: conversation.isOnline
                            )
                        } label: {
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
                NewMessageComposerSheet { selected in
                    // Add or navigate to conversation
                    if !conversations.contains(where: { $0.id == selected.id }) {
                        conversations.insert(selected, at: 0)
                    }
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
            // Avatar with optional online dot
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
                        .foregroundStyle(
                            conversation.unreadCount > 0 ? Color.dinkrGreen : Color.secondary
                        )
                }

                HStack(alignment: .center) {
                    Text(conversation.lastMessage)
                        .font(.subheadline)
                        .foregroundStyle(
                            conversation.unreadCount > 0 ? Color.primary : Color.secondary
                        )
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

// MARK: - NewMessageComposerSheet

struct NewMessageComposerSheet: View {
    let onSelect: (DMConversation) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var navigateToConv: DMConversation? = nil

    private var allPlayers: [(name: String, initial: String, id: String)] {
        [
            ("Alex Rivera", "A", "user_010"),
            ("Casey Thompson", "C", "user_011"),
            ("Taylor Kim", "T", "user_012"),
            ("Morgan Davis", "M", "user_013"),
            ("Drew Patel", "D", "user_014"),
        ]
    }

    private var filtered: [(name: String, initial: String, id: String)] {
        if searchText.isEmpty { return allPlayers }
        return allPlayers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered, id: \.id) { player in
                    Button {
                        let conv = DMConversation(
                            id: "conv_\(player.id)",
                            otherUserId: player.id,
                            otherUserName: player.name,
                            otherUserInitial: player.initial,
                            lastMessage: "",
                            lastMessageTime: Date(),
                            unreadCount: 0,
                            isOnline: false
                        )
                        navigateToConv = conv
                        onSelect(conv)
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.dinkrGreen.opacity(0.18))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text(player.initial)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.dinkrGreen)
                                )

                            Text(player.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.primary)

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
            .navigationDestination(item: $navigateToConv) { conv in
                DirectMessageView(
                    conversationId: conv.id,
                    otherUserName: conv.otherUserName,
                    otherUserInitial: conv.otherUserInitial,
                    isOnline: conv.isOnline
                )
            }
        }
    }
}

// MARK: - Preview

#Preview("Messages") {
    MessagesView()
}

#Preview("New Message Composer") {
    NewMessageComposerSheet { _ in }
}

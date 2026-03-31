import SwiftUI

// MARK: - Filter Tab

enum MessageFilter: String, CaseIterable {
    case all      = "All"
    case unread   = "Unread"
    case groups   = "Groups"
    case game     = "Game Threads"
}

// MARK: - Extended Conversation Model (view-layer)

struct ConversationRow: Identifiable {
    var id: String
    var name: String
    var initial: String
    var lastMessage: String
    var lastMessageTime: Date
    var unreadCount: Int
    var isOnline: Bool
    var isGroup: Bool
    var isGameThread: Bool
    var isMuted: Bool
    var isArchived: Bool

    // Map from DMConversation
    init(from conv: DMConversation) {
        id           = conv.id
        name         = conv.otherUserName
        initial      = conv.otherUserInitial
        lastMessage  = conv.lastMessage
        lastMessageTime = conv.lastMessageTime
        unreadCount  = conv.unreadCount
        isOnline     = conv.isOnline
        isGroup      = false
        isGameThread = false
        isMuted      = false
        isArchived   = false
    }
}

// MARK: - Mock Data Extension

private extension ConversationRow {
    static var mockRows: [ConversationRow] {
        let base = DMConversation.mockConversations.map { ConversationRow(from: $0) }

        // Stamp some as game threads or groups for demo
        var rows = base
        if rows.indices.contains(1) { rows[1].isGameThread = true }
        if rows.indices.contains(4) { rows[4].isGameThread = true }

        // Append two synthetic group rows
        rows.append(ConversationRow(
            id: "group_001",
            name: "Austin Dink Squad",
            initial: "A",
            lastMessage: "Court 4 is open — who's in?",
            lastMessageTime: Calendar.current.date(byAdding: .minute, value: -15, to: Date()) ?? Date(),
            unreadCount: 5,
            isOnline: false,
            isGroup: true,
            isGameThread: false,
            isMuted: false,
            isArchived: false
        ))
        rows.append(ConversationRow(
            id: "group_002",
            name: "Mueller Morning Crew",
            initial: "M",
            lastMessage: "See everyone at 7am!",
            lastMessageTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
            unreadCount: 0,
            isOnline: false,
            isGroup: true,
            isGameThread: false,
            isMuted: true,
            isArchived: false
        ))
        return rows
    }

    init(
        id: String,
        name: String,
        initial: String,
        lastMessage: String,
        lastMessageTime: Date,
        unreadCount: Int,
        isOnline: Bool,
        isGroup: Bool,
        isGameThread: Bool,
        isMuted: Bool,
        isArchived: Bool
    ) {
        self.id            = id
        self.name          = name
        self.initial       = initial
        self.lastMessage   = lastMessage
        self.lastMessageTime = lastMessageTime
        self.unreadCount   = unreadCount
        self.isOnline      = isOnline
        self.isGroup       = isGroup
        self.isGameThread  = isGameThread
        self.isMuted       = isMuted
        self.isArchived    = isArchived
    }
}

// MARK: - MessagesView

struct MessagesView: View {
    @State private var conversations: [ConversationRow] = ConversationRow.mockRows
    @State private var searchText: String = ""
    @State private var selectedFilter: MessageFilter = .all
    @State private var showNewMessage = false

    private var filtered: [ConversationRow] {
        var result = conversations.filter { !$0.isArchived }

        // Filter tab
        switch selectedFilter {
        case .all:
            break
        case .unread:
            result = result.filter { $0.unreadCount > 0 }
        case .groups:
            result = result.filter { $0.isGroup }
        case .game:
            result = result.filter { $0.isGameThread }
        }

        // Search
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            result = result.filter {
                $0.name.lowercased().contains(q) || $0.lastMessage.lowercased().contains(q)
            }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    filterTabBar
                    Divider()

                    if filtered.isEmpty {
                        emptyState
                    } else {
                        conversationList
                    }
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search conversations")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewMessage = true
                    } label: {
                        Image(systemName: "pencil.and.outline")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                }
            }
            .sheet(isPresented: $showNewMessage) {
                NewMessageView { newConv in
                    conversations.insert(newConv, at: 0)
                }
            }
        }
    }

    // MARK: - Filter Tab Bar

    private var filterTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MessageFilter.allCases, id: \.self) { filter in
                    MsgFilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Conversation List

    private var conversationList: some View {
        List {
            ForEach(filtered) { conv in
                NavigationLink {
                    DirectMessageView(
                        conversationId: conv.id,
                        otherUserName: conv.name,
                        otherUserInitial: conv.initial,
                        isOnline: conv.isOnline
                    )
                } label: {
                    ConversationRowView(conversation: conv)
                }
                .listRowBackground(conv.unreadCount > 0 ? Color.dinkrGreen.opacity(0.04) : Color.appBackground)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteConversation(id: conv.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        archiveConversation(id: conv.id)
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .tint(Color.dinkrAmber)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        toggleMute(id: conv.id)
                    } label: {
                        Label(
                            conv.isMuted ? "Unmute" : "Mute",
                            systemImage: conv.isMuted ? "bell" : "bell.slash"
                        )
                    }
                    .tint(Color.dinkrSky)
                }
            }
        }
        .listStyle(.plain)
        .animation(.default, value: filtered.map(\.id))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.1))
                    .frame(width: 96, height: 96)
                Text("🏓")
                    .font(.system(size: 44))
            }
            VStack(spacing: 6) {
                Text("No messages yet")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.primary)
                Text("Find players and start chatting! 🏓")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                showNewMessage = true
            } label: {
                Label("Start a Conversation", systemImage: "pencil.and.outline")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.dinkrGreen)
                    .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Actions

    private func deleteConversation(id: String) {
        withAnimation {
            conversations.removeAll { $0.id == id }
        }
    }

    private func archiveConversation(id: String) {
        withAnimation {
            if let idx = conversations.firstIndex(where: { $0.id == id }) {
                conversations[idx].isArchived = true
            }
        }
    }

    private func toggleMute(id: String) {
        if let idx = conversations.firstIndex(where: { $0.id == id }) {
            conversations[idx].isMuted.toggle()
        }
    }
}

// MARK: - FilterChip

private struct MsgFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : Color.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(isSelected ? Color.dinkrGreen : Color.cardBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
                )
        }
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

// MARK: - ConversationRowView

private struct ConversationRowView: View {
    let conversation: ConversationRow

    private var timeLabel: String {
        let now = Date()
        let interval = now.timeIntervalSince(conversation.lastMessageTime)
        if interval < 60 { return "now" }
        if interval < 3600 { return "\(Int(interval / 60))m" }
        if interval < 86400 { return "\(Int(interval / 3600))h" }
        if interval < 604800 { return "\(Int(interval / 86400))d" }
        return conversation.lastMessageTime.shortDateString
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Avatar + online dot
            avatarStack

            // Text block
            VStack(alignment: .leading, spacing: 3) {
                // Name row
                HStack(spacing: 6) {
                    Text(conversation.name)
                        .font(.subheadline.weight(conversation.unreadCount > 0 ? .bold : .regular))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)

                    if conversation.isMuted {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.secondary)
                    }

                    Spacer()

                    Text(timeLabel)
                        .font(.caption2)
                        .foregroundStyle(
                            conversation.unreadCount > 0 ? Color.dinkrGreen : Color.secondary
                        )
                }

                // Preview + badge row
                HStack(spacing: 6) {
                    // Game thread chip
                    if conversation.isGameThread {
                        HStack(spacing: 3) {
                            Image(systemName: "sportscourt.fill")
                                .font(.system(size: 9, weight: .semibold))
                            Text("Game")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(Color.dinkrCoral)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.dinkrCoral.opacity(0.1))
                        .clipShape(Capsule())
                    }

                    // DinkrGroup chip
                    if conversation.isGroup {
                        HStack(spacing: 3) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 9, weight: .semibold))
                            Text("DinkrGroup")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(Color.dinkrSky)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.dinkrSky.opacity(0.1))
                        .clipShape(Capsule())
                    }

                    Text(conversation.lastMessage)
                        .font(.caption)
                        .foregroundStyle(
                            conversation.unreadCount > 0 ? Color.primary.opacity(0.75) : Color.secondary
                        )
                        .fontWeight(conversation.unreadCount > 0 ? .medium : .regular)
                        .lineLimit(1)

                    Spacer()

                    // Unread badge
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .padding(.horizontal, 5)
                            .background(conversation.isMuted ? Color.secondary : Color.dinkrGreen)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    // MARK: - Avatar Stack

    private var avatarStack: some View {
        ZStack(alignment: .bottomTrailing) {
            if conversation.isGroup {
                // DinkrGroup avatar: overlapping initials
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.dinkrNavy, Color.dinkrSky],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                }
            } else {
                AvatarView(displayName: conversation.name, size: 50)
            }

            if conversation.isOnline && !conversation.isGroup {
                ZStack {
                    Circle()
                        .fill(Color.appBackground)
                        .frame(width: 15, height: 15)
                    Circle()
                        .fill(Color.dinkrGreen)
                        .frame(width: 11, height: 11)
                }
                .offset(x: 2, y: 2)
            }
        }
    }
}

// MARK: - Preview

#Preview("Messages") {
    MessagesView()
}

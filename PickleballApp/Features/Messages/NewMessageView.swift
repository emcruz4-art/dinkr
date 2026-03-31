import SwiftUI

// MARK: - NewMessageView

struct NewMessageView: View {
    @Environment(\.dismiss) private var dismiss
    let onStartConversation: (ConversationRow) -> Void

    @State private var searchText: String = ""
    @State private var selectedUsers: [MockPlayer] = []
    @State private var groupName: String = ""
    @State private var showGroupNameField: Bool = false

    private var isGroupMode: Bool { selectedUsers.count > 1 }

    private var filteredPlayers: [MockPlayer] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return MockPlayer.all }
        return MockPlayer.all.filter {
            $0.name.lowercased().contains(q) || $0.username.lowercased().contains(q)
        }
    }

    private var recentContacts: [MockPlayer] {
        Array(MockPlayer.all.prefix(4))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Selected recipients chips
                    if !selectedUsers.isEmpty {
                        recipientChips
                    }

                    Divider()

                    // DinkrGroup name field (appears when 2+ selected)
                    if showGroupNameField {
                        groupNameField
                        Divider()
                    }

                    List {
                        // Start DinkrGroup Chat option
                        Section {
                            startGroupChatRow
                        }

                        // Recent contacts
                        if searchText.isEmpty {
                            Section("Recent") {
                                ForEach(recentContacts) { player in
                                    PlayerSelectionRow(
                                        player: player,
                                        isSelected: selectedUsers.contains(where: { $0.id == player.id })
                                    ) {
                                        toggleSelection(player)
                                    }
                                }
                            }
                        }

                        // Search results or all players
                        Section(searchText.isEmpty ? "Suggested Players" : "Results") {
                            if filteredPlayers.isEmpty {
                                Text("No players found for \"\(searchText)\"")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                                    .listRowBackground(Color.appBackground)
                            } else {
                                ForEach(filteredPlayers) { player in
                                    PlayerSelectionRow(
                                        player: player,
                                        isSelected: selectedUsers.contains(where: { $0.id == player.id })
                                    ) {
                                        toggleSelection(player)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchText, prompt: "Search players by name or @username")
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Start") {
                        startConversation()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(selectedUsers.isEmpty ? Color.secondary : Color.dinkrGreen)
                    .disabled(selectedUsers.isEmpty)
                }
            }
        }
    }

    // MARK: - Recipient Chips

    private var recipientChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(selectedUsers) { player in
                    HStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color.dinkrGreen)
                                .frame(width: 26, height: 26)
                            Text(String(player.name.prefix(1)))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        Text(player.name.components(separatedBy: " ").first ?? player.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.primary)
                        Button {
                            withAnimation(.spring(response: 0.25)) {
                                selectedUsers.removeAll { $0.id == player.id }
                                if selectedUsers.count < 2 { showGroupNameField = false }
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.cardBackground)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.dinkrGreen.opacity(0.3), lineWidth: 1))
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.appBackground)
    }

    // MARK: - DinkrGroup Name Field

    private var groupNameField: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.3.fill")
                .foregroundStyle(Color.dinkrSky)
            TextField("DinkrGroup name (optional)", text: $groupName)
                .font(.subheadline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appBackground)
    }

    // MARK: - Start DinkrGroup Chat Row

    private var startGroupChatRow: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                showGroupNameField.toggle()
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.dinkrNavy, Color.dinkrSky],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Start DinkrGroup Chat")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                    Text("Select 2 or more players")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    // MARK: - Actions

    private func toggleSelection(_ player: MockPlayer) {
        withAnimation(.spring(response: 0.25)) {
            if let idx = selectedUsers.firstIndex(where: { $0.id == player.id }) {
                selectedUsers.remove(at: idx)
                if selectedUsers.count < 2 { showGroupNameField = false }
            } else {
                selectedUsers.append(player)
                if selectedUsers.count >= 2 { showGroupNameField = true }
            }
        }
    }

    private func startConversation() {
        guard let first = selectedUsers.first else { return }

        let isGroup = selectedUsers.count > 1
        let name = isGroup
            ? (groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
               ? selectedUsers.map { $0.name.components(separatedBy: " ").first ?? $0.name }.joined(separator: ", ")
               : groupName)
            : first.name

        let dmConv = DMConversation(
            id: UUID().uuidString,
            otherUserId: first.id,
            otherUserName: name,
            otherUserInitial: String(name.prefix(1)),
            lastMessage: "",
            lastMessageTime: Date(),
            unreadCount: 0,
            isOnline: first.isOnline
        )
        let conv = ConversationRow(from: dmConv)
        onStartConversation(conv)
        dismiss()
    }
}

// MARK: - PlayerSelectionRow

private struct PlayerSelectionRow: View {
    let player: MockPlayer
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.dinkrGreen, Color.dinkrSky],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(String(player.name.prefix(1)))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                        )

                    if player.isOnline {
                        ZStack {
                            Circle().fill(Color.appBackground).frame(width: 13, height: 13)
                            Circle().fill(Color.dinkrGreen).frame(width: 9, height: 9)
                        }
                        .offset(x: 1, y: 1)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.primary)
                    HStack(spacing: 6) {
                        Text("@\(player.username)")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                        Text(player.skillLevel)
                            .font(.caption)
                            .foregroundStyle(Color.dinkrAmber)
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.dinkrGreen : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(Color.dinkrGreen)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .animation(.spring(response: 0.25), value: isSelected)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - MockPlayer (view-local model)

struct MockPlayer: Identifiable {
    let id: String
    let name: String
    let username: String
    let skillLevel: String
    let isOnline: Bool

    static let all: [MockPlayer] = [
        MockPlayer(id: "user_002", name: "Maria Chen",    username: "mariachen",    skillLevel: "4.5", isOnline: true),
        MockPlayer(id: "user_003", name: "Jordan Smith",  username: "jordansmith",  skillLevel: "4.0", isOnline: true),
        MockPlayer(id: "user_004", name: "Sarah Johnson", username: "sarahjohnson", skillLevel: "3.5", isOnline: false),
        MockPlayer(id: "user_005", name: "Chris Park",    username: "chrispark",    skillLevel: "4.0", isOnline: true),
        MockPlayer(id: "user_006", name: "Alex Rivera",   username: "alexrivera",   skillLevel: "5.0", isOnline: false),
        MockPlayer(id: "user_007", name: "Jamie Lee",     username: "jamielee",     skillLevel: "4.5", isOnline: false),
        MockPlayer(id: "user_008", name: "Taylor Nguyen", username: "taylornguyen", skillLevel: "3.0", isOnline: true),
        MockPlayer(id: "user_009", name: "Riley Torres",  username: "rileytorres",  skillLevel: "4.0", isOnline: false),
        MockPlayer(id: "user_010", name: "Sam Patel",     username: "sampatel",     skillLevel: "3.5", isOnline: true),
        MockPlayer(id: "user_011", name: "Casey Wright",  username: "caseywright",  skillLevel: "4.5", isOnline: false),
    ]
}

// MARK: - Preview

#Preview("New Message") {
    NewMessageView { _ in }
}

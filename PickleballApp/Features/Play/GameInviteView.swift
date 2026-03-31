import SwiftUI

// MARK: - GameInviteView

struct GameInviteView: View {
    let session: GameSession

    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var invitedIds: Set<String> = []
    @State private var showSuccess = false

    // MARK: - Mock data

    private let allPlayers = User.mockPlayers

    // "Suggested": players whose skill level falls within the session's skill range (first 3)
    private var suggestedPlayers: [User] {
        Array(
            allPlayers.filter { session.skillRange.contains($0.skillLevel) }
                .prefix(3)
        )
    }

    // "Your Friends": everyone else
    private var friendPlayers: [User] {
        let suggestedIds = Set(suggestedPlayers.map(\.id))
        return allPlayers.filter { !suggestedIds.contains($0.id) }
    }

    private func filtered(_ list: [User]) -> [User] {
        guard !searchText.isEmpty else { return list }
        let q = searchText.lowercased()
        return list.filter {
            $0.displayName.lowercased().contains(q) ||
            $0.username.lowercased().contains(q)
        }
    }

    private var filteredSuggested: [User] { filtered(suggestedPlayers) }
    private var filteredFriends: [User]   { filtered(friendPlayers) }

    private var selectedPlayers: [User] {
        allPlayers.filter { invitedIds.contains($0.id) }
    }

    private var spotsLabel: String {
        let r = session.spotsRemaining
        return "\(r) spot\(r == 1 ? "" : "s") left"
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 0) {
                    gameMiniCard
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    if !selectedPlayers.isEmpty {
                        selectedStrip
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }

                    SearchBar(text: $searchText)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)

                    playerList

                    sendButton
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .padding(.top, 8)
                }
                .navigationTitle("Invite Players")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(Color.dinkrGreen)
                    }
                }
                .background(Color.appBackground.ignoresSafeArea())
            }

            if showSuccess {
                successOverlay
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Game Mini-Card

    private var gameMiniCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.courtName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(session.dateTime.formatted(.dateTime.weekday(.short).month(.abbreviated).day().hour().minute()))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("·")
                        .foregroundStyle(.secondary)
                        .font(.caption)

                    Text(session.format.rawValue.capitalized)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.dinkrNavy)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(session.skillRange.lowerBound.label + "–" + session.skillRange.upperBound.label)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.dinkrGreen, in: Capsule())

                Text(spotsLabel)
                    .font(.caption)
                    .foregroundStyle(session.isFull ? Color.dinkrCoral : .secondary)
            }
        }
        .padding(14)
        .cardStyle()
    }

    // MARK: - Selected Strip

    private var selectedStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(selectedPlayers) { player in
                    selectedAvatar(player)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }

    private func selectedAvatar(_ player: User) -> some View {
        ZStack(alignment: .topTrailing) {
            AvatarView(displayName: player.displayName, size: 44)

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    _ = invitedIds.remove(player.id)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.dinkrNavy)
                    .background(Circle().fill(Color.white))
            }
            .offset(x: 4, y: -4)
        }
    }

    // MARK: - Player List

    private var playerList: some View {
        List {
            if !filteredSuggested.isEmpty {
                Section {
                    ForEach(filteredSuggested) { player in
                        PlayerInviteRow(
                            player: player,
                            isInvited: invitedIds.contains(player.id)
                        ) {
                            toggleInvite(player.id)
                        }
                        .listRowBackground(Color.cardBackground)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                } header: {
                    Text("Suggested")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }

            if !filteredFriends.isEmpty {
                Section {
                    ForEach(filteredFriends) { player in
                        PlayerInviteRow(
                            player: player,
                            isInvited: invitedIds.contains(player.id)
                        ) {
                            toggleInvite(player.id)
                        }
                        .listRowBackground(Color.cardBackground)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                } header: {
                    Text("Your Friends")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }

            if filteredSuggested.isEmpty && filteredFriends.isEmpty {
                Section {
                    Text("No players match \"\(searchText)\"")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                        .listRowBackground(Color.cardBackground)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button {
            handleSend()
        } label: {
            HStack(spacing: 8) {
                if showSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                    Text("Invites Sent!")
                        .font(.subheadline.weight(.semibold))
                } else {
                    Text(invitedIds.isEmpty ? "Send Invites" : "Send \(invitedIds.count) Invite\(invitedIds.count == 1 ? "" : "s")")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(invitedIds.isEmpty ? Color.dinkrGreen.opacity(0.4) : Color.dinkrGreen)
            )
        }
        .disabled(invitedIds.isEmpty)
        .animation(.easeInOut(duration: 0.2), value: invitedIds.isEmpty)
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.dinkrGreen)

                Text("Invites Sent!")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)

                Text("\(invitedIds.count) player\(invitedIds.count == 1 ? "" : "s") invited to join \(session.courtName).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(32)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    // MARK: - Actions

    private func toggleInvite(_ id: String) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if invitedIds.contains(id) {
                invitedIds.remove(id)
            } else {
                invitedIds.insert(id)
            }
        }
    }

    private func handleSend() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            showSuccess = true
        }
        Task {
            try? await Task.sleep(for: .seconds(1))
            dismiss()
        }
    }
}

// MARK: - PlayerInviteRow

private struct PlayerInviteRow: View {
    let player: User
    let isInvited: Bool
    let onToggle: () -> Void

    // Mock mutual groups count based on overlapping clubIds with current user (user_001 clubs: ["club_001", "club_002"])
    private static let currentUserClubIds: Set<String> = ["club_001", "club_002"]
    private var mutualGroupsCount: Int {
        Set(player.clubIds).intersection(Self.currentUserClubIds).count
    }

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(displayName: player.displayName, size: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(player.displayName)
                    .font(.subheadline.weight(.semibold))

                HStack(spacing: 6) {
                    SkillBadge(level: player.skillLevel, compact: true)

                    if mutualGroupsCount > 0 {
                        Text("\(mutualGroupsCount) mutual group\(mutualGroupsCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Button(action: onToggle) {
                HStack(spacing: 4) {
                    if isInvited {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                        Text("Invited")
                            .font(.caption.weight(.semibold))
                    } else {
                        Text("Invite")
                            .font(.caption.weight(.semibold))
                    }
                }
                .foregroundStyle(isInvited ? Color.dinkrGreen : Color.dinkrGreen)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.dinkrGreen, lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(isInvited ? Color.dinkrGreen.opacity(0.12) : Color.clear)
                        )
                )
            }
            .animation(.easeInOut(duration: 0.15), value: isInvited)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - SearchBar

private struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.subheadline)

            TextField("Search players…", text: $text)
                .font(.subheadline)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    GameInviteView(session: GameSession.mockSessions[0])
}

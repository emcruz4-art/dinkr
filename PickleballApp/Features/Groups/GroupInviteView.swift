import SwiftUI

// MARK: - GroupInviteView

struct GroupInviteView: View {
    let group: DinkrGroup

    @State private var searchText = ""
    @State private var invitedIds: Set<String> = []
    @State private var showLinkCopiedToast = false

    @Environment(\.dismiss) private var dismiss

    private var allPlayers: [User] { User.mockPlayers }

    private var filteredPlayers: [User] {
        if searchText.isEmpty { return allPlayers }
        let q = searchText.lowercased()
        return allPlayers.filter {
            $0.displayName.lowercased().contains(q) ||
            $0.username.lowercased().contains(q) ||
            $0.city.lowercased().contains(q)
        }
    }

    private var invitedPlayers: [User] {
        allPlayers.filter { invitedIds.contains($0.id) }
    }

    private var inviteCount: Int { invitedIds.count }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 0) {

                        // ── Search bar ────────────────────────────────────────
                        searchBar
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 8)

                        // ── Invited section ───────────────────────────────────
                        if !invitedPlayers.isEmpty {
                            invitedSection
                                .padding(.bottom, 8)
                        }

                        // ── Share options ─────────────────────────────────────
                        shareSection
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)

                        // ── Suggested players ─────────────────────────────────
                        suggestedSection
                            .padding(.bottom, 120)
                    }
                }

                // ── Send Invites CTA ──────────────────────────────────────────
                sendButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)

                // ── Link copied toast ─────────────────────────────────────────
                if showLinkCopiedToast {
                    linkCopiedToast
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(20)
                        .padding(.bottom, 110)
                }
            }
            .navigationTitle("Invite to \(group.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        HapticManager.selection()
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 16, weight: .medium))

            TextField("Search players by name or username…", text: $searchText)
                .font(.subheadline)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !searchText.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Invited Section

    private var invitedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Invited (\(inviteCount))")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(invitedPlayers) { player in
                        InvitedAvatarChip(player: player) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                invitedIds.remove(player.id)
                            }
                            HapticManager.selection()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Share Section

    private var shareSection: some View {
        VStack(spacing: 0) {
            // Copy invite link row
            Button {
                HapticManager.medium()
                UIPasteboard.general.string = "https://dinkr.app/invite/\(group.id)"
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    showLinkCopiedToast = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    withAnimation { showLinkCopiedToast = false }
                }
            } label: {
                ShareOptionRow(
                    icon: "link",
                    iconColor: Color.dinkrGreen,
                    title: "Copy Invite Link",
                    subtitle: "Share a link anyone can use to join"
                )
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 60)

            // Messages placeholder
            Button {
                HapticManager.selection()
            } label: {
                ShareOptionRow(
                    icon: "message.fill",
                    iconColor: Color.dinkrSky,
                    title: "Share via Messages",
                    subtitle: "Send an iMessage or SMS invite"
                )
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 60)

            // WhatsApp placeholder
            Button {
                HapticManager.selection()
            } label: {
                ShareOptionRow(
                    icon: "paperplane.fill",
                    iconColor: Color(red: 0.23, green: 0.73, blue: 0.34),
                    title: "Share via WhatsApp",
                    subtitle: "Open WhatsApp to send group invite"
                )
            }
            .buttonStyle(.plain)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Suggested Players Section

    private var suggestedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(searchText.isEmpty ? "Suggested Players" : "Search Results")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

            if filteredPlayers.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("No players found")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filteredPlayers.enumerated()), id: \.element.id) { index, player in
                        PlayerInviteRow(
                            player: player,
                            isInvited: invitedIds.contains(player.id)
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if invitedIds.contains(player.id) {
                                    invitedIds.remove(player.id)
                                } else {
                                    invitedIds.insert(player.id)
                                }
                            }
                            HapticManager.medium()
                        }

                        if index < filteredPlayers.count - 1 {
                            Divider().padding(.leading, 68)
                        }
                    }
                }
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button {
            HapticManager.success()
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "paperplane.fill")
                Text(inviteCount > 0 ? "Send Invites (\(inviteCount))" : "Send Invites")
                    .fontWeight(.bold)
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: inviteCount > 0
                        ? [Color.dinkrGreen, Color.dinkrGreen.opacity(0.80)]
                        : [Color.secondary.opacity(0.35), Color.secondary.opacity(0.25)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: inviteCount > 0 ? Color.dinkrGreen.opacity(0.35) : .clear,
                radius: 10, x: 0, y: 5
            )
        }
        .buttonStyle(.plain)
        .disabled(inviteCount == 0)
        .animation(.easeInOut(duration: 0.2), value: inviteCount)
    }

    // MARK: - Link Copied Toast

    private var linkCopiedToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.dinkrGreen)
            Text("Link copied!")
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(Color.appBackground)
                .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 6)
        )
    }
}

// MARK: - Invited Avatar Chip

private struct InvitedAvatarChip: View {
    let player: User
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 5) {
            ZStack(alignment: .topTrailing) {
                AvatarView(urlString: player.avatarURL, displayName: player.displayName, size: 48)

                Button(action: onRemove) {
                    ZStack {
                        Circle()
                            .fill(Color.dinkrCoral)
                            .frame(width: 18, height: 18)
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .offset(x: 4, y: -4)
            }

            Text(player.displayName.components(separatedBy: " ").first ?? player.displayName)
                .font(.caption2.weight(.medium))
                .lineLimit(1)
                .frame(width: 52)
        }
    }
}

// MARK: - Player Invite Row

private struct PlayerInviteRow: View {
    let player: User
    let isInvited: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(urlString: player.avatarURL, displayName: player.displayName, size: 44)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(player.displayName)
                        .font(.subheadline.weight(.semibold))
                    SkillBadge(level: player.skillLevel, compact: true)
                }
                Text("@\(player.username)  ·  \(player.city)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Invite / Invited button
            Button(action: onToggle) {
                HStack(spacing: 5) {
                    if isInvited {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                    }
                    Text(isInvited ? "Invited" : "Invite")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(isInvited ? Color.dinkrGreen : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isInvited
                        ? Color.dinkrGreen.opacity(0.12)
                        : Color.dinkrGreen
                )
                .overlay(
                    Capsule()
                        .stroke(isInvited ? Color.dinkrGreen : Color.clear, lineWidth: 1.5)
                )
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isInvited)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }
}

// MARK: - Share Option Row

private struct ShareOptionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    GroupInviteView(group: DinkrGroup.mockGroups[0])
}

import SwiftUI

// MARK: - Member Role Badge

struct MemberRoleBadge: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(Capsule())
    }
}

// MARK: - Sort Option

enum MemberSortOption: String, CaseIterable, Identifiable {
    case mostActive     = "Most Active"
    case recentlyJoined = "Recently Joined"
    case skillLevel     = "Skill Level"
    case alphabetical   = "Alphabetical"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .mostActive:     return "flame.fill"
        case .recentlyJoined: return "calendar.badge.plus"
        case .skillLevel:     return "chart.bar.fill"
        case .alphabetical:   return "textformat.abc"
        }
    }
}

// MARK: - GroupMembersView

struct GroupMembersView: View {
    let group: DinkrGroup
    let allMembers: [User] = User.mockPlayers

    @Environment(AuthService.self) private var authService
    @State private var searchText = ""
    @State private var sortOption: MemberSortOption = .mostActive
    @State private var showSortPicker = false

    // Roles keyed by user id
    private let adminRoles: [String: (label: String, color: Color)] = [
        "user_003": ("Admin", Color.dinkrAmber),
        "user_009": ("Mod",   Color.dinkrSky),
    ]

    // Current user is admin if their id appears in group.adminIds
    private var currentUserIsAdmin: Bool {
        guard let uid = authService.currentUser?.id else { return false }
        return group.adminIds.contains(uid)
    }

    // Members active in last 24h (mocked by reliabilityScore threshold)
    private func isOnline(_ member: User) -> Bool {
        member.reliabilityScore >= 4.7
    }

    private var filteredMembers: [User] {
        let base = searchText.isEmpty
            ? allMembers
            : allMembers.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.username.localizedCaseInsensitiveContains(searchText)
            }
        return sorted(base)
    }

    private var onlineMembers: [User] {
        filteredMembers.filter { isOnline($0) }
    }

    private var offlineMembers: [User] {
        filteredMembers.filter { !isOnline($0) }
    }

    private func sorted(_ members: [User]) -> [User] {
        switch sortOption {
        case .mostActive:
            return members.sorted { $0.gamesPlayed > $1.gamesPlayed }
        case .recentlyJoined:
            return members.sorted { $0.joinedDate > $1.joinedDate }
        case .skillLevel:
            return members.sorted { $0.skillLevel.sortOrder > $1.skillLevel.sortOrder }
        case .alphabetical:
            return members.sorted { $0.displayName < $1.displayName }
        }
    }

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {

            // ── Header: member count + sort ───────────────────────────────
            HStack {
                HStack(spacing: 6) {
                    Text("Members")
                        .font(.headline)
                    Text("\(allMembers.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.dinkrNavy)
                        .clipShape(Capsule())
                }

                Spacer()

                // Sort picker button
                Button {
                    showSortPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: sortOption.systemImage)
                            .font(.system(size: 11, weight: .semibold))
                        Text(sortOption.rawValue)
                            .font(.caption.weight(.semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundStyle(Color.dinkrGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.dinkrGreen.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.dinkrGreen.opacity(0.3), lineWidth: 1)
                    )
                }
                .confirmationDialog("Sort Members By", isPresented: $showSortPicker, titleVisibility: .visible) {
                    ForEach(MemberSortOption.allCases) { option in
                        Button(option.rawValue) {
                            withAnimation(.easeInOut) {
                                sortOption = option
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            // ── Search bar ────────────────────────────────────────────────
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 14))
                TextField("Search members…", text: $searchText)
                    .font(.subheadline)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            // ── Grid content ──────────────────────────────────────────────
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {

                    // Online section
                    if !onlineMembers.isEmpty {
                        Section {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(onlineMembers) { member in
                                    MemberAvatarCell(
                                        member: member,
                                        roleInfo: adminRoles[member.id],
                                        isOnline: true,
                                        isAdmin: adminRoles[member.id]?.label == "Admin",
                                        currentUserIsAdmin: currentUserIsAdmin,
                                        currentUserId: authService.currentUser?.id ?? "",
                                        group: group
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                            .padding(.bottom, 16)
                        } header: {
                            GroupMembersViewSectionHeader(
                                label: "Online Now",
                                icon: "circle.fill",
                                iconColor: Color.dinkrGreen,
                                count: onlineMembers.count
                            )
                        }
                    }

                    // All / offline members
                    if !offlineMembers.isEmpty {
                        Section {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(offlineMembers) { member in
                                    MemberAvatarCell(
                                        member: member,
                                        roleInfo: adminRoles[member.id],
                                        isOnline: false,
                                        isAdmin: adminRoles[member.id]?.label == "Admin",
                                        currentUserIsAdmin: currentUserIsAdmin,
                                        currentUserId: authService.currentUser?.id ?? "",
                                        group: group
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                            .padding(.bottom, 24)
                        } header: {
                            GroupMembersViewSectionHeader(
                                label: onlineMembers.isEmpty ? "All Members" : "Other Members",
                                icon: "person.2.fill",
                                iconColor: Color.dinkrNavy,
                                count: offlineMembers.count
                            )
                        }
                    }

                    // Empty state
                    if filteredMembers.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.slash")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.secondary.opacity(0.4))
                            Text("No members found")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    }
                }
                .padding(.top, 4)
            }
        }
    }
}

// MARK: - Section Header

private struct GroupMembersViewSectionHeader: View {
    let label: String
    let icon: String
    let iconColor: Color
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(iconColor)
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
            Text("·  \(count)")
                .font(.system(size: 11))
                .foregroundStyle(Color.secondary.opacity(0.6))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.appBackground)
    }
}

// MARK: - Member Avatar Cell

private struct MemberAvatarCell: View {
    let member: User
    let roleInfo: (label: String, color: Color)?
    let isOnline: Bool
    let isAdmin: Bool
    let currentUserIsAdmin: Bool
    let currentUserId: String
    let group: DinkrGroup

    @State private var showAdminConfirm = false
    @State private var showRemoveConfirm = false
    @State private var pendingAction: AdminAction?

    enum AdminAction { case makeAdmin, remove }

    var body: some View {
        NavigationLink(destination: UserProfileView(user: member, currentUserId: currentUserId)) {
            VStack(spacing: 6) {

                ZStack(alignment: .bottomTrailing) {
                    ZStack(alignment: .topTrailing) {
                        AvatarView(
                            urlString: member.avatarURL,
                            displayName: member.displayName,
                            size: 60
                        )

                        // Admin crown
                        if isAdmin {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.dinkrAmber)
                                .padding(3)
                                .background(.white)
                                .clipShape(Circle())
                                .shadow(color: Color.dinkrAmber.opacity(0.4), radius: 3)
                                .offset(x: 4, y: -4)
                        }
                    }

                    // Role badge (Mod, etc.)
                    if let roleInfo, !isAdmin {
                        MemberRoleBadge(label: roleInfo.label, color: roleInfo.color)
                            .offset(y: 6)
                    }

                    // Online dot
                    if isOnline {
                        Circle()
                            .fill(Color.dinkrGreen)
                            .frame(width: 11, height: 11)
                            .overlay(Circle().stroke(Color.appBackground, lineWidth: 2))
                            .offset(x: 3, y: 3)
                    }
                }
                .padding(.bottom, roleInfo != nil && !isAdmin ? 6 : 0)

                Text(member.displayName.components(separatedBy: " ").first ?? member.displayName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                SkillBadge(level: member.skillLevel, compact: true)

                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Color.dinkrAmber)
                    Text(String(format: "%.1f", member.reliabilityScore))
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            if currentUserIsAdmin {
                Button {
                    pendingAction = .makeAdmin
                    showAdminConfirm = true
                } label: {
                    Label(
                        isAdmin ? "Remove Admin Role" : "Make Admin",
                        systemImage: isAdmin ? "crown.slash" : "crown.fill"
                    )
                }

                Button(role: .destructive) {
                    pendingAction = .remove
                    showRemoveConfirm = true
                } label: {
                    Label("Remove from DinkrGroup", systemImage: "person.badge.minus")
                }
            }
        }
        .alert(
            isAdmin ? "Remove Admin Role?" : "Make \(member.displayName.components(separatedBy: " ").first ?? "this member") Admin?",
            isPresented: $showAdminConfirm
        ) {
            Button("Confirm") { HapticManager.medium() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(isAdmin
                 ? "This will remove their admin privileges."
                 : "They will gain full admin controls for \(group.name).")
        }
        .alert("Remove from DinkrGroup?", isPresented: $showRemoveConfirm) {
            Button("Remove", role: .destructive) { HapticManager.medium() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(member.displayName) will be removed from \(group.name) and will need to rejoin.")
        }
    }
}

// MARK: - SkillLevel sort helper (uses existing sortIndex from Enums)

private extension SkillLevel {
    var sortOrder: Int { sortIndex }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GroupMembersView(group: DinkrGroup.mockGroups[0])
    }
}

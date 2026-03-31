import SwiftUI

// MARK: - Privacy Option

enum GroupPrivacyOption: String, CaseIterable, Identifiable {
    case publicGroup  = "Public"
    case privateGroup = "Private"
    case inviteOnly   = "Invite Only"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .publicGroup:  return "globe"
        case .privateGroup: return "lock.fill"
        case .inviteOnly:   return "envelope.fill"
        }
    }

    var description: String {
        switch self {
        case .publicGroup:  return "Anyone can find and join this group."
        case .privateGroup: return "Anyone can find it, but members must be approved."
        case .inviteOnly:   return "Only people with an invite link can join."
        }
    }
}

// MARK: - Mock Member Role

enum MemberRole {
    case admin, mod, member

    var label: String? {
        switch self {
        case .admin:  return "Admin"
        case .mod:    return "Mod"
        case .member: return nil
        }
    }

    var color: Color? {
        switch self {
        case .admin:  return Color.dinkrAmber
        case .mod:    return Color.dinkrSky
        case .member: return nil
        }
    }
}

struct MockGroupMember: Identifiable {
    let id: String
    let name: String
    var role: MemberRole
}

// MARK: - GroupSettingsView

struct GroupSettingsView: View {
    let group: DinkrGroup

    // DinkrGroup info
    @State private var groupName: String
    @State private var groupDescription: String
    @State private var groupType: GroupType

    // Privacy
    @State private var privacyOption: GroupPrivacyOption
    @State private var requireAdminApproval = false

    // Members
    @State private var maxMembers = 50
    @State private var members: [MockGroupMember]

    // Notifications
    @State private var notifyNewEvents = true
    @State private var notifyNewPolls = true
    @State private var notifyChallenges = false
    @State private var notifyNewMembers = true

    // UI state
    @State private var showDeleteAlert = false
    @State private var showArchiveAlert = false
    @State private var showSavedToast = false
    @State private var showPhotoPlaceholderPulse = false
    @State private var showAnalytics = false

    @Environment(\.dismiss) private var dismiss

    init(group: DinkrGroup) {
        self.group = group
        _groupName        = State(initialValue: group.name)
        _groupDescription = State(initialValue: group.description)
        _groupType        = State(initialValue: group.type)
        _privacyOption    = State(initialValue: group.isPrivate ? .privateGroup : .publicGroup)
        _members          = State(initialValue: [
            MockGroupMember(id: "user_001", name: "Alex Rivera",  role: .admin),
            MockGroupMember(id: "user_002", name: "Maria Chen",   role: .mod),
            MockGroupMember(id: "user_003", name: "Jordan Smith", role: .member),
            MockGroupMember(id: "user_004", name: "Sarah Johnson",role: .member),
            MockGroupMember(id: "user_005", name: "Chris Park",   role: .member),
        ])
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Form {
                    groupInfoSection
                    privacySection
                    membersSection
                    adminSection
                    notificationsSection
                    dangerZoneSection
                }
                .scrollContentBackground(.visible)

                // Toast
                if showSavedToast {
                    toastBanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10)
                }
            }
            .navigationTitle("DinkrGroup Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        HapticManager.selection()
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.dinkrGreen)
                }
            }
            .alert("Archive DinkrGroup", isPresented: $showArchiveAlert) {
                Button("Archive", role: .destructive) { dismiss() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Archiving hides the group from search. Members can still view past content.")
            }
            .alert("Delete DinkrGroup", isPresented: $showDeleteAlert) {
                Button("Delete Forever", role: .destructive) { dismiss() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete \"\(groupName)\" and all its posts, events, and polls. This cannot be undone.")
            }
        }
    }

    // MARK: - DinkrGroup Info Section

    private var groupInfoSection: some View {
        Section {
            // Photo placeholder
            HStack {
                Spacer()
                Button {
                    HapticManager.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        showPhotoPlaceholderPulse.toggle()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.dinkrGreen.opacity(0.12))
                            .frame(width: 86, height: 86)
                            .scaleEffect(showPhotoPlaceholderPulse ? 1.05 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showPhotoPlaceholderPulse)

                        Image(systemName: "camera.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Color.dinkrGreen)

                        Circle()
                            .stroke(Color.dinkrGreen.opacity(0.35), lineWidth: 2)
                            .frame(width: 86, height: 86)
                    }
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .listRowBackground(Color.appBackground)
            .padding(.vertical, 8)

            // Name field
            HStack {
                Label("Name", systemImage: "pencil")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .frame(width: 80, alignment: .leading)
                TextField("DinkrGroup name", text: $groupName)
                    .font(.subheadline.weight(.medium))
            }

            // Description
            VStack(alignment: .leading, spacing: 6) {
                Label("Description", systemImage: "text.alignleft")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                TextEditor(text: $groupDescription)
                    .font(.subheadline)
                    .frame(minHeight: 80)
            }
            .padding(.vertical, 4)

            // GroupType picker
            VStack(alignment: .leading, spacing: 8) {
                Label("Type", systemImage: "tag")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                Picker("DinkrGroup Type", selection: $groupType) {
                    ForEach(GroupType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.dinkrGreen)
            }
            .padding(.vertical, 4)
        } header: {
            Text("DinkrGroup Info")
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        Section {
            ForEach(GroupPrivacyOption.allCases) { option in
                Button {
                    HapticManager.selection()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        privacyOption = option
                    }
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(privacyOption == option ? Color.dinkrGreen.opacity(0.15) : Color.secondary.opacity(0.08))
                                .frame(width: 40, height: 40)
                            Image(systemName: option.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(privacyOption == option ? Color.dinkrGreen : .secondary)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(option.rawValue)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(privacyOption == option ? Color.dinkrGreen : .primary)
                            Text(option.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if privacyOption == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.dinkrGreen)
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Toggle(isOn: $requireAdminApproval) {
                Label("Require admin approval", systemImage: "checkmark.shield")
            }
            .tint(Color.dinkrGreen)

        } header: {
            Text("Privacy")
        }
    }

    // MARK: - Members Section

    private var membersSection: some View {
        Section {
            // Max members stepper
            Stepper(value: $maxMembers, in: 2...50) {
                HStack {
                    Label("Max Members", systemImage: "person.2.fill")
                        .font(.subheadline)
                    Spacer()
                    Text("\(maxMembers)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.dinkrGreen)
                        .monospacedDigit()
                }
            }
            .tint(Color.dinkrGreen)

            // Co-admin toggles
            DisclosureGroup {
                ForEach($members) { $member in
                    HStack {
                        AvatarView(urlString: nil, displayName: member.name, size: 32)
                        Text(member.name)
                            .font(.subheadline)
                        Spacer()
                        Toggle("Co-admin", isOn: Binding(
                            get: { member.role == .admin || member.role == .mod },
                            set: { isOn in
                                HapticManager.selection()
                                member.role = isOn ? .mod : .member
                            }
                        ))
                        .labelsHidden()
                        .tint(Color.dinkrAmber)
                    }
                }
            } label: {
                Label("Co-admin Assignment", systemImage: "person.badge.shield.checkmark")
                    .font(.subheadline)
            }

            // Remove member list with swipe
            DisclosureGroup {
                ForEach(members.filter { $0.role == .member }) { member in
                    HStack {
                        AvatarView(urlString: nil, displayName: member.name, size: 32)
                        Text(member.name)
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "person.fill")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            HapticManager.medium()
                            withAnimation {
                                members.removeAll { $0.id == member.id }
                            }
                        } label: {
                            Label("Remove", systemImage: "person.fill.xmark")
                        }
                    }
                }
            } label: {
                Label("Remove Members", systemImage: "person.fill.xmark")
                    .font(.subheadline)
            }

        } header: {
            Text("Members")
        }
    }

    // MARK: - Admin Tools Section

    private var adminSection: some View {
        Section {
            NavigationLink(destination: GroupAnalyticsView(group: group)) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.dinkrAmber.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.dinkrAmber)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DinkrGroup Analytics")
                            .font(.subheadline.weight(.semibold))
                        Text("Member growth, engagement & game stats")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Admin Tools")
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $notifyNewEvents) {
                Label("New Events", systemImage: "calendar")
            }
            .tint(Color.dinkrGreen)

            Toggle(isOn: $notifyNewPolls) {
                Label("New Polls", systemImage: "chart.bar.fill")
            }
            .tint(Color.dinkrGreen)

            Toggle(isOn: $notifyChallenges) {
                Label("Challenges", systemImage: "trophy.fill")
            }
            .tint(Color.dinkrCoral)

            Toggle(isOn: $notifyNewMembers) {
                Label("New Members", systemImage: "person.badge.plus")
            }
            .tint(Color.dinkrSky)
        } header: {
            Text("Notify All Members Of")
        } footer: {
            Text("Push notifications will be sent to all group members for selected activity types.")
        }
    }

    // MARK: - Danger Zone Section

    private var dangerZoneSection: some View {
        Section {
            Button {
                HapticManager.medium()
                showArchiveAlert = true
            } label: {
                HStack {
                    Spacer()
                    Label("Archive DinkrGroup", systemImage: "archivebox")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrCoral)
                    Spacer()
                }
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.dinkrCoral.opacity(0.5), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
            .listRowBackground(Color.clear)

            Button {
                HapticManager.medium()
                showDeleteAlert = true
            } label: {
                HStack {
                    Spacer()
                    Label("Delete DinkrGroup", systemImage: "trash.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(Color.dinkrCoral)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)

        } header: {
            Text("Danger Zone")
                .foregroundStyle(Color.dinkrCoral)
        }
    }

    // MARK: - Toast Banner

    private var toastBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.dinkrGreen)
            Text("Changes saved")
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(Color.appBackground)
                .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 6)
        )
        .padding(.bottom, 24)
    }

    // MARK: - Actions

    private func saveChanges() {
        HapticManager.success()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            showSavedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation {
                showSavedToast = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    GroupSettingsView(group: DinkrGroup.mockGroups[0])
}

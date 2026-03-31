import SwiftUI

// MARK: - GroupPostComposerView

struct GroupPostComposerView: View {
    let group: DinkrGroup

    @Environment(\.dismiss) private var dismiss

    // Composer state
    @State private var postText: String = ""
    @State private var selectedPostType: GroupPostType = .announcement
    @State private var isPinnedToTop: Bool = false
    @State private var showMemberPicker: Bool = false
    @State private var mentionedMemberIds: [String] = []
    @State private var isPosting: Bool = false
    @State private var showDiscardConfirm: Bool = false

    // @mention inline suggestion
    @State private var mentionQuery: String = ""
    @State private var showMentionSuggestions: Bool = false
    @FocusState private var textFieldFocused: Bool

    // Linked context
    @State private var linkedEventIndex: Int? = nil
    @State private var linkedGameIndex: Int? = nil

    // Mock data
    private let mockMembers: [GroupMember] = GroupMember.mockMembers
    private let mockEvents: [Event] = Event.mockEvents
        .filter { $0.dateTime >= Date() }
        .prefix(5)
        .map { $0 }

    private var currentUserIsAdmin: Bool {
        group.adminIds.contains("user_001")
    }

    private var canPost: Bool {
        !postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var mentionSuggestions: [GroupMember] {
        guard !mentionQuery.isEmpty else { return [] }
        return mockMembers.filter {
            $0.displayName.localizedCaseInsensitiveContains(mentionQuery) ||
            $0.username.localizedCaseInsensitiveContains(mentionQuery)
        }
        .prefix(5)
        .map { $0 }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 0) {

                        // ── Post type selector ───────────────────────────
                        postTypePicker
                            .padding(.top, 16)
                            .padding(.horizontal, 16)

                        // ── Text compose area ────────────────────────────
                        composeArea
                            .padding(.horizontal, 16)
                            .padding(.top, 14)

                        // ── @mention suggestion overlay ──────────────────
                        if showMentionSuggestions && !mentionSuggestions.isEmpty {
                            mentionSuggestionsList
                                .padding(.horizontal, 16)
                                .padding(.top, 4)
                        }

                        // ── Mentioned members row ────────────────────────
                        if !mentionedMemberIds.isEmpty {
                            mentionedRow
                                .padding(.horizontal, 16)
                                .padding(.top, 10)
                        }

                        // ── Link upcoming event ──────────────────────────
                        if selectedPostType == .announcement || selectedPostType == .lookingForPlayers {
                            eventLinkSection
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                        }

                        // ── Pin to top toggle (admin only) ───────────────
                        if currentUserIsAdmin {
                            pinToggle
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                        }

                        Spacer().frame(height: 120)
                    }
                }

                // ── Bottom action bar ────────────────────────────────────
                bottomBar
            }
            .background(Color.appBackground)
            .navigationTitle("New DinkrGroup Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
            .sheet(isPresented: $showMemberPicker) {
                GroupMemberPickerView(
                    members: mockMembers,
                    selectedIds: $mentionedMemberIds
                )
            }
            .confirmationDialog(
                "Discard this post?",
                isPresented: $showDiscardConfirm,
                titleVisibility: .visible
            ) {
                Button("Discard Post", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
            }
        }
    }

    // MARK: - Post Type Picker

    private var postTypePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Post type", systemImage: "tag.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(GroupPostType.allCases, id: \.self) { type in
                        GroupPostTypeChip(
                            type: type,
                            isSelected: selectedPostType == type
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedPostType = type
                            }
                            HapticManager.selection()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Compose Area

    private var composeArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Context badge
            HStack(spacing: 6) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.dinkrNavy)
                Text("Posting to \(group.name)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrNavy)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.dinkrNavy.opacity(0.08))
            .clipShape(Capsule())

            // Text editor
            ZStack(alignment: .topLeading) {
                if postText.isEmpty {
                    Text(selectedPostType.placeholder)
                        .font(.body)
                        .foregroundStyle(Color.secondary.opacity(0.6))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $postText)
                    .font(.body)
                    .frame(minHeight: 120, maxHeight: 240)
                    .focused($textFieldFocused)
                    .scrollContentBackground(.hidden)
                    .onChange(of: postText) { _, newValue in
                        detectMentionTrigger(in: newValue)
                    }
            }
            .padding(12)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        textFieldFocused ? Color.dinkrGreen.opacity(0.4) : Color.secondary.opacity(0.15),
                        lineWidth: textFieldFocused ? 1.5 : 1
                    )
            )

            // Character count
            HStack {
                Spacer()
                Text("\(postText.count)/500")
                    .font(.caption2)
                    .foregroundStyle(postText.count > 450 ? Color.dinkrCoral : .secondary)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - @mention Suggestions

    private var mentionSuggestionsList: some View {
        VStack(spacing: 0) {
            ForEach(mentionSuggestions) { member in
                Button {
                    insertMention(member)
                } label: {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.dinkrGreen.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Text(member.displayName.prefix(1))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.dinkrGreen)
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text(member.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("@\(member.username)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if member.isAdmin {
                            Text("Admin")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.dinkrAmber)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Color.dinkrAmber.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if member.id != mentionSuggestions.last?.id {
                    Divider().padding(.leading, 54)
                }
            }
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.dinkrGreen.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Mentioned Row

    private var mentionedRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Image(systemName: "at")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                ForEach(mentionedMemberIds, id: \.self) { memberId in
                    if let member = mockMembers.first(where: { $0.id == memberId }) {
                        HStack(spacing: 5) {
                            Text("@\(member.username)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.dinkrGreen)
                            Button {
                                mentionedMemberIds.removeAll { $0 == memberId }
                                HapticManager.selection()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color.dinkrGreen.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.dinkrGreen.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }

                Button {
                    showMemberPicker = true
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text("@mention")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Color.dinkrGreen)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.dinkrGreen.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.dinkrGreen.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Event Link Section

    private var eventLinkSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Link an Upcoming Event", systemImage: "link")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // None pill
                    Button {
                        withAnimation { linkedEventIndex = nil }
                        HapticManager.selection()
                    } label: {
                        Text("None")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(linkedEventIndex == nil ? .white : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(linkedEventIndex == nil ? Color.dinkrNavy : Color.cardBackground)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(linkedEventIndex == nil ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    ForEach(mockEvents.indices, id: \.self) { idx in
                        let event = mockEvents[idx]
                        Button {
                            withAnimation { linkedEventIndex = idx }
                            HapticManager.selection()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10, weight: .semibold))
                                Text(event.title)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(linkedEventIndex == idx ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(linkedEventIndex == idx ? Color.dinkrSky : Color.cardBackground)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(linkedEventIndex == idx ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Pin Toggle

    private var pinToggle: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color.dinkrAmber.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "pin.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.dinkrAmber)
                    .rotationEffect(.degrees(45))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Pin to top of group feed")
                    .font(.subheadline.weight(.semibold))
                Text("Only admins can pin posts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isPinnedToTop)
                .labelsHidden()
                .tint(Color.dinkrAmber)
                .onChange(of: isPinnedToTop) { _, _ in
                    HapticManager.selection()
                }
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isPinnedToTop ? Color.dinkrAmber.opacity(0.35) : Color.secondary.opacity(0.12), lineWidth: 1)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPinnedToTop)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                // @mention quick trigger
                Button {
                    postText += " @"
                    textFieldFocused = true
                    HapticManager.selection()
                } label: {
                    Image(systemName: "at")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.dinkrGreen)
                        .frame(width: 40, height: 40)
                        .background(Color.dinkrGreen.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                // Member picker trigger
                Button {
                    showMemberPicker = true
                    HapticManager.selection()
                } label: {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.dinkrNavy)
                        .frame(width: 40, height: 40)
                        .background(Color.dinkrNavy.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                // Pinned indicator
                if isPinnedToTop {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.dinkrAmber)
                        .rotationEffect(.degrees(45))
                }

                Spacer()

                // Post button
                Button {
                    submitPost()
                } label: {
                    HStack(spacing: 8) {
                        if isPosting {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.subheadline.weight(.semibold))
                        }
                        Text("Post")
                            .font(.headline.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        canPost ? Color.dinkrGreen : Color.secondary.opacity(0.3),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .shadow(
                        color: canPost ? Color.dinkrGreen.opacity(0.4) : .clear,
                        radius: 6, x: 0, y: 3
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canPost || isPosting)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: canPost)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appBackground)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") {
                if canPost {
                    showDiscardConfirm = true
                } else {
                    dismiss()
                }
            }
            .foregroundStyle(.secondary)
        }

        ToolbarItem(placement: .principal) {
            VStack(spacing: 1) {
                Text("New Post")
                    .font(.subheadline.weight(.bold))
                Text(group.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func submitPost() {
        guard canPost else { return }
        isPosting = true
        HapticManager.medium()

        // Simulate async post submission
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isPosting = false
            HapticManager.success()
            dismiss()
        }
    }

    private func detectMentionTrigger(in text: String) {
        // Detect "@" followed by non-whitespace characters at the end of the current word
        let pattern = /@(\w*)$/
        if let match = text.firstMatch(of: pattern) {
            let query = String(match.output.1)
            mentionQuery = query
            withAnimation(.easeInOut(duration: 0.2)) {
                showMentionSuggestions = true
            }
        } else {
            mentionQuery = ""
            withAnimation(.easeInOut(duration: 0.15)) {
                showMentionSuggestions = false
            }
        }
    }

    private func insertMention(_ member: GroupMember) {
        // Replace the trailing @query with @username
        let pattern = "@\\w*$"
        if let range = postText.range(of: pattern, options: .regularExpression) {
            postText.replaceSubrange(range, with: "@\(member.username) ")
        }
        if !mentionedMemberIds.contains(member.id) {
            mentionedMemberIds.append(member.id)
        }
        mentionQuery = ""
        withAnimation { showMentionSuggestions = false }
        HapticManager.selection()
    }
}

// MARK: - DinkrGroup Post Type Chip

private struct GroupPostTypeChip: View {
    let type: GroupPostType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(type.label)
                    .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
            }
            .foregroundStyle(isSelected ? .white : type.color)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isSelected ? type.color : type.color.opacity(0.1))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : type.color.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: isSelected ? type.color.opacity(0.35) : .clear, radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - DinkrGroup Member Picker Sheet

private struct GroupMemberPickerView: View {
    let members: [GroupMember]
    @Binding var selectedIds: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var filtered: [GroupMember] {
        if search.isEmpty { return members }
        return members.filter {
            $0.displayName.localizedCaseInsensitiveContains(search) ||
            $0.username.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { member in
                    let isSelected = selectedIds.contains(member.id)
                    Button {
                        if isSelected {
                            selectedIds.removeAll { $0 == member.id }
                        } else {
                            selectedIds.append(member.id)
                        }
                        HapticManager.selection()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.dinkrGreen.opacity(0.15))
                                    .frame(width: 38, height: 38)
                                Text(member.displayName.prefix(1))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(Color.dinkrGreen)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 5) {
                                    Text(member.displayName)
                                        .font(.subheadline.weight(.medium))
                                    if member.isAdmin {
                                        Text("Admin")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(Color.dinkrAmber)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.dinkrAmber.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                }
                                Text("@\(member.username)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.dinkrGreen)
                                    .font(.title3)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .searchable(text: $search, prompt: "Search members")
            .navigationTitle("Mention Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum GroupPostType: CaseIterable {
    case announcement
    case lookingForPlayers
    case result
    case discussion

    var label: String {
        switch self {
        case .announcement:      return "Announcement"
        case .lookingForPlayers: return "LFP"
        case .result:            return "Result"
        case .discussion:        return "Discussion"
        }
    }

    var icon: String {
        switch self {
        case .announcement:      return "megaphone.fill"
        case .lookingForPlayers: return "person.badge.plus"
        case .result:            return "trophy.fill"
        case .discussion:        return "bubble.left.and.bubble.right.fill"
        }
    }

    var color: Color {
        switch self {
        case .announcement:      return Color.dinkrAmber
        case .lookingForPlayers: return Color.dinkrGreen
        case .result:            return Color.dinkrCoral
        case .discussion:        return Color.dinkrSky
        }
    }

    var placeholder: String {
        switch self {
        case .announcement:
            return "Share an announcement with the group..."
        case .lookingForPlayers:
            return "Looking for players? Describe the game, time, and skill level..."
        case .result:
            return "Share a match result or tournament outcome..."
        case .discussion:
            return "Start a discussion — strategy, gear, tips, or anything else..."
        }
    }
}

struct GroupMember: Identifiable {
    let id: String
    let displayName: String
    let username: String
    let isAdmin: Bool

    static let mockMembers: [GroupMember] = [
        GroupMember(id: "user_001", displayName: "Alex Rivera",   username: "alex_rivera",   isAdmin: false),
        GroupMember(id: "user_002", displayName: "Maria Chen",    username: "maria_chen",    isAdmin: true),
        GroupMember(id: "user_003", displayName: "Jordan Smith",  username: "jordan_s",      isAdmin: false),
        GroupMember(id: "user_004", displayName: "Sarah Johnson", username: "sarah_j",       isAdmin: false),
        GroupMember(id: "user_005", displayName: "Chris Park",    username: "chrispark",     isAdmin: false),
        GroupMember(id: "user_006", displayName: "Taylor Kim",    username: "taylor_kim",    isAdmin: false),
        GroupMember(id: "user_007", displayName: "Jamie Lee",     username: "jamie_lee",     isAdmin: false),
        GroupMember(id: "user_008", displayName: "Morgan Davis",  username: "morgan_d",      isAdmin: false),
        GroupMember(id: "user_009", displayName: "Riley Torres",  username: "riley_t",       isAdmin: true),
        GroupMember(id: "user_010", displayName: "Tyler Brooks",  username: "tylerb",        isAdmin: false),
        GroupMember(id: "user_011", displayName: "Priya Patel",   username: "priyap",        isAdmin: false),
        GroupMember(id: "user_012", displayName: "Marcus Williams", username: "marcusw",     isAdmin: false),
    ]
}

// MARK: - Preview

#Preview {
    GroupPostComposerView(group: DinkrGroup.mockGroups[0])
}

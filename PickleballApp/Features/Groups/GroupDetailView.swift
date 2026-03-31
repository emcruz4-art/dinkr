import SwiftUI

// MARK: - GroupDetailView

struct GroupDetailView: View {
    let group: DinkrGroup
    @State private var selectedTab = 0
    @State private var showCreatePoll = false
    @State private var showSettings = false
    @State private var showInvite = false
    @State private var showShareSheet = false
    let tabs = ["Feed", "Members", "Events"]

    // Derived from group — in a real app this would come from the current user's membership state
    private var currentUserIsAdmin: Bool { group.adminIds.contains("user_001") }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── Hero Banner ───────────────────────────────────────────
                GroupHeroBanner(group: group)

                // ── Activity Ribbon ───────────────────────────────────────
                GroupActivityRibbon(group: group)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                // ── DinkrGroup Stats Strip ─────────────────────────────────────
                GroupStatsStrip(group: group)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                // ── Upcoming Games ────────────────────────────────────────
                GroupUpcomingGamesSection()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                // ── Sliding Underline Tab Bar ─────────────────────────────
                SlidingTabBar(tabs: tabs, selectedTab: $selectedTab)
                    .background(Color.appBackground)
                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

                // ── Active availability poll (Feed tab) ───────────────────
                if selectedTab == 0 {
                    AvailabilityPollCard(poll: .mock, currentUserId: "user_001")
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                    // ── Pinned Post ───────────────────────────────────────
                    PinnedPostBanner(
                        post: Post.mockPosts.first(where: { $0.groupId == group.id }) ?? Post.mockPosts[1],
                        isAdmin: currentUserIsAdmin
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

                // ── Tab content ───────────────────────────────────────────
                switch selectedTab {
                case 0:
                    GroupFeedView(group: group)
                    GroupAboutSection(group: group)
                        .padding(.top, 8)
                case 1:
                    GroupMembersView(group: group)
                case 2:
                    GroupEventsView(group: group)
                default:
                    EmptyView()
                }
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 4) {
                    // Share DinkrGroup
                    Button {
                        HapticManager.selection()
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen)
                    }

                    Button {
                        HapticManager.selection()
                        showInvite = true
                    } label: {
                        Label("Invite", systemImage: "person.badge.plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen)
                    }

                    Button {
                        HapticManager.selection()
                        showCreatePoll = true
                    } label: {
                        Label("Schedule", systemImage: "calendar.badge.plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen)
                    }

                    Button {
                        HapticManager.selection()
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                }
            }
        }
        .sheet(isPresented: $showInvite) {
            GroupInviteView(group: group)
        }
        .sheet(isPresented: $showCreatePoll) {
            CreateAvailabilityPollView()
        }
        .sheet(isPresented: $showSettings) {
            GroupSettingsView(group: group)
        }
        .sheet(isPresented: $showShareSheet) {
            let url = URL(string: "https://dinkr.app/groups/\(group.id)") ?? URL(string: "https://dinkr.app")!
            ActivityShareSheet(items: ["Join \(group.name) on Dinkr!", url])
        }
    }
}

// MARK: - Sliding Tab Bar

struct SlidingTabBar: View {
    let tabs: [String]
    @Binding var selectedTab: Int

    var body: some View {
        GeometryReader { geo in
            let tabWidth = geo.size.width / CGFloat(tabs.count)

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(tabs.indices, id: \.self) { i in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                selectedTab = i
                            }
                        } label: {
                            Text(tabs[i])
                                .font(.subheadline.weight(selectedTab == i ? .bold : .regular))
                                .foregroundStyle(selectedTab == i ? Color.dinkrGreen : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.2), value: selectedTab)
                    }
                }

                // Sliding underline
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 1)

                    Rectangle()
                        .fill(Color.dinkrGreen)
                        .frame(width: tabWidth - 32, height: 2.5)
                        .clipShape(Capsule())
                        .offset(x: tabWidth * CGFloat(selectedTab) + 16)
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selectedTab)
                }
            }
        }
        .frame(height: 48)
    }
}

// MARK: - Activity Ribbon

struct GroupActivityRibbon: View {
    let group: DinkrGroup

    // Mock activity state derived from member count for demo purposes
    private var activityState: ActivityState {
        if group.memberCount > 40 { return .hot }
        if group.memberCount > 20 { return .active }
        return .quiet
    }

    private var lastActivityLabel: String {
        switch activityState {
        case .hot:    return "Last activity 12 min ago"
        case .active: return "Last activity 2h ago"
        case .quiet:  return "Last activity 3 days ago"
        }
    }

    enum ActivityState {
        case hot, active, quiet

        var label: String {
            switch self {
            case .hot:    return "🔥 Active"
            case .active: return "Active"
            case .quiet:  return "Quiet"
            }
        }

        var pillColor: Color {
            switch self {
            case .hot:    return Color.dinkrCoral
            case .active: return Color.dinkrGreen
            case .quiet:  return Color.secondary
            }
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            // Activity pill
            HStack(spacing: 5) {
                if activityState != .quiet {
                    Circle()
                        .fill(activityState.pillColor)
                        .frame(width: 7, height: 7)
                        .overlay(
                            Circle()
                                .stroke(activityState.pillColor.opacity(0.3), lineWidth: 4)
                                .scaleEffect(1.8)
                                .opacity(0.6)
                        )
                }
                Text(activityState.label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(activityState.pillColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(activityState.pillColor.opacity(0.1))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(activityState.pillColor.opacity(0.25), lineWidth: 1)
            )

            Text(lastActivityLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}

// MARK: - DinkrGroup Stats Strip

struct GroupStatsStrip: View {
    let group: DinkrGroup

    private var accentColor: Color { groupDetailColor(for: group.type) }

    // Mock computed stats
    private var totalGames: Int { group.memberCount * 3 }
    private var winRate: String {
        // Deterministic mock derived from memberCount so it's stable across renders
        let r = 0.52 + (Double(group.memberCount % 20) / 100.0)
        return String(format: "%.0f%%", r * 100)
    }
    private var topPlayer: String { "Jordan S." }
    private var foundedLabel: String { "Jan 2024" }

    var body: some View {
        HStack(spacing: 0) {
            StatStripCell(
                value: "\(totalGames)",
                label: "Games",
                icon: "figure.pickleball",
                color: accentColor
            )
            Divider().frame(height: 36)
            StatStripCell(
                value: winRate,
                label: "Win Rate",
                icon: "percent",
                color: Color.dinkrGreen
            )
            Divider().frame(height: 36)
            StatStripCell(
                value: topPlayer,
                label: "Top Player",
                icon: "trophy.fill",
                color: Color.dinkrAmber
            )
            Divider().frame(height: 36)
            StatStripCell(
                value: foundedLabel,
                label: "Founded",
                icon: "calendar",
                color: Color.dinkrSky
            )
        }
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 5, x: 0, y: 2)
    }
}

private struct StatStripCell: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Upcoming Games Section

struct GroupUpcomingGamesSection: View {
    private let sessions: [GameSession] = Array(GameSession.mockSessions
        .filter { $0.dateTime > Date() }
        .sorted { $0.dateTime < $1.dateTime }
        .prefix(3))

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.dinkrNavy)
                Text("Upcoming Games")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Text("See all")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dinkrGreen)
            }

            ForEach(sessions) { session in
                UpcomingGameCompactCard(session: session)
            }
        }
    }
}

private struct UpcomingGameCompactCard: View {
    let session: GameSession

    private var accentColor: Color {
        switch session.format {
        case .doubles:     return Color.dinkrGreen
        case .singles:     return Color.dinkrCoral
        case .mixed:       return Color.dinkrSky
        case .round_robin: return Color.dinkrAmber
        default:           return Color.dinkrNavy
        }
    }

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: session.dateTime)
    }

    private var timeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: session.dateTime)
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(accentColor)
                .frame(width: 4)
                .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 3) {
                Text(session.format.displayLabel + " · " + session.courtName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(dateLabel, systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Label(timeLabel, systemImage: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Text("\(session.spotsRemaining) spot\(session.spotsRemaining == 1 ? "" : "s") left")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(session.spotsRemaining <= 1 ? Color.dinkrCoral : .secondary)
                }
            }

            Spacer()

            Text("RSVP")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(accentColor)
                .clipShape(Capsule())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(accentColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Pinned Post Banner

struct PinnedPostBanner: View {
    let post: Post
    var isAdmin: Bool = false
    @State private var isPinned = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "pin.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.dinkrAmber)
                Text("Pinned Post")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dinkrAmber)
                Spacer()
            }

            Text(post.content)
                .font(.subheadline)
                .lineLimit(3)
                .foregroundStyle(.primary)

            HStack(spacing: 12) {
                Label(post.authorName, systemImage: "person.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("\(post.likes)", systemImage: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(Color.dinkrCoral.opacity(0.8))

                Spacer()
            }
        }
        .padding(14)
        .background(Color.dinkrAmber.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.dinkrAmber.opacity(0.3), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .contextMenu {
            if isAdmin {
                Button {
                    HapticManager.medium()
                    isPinned.toggle()
                } label: {
                    Label(isPinned ? "Unpin Post" : "Pin Post",
                          systemImage: isPinned ? "pin.slash.fill" : "pin.fill")
                }
            }
            Button(role: .destructive) {} label: {
                Label("Report Post", systemImage: "flag")
            }
        }
    }
}

// MARK: - Premium DinkrGroup Detail Header (Hero Banner)

struct GroupHeroBanner: View {
    let group: DinkrGroup
    @State private var isJoined = false

    var accentColor: Color { groupDetailColor(for: group.type) }

    var body: some View {
        ZStack(alignment: .bottom) {

            // ── Hero gradient background ──────────────────────────────────
            ZStack(alignment: .topTrailing) {
                LinearGradient(
                    colors: [Color.dinkrNavy, accentColor.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Decorative watermark icon
                Image(systemName: groupDetailIcon(for: group.type))
                    .font(.system(size: 130, weight: .black))
                    .foregroundStyle(.white.opacity(0.05))
                    .padding(.top, 8)
                    .padding(.trailing, 8)
            }
            .frame(height: 220)

            // Overlay: group name + member count + Joined badge
            VStack(spacing: 0) {
                Spacer()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.name)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 1)
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            Label("\(group.memberCount) members", systemImage: "person.2.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                    .padding(.leading, 16)

                    Spacer()

                    // Joined badge
                    if isJoined {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("Joined")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.dinkrGreen.opacity(0.9))
                        .clipShape(Capsule())
                        .padding(.trailing, 16)
                    }
                }
                .padding(.bottom, 16)
            }
            .frame(height: 220)

            // Bottom vignette
            LinearGradient(
                colors: [.clear, Color.dinkrNavy.opacity(0.65)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 100)
        }

        // ── Below-hero content ─────────────────────────────────────────
        VStack(spacing: 16) {

            // DinkrGroup icon avatar — overlapping the hero
            ZStack {
                Circle()
                    .fill(Color.appBackground)
                    .frame(width: 88, height: 88)

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentColor, Color.dinkrNavy],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 78, height: 78)
                    Image(systemName: groupDetailIcon(for: group.type))
                        .foregroundStyle(.white)
                        .font(.system(size: 30, weight: .semibold))
                }
            }
            .shadow(color: accentColor.opacity(0.35), radius: 12, x: 0, y: 6)
            .offset(y: -44)
            .padding(.bottom, -44)

            // Name + privacy
            VStack(spacing: 5) {
                HStack(spacing: 8) {
                    Text(group.name)
                        .font(.title2.weight(.bold))
                    if group.isPrivate {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
                Text(group.type.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !group.description.isEmpty {
                    Text(group.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.top, 2)
                }
            }

            // ── Stats chips ───────────────────────────────────────────────
            HStack(spacing: 12) {
                GroupStatChip(value: "\(group.memberCount)", label: "Members", icon: "person.2.fill", color: accentColor)
                GroupStatChip(value: "24", label: "Posts", icon: "bubble.left.fill", color: Color.dinkrSky)
                GroupStatChip(value: group.isPrivate ? "Private" : "Public", label: "Access", icon: group.isPrivate ? "lock.fill" : "globe", color: Color.dinkrAmber)
            }

            // ── Member avatar stack ───────────────────────────────────────
            VStack(spacing: 6) {
                HStack(spacing: -9) {
                    ForEach(0..<min(6, max(0, group.memberCount)), id: \.self) { i in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [accentColor.opacity(0.4 + Double(i) * 0.08), accentColor.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 34, height: 34)
                            .overlay(Circle().stroke(Color.appBackground, lineWidth: 2.5))
                    }
                    if group.memberCount > 6 {
                        ZStack {
                            Circle()
                                .fill(Color.secondary.opacity(0.15))
                                .frame(width: 34, height: 34)
                            Text("+\(group.memberCount - 6)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                        .overlay(Circle().stroke(Color.appBackground, lineWidth: 2.5))
                    }
                }

                Text("\(group.memberCount) members")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // ── Join / Joined CTA ─────────────────────────────────────────
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isJoined.toggle()
                }
                HapticManager.medium()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isJoined ? "checkmark.circle.fill" : "person.badge.plus")
                    Text(isJoined ? "Joined" : "Join DinkrGroup")
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.75)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
        }
        .padding(.top, 8)
        .padding(.bottom, 20)
    }
}

// MARK: - DinkrGroup Stat Chip

struct GroupStatChip: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline.weight(.bold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 72)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Helpers

private func groupDetailIcon(for type: GroupType) -> String {
    switch type {
    case .publicClub, .privateClub: return "building.2"
    case .womenOnly:                return "figure.stand"
    case .ageGroup:                 return "person.3"
    case .recreational:             return "figure.pickleball"
    case .competitive:              return "trophy"
    case .neighborhood:             return "house"
    case .corporate:                return "briefcase"
    case .internalLeague:           return "list.bullet.clipboard"
    }
}

private func groupDetailColor(for type: GroupType) -> Color {
    switch type {
    case .publicClub, .privateClub: return Color.dinkrSky
    case .womenOnly:                return .pink
    case .ageGroup:                 return .purple
    case .recreational:             return Color.dinkrGreen
    case .competitive:              return Color.dinkrCoral
    case .neighborhood:             return .teal
    case .corporate:                return Color.dinkrNavy
    case .internalLeague:           return Color.dinkrAmber
    }
}

// MARK: - About This DinkrGroup Section

struct GroupAboutSection: View {
    let group: DinkrGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.dinkrNavy)
                Text("About This DinkrGroup")
                    .font(.headline)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            VStack(spacing: 0) {
                NavigationLink(destination: GroupMilestonesView()) {
                    AboutRow(
                        icon: "trophy.fill",
                        iconColor: Color.dinkrAmber,
                        title: "DinkrGroup Milestones",
                        subtitle: "6 achievements unlocked"
                    )
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.leading, 56)

                NavigationLink(destination: GroupRulesView(showAgreementButton: false)) {
                    AboutRow(
                        icon: "list.bullet.clipboard.fill",
                        iconColor: Color.dinkrNavy,
                        title: "DinkrGroup Rules",
                        subtitle: "8 community rules · Updated Mar 2026"
                    )
                }
                .buttonStyle(.plain)
            }
            .background(Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .padding(.top, 8)
    }
}

// MARK: - About Row

private struct AboutRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
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
                .foregroundStyle(Color.secondary.opacity(0.45))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        GroupDetailView(group: DinkrGroup.mockGroups[0])
    }
}

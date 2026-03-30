import SwiftUI

struct GroupDetailView: View {
    let group: Group
    @State private var selectedTab = 0
    @State private var tabIndicatorOffset: CGFloat = 0
    let tabs = ["Feed", "Members", "Events"]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── Gradient hero header ─────────────────────────────────
                GroupDetailHeader(group: group)

                // ── Custom animated tab selector ─────────────────────────
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        ForEach(tabs.indices, id: \.self) { i in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    selectedTab = i
                                }
                            } label: {
                                VStack(spacing: 5) {
                                    Text(tabs[i])
                                        .font(.subheadline.weight(selectedTab == i ? .bold : .regular))
                                        .foregroundStyle(selectedTab == i ? Color.dinkrGreen : .secondary)
                                        .animation(.easeInOut(duration: 0.2), value: selectedTab)

                                    // Animated indicator pill
                                    Capsule()
                                        .fill(selectedTab == i ? Color.dinkrGreen : Color.clear)
                                        .frame(height: 3)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)

                    Divider()
                }
                .background(Color.appBackground)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

                // ── Tab content ──────────────────────────────────────────
                switch selectedTab {
                case 0:
                    GroupFeedView(group: group)
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
    }
}

// MARK: - Premium Group Detail Header

struct GroupDetailHeader: View {
    let group: Group

    var accentColor: Color { groupDetailColor(for: group.type) }

    var body: some View {
        ZStack(alignment: .bottom) {

            // ── Hero gradient background ─────────────────────────────────
            ZStack(alignment: .topTrailing) {
                LinearGradient(
                    colors: [Color.dinkrNavy, accentColor.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Decorative large icon watermark
                Image(systemName: groupDetailIcon(for: group.type))
                    .font(.system(size: 130, weight: .black))
                    .foregroundStyle(.white.opacity(0.05))
                    .padding(.top, 8)
                    .padding(.trailing, 8)
            }
            .frame(height: 220)

            // Bottom-of-hero vignette
            LinearGradient(
                colors: [.clear, Color.appBackground.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)

            // Activity badge in hero
            HStack {
                Spacer()
                Label("Active", systemImage: "circle.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.dinkrGreen.opacity(0.85))
                    .clipShape(Capsule())
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
            }
        }

        // ── Below-hero content ───────────────────────────────────────────
        VStack(spacing: 16) {

            // Group icon avatar — overlapping the hero
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

            // ── Member avatar stack ──────────────────────────────────────
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
            Button {} label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                    Text("Join Group")
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

// MARK: - Group Stat Chip

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

// MARK: - Helpers (module-level free functions mirroring GroupsView helpers)

private func groupDetailIcon(for type: GroupType) -> String {
    switch type {
    case .publicClub, .privateClub: return "building.2"
    case .womenOnly:                return "figure.stand"
    case .ageGroup:                 return "person.3"
    case .recreational:             return "figure.pickleball"
    case .competitive:              return "trophy"
    case .neighborhood:             return "house"
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
    }
}

#Preview {
    NavigationStack {
        GroupDetailView(group: Group.mockGroups[0])
    }
}

import SwiftUI
import MapKit

// MARK: - GroupDiscoveryView

struct GroupDiscoveryView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var searchText: String = ""
    @State private var selectedCategory: DiscoveryCategory = .all
    @State private var joinedGroupIds: Set<String> = []
    @State private var isRefreshing = false
    @State private var showCreateGroup = false

    // MARK: - Derived data

    private var nearYouGroups: [(group: DinkrGroup, distance: String)] {
        let pairs: [(DinkrGroup, String)] = [
            (DinkrGroup.mockGroups[0], "0.8 mi away"),
            (DinkrGroup.mockGroups[2], "1.2 mi away"),
            (DinkrGroup.mockGroups[3], "2.1 mi away"),
        ]
        return pairs.map { (group: $0.0, distance: $0.1) }
    }

    private var trendingGroups: [(group: DinkrGroup, growth: Int)] {
        let sorted = DinkrGroup.mockGroups.sorted { $0.memberCount > $1.memberCount }
        let growths = [12, 8, 15, 5, 20, 9, 3, 11]
        return sorted.enumerated().map { index, group in
            (group: group, growth: growths[index % growths.count])
        }
    }

    private var suggestedGroups: [DinkrGroup] {
        // Mock "suggested for you" — competitive + recreational first
        DinkrGroup.mockGroups
            .filter { $0.type == .competitive || $0.type == .recreational }
            .sorted { $0.memberCount > $1.memberCount }
    }

    private var filteredGroups: [DinkrGroup] {
        let base: [DinkrGroup]
        if selectedCategory == .all {
            base = DinkrGroup.mockGroups
        } else {
            base = DinkrGroup.mockGroups.filter { selectedCategory.matchesGroupType($0.type) }
        }
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // ── Category filter tabs ──────────────────────────
                        categoryFilterBar
                            .padding(.top, 8)

                        // ── Near You ─────────────────────────────────────
                        if searchText.isEmpty {
                            nearYouSection
                                .padding(.top, 20)

                            Divider()
                                .padding(.horizontal)
                                .padding(.top, 16)

                            // ── Trending This Week ────────────────────────
                            trendingSection
                                .padding(.top, 20)

                            Divider()
                                .padding(.horizontal)
                                .padding(.top, 16)

                            // ── Suggested for You ─────────────────────────
                            suggestedSection
                                .padding(.top, 20)

                            Divider()
                                .padding(.horizontal)
                                .padding(.top, 16)
                        }

                        // ── All / filtered results ────────────────────────
                        allGroupsSection
                            .padding(.top, 20)

                        // bottom padding for floating button
                        Spacer().frame(height: 100)
                    }
                }
                .searchable(text: $searchText, prompt: "Search groups…")
                .refreshable {
                    await refreshData()
                }

                // ── Create a DinkrGroup + floating button ──────────────────────
                createGroupButton
            }
            .navigationTitle("Discover Groups")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
        .sheet(isPresented: $showCreateGroup) {
            CreateGroupView()
        }
    }

    // MARK: - Category filter bar

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DiscoveryCategory.allCases, id: \.self) { cat in
                    DiscoveryCategoryChip(
                        category: cat,
                        isSelected: selectedCategory == cat
                    ) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                            selectedCategory = cat
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Near You section

    private var nearYouSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                icon: "location.fill",
                iconColor: Color.dinkrGreen,
                title: "Near You"
            )
            .padding(.horizontal)

            VStack(spacing: 10) {
                ForEach(nearYouGroups, id: \.group.id) { item in
                    NavigationLink {
                        GroupDetailView(group: item.group)
                    } label: {
                        NearYouDiscoveryCard(
                            group: item.group,
                            distance: item.distance,
                            isJoined: joinedGroupIds.contains(item.group.id)
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                toggleJoin(item.group.id)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Trending section

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🔥 Trending This Week")
                    .font(.title3.weight(.bold))
                Spacer()
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(trendingGroups.prefix(5), id: \.group.id) { item in
                        NavigationLink {
                            GroupDetailView(group: item.group)
                        } label: {
                            TrendingDiscoveryCard(
                                group: item.group,
                                weeklyGrowth: item.growth,
                                isJoined: joinedGroupIds.contains(item.group.id)
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    toggleJoin(item.group.id)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
        }
    }

    // MARK: - Suggested section

    private var suggestedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                icon: "sparkles",
                iconColor: Color.dinkrAmber,
                title: "Suggested for You"
            )
            .padding(.horizontal)

            Text("Based on your 3.5 skill rating")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            VStack(spacing: 10) {
                ForEach(suggestedGroups.prefix(3)) { group in
                    NavigationLink {
                        GroupDetailView(group: group)
                    } label: {
                        DiscoveryGroupCard(
                            group: group,
                            activityLevel: mockActivityLevel(for: group),
                            isJoined: joinedGroupIds.contains(group.id)
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                toggleJoin(group.id)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - All groups section

    private var allGroupsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(searchText.isEmpty ? "All Groups" : "Search Results")
                    .font(.title3.weight(.bold))
                Spacer()
                Text("\(filteredGroups.count) groups")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            if filteredGroups.isEmpty {
                ContentUnavailableView(
                    "No groups found",
                    systemImage: "person.3",
                    description: Text("Try a different filter or search term.")
                )
                .padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(filteredGroups) { group in
                        NavigationLink {
                            GroupDetailView(group: group)
                        } label: {
                            DiscoveryGroupCard(
                                group: group,
                                activityLevel: mockActivityLevel(for: group),
                                isJoined: joinedGroupIds.contains(group.id)
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    toggleJoin(group.id)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Create group floating button

    private var createGroupButton: some View {
        VStack {
            Spacer()
            Button {
                showCreateGroup = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Create a DinkrGroup")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.82)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.dinkrGreen.opacity(0.42), radius: 14, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionHeader(icon: String, iconColor: Color, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(iconColor)
            Text(title)
                .font(.title3.weight(.bold))
            Spacer()
        }
    }

    private func toggleJoin(_ id: String) {
        if joinedGroupIds.contains(id) {
            joinedGroupIds.remove(id)
        } else {
            joinedGroupIds.insert(id)
        }
    }

    private func mockActivityLevel(for group: DinkrGroup) -> GroupActivityLevel {
        switch group.memberCount {
        case 50...: return .veryActive
        case 25..<50: return .active
        default: return .quiet
        }
    }

    private func refreshData() async {
        isRefreshing = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isRefreshing = false
    }
}

// MARK: - Discovery Category

enum DiscoveryCategory: String, CaseIterable {
    case all = "All"
    case competitive = "Competitive"
    case recreational = "Recreational"
    case womens = "Women's"
    case neighborhood = "Neighborhood"
    case corporate = "Corporate"
    case ageGroup = "Age DinkrGroup"

    func matchesGroupType(_ type: GroupType) -> Bool {
        switch self {
        case .all: return true
        case .competitive: return type == .competitive
        case .recreational: return type == .recreational
        case .womens: return type == .womenOnly
        case .neighborhood: return type == .neighborhood
        case .corporate: return type == .corporate
        case .ageGroup: return type == .ageGroup
        }
    }
}

// MARK: - DinkrGroup Activity Level

enum GroupActivityLevel: String {
    case veryActive = "Very Active"
    case active = "Active"
    case quiet = "Quiet"

    var color: Color {
        switch self {
        case .veryActive: return Color.dinkrGreen
        case .active: return Color.dinkrSky
        case .quiet: return Color.dinkrAmber
        }
    }

    var icon: String {
        switch self {
        case .veryActive: return "bolt.fill"
        case .active: return "waveform"
        case .quiet: return "moon.fill"
        }
    }
}

// MARK: - Discovery Category Chip

struct DiscoveryCategoryChip: View {
    let category: DiscoveryCategory
    let isSelected: Bool
    let action: () -> Void

    private var chipColor: Color {
        switch category {
        case .all:          return Color.dinkrGreen
        case .competitive:  return Color.dinkrCoral
        case .recreational: return Color.dinkrGreen
        case .womens:       return .pink
        case .neighborhood: return .teal
        case .corporate:    return Color.dinkrAmber
        case .ageGroup:     return .purple
        }
    }

    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : chipColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? chipColor : chipColor.opacity(0.10))
                .clipShape(Capsule())
                .shadow(color: isSelected ? chipColor.opacity(0.35) : .clear, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Near You Discovery Card (map thumbnail + details)

struct NearYouDiscoveryCard: View {
    let group: DinkrGroup
    let distance: String
    let isJoined: Bool
    let onJoin: () -> Void

    private var accentColor: Color { discoveryGroupTypeColor(for: group.type) }
    private var initial: String { String(group.name.prefix(1)).uppercased() }

    // Mock coordinates offset per group for visual variety
    private var mapRegion: MKCoordinateRegion {
        let offsets: [CLLocationDegrees] = [0.003, -0.005, 0.007]
        let idx = abs(group.id.hashValue) % offsets.count
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: 30.2672 + offsets[idx],
                longitude: -97.7431 + offsets[idx]
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            // Map thumbnail
            ZStack {
                Map(initialPosition: .region(mapRegion))
                    .frame(width: 90)
                    .disabled(true)
                    .allowsHitTesting(false)

                // Pin overlay
                VStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .shadow(color: .white.opacity(0.6), radius: 2)
                    Spacer()
                }
                .padding(.top, 10)
            }
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 18, bottomLeadingRadius: 18,
                bottomTrailingRadius: 0, topTrailingRadius: 0
            ))

            // Details
            VStack(alignment: .leading, spacing: 6) {
                Text(group.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(group.type.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(accentColor.opacity(0.12))
                        .clipShape(Capsule())

                    HStack(spacing: 3) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.dinkrGreen)
                        Text(distance)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.dinkrGreen.opacity(0.10))
                    .clipShape(Capsule())
                }

                HStack(spacing: 12) {
                    Label("\(group.memberCount)", systemImage: "person.2.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button(action: onJoin) {
                        Text(isJoined ? "Joined ✓" : "Join")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(isJoined ? accentColor : .white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(isJoined ? accentColor.opacity(0.12) : accentColor)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: accentColor.opacity(0.12), radius: 8, x: 0, y: 3)
        .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
        .frame(height: 90)
    }
}

// MARK: - Trending Discovery Card

struct TrendingDiscoveryCard: View {
    let group: DinkrGroup
    let weeklyGrowth: Int
    let isJoined: Bool
    let onJoin: () -> Void

    private var accentColor: Color { discoveryGroupTypeColor(for: group.type) }
    private var initial: String { String(group.name.prefix(1)).uppercased() }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header gradient
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [accentColor.opacity(0.85), accentColor.opacity(0.45)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 80)

                // Large faint initial
                Text(initial)
                    .font(.system(size: 72, weight: .black))
                    .foregroundStyle(.white.opacity(0.12))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.trailing, 8)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 3) {
                        // Growth badge
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(.white)
                            Text("+\(weeklyGrowth) this week")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.22))
                        .clipShape(Capsule())
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                }
            }
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 18, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: 18
            ))

            // Body
            VStack(alignment: .leading, spacing: 8) {
                Text(group.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    Text(group.type.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(accentColor.opacity(0.12))
                        .clipShape(Capsule())

                    Spacer()
                }

                HStack {
                    Label("\(group.memberCount) members", systemImage: "person.2.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button(action: onJoin) {
                        Text(isJoined ? "Joined" : "Join")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(isJoined ? accentColor : .white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(isJoined ? accentColor.opacity(0.12) : accentColor)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(Color.cardBackground)
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: 18,
                bottomTrailingRadius: 18, topTrailingRadius: 0
            ))
        }
        .frame(width: 210)
        .shadow(color: accentColor.opacity(0.14), radius: 10, x: 0, y: 4)
        .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Discovery DinkrGroup Card (used in Suggested + All)

struct DiscoveryGroupCard: View {
    let group: DinkrGroup
    let activityLevel: GroupActivityLevel
    let isJoined: Bool
    let onJoin: () -> Void

    private var accentColor: Color { discoveryGroupTypeColor(for: group.type) }
    private var initial: String { String(group.name.prefix(1)).uppercased() }

    var body: some View {
        HStack(spacing: 14) {
            // Circle icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                Text(initial)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(group.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    if group.isPrivate {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 6) {
                    // Type badge
                    Text(group.type.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(accentColor.opacity(0.12))
                        .clipShape(Capsule())

                    // Activity level badge
                    HStack(spacing: 3) {
                        Image(systemName: activityLevel.icon)
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(activityLevel.color)
                        Text(activityLevel.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(activityLevel.color)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(activityLevel.color.opacity(0.10))
                    .clipShape(Capsule())
                }

                Label("\(group.memberCount) members", systemImage: "person.2.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onJoin) {
                Text(isJoined ? "Joined" : "Join")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isJoined ? accentColor : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(isJoined ? accentColor.opacity(0.12) : accentColor)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: accentColor.opacity(0.10), radius: 6, x: 0, y: 2)
        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Helper: group type color (mirrors GroupsView, scoped to this file)

private func discoveryGroupTypeColor(for type: GroupType) -> Color {
    switch type {
    case .publicClub, .privateClub: return Color.dinkrSky
    case .womenOnly:                return .pink
    case .ageGroup:                 return .purple
    case .recreational:             return Color.dinkrGreen
    case .competitive:              return Color.dinkrCoral
    case .neighborhood:             return .teal
    case .corporate:                return Color.dinkrAmber
    case .internalLeague:           return Color.dinkrNavy
    }
}

// MARK: - Preview

#Preview {
    GroupDiscoveryView()
}

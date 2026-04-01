import SwiftUI
import FirebaseFirestore

// MARK: - GroupsView

struct GroupsView: View {
    @State private var viewModel = GroupsViewModel()
    @Environment(AuthService.self) private var authService
    @State private var selectedType: GroupType? = nil
    @State private var searchText: String = ""
    @State private var joinedGroupIds: Set<String> = []
    @State private var showDiscovery = false

    // Category filter options as display strings mapped to GroupType
    private let filterChips: [(label: String, type: GroupType?)] = [
        ("All", nil),
        ("Competitive", .competitive),
        ("Recreational", .recreational),
        ("Women's", .womenOnly),
        ("Corporate", .corporate),
        ("Neighborhood", .neighborhood),
    ]

    var myGroupIds: Set<String> {
        Set(viewModel.myGroups.map(\.id))
    }

    var discoverGroups: [DinkrGroup] {
        let base = viewModel.discoverGroups.filter { !myGroupIds.contains($0.id) }
        let typed: [DinkrGroup]
        if let type = selectedType {
            typed = base.filter { $0.type == type }
        } else {
            typed = base
        }
        if searchText.isEmpty { return typed }
        return typed.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var trendingGroups: [DinkrGroup] {
        // Pick 3 from discover with highest member count as proxy for trending
        let sorted = viewModel.discoverGroups
            .filter { !myGroupIds.contains($0.id) }
            .sorted { $0.memberCount > $1.memberCount }
        return Array(sorted.prefix(3))
    }

    var nearYouGroups: [DinkrGroup] {
        // Pick 3 neighborhood/recreational groups as "near you" proxies
        let candidates = viewModel.discoverGroups
            .filter { !myGroupIds.contains($0.id) }
            .filter { $0.type == .neighborhood || $0.type == .recreational }
        return Array(candidates.prefix(3))
    }

    var featuredGroup: DinkrGroup? {
        viewModel.discoverGroups.first { !myGroupIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── My Groups horizontal scroll ───────────────────────
                    if !viewModel.myGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("My Groups")
                                .font(.title3.weight(.bold))
                                .padding(.horizontal)
                                .padding(.top, 16)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.myGroups) { group in
                                        NavigationLink {
                                            GroupDetailView(group: group)
                                        } label: {
                                            MyGroupSquareCard(group: group)
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    // Discover CTA card
                                    Button {
                                        showDiscovery = true
                                    } label: {
                                        DiscoverMoreCard()
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 4)
                            }
                        }

                        Divider()
                            .padding(.top, 12)
                    }

                    // ── Trending This Week ────────────────────────────────
                    if !trendingGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(Color.dinkrCoral)
                                Text("Trending")
                                    .font(.title3.weight(.bold))
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 18)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(trendingGroups) { group in
                                        NavigationLink {
                                            GroupDetailView(group: group)
                                        } label: {
                                            TrendingGroupCard(group: group)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 4)
                            }
                        }

                        Divider()
                            .padding(.top, 12)
                    }

                    // ── Near You ─────────────────────────────────────────
                    if !nearYouGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("Near You", systemImage: "location.fill")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 18)

                            ForEach(Array(nearYouGroups.enumerated()), id: \.element.id) { index, group in
                                let distances = ["0.8 mi away", "1.2 mi away", "2.1 mi away"]
                                let distance = distances[index % distances.count]
                                NavigationLink {
                                    GroupDetailView(group: group)
                                } label: {
                                    NearYouGroupRow(group: group, distance: distance)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Divider()
                            .padding(.top, 12)
                    }

                    // ── Featured DinkrGroup Hero ───────────────────────────────
                    if let featured = featuredGroup {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Featured DinkrGroup")
                                    .font(.title3.weight(.bold))
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 18)

                            NavigationLink {
                                GroupDetailView(group: featured)
                            } label: {
                                FeaturedGroupHeroCard(
                                    group: featured,
                                    isJoined: joinedGroupIds.contains(featured.id)
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        toggleJoin(featured.id)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .buttonStyle(.plain)
                        }

                        Divider()
                            .padding(.top, 12)
                    }

                    // ── Discover Groups ───────────────────────────────────
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("Discover Groups")
                                .font(.title3.weight(.bold))
                            Spacer()
                            Button {
                                showDiscovery = true
                            } label: {
                                Text("See all →")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.dinkrGreen)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                        .padding(.top, 18)
                        .padding(.bottom, 4)

                        // Category filter chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(filterChips, id: \.label) { chip in
                                    GroupFilterChip(
                                        label: chip.label,
                                        isSelected: selectedType == chip.type,
                                        color: chip.type.map { groupTypeColor(for: $0) } ?? Color.dinkrGreen
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedType = chip.type
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }

                        if discoverGroups.isEmpty {
                            ContentUnavailableView(
                                "No groups found",
                                systemImage: "person.3",
                                description: Text("Try a different filter or search term.")
                            )
                            .padding(.vertical, 32)
                        } else {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(discoverGroups) { group in
                                    NavigationLink {
                                        GroupDetailView(group: group)
                                    } label: {
                                        DiscoverGroupRow(
                                            group: group,
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
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search groups")
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        // Discover button
                        Button {
                            showDiscovery = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "compass.drawing")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Discover")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(Color.dinkrGreen)
                        }

                        // Create group button
                        Button {
                            viewModel.showCreateGroup = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .tint(Color.dinkrGreen)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showCreateGroup) {
            CreateGroupView()
        }
        .sheet(isPresented: $showDiscovery) {
            GroupDiscoveryView()
        }
        .task { await viewModel.load(currentUserId: authService.currentUser?.id) }
    }

    private func toggleJoin(_ id: String) {
        guard let uid = authService.currentUser?.id else { return }
        if joinedGroupIds.contains(id) {
            joinedGroupIds.remove(id)
        } else {
            joinedGroupIds.insert(id)
        }
        let isJoining = joinedGroupIds.contains(id)
        Task {
            try? await FirestoreService.shared.updateDocument(
                collection: FirestoreCollections.groups,
                documentId: id,
                data: [
                    "memberIds": isJoining
                        ? FirebaseFirestore.FieldValue.arrayUnion([uid])
                        : FirebaseFirestore.FieldValue.arrayRemove([uid]),
                    "memberCount": isJoining
                        ? FirebaseFirestore.FieldValue.increment(Int64(1))
                        : FirebaseFirestore.FieldValue.increment(Int64(-1))
                ]
            )
        }
    }
}

// MARK: - My DinkrGroup Square Card (130x130)

struct MyGroupSquareCard: View {
    let group: DinkrGroup

    var accentColor: Color { groupTypeColor(for: group.type) }
    var initial: String { String(group.name.prefix(1)).uppercased() }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.15))
                    .frame(width: 60, height: 60)

                Text(initial)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.dinkrGreen)
            }

            Text(group.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)

            Label("\(group.memberCount)", systemImage: "person.2.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(width: 130, height: 130)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Discover More Card

struct DiscoverMoreCard: View {
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.12))
                    .frame(width: 60, height: 60)

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.dinkrGreen)
            }

            Text("Discover")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.dinkrGreen)

            Text("Find more")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(width: 130, height: 130)
        .background(Color.dinkrGreen.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Trending DinkrGroup Card

struct TrendingGroupCard: View {
    let group: DinkrGroup

    var accentColor: Color { groupTypeColor(for: group.type) }
    var activityCount: Int { max(4, group.memberCount / 3) }
    var initial: String { String(group.name.prefix(1)).uppercased() }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.dinkrGreen.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Text(initial)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.dinkrGreen)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .foregroundStyle(.primary)

                    Text(group.type.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(accentColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
                Text("\(activityCount) posts this week")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Label("\(group.memberCount) members", systemImage: "person.2.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(width: 200)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Near You DinkrGroup Row

struct NearYouGroupRow: View {
    let group: DinkrGroup
    let distance: String

    var accentColor: Color { groupTypeColor(for: group.type) }
    var initial: String { String(group.name.prefix(1)).uppercased() }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.15))
                    .frame(width: 48, height: 48)

                Text(initial)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.dinkrGreen)
            }

            VStack(alignment: .leading, spacing: 4) {
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

                Label("\(group.memberCount) members", systemImage: "person.2.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Featured DinkrGroup Hero Card

struct FeaturedGroupHeroCard: View {
    let group: DinkrGroup
    let isJoined: Bool
    let onJoin: () -> Void

    var accentColor: Color { groupTypeColor(for: group.type) }
    var initial: String { String(group.name.prefix(1)).uppercased() }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient background
            LinearGradient(
                colors: [accentColor, accentColor.opacity(0.55), Color.dinkrNavy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 22))

            // Content overlay
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("FEATURED")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.white.opacity(0.18))
                            .clipShape(Capsule())

                        if group.isPrivate {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }

                    Text(group.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(group.description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.80))
                        .lineLimit(2)

                    Label("\(group.memberCount) members", systemImage: "person.2.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }

                Spacer()

                // Join CTA
                Button(action: onJoin) {
                    Text(isJoined ? "Joined" : "Join")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isJoined ? accentColor : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(isJoined ? .white : .white.opacity(0.22))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().strokeBorder(.white.opacity(isJoined ? 0 : 0.45), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(18)
        }
        .frame(height: 200)
    }
}

// MARK: - Discover DinkrGroup Row

struct DiscoverGroupRow: View {
    let group: DinkrGroup
    let isJoined: Bool
    let onJoin: () -> Void

    var accentColor: Color { groupTypeColor(for: group.type) }
    var initial: String { String(group.name.prefix(1)).uppercased() }

    var body: some View {
        HStack(spacing: 14) {
            // Colored initial circle icon
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.15))
                    .frame(width: 50, height: 50)

                Text(initial)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(Color.dinkrGreen)
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

                // Type badge
                Text(group.type.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(accentColor.opacity(0.12))
                    .clipShape(Capsule())

                Label("\(group.memberCount) members", systemImage: "person.2.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Join button
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
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - DinkrGroup Filter Chip

struct GroupFilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = Color.dinkrGreen
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected
                    ? color
                    : color.opacity(0.10)
                )
                .clipShape(Capsule())
                .shadow(color: isSelected ? color.opacity(0.35) : .clear, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Helpers

private func groupTypeIcon(for type: GroupType) -> String {
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

private func groupTypeColor(for type: GroupType) -> Color {
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

// Keep old aliases for backward compat
typealias GroupRowCard = DiscoverGroupRow
typealias EnhancedGroupRowCard = DiscoverGroupRow
typealias PremiumGroupCard = DiscoverGroupRow
typealias PremiumGroupHero = FeaturedGroupHeroCard
typealias FeaturedGroupHero = FeaturedGroupHeroCard

#Preview {
    GroupsView()
}

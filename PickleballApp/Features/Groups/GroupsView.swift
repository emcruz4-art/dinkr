import SwiftUI

struct GroupsView: View {
    @State private var viewModel = GroupsViewModel()
    @State private var selectedType: GroupType? = nil

    var filteredDiscover: [Group] {
        if let type = selectedType {
            return viewModel.discoverGroups.filter { $0.type == type }
        }
        return viewModel.discoverGroups
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Featured group hero ──────────────────────────────
                    if let featured = viewModel.discoverGroups.first {
                        NavigationLink {
                            GroupDetailView(group: featured)
                        } label: {
                            PremiumGroupHero(group: featured)
                                .padding(.horizontal)
                                .padding(.top, 12)
                        }
                        .buttonStyle(.plain)
                    }

                    // ── Category filter chips ────────────────────────────
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            GroupFilterChip(
                                label: "All",
                                isSelected: selectedType == nil,
                                color: Color.dinkrGreen
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedType = nil
                                }
                            }
                            ForEach(GroupType.allCases, id: \.self) { type in
                                GroupFilterChip(
                                    label: type.rawValue,
                                    isSelected: selectedType == type,
                                    color: groupTypeColor(for: type)
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedType = selectedType == type ? nil : type
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }

                    Divider()

                    LazyVStack(alignment: .leading, spacing: 14) {
                        if !viewModel.myGroups.isEmpty {
                            Text("My Groups")
                                .sectionHeader()
                                .padding(.top, 14)
                            ForEach(viewModel.myGroups) { group in
                                NavigationLink {
                                    GroupDetailView(group: group)
                                } label: {
                                    PremiumGroupCard(group: group, isJoined: true)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack {
                            Text("Discover")
                                .font(.title3.weight(.bold))
                            Spacer()
                            Text("See all →")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.dinkrGreen)
                        }
                        .padding(.horizontal)
                        .padding(.top, 14)

                        ForEach(filteredDiscover) { group in
                            NavigationLink {
                                GroupDetailView(group: group)
                            } label: {
                                PremiumGroupCard(group: group, isJoined: false)
                                    .padding(.horizontal)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showCreateGroup = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .tint(Color.dinkrGreen)
                }
            }
        }
        .sheet(isPresented: $viewModel.showCreateGroup) {
            CreateGroupView()
        }
        .task { await viewModel.load() }
    }
}

// MARK: - Premium Featured Hero

struct PremiumGroupHero: View {
    let group: Group

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient background
            LinearGradient(
                colors: [
                    groupTypeColor(for: group.type),
                    Color.dinkrNavy
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 22))

            // Decorative icon (large, faint)
            Image(systemName: groupTypeIcon(for: group.type))
                .font(.system(size: 90, weight: .black))
                .foregroundStyle(.white.opacity(0.07))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.trailing, 16)
                .padding(.top, 10)

            // Vignette
            LinearGradient(
                colors: [.clear, .black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))

            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("FEATURED GROUP")
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

                HStack(spacing: 12) {
                    Label("\(group.memberCount) members", systemImage: "person.2.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))

                    Text("·")
                        .foregroundStyle(.white.opacity(0.5))

                    Text(group.type.rawValue)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                // Overlapping member bubbles
                HStack(spacing: -7) {
                    ForEach(0..<min(5, max(0, group.memberCount)), id: \.self) { i in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [groupTypeColor(for: group.type).opacity(0.5 + Double(i) * 0.1), .white.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 26, height: 26)
                            .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1.5))
                    }
                    if group.memberCount > 5 {
                        Text("+\(group.memberCount - 5)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(.white.opacity(0.25))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1.5))
                    }
                }
                .padding(.top, 2)
            }
            .padding(16)
        }
        .frame(height: 170)
    }
}

// MARK: - Premium Group Card

struct PremiumGroupCard: View {
    let group: Group
    let isJoined: Bool

    var accentColor: Color { groupTypeColor(for: group.type) }

    var body: some View {
        ZStack(alignment: .leading) {
            // Card background
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.cardBackground)

            // Left accent strip
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(accentColor)
                    .frame(width: 4)
                    .padding(.vertical, 14)
                    .padding(.leading, 8)
                Spacer()
            }

            // Content
            HStack(spacing: 14) {
                // Icon block
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.18), accentColor.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)
                    Image(systemName: groupTypeIcon(for: group.type))
                        .foregroundStyle(accentColor)
                        .font(.system(size: 22, weight: .medium))
                }
                .padding(.leading, 20)

                VStack(alignment: .leading, spacing: 5) {
                    // Name + lock
                    HStack(spacing: 6) {
                        Text(group.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        if group.isPrivate {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Type pill + activity
                    HStack(spacing: 6) {
                        Text(group.type.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(accentColor.opacity(0.12))
                            .clipShape(Capsule())

                        Text(activityText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Member avatar stack + count
                    HStack(spacing: -6) {
                        ForEach(0..<min(4, max(0, group.memberCount)), id: \.self) { i in
                            Circle()
                                .fill(accentColor.opacity(0.25 + Double(i) * 0.12))
                                .frame(width: 20, height: 20)
                                .overlay(Circle().stroke(Color.cardBackground, lineWidth: 1.5))
                        }
                        if group.memberCount > 4 {
                            ZStack {
                                Circle()
                                    .fill(Color.secondary.opacity(0.15))
                                    .frame(width: 20, height: 20)
                                Text("+\(group.memberCount - 4)")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(.secondary)
                            }
                            .overlay(Circle().stroke(Color.cardBackground, lineWidth: 1.5))
                        }
                        Text("\(group.memberCount) members")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 10)
                    }
                }

                Spacer()

                // Join / Joined button
                VStack(spacing: 4) {
                    if isJoined {
                        Text("Joined")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(accentColor.opacity(0.12))
                            .clipShape(Capsule())
                    } else {
                        Text("Join")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(accentColor)
                            .clipShape(Capsule())
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.trailing, 14)
            }
            .padding(.vertical, 14)
        }
        .shadow(color: accentColor.opacity(0.12), radius: 8, x: 0, y: 3)
        .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
    }

    var activityText: String {
        let seed = group.memberCount % 5
        switch seed {
        case 0: return "Last active 1h ago"
        case 1: return "12 posts this week"
        case 2: return "Active daily"
        case 3: return "8 posts this week"
        default: return "Last active 2h ago"
        }
    }
}

// MARK: - Group Filter Chip

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

// MARK: - Helpers (file-private free functions)

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
typealias GroupRowCard = PremiumGroupCard
typealias EnhancedGroupRowCard = PremiumGroupCard
typealias FeaturedGroupHero = PremiumGroupHero

#Preview {
    GroupsView()
}

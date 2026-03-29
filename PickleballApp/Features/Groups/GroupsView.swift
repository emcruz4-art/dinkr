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
                    // Featured group hero
                    if let featured = viewModel.discoverGroups.first {
                        NavigationLink {
                            GroupDetailView(group: featured)
                        } label: {
                            FeaturedGroupHero(group: featured)
                                .padding(.horizontal)
                                .padding(.top, 12)
                        }
                        .buttonStyle(.plain)
                    }

                    // Category filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: selectedType == nil, color: Color.dinkrGreen) {
                                selectedType = nil
                            }
                            ForEach(GroupType.allCases, id: \.self) { type in
                                FilterChip(label: type.rawValue, isSelected: selectedType == type, color: Color.dinkrGreen) {
                                    selectedType = selectedType == type ? nil : type
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }

                    Divider()

                    LazyVStack(alignment: .leading, spacing: 16) {
                        if !viewModel.myGroups.isEmpty {
                            Text("My Groups").sectionHeader()
                                .padding(.top, 12)
                            ForEach(viewModel.myGroups) { group in
                                NavigationLink {
                                    GroupDetailView(group: group)
                                } label: {
                                    EnhancedGroupRowCard(group: group)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Text("Discover").sectionHeader()
                            .padding(.top, 8)
                        ForEach(filteredDiscover) { group in
                            NavigationLink {
                                GroupDetailView(group: group)
                            } label: {
                                EnhancedGroupRowCard(group: group)
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

struct FeaturedGroupHero: View {
    let group: Group

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color.dinkrNavy, Color.dinkrGreen.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(alignment: .leading, spacing: 6) {
                Text("FEATURED GROUP")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.8))
                Text(group.name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                HStack(spacing: 8) {
                    Text(group.type.rawValue)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                    Text("·")
                        .foregroundStyle(.white.opacity(0.5))
                    Text("\(group.memberCount) members")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(16)
        }
    }
}

struct EnhancedGroupRowCard: View {
    let group: Group

    var body: some View {
        PickleballCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(groupTypeColor.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: groupTypeIcon)
                        .foregroundStyle(groupTypeColor)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(group.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                        if group.isPrivate {
                            Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    Text(group.type.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Member avatar row
                    HStack(spacing: -6) {
                        ForEach(0..<min(4, group.memberCount), id: \.self) { i in
                            Circle()
                                .fill(Color.dinkrGreen.opacity(0.3 + Double(i) * 0.1))
                                .frame(width: 20, height: 20)
                                .overlay(Circle().stroke(Color.appBackground, lineWidth: 1.5))
                        }
                        if group.memberCount > 4 {
                            Circle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Text("+\(group.memberCount - 4)")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundStyle(.secondary)
                                )
                                .overlay(Circle().stroke(Color.appBackground, lineWidth: 1.5))
                        }
                        Text("\(group.memberCount) members")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 10)
                    }
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
        }
    }

    var groupTypeIcon: String {
        switch group.type {
        case .publicClub, .privateClub: return "building.2"
        case .womenOnly: return "figure.stand"
        case .ageGroup: return "person.3"
        case .recreational: return "figure.pickleball"
        case .competitive: return "trophy"
        case .neighborhood: return "house"
        }
    }

    var groupTypeColor: Color {
        switch group.type {
        case .publicClub, .privateClub: return Color.dinkrSky
        case .womenOnly: return .pink
        case .ageGroup: return .purple
        case .recreational: return Color.dinkrGreen
        case .competitive: return Color.dinkrCoral
        case .neighborhood: return .teal
        }
    }
}

// Keep old GroupRowCard as alias for backward compat
typealias GroupRowCard = EnhancedGroupRowCard

#Preview {
    GroupsView()
}

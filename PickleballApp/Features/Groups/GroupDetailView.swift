import SwiftUI

struct GroupDetailView: View {
    let group: Group
    @State private var selectedTab = 0
    let tabs = ["Feed", "Members", "Events"]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero header
                GroupDetailHeader(group: group)

                // Tab bar
                HStack(spacing: 0) {
                    ForEach(tabs.indices, id: \.self) { i in
                        Button {
                            selectedTab = i
                        } label: {
                            VStack(spacing: 4) {
                                Text(tabs[i])
                                    .font(.subheadline.weight(selectedTab == i ? .bold : .regular))
                                    .foregroundStyle(selectedTab == i ? Color.dinkrGreen : .secondary)
                                Rectangle()
                                    .fill(selectedTab == i ? Color.dinkrGreen : Color.clear)
                                    .frame(height: 2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                Divider()

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

struct GroupDetailHeader: View {
    let group: Group

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(groupColor.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: groupIcon)
                    .foregroundStyle(groupColor)
                    .font(.largeTitle)
            }

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text(group.name).font(.title2.weight(.bold))
                    if group.isPrivate {
                        Image(systemName: "lock.fill").foregroundStyle(.secondary)
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
                        .padding(.horizontal, 32)
                }
            }

            // Stats row
            HStack(spacing: 40) {
                StatColumn(value: "\(group.memberCount)", label: "Members")
                StatColumn(value: group.isPrivate ? "Private" : "Public", label: "Access")
                StatColumn(value: "Active", label: "Status")
            }

            // Member avatar row preview
            HStack(spacing: -8) {
                ForEach(0..<min(5, group.memberCount), id: \.self) { i in
                    Circle()
                        .fill(Color.dinkrGreen.opacity(0.2 + Double(i) * 0.08))
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(Color.appBackground, lineWidth: 2))
                }
                if group.memberCount > 5 {
                    Circle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("+\(group.memberCount - 5)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.secondary)
                        )
                        .overlay(Circle().stroke(Color.appBackground, lineWidth: 2))
                }
            }

            Button {} label: {
                Text("Join Group")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.dinkrGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)
        }
        .padding()
    }

    var groupIcon: String {
        switch group.type {
        case .publicClub, .privateClub: return "building.2"
        case .womenOnly: return "figure.stand"
        case .ageGroup: return "person.3"
        case .recreational: return "figure.pickleball"
        case .competitive: return "trophy"
        case .neighborhood: return "house"
        }
    }

    var groupColor: Color {
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

#Preview {
    NavigationStack {
        GroupDetailView(group: Group.mockGroups[0])
    }
}

import SwiftUI

struct GroupMembersView: View {
    let group: Group
    let members: [User] = User.mockPlayers

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(members) { member in
                    VStack(spacing: 8) {
                        AvatarView(urlString: member.avatarURL, displayName: member.displayName, size: 60)
                        Text(member.displayName.components(separatedBy: " ").first ?? member.displayName)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                        SkillBadge(level: member.skillLevel)
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
                }
            }
            .padding()
        }
        .navigationTitle("Members")
    }
}

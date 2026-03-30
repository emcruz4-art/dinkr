import SwiftUI

struct TaggedUsersRow: View {
    let taggedIds: [String]
    var allUsers: [User] = User.mockPlayers + [User.mockCurrentUser]

    var taggedUsers: [User] {
        taggedIds.compactMap { id in allUsers.first { $0.id == id } }
    }

    var body: some View {
        if !taggedUsers.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ForEach(taggedUsers) { user in
                        HStack(spacing: 4) {
                            AvatarView(urlString: user.avatarURL, displayName: user.displayName, size: 18)
                            Text(user.displayName.components(separatedBy: " ").first ?? user.displayName)
                                .font(.caption2.weight(.semibold))
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.dinkrGreen.opacity(0.1), in: Capsule())
                        .overlay(Capsule().stroke(Color.dinkrGreen.opacity(0.25), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
}

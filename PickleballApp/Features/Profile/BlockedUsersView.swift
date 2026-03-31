import SwiftUI

// MARK: - BlockedUsersView

struct BlockedUsersView: View {
    @State private var blockedUsers: [User] = Array(User.mockPlayers.prefix(3))
    @State private var userPendingUnblock: User? = nil
    @State private var showUnblockAlert = false

    var body: some View {
        ZStack {
            if blockedUsers.isEmpty {
                emptyState
            } else {
                blockedList
            }
        }
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.large)
        .alert("Unblock \(userPendingUnblock?.displayName ?? "this user")?", isPresented: $showUnblockAlert) {
            Button("Unblock", role: .destructive) {
                if let user = userPendingUnblock {
                    withAnimation {
                        blockedUsers.removeAll { $0.id == user.id }
                    }
                }
                userPendingUnblock = nil
            }
            Button("Cancel", role: .cancel) {
                userPendingUnblock = nil
            }
        } message: {
            Text("They'll be able to find your profile and contact you again.")
        }
    }

    // MARK: - Blocked List

    private var blockedList: some View {
        List {
            ForEach(blockedUsers) { user in
                BlockedUserRow(user: user) {
                    userPendingUnblock = user
                    showUnblockAlert = true
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.slash")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.secondary.opacity(0.5))
            Text("You haven't blocked anyone")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Blocked users won't be able to see your profile or interact with your posts.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - BlockedUserRow

private struct BlockedUserRow: View {
    let user: User
    let onUnblock: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(urlString: user.avatarURL, displayName: user.displayName, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.subheadline.weight(.semibold))
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onUnblock) {
                Text("Unblock")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BlockedUsersView()
    }
}

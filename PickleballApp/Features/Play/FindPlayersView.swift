import SwiftUI

struct FindPlayersView: View {
    let players: [User]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if players.isEmpty {
                    EmptyStateView(
                        icon: "person.2",
                        title: "No Players Found",
                        message: "Players in your area will appear here."
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(players) { player in
                        PlayerCardView(player: player)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct PlayerCardView: View {
    let player: User

    var body: some View {
        PickleballCard {
            HStack(spacing: 14) {
                AvatarView(urlString: player.avatarURL, displayName: player.displayName, size: 52)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(player.displayName)
                            .font(.subheadline.weight(.semibold))
                        SkillBadge(level: player.skillLevel, compact: true)
                    }
                    Text(player.city)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        Label("\(player.gamesPlayed) games", systemImage: "figure.pickleball")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Label(String(format: "%.0f%%", player.winRate * 100) + " wins", systemImage: "trophy")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button("Connect") {}
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.pickleballGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.pickleballGreen.opacity(0.1), in: Capsule())
            }
            .padding(14)
        }
    }
}

#Preview {
    FindPlayersView(players: [User.mockCurrentUser])
        .padding()
}

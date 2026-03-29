import SwiftUI

struct ExploreSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "safari.fill")
                    .foregroundStyle(Color.dinkrCoral)
                Text("EXPLORE & TRENDING")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("See all →")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrCoral)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)

            // Trending Drills
            VStack(alignment: .leading, spacing: 6) {
                Text("🔥 Trending Drill Challenges")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 14)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(DrillChallenge.mockChallenges) { challenge in
                            DrillChallengeCard(challenge: challenge)
                        }
                    }
                    .padding(.horizontal, 14)
                }
            }

            Divider().padding(.horizontal, 14)

            // Trending hashtags
            VStack(alignment: .leading, spacing: 8) {
                Text("📈 Trending Topics")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 14)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["#austintx", "#dinklife", "#pickleballchallenge", "#4point0", "#womenspicleball", "#dinkr", "#kitchenmagic", "#openplay"], id: \.self) { tag in
                            Text(tag)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.dinkrSky)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.dinkrSky.opacity(0.10))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 14)
                }
            }

            Divider().padding(.horizontal, 14)

            // Top Players Near You
            VStack(alignment: .leading, spacing: 8) {
                Text("⭐ Top Players Near You")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 14)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(User.mockPlayers.prefix(5)) { player in
                            TopPlayerCard(player: player)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                }
            }
            .padding(.bottom, 14)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct DrillChallenge: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let participants: Int
    let difficulty: String
    let color: Color
}

extension DrillChallenge {
    static let mockChallenges: [DrillChallenge] = [
        DrillChallenge(id: "d1", name: "50 Dinks in a Row", emoji: "🏓", participants: 2847, difficulty: "Medium", color: Color.dinkrGreen),
        DrillChallenge(id: "d2", name: "Kitchen Dominator", emoji: "👨‍🍳", participants: 1923, difficulty: "Hard", color: Color.dinkrCoral),
        DrillChallenge(id: "d3", name: "Third Shot Drop", emoji: "🎯", participants: 3412, difficulty: "Hard", color: Color.dinkrAmber),
        DrillChallenge(id: "d4", name: "Speed Dink Rally", emoji: "⚡", participants: 1456, difficulty: "Easy", color: Color.dinkrSky),
        DrillChallenge(id: "d5", name: "Erne Master", emoji: "🦅", participants: 876, difficulty: "Pro", color: .purple),
    ]
}

struct DrillChallengeCard: View {
    let challenge: DrillChallenge

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(challenge.color.opacity(0.12))
                    .frame(width: 120, height: 80)
                Text(challenge.emoji)
                    .font(.system(size: 36))
            }
            Text(challenge.name)
                .font(.caption.weight(.bold))
                .lineLimit(2)
                .frame(width: 120, alignment: .leading)
            HStack(spacing: 4) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                Text("\(challenge.participants.formatted()) joined")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            Text(challenge.difficulty)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(challenge.color)
                .clipShape(Capsule())
        }
        .frame(width: 120)
    }
}

struct TopPlayerCard: View {
    let player: User

    var body: some View {
        VStack(spacing: 6) {
            AvatarView(displayName: player.displayName, size: 52)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(colors: [Color.dinkrGreen, Color.dinkrAmber], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 2
                        )
                )
            Text(player.displayName.components(separatedBy: " ").first ?? "")
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .frame(width: 60)
            SkillBadge(level: player.skillLevel)
        }
    }
}

import SwiftUI

struct AchievementsView: View {
    var user: User = User.mockCurrentUser
    var gameResults: [GameResult] = GameResult.mockResults

    struct Achievement: Identifiable {
        let id: String
        let icon: String
        let name: String
        let description: String
        let isUnlocked: Bool
        let unlockedAt: Date?
    }

    private var currentWinStreak: Int {
        var streak = 0
        for result in gameResults.sorted(by: { $0.playedAt > $1.playedAt }) {
            if result.isWin { streak += 1 } else { break }
        }
        return streak
    }

    private var uniqueCourts: Int {
        Set(gameResults.map { $0.courtName }).count
    }

    var achievements: [Achievement] {
        [
            Achievement(id: "a1", icon: "figure.pickleball", name: "First Dink",
                        description: "Play your first game on Dinkr",
                        isUnlocked: user.gamesPlayed >= 1,
                        unlockedAt: user.gamesPlayed >= 1 ? user.joinedDate : nil),
            Achievement(id: "a2", icon: "trophy.fill", name: "Tournament Victor",
                        description: "Win a tournament event",
                        isUnlocked: user.badges.contains(where: { $0.type == .tournamentWinner }),
                        unlockedAt: user.badges.first(where: { $0.type == .tournamentWinner })?.earnedAt),
            Achievement(id: "a3", icon: "person.3.fill", name: "Community Pillar",
                        description: "Join 3 or more groups",
                        isUnlocked: user.clubIds.count >= 2,
                        unlockedAt: user.clubIds.count >= 2 ? user.joinedDate : nil),
            Achievement(id: "a4", icon: "star.fill", name: "Reliable Pro",
                        description: "Maintain a 4.8+ reliability score over 50 games",
                        isUnlocked: user.reliabilityScore >= 4.8 && user.gamesPlayed >= 50,
                        unlockedAt: user.reliabilityScore >= 4.8 ? user.joinedDate : nil),
            Achievement(id: "a5", icon: "100.circle.fill", name: "Centurion",
                        description: "Play 100 games on Dinkr",
                        isUnlocked: user.gamesPlayed >= 100,
                        unlockedAt: nil),
            Achievement(id: "a6", icon: "flame.fill", name: "On Fire",
                        description: "Win 5 games in a row",
                        isUnlocked: currentWinStreak >= 5,
                        unlockedAt: nil),
            Achievement(id: "a7", icon: "graduationcap.fill", name: "Level Master",
                        description: "Reach Level 10",
                        isUnlocked: user.gamesPlayed >= 300,
                        unlockedAt: nil),
            Achievement(id: "a8", icon: "heart.fill", name: "Court Regular",
                        description: "Play at 10 different courts",
                        isUnlocked: uniqueCourts >= 10,
                        unlockedAt: nil),
            Achievement(id: "a9", icon: "globe", name: "Social Butterfly",
                        description: "Follow 20 players",
                        isUnlocked: user.followingCount >= 20,
                        unlockedAt: nil),
            Achievement(id: "a10", icon: "calendar.badge.checkmark", name: "Consistent Player",
                        description: "Play at least once per week for 4 weeks",
                        isUnlocked: user.gamesPlayed >= 4,
                        unlockedAt: nil),
            Achievement(id: "a11", icon: "crown.fill", name: "Dinkr Champion",
                        description: "Reach #1 on your local leaderboard",
                        isUnlocked: user.followersCount >= 500,
                        unlockedAt: nil),
            Achievement(id: "a12", icon: "sparkles", name: "Legend",
                        description: "Play 500 games on Dinkr",
                        isUnlocked: user.gamesPlayed >= 500,
                        unlockedAt: nil),
        ]
    }

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var unlockedCount: Int { achievements.filter { $0.isUnlocked }.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Progress header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(unlockedCount) of \(achievements.count) unlocked")
                            .font(.headline.weight(.bold))
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.dinkrAmber.opacity(0.2))
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.dinkrAmber)
                                    .frame(width: geo.size.width * Double(unlockedCount) / Double(achievements.count))
                            }
                        }
                        .frame(height: 8)
                    }
                    Spacer()
                    Text("🏅 \(Int(Double(unlockedCount) / Double(achievements.count) * 100))%")
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(Color.dinkrAmber)
                }
                .padding()
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                .padding(.top, 12)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(achievements) { achievement in
                        AchievementBadgeCell(achievement: achievement)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
    }
}

struct AchievementBadgeCell: View {
    let achievement: AchievementsView.Achievement

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked
                          ? Color.dinkrAmber.opacity(0.15)
                          : Color.secondary.opacity(0.08))
                    .frame(width: 64, height: 64)
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundStyle(achievement.isUnlocked ? Color.dinkrAmber : Color.secondary.opacity(0.3))

                if !achievement.isUnlocked {
                    Circle()
                        .fill(Color.black.opacity(0.25))
                        .frame(width: 64, height: 64)
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            Text(achievement.name)
                .font(.caption2.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)
        }
    }
}

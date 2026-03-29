import SwiftUI

struct ReputationView: View {
    let user: User

    var level: Int {
        switch user.gamesPlayed {
        case 0..<10: return 1
        case 10..<25: return 2
        case 25..<50: return 3
        case 50..<75: return 4
        case 75..<100: return 5
        case 100..<125: return 6
        case 125..<150: return 7
        case 150..<200: return 8
        case 200..<300: return 9
        default: return 10
        }
    }

    var levelTitle: String {
        switch level {
        case 1: return "Newbie"
        case 2: return "Rookie"
        case 3: return "Player"
        case 4: return "Regular"
        case 5: return "Competitor"
        case 6: return "Veteran"
        case 7: return "Dinkmaster"
        case 8: return "Court Legend"
        case 9: return "Pro Circuit"
        default: return "Hall of Fame"
        }
    }

    var xpProgress: Double {
        let thresholds = [0, 10, 25, 50, 75, 100, 125, 150, 200, 300, Int.max]
        let lower = thresholds[level - 1]
        let upper = thresholds[level]
        let progress = Double(user.gamesPlayed - lower) / Double(upper - lower)
        return min(max(progress, 0), 1)
    }

    var nextLevelGames: Int {
        let thresholds = [0, 10, 25, 50, 75, 100, 125, 150, 200, 300, 500]
        return thresholds[min(level, thresholds.count - 1)]
    }

    var body: some View {
        VStack(spacing: 16) {
            // Level + XP
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen.opacity(0.12))
                        .frame(width: 60, height: 60)
                    VStack(spacing: 0) {
                        Text("LVL")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(Color.dinkrGreen.opacity(0.7))
                        Text("\(level)")
                            .font(.title2.weight(.heavy))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("Level \(level) · \(levelTitle)")
                            .font(.subheadline.weight(.bold))
                        if level >= 7 {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundStyle(Color.dinkrAmber)
                        }
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.dinkrGreen.opacity(0.15))
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.dinkrGreen, Color.dinkrSky],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * xpProgress)
                        }
                    }
                    .frame(height: 8)
                    Text("\(user.gamesPlayed) games · \(nextLevelGames - user.gamesPlayed) to Level \(level + 1)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(14)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Stats row
            HStack(spacing: 0) {
                ReputationStatItem(value: String(format: "%.1f", user.reliabilityScore),
                                   label: "Reliability", icon: "star.fill", color: Color.dinkrAmber)
                Divider().frame(height: 40)
                ReputationStatItem(value: "\(Int(user.winRate * 100))%",
                                   label: "Win Rate", icon: "trophy.fill", color: Color.dinkrGreen)
                Divider().frame(height: 40)
                ReputationStatItem(value: "\(user.gamesPlayed)",
                                   label: "Games", icon: "figure.pickleball", color: Color.dinkrSky)
            }
            .padding(.vertical, 8)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Badges
            if !user.badges.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Badges")
                        .font(.subheadline.weight(.bold))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(user.badges) { badge in
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.dinkrAmber.opacity(0.12))
                                            .frame(width: 48, height: 48)
                                        Image(systemName: "medal.fill")
                                            .foregroundStyle(Color.dinkrAmber)
                                            .font(.title3)
                                    }
                                    Text(badge.label)
                                        .font(.caption2)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 60)
                                        .lineLimit(2)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(14)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

struct ReputationStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
            Text(value)
                .font(.title3.weight(.heavy))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

#Preview {
    ReputationView(user: User.mockCurrentUser)
        .padding()
}

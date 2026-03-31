import SwiftUI

// MARK: - Main View

struct AchievementsView: View {
    var user: User = User.mockCurrentUser
    var gameResults: [GameResult] = []

    private let achievements = Achievement.all
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    @State private var selectedAchievement: Achievement? = nil
    @State private var showBadgeShowcase = false

    private var unlockedCount: Int { achievements.filter { $0.isUnlocked }.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ── Summary header ───────────────────────────────────────
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlocked \(unlockedCount) of \(achievements.count)")
                                .font(.headline.weight(.bold))
                            Text("\(Int(Double(unlockedCount) / Double(achievements.count) * 100))% complete")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        // View All Badges button
                        Button {
                            showBadgeShowcase = true
                        } label: {
                            HStack(spacing: 5) {
                                Text("🏅")
                                    .font(.subheadline)
                                Text("View All")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.dinkrGreen)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(Color.dinkrGreen.opacity(0.8))
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.dinkrAmber.opacity(0.20))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.dinkrAmber)
                                .frame(
                                    width: geo.size.width * Double(unlockedCount) / Double(achievements.count),
                                    height: 8
                                )
                        }
                    }
                    .frame(height: 8)
                }
                .padding()
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                .padding(.top, 12)

                // ── Badge grid ───────────────────────────────────────────
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(achievements) { achievement in
                        AchievementBadgeCard(achievement: achievement)
                            .onTapGesture {
                                selectedAchievement = achievement
                            }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailView(achievement: achievement, user: user, justUnlocked: false)
        }
        .sheet(isPresented: $showBadgeShowcase) {
            BadgeShowcaseView(user: user)
        }
    }
}

// MARK: - Badge card

struct AchievementBadgeCard: View {
    let achievement: Achievement

    private var badgeColor: Color {
        switch achievement.color {
        case "dinkrGreen":  return Color.dinkrGreen
        case "dinkrNavy":   return Color.dinkrNavy
        case "dinkrCoral":  return Color.dinkrCoral
        case "dinkrSky":    return Color.dinkrSky
        default:            return Color.dinkrAmber
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(
                        achievement.isUnlocked
                            ? badgeColor.opacity(0.15)
                            : Color.secondary.opacity(0.08)
                    )
                    .frame(width: 68, height: 68)

                Image(systemName: achievement.icon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(
                        achievement.isUnlocked
                            ? badgeColor
                            : Color.secondary.opacity(0.30)
                    )
                    .saturation(achievement.isUnlocked ? 1 : 0)

                if !achievement.isUnlocked {
                    Circle()
                        .fill(Color.black.opacity(0.28))
                        .frame(width: 68, height: 68)
                    Image(systemName: "lock.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.70))
                }
            }

            // Title
            Text(achievement.title)
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)

            // Progress bar + counter
            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                achievement.isUnlocked
                                    ? Color.dinkrGreen
                                    : Color.secondary.opacity(0.35)
                            )
                            .frame(
                                width: geo.size.width * achievement.progressFraction,
                                height: 5
                            )
                    }
                }
                .frame(height: 5)

                Text("\(achievement.progress) / \(achievement.goal)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    achievement.isUnlocked ? badgeColor.opacity(0.30) : Color.clear,
                    lineWidth: 1.5
                )
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AchievementsView(user: User.mockCurrentUser)
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
    }
}

import SwiftUI

struct StreakDashboard: View {
    let streak: Int = DailyChallenge.currentStreak
    let longestStreak: Int = DailyChallenge.longestStreak
    let weeklyXP: Int = DailyChallenge.weeklyXP
    @State private var challenges = DailyChallenge.mockChallenges
    @State private var fireScale = 1.0
    @State private var showStreakCelebration = false

    var completedCount: Int { challenges.filter { $0.isCompleted }.count }
    var totalXPToday: Int { challenges.filter { $0.isCompleted }.reduce(0) { $0 + $1.xpReward } }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Streak hero card
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.4, blue: 0.1), Color(red: 0.96, green: 0.65, blue: 0.14)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Decorative circles
                    Circle().fill(Color.white.opacity(0.08)).frame(width: 150, height: 150).offset(x: 100, y: -40)
                    Circle().fill(Color.white.opacity(0.05)).frame(width: 80, height: 80).offset(x: 130, y: 30)

                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("🔥")
                                .font(.system(size: 52))
                                .scaleEffect(fireScale)
                                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: fireScale)
                                .onAppear { fireScale = 1.15 }

                            Text("\(streak)-Day Streak")
                                .font(.title.weight(.heavy))
                                .foregroundStyle(.white)

                            Text("Keep it going!")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        Spacer()
                        VStack(spacing: 12) {
                            StreakStat(value: "\(streak)", label: "Current", icon: "flame.fill")
                            StreakStat(value: "\(longestStreak)", label: "Best", icon: "crown.fill")
                        }
                    }
                    .padding(20)
                }
                .padding(.horizontal)
                .padding(.top, 12)

                // Weekly XP + completion
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(Color.dinkrAmber)
                                .font(.caption)
                            Text("TODAY'S XP")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(.secondary)
                        }
                        Text("+\(totalXPToday) XP")
                            .font(.title2.weight(.heavy))
                            .foregroundStyle(Color.dinkrAmber)
                        Text("of \(DailyChallenge.mockChallenges.reduce(0) { $0 + $1.xpReward }) possible")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.dinkrGreen)
                                .font(.caption)
                            Text("COMPLETED")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(.secondary)
                        }
                        Text("\(completedCount)/\(challenges.count)")
                            .font(.title2.weight(.heavy))
                            .foregroundStyle(Color.dinkrGreen)
                        Text("challenges today")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)

                // Daily Challenges
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Daily Challenges")
                            .font(.headline.weight(.bold))
                        Spacer()
                        Text("Resets in \(hoursUntilReset)h")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    ForEach(challenges.indices, id: \.self) { i in
                        DailyChallengeRow(challenge: challenges[i]) {
                            // toggle completion
                        }
                        .padding(.horizontal)
                    }
                }

                // Weekly streak grid
                VStack(alignment: .leading, spacing: 10) {
                    Text("This Week")
                        .font(.headline.weight(.bold))
                        .padding(.horizontal)

                    HStack(spacing: 8) {
                        ForEach(0..<7) { dayOffset in
                            let date = Calendar.current.date(byAdding: .day, value: dayOffset - 6, to: Date()) ?? Date()
                            let isActive = dayOffset >= 7 - streak
                            let isToday = dayOffset == 6
                            VStack(spacing: 4) {
                                Text(date, format: .dateTime.weekday(.narrow))
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                ZStack {
                                    Circle()
                                        .fill(isActive ? Color.dinkrAmber : Color.secondary.opacity(0.1))
                                        .frame(width: 34, height: 34)
                                    if isActive {
                                        Text("🔥")
                                            .font(.system(size: 16))
                                    } else {
                                        Text(date, format: .dateTime.day())
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                    if isToday {
                                        Circle()
                                            .stroke(Color.dinkrAmber, lineWidth: 2.5)
                                            .frame(width: 34, height: 34)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Streaks & Challenges")
    }

    var hoursUntilReset: Int {
        let calendar = Calendar.current
        let now = Date()
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
        let diff = tomorrow.timeIntervalSince(now)
        return Int(diff / 3600)
    }
}

struct StreakStat: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
            Text(value)
                .font(.title3.weight(.heavy))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

struct DailyChallengeRow: View {
    let challenge: DailyChallenge
    let onComplete: () -> Void

    var categoryColor: Color {
        switch challenge.category {
        case .play: return Color.dinkrGreen
        case .social: return Color.dinkrSky
        case .streak: return Color.dinkrAmber
        case .skill: return Color.dinkrCoral
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(challenge.isCompleted ? Color.dinkrGreen.opacity(0.15) : categoryColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                if challenge.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.dinkrGreen)
                } else {
                    Image(systemName: challenge.icon)
                        .foregroundStyle(categoryColor)
                        .font(.headline)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(challenge.title)
                        .font(.subheadline.weight(challenge.isCompleted ? .regular : .semibold))
                        .foregroundStyle(challenge.isCompleted ? .secondary : .primary)
                        .strikethrough(challenge.isCompleted)
                    Text(challenge.category.rawValue)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(categoryColor)
                        .clipShape(Capsule())
                }
                if !challenge.isCompleted {
                    Text(challenge.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if challenge.total > 1 {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3).fill(Color.secondary.opacity(0.15))
                                RoundedRectangle(cornerRadius: 3).fill(categoryColor)
                                    .frame(width: geo.size.width * challenge.progressFraction)
                            }
                        }
                        .frame(height: 4)
                    }
                }
            }

            Spacer()

            HStack(spacing: 2) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.dinkrAmber)
                Text("+\(challenge.xpReward)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dinkrAmber)
            }
        }
        .padding(12)
        .background(challenge.isCompleted ? Color.dinkrGreen.opacity(0.04) : Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

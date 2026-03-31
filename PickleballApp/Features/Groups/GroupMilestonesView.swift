import SwiftUI

// MARK: - Models

private struct GroupMilestone: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let date: String
    let tier: MilestoneTier

    enum MilestoneTier {
        case bronze, silver, gold
        var label: String {
            switch self {
            case .bronze: return "Bronze"
            case .silver: return "Silver"
            case .gold:   return "Gold"
            }
        }
        var color: Color {
            switch self {
            case .bronze: return Color(red: 0.80, green: 0.50, blue: 0.20)
            case .silver: return Color(red: 0.70, green: 0.70, blue: 0.75)
            case .gold:   return Color(red: 1.00, green: 0.78, blue: 0.10)
            }
        }
    }
}

private struct LockedMilestone: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let progress: Double      // 0–1
    let progressLabel: String
}

// MARK: - View

struct GroupMilestonesView: View {

    // ── Static data ────────────────────────────────────────────────────────
    private let headerStats: [(value: String, label: String, icon: String, color: Color)] = [
        ("127",  "Games Played", "gamecontroller.fill",  Color.dinkrGreen),
        ("48",   "Members",      "person.2.fill",        Color.dinkrSky),
        ("284",  "Days Active",  "calendar",             Color.dinkrAmber),
    ]

    private let unlockedMilestones: [GroupMilestone] = [
        GroupMilestone(emoji: "🎉", title: "First Game Hosted",    date: "Jan 12, 2025",  tier: .bronze),
        GroupMilestone(emoji: "👥", title: "10 Members",           date: "Feb 3, 2025",   tier: .bronze),
        GroupMilestone(emoji: "🏆", title: "First Tournament Win", date: "Mar 22, 2025",  tier: .silver),
        GroupMilestone(emoji: "💯", title: "100 Games Played",     date: "Jun 15, 2025",  tier: .silver),
        GroupMilestone(emoji: "⭐", title: "Top Rated DinkrGroup",      date: "Aug 1, 2025",   tier: .gold),
        GroupMilestone(emoji: "🌟", title: "50 Members",           date: "Nov 10, 2025",  tier: .gold),
    ]

    private let lockedMilestones: [LockedMilestone] = [
        LockedMilestone(emoji: "👥", title: "100 Members",       progress: 0.48, progressLabel: "48 / 100"),
        LockedMilestone(emoji: "🎮", title: "500 Games Played",  progress: 0.254, progressLabel: "127 / 500"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // ── Header stats ───────────────────────────────────────────
                headerStatsSection

                // ── Unlocked milestones ────────────────────────────────────
                VStack(alignment: .leading, spacing: 0) {
                    sectionHeader(title: "Achievements Unlocked", icon: "trophy.fill", color: Color.dinkrAmber)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    VStack(spacing: 0) {
                        ForEach(Array(unlockedMilestones.enumerated()), id: \.element.id) { index, milestone in
                            MilestoneRow(milestone: milestone, isLast: index == unlockedMilestones.count - 1)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // ── Locked milestones ──────────────────────────────────────
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader(title: "Next Targets", icon: "lock.fill", color: .secondary)
                        .padding(.horizontal, 20)

                    VStack(spacing: 12) {
                        ForEach(lockedMilestones) { milestone in
                            LockedMilestoneRow(milestone: milestone)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // ── Share button ───────────────────────────────────────────
                Button {
                    HapticManager.medium()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Milestones")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.75)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .padding(.top, 24)
        }
        .navigationTitle("DinkrGroup Milestones")
        .navigationBarTitleDisplayMode(.large)
        .background(Color.appBackground)
    }

    // MARK: - Header stats row

    private var headerStatsSection: some View {
        HStack(spacing: 12) {
            ForEach(headerStats, id: \.label) { stat in
                VStack(spacing: 6) {
                    Image(systemName: stat.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(stat.color)
                    Text(stat.value)
                        .font(.title2.weight(.bold))
                    Text(stat.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(stat.color.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Section header helper

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
        }
    }
}

// MARK: - Milestone Row (unlocked)

private struct MilestoneRow: View {
    let milestone: GroupMilestone
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {

            // ── Timeline spine ─────────────────────────────────────────────
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(milestone.tier.color.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Text(milestone.emoji)
                        .font(.system(size: 20))
                }
                if !isLast {
                    Rectangle()
                        .fill(Color.dinkrGreen.opacity(0.25))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .frame(width: 44)

            // ── Content ────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 8) {
                    Text(milestone.title)
                        .font(.subheadline.weight(.semibold))
                    MilestoneBadge(tier: milestone.tier)
                    Spacer()
                }
                Text(milestone.date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 14)
            .padding(.vertical, 10)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Milestone Badge

private struct MilestoneBadge: View {
    let tier: GroupMilestone.MilestoneTier

    var body: some View {
        Text(tier.label)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(tier.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tier.color.opacity(0.15))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(tier.color.opacity(0.4), lineWidth: 1)
            )
    }
}

// MARK: - Locked Milestone Row

private struct LockedMilestoneRow: View {
    let milestone: LockedMilestone

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.secondary.opacity(0.10))
                        .frame(width: 44, height: 44)
                    Text(milestone.emoji)
                        .font(.system(size: 20))
                        .grayscale(1)
                        .opacity(0.5)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(milestone.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(milestone.progressLabel)
                        .font(.caption)
                        .foregroundStyle(Color.secondary.opacity(0.7))
                }

                Spacer()

                Image(systemName: "lock.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.secondary.opacity(0.4))
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.12))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.dinkrGreen.opacity(0.5))
                        .frame(width: geo.size.width * milestone.progress, height: 6)
                }
            }
            .frame(height: 6)
            .padding(.leading, 54)
        }
        .padding(14)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GroupMilestonesView()
    }
}

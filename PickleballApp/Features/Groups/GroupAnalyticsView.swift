import SwiftUI

// MARK: - GroupAnalyticsView

struct GroupAnalyticsView: View {
    let group: DinkrGroup

    @State private var showExportAlert = false

    // Mock data
    private let memberGrowthData: [CGFloat] = [8, 14, 19, 27, 38, 54]
    private let monthLabels = ["Oct", "Nov", "Dec", "Jan", "Feb", "Mar"]

    private let topContributors: [ContributorEntry] = [
        ContributorEntry(id: "u1", name: "Alex Rivera",  username: "pickleking",       skillLevel: .intermediate35, activityScore: 98),
        ContributorEntry(id: "u2", name: "Maria Chen",   username: "maria_plays",      skillLevel: .intermediate35, activityScore: 87),
        ContributorEntry(id: "u3", name: "Jordan Smith", username: "jordan_4point0",   skillLevel: .advanced40,     activityScore: 74),
        ContributorEntry(id: "u4", name: "Sarah Johnson",username: "sarahj_pb",        skillLevel: .intermediate35, activityScore: 61),
        ContributorEntry(id: "u5", name: "Chris Park",   username: "chrisp_dink",      skillLevel: .advanced40,     activityScore: 53),
    ]

    private let gameFormatData: [GameFormatEntry] = [
        GameFormatEntry(label: "Doubles",    value: 0.52, color: Color.dinkrGreen),
        GameFormatEntry(label: "Singles",    value: 0.21, color: Color.dinkrSky),
        GameFormatEntry(label: "Open Play",  value: 0.27, color: Color.dinkrAmber),
    ]

    private let engagementRate: Double = 0.68
    private let activeThisWeek = 31
    private let gamesHosted = 47
    private let winRate: Double = 0.61

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // ── Header Stats ──────────────────────────────────────────────
                headerStatsGrid
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // ── Member Growth Chart ───────────────────────────────────────
                memberGrowthCard
                    .padding(.horizontal, 16)

                // ── Engagement Ring ───────────────────────────────────────────
                engagementCard
                    .padding(.horizontal, 16)

                // ── Games by Format ───────────────────────────────────────────
                gamesByFormatCard
                    .padding(.horizontal, 16)

                // ── Top Contributors ──────────────────────────────────────────
                topContributorsCard
                    .padding(.horizontal, 16)

                // ── Export Report ─────────────────────────────────────────────
                exportButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
            }
        }
        .navigationTitle("DinkrGroup Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.appBackground)
        .alert("Report Exported", isPresented: $showExportAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Admin report emailed to your registered email.")
        }
    }

    // MARK: - Header Stats Grid

    private var headerStatsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible()),
                      GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            AnalyticsStatTile(value: "\(group.memberCount)", label: "Members",
                              icon: "person.2.fill", color: Color.dinkrGreen)
            AnalyticsStatTile(value: "\(activeThisWeek)", label: "Active\nThis Week",
                              icon: "bolt.fill", color: Color.dinkrAmber)
            AnalyticsStatTile(value: "\(gamesHosted)", label: "Games\nHosted",
                              icon: "sportscourt.fill", color: Color.dinkrSky)
            AnalyticsStatTile(value: "\(Int(winRate * 100))%", label: "Win\nRate",
                              icon: "trophy.fill", color: Color.dinkrCoral)
        }
    }

    // MARK: - Member Growth Card

    private var memberGrowthCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            GroupAnalyticsViewSectionHeader(title: "Member Growth", subtitle: "Last 6 months",
                          icon: "arrow.up.right", iconColor: Color.dinkrGreen)

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let maxVal = memberGrowthData.max() ?? 1
                let points = chartPoints(data: memberGrowthData, width: w, height: h, maxVal: maxVal)

                ZStack {
                    // Gradient fill under the line
                    Path { path in
                        guard points.count > 1 else { return }
                        path.move(to: CGPoint(x: points[0].x, y: h))
                        for pt in points { path.addLine(to: pt) }
                        path.addLine(to: CGPoint(x: points.last!.x, y: h))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [Color.dinkrGreen.opacity(0.35), Color.dinkrGreen.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Smooth line
                    Path { path in
                        guard points.count > 1 else { return }
                        path.move(to: points[0])
                        for i in 1..<points.count {
                            let prev = points[i - 1]
                            let curr = points[i]
                            let cp1 = CGPoint(x: prev.x + (curr.x - prev.x) * 0.5, y: prev.y)
                            let cp2 = CGPoint(x: prev.x + (curr.x - prev.x) * 0.5, y: curr.y)
                            path.addCurve(to: curr, control1: cp1, control2: cp2)
                        }
                    }
                    .stroke(Color.dinkrGreen, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    // Data point dots
                    ForEach(0..<points.count, id: \.self) { i in
                        Circle()
                            .fill(Color.dinkrGreen)
                            .frame(width: 7, height: 7)
                            .position(points[i])

                        // Value label above dot
                        Text("\(Int(memberGrowthData[i]))")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.dinkrGreen)
                            .position(x: points[i].x, y: points[i].y - 12)
                    }
                }
            }
            .frame(height: 130)

            // X-axis month labels
            HStack {
                ForEach(monthLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func chartPoints(data: [CGFloat], width: CGFloat, height: CGFloat, maxVal: CGFloat) -> [CGPoint] {
        let count = data.count
        guard count > 1 else { return [] }
        return data.enumerated().map { i, val in
            CGPoint(
                x: width * CGFloat(i) / CGFloat(count - 1),
                y: height - (val / maxVal) * height * 0.88 - height * 0.06
            )
        }
    }

    // MARK: - Engagement Card

    private var engagementCard: some View {
        HStack(alignment: .center, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                GroupAnalyticsViewSectionHeader(title: "Engagement Rate", subtitle: "Members active this week",
                              icon: "sparkles", iconColor: Color.dinkrAmber)

                Text("\(Int(engagementRate * 100))%")
                    .font(.system(size: 40, weight: .black))
                    .foregroundStyle(Color.dinkrAmber)

                Text("of members interacted with\ngroup content this week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Manual arc ring
            EngagementRing(progress: engagementRate, color: Color.dinkrAmber)
                .frame(width: 90, height: 90)
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Games by Format Card

    private var gamesByFormatCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            GroupAnalyticsViewSectionHeader(title: "Games by Format", subtitle: "All-time distribution",
                          icon: "chart.bar.fill", iconColor: Color.dinkrSky)

            VStack(spacing: 12) {
                ForEach(gameFormatData) { entry in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(entry.label)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(Int(entry.value * 100))%")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(entry.color)
                                .monospacedDigit()
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(entry.color.opacity(0.12))
                                    .frame(height: 10)

                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [entry.color, entry.color.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * entry.value, height: 10)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: entry.value)
                            }
                        }
                        .frame(height: 10)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Top Contributors Card

    private var topContributorsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            GroupAnalyticsViewSectionHeader(title: "Top Contributors", subtitle: "Most active members",
                          icon: "star.fill", iconColor: Color.dinkrCoral)

            VStack(spacing: 0) {
                ForEach(Array(topContributors.enumerated()), id: \.element.id) { index, contributor in
                    TopContributorRow(rank: index + 1, contributor: contributor)

                    if index < topContributors.count - 1 {
                        Divider().padding(.leading, 58)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Export Button

    private var exportButton: some View {
        Button {
            HapticManager.medium()
            showExportAlert = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                Text("Export Report")
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(Color.dinkrNavy)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: [Color.dinkrAmber, Color.dinkrAmber.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.dinkrAmber.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Engagement Ring (Manual Arc)

private struct EngagementRing: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            // Track ring
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 10)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.6), color],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Center label
            VStack(spacing: 1) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(color)
                Text("rate")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Analytics Stat Tile

private struct AnalyticsStatTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(value)
                .font(.system(size: 16, weight: .black))
                .monospacedDigit()
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Top Contributor Row

private struct TopContributorRow: View {
    let rank: Int
    let contributor: ContributorEntry

    private var rankColor: Color {
        switch rank {
        case 1: return Color.dinkrAmber
        case 2: return Color(white: 0.7)
        case 3: return Color(red: 0.8, green: 0.52, blue: 0.25)
        default: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor.opacity(rank <= 3 ? 0.18 : 0.08))
                    .frame(width: 30, height: 30)
                Text("\(rank)")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(rankColor)
            }

            AvatarView(urlString: nil, displayName: contributor.name, size: 38)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(contributor.name)
                        .font(.subheadline.weight(.semibold))
                    SkillBadge(level: contributor.skillLevel, compact: true)
                }
                Text("@\(contributor.username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Activity score bar + value
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(contributor.activityScore)")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(Color.dinkrGreen)
                    .monospacedDigit()

                Capsule()
                    .fill(Color.dinkrGreen.opacity(0.15))
                    .frame(width: 50, height: 5)
                    .overlay(
                        GeometryReader { geo in
                            Capsule()
                                .fill(Color.dinkrGreen)
                                .frame(width: geo.size.width * (CGFloat(contributor.activityScore) / 100.0))
                        }
                    )
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// MARK: - Section Header

private struct GroupAnalyticsViewSectionHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(iconColor)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Supporting Models

private struct ContributorEntry: Identifiable {
    let id: String
    let name: String
    let username: String
    let skillLevel: SkillLevel
    let activityScore: Int
}

private struct GameFormatEntry: Identifiable {
    var id: String { label }
    let label: String
    let value: CGFloat
    let color: Color
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GroupAnalyticsView(group: DinkrGroup.mockGroups[0])
    }
}

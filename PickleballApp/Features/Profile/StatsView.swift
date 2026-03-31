import SwiftUI

// MARK: - StatsView

struct StatsView: View {
    let user: User

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                WinLossBarChartSection()
                DUPRTrendSection()
                PerformanceGridSection()
                CourtHeatmapSection()
                TopPartnersSection()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Section Header

private struct StatsSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.dinkrGreen)
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.primary)
            Spacer()
        }
    }
}

// MARK: - Section 1: Win/Loss Bar Chart

private struct WinLossBarChartSection: View {
    // Oct–Mar data: (month, wins, losses)
    private let monthData: [(label: String, wins: Int, losses: Int)] = [
        ("Oct", 6, 4),
        ("Nov", 8, 3),
        ("Dec", 5, 5),
        ("Jan", 9, 2),
        ("Feb", 11, 3),
        ("Mar", 9, 5),
    ]

    private var maxTotal: Int {
        monthData.map { $0.wins + $0.losses }.max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StatsSectionHeader(title: "Win / Loss by Month", icon: "chart.bar.fill")

            // Chart area
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(monthData, id: \.label) { item in
                    WinLossBarColumn(
                        wins: item.wins,
                        losses: item.losses,
                        maxTotal: maxTotal,
                        label: item.label
                    )
                }
            }
            .frame(height: 160)

            // Legend
            HStack(spacing: 20) {
                Spacer()
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.dinkrGreen)
                        .frame(width: 14, height: 10)
                    Text("Wins")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.dinkrCoral)
                        .frame(width: 14, height: 10)
                    Text("Losses")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct WinLossBarColumn: View {
    let wins: Int
    let losses: Int
    let maxTotal: Int
    let label: String

    private let chartHeight: CGFloat = 130
    @State private var animated = false

    private var winFraction: CGFloat {
        CGFloat(wins) / CGFloat(maxTotal)
    }

    private var lossFraction: CGFloat {
        CGFloat(losses) / CGFloat(maxTotal)
    }

    var body: some View {
        VStack(spacing: 4) {
            // Win count label above bar
            Text("\(wins)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.dinkrGreen)
                .frame(height: 14)

            // Stacked bars
            VStack(spacing: 2) {
                // Win bar (green, on top)
                Spacer(minLength: 0)

                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.dinkrGreen)
                    .frame(
                        height: animated ? winFraction * chartHeight : 0
                    )
                    .animation(.spring(response: 0.7, dampingFraction: 0.75).delay(Double(["Oct","Nov","Dec","Jan","Feb","Mar"].firstIndex(of: label) ?? 0) * 0.08), value: animated)

                // Loss bar (coral, below)
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.dinkrCoral)
                    .frame(
                        height: animated ? lossFraction * chartHeight : 0
                    )
                    .animation(.spring(response: 0.7, dampingFraction: 0.75).delay(Double(["Oct","Nov","Dec","Jan","Feb","Mar"].firstIndex(of: label) ?? 0) * 0.08 + 0.1), value: animated)
            }
            .frame(height: chartHeight)

            // Month label below bar
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .onAppear { animated = true }
    }
}

// MARK: - Section 2: DUPR Trend Line

private struct DUPRTrendSection: View {
    // 6 months of mock DUPR: Oct → Mar
    private let duprData: [Double] = [3.42, 3.48, 3.51, 3.47, 3.54, 3.67]
    private let monthLabels = ["Oct", "Nov", "Dec", "Jan", "Feb", "Mar"]
    @State private var lineProgress: CGFloat = 0
    @State private var showDUPRDetail = false

    private var minVal: Double { (duprData.min() ?? 3.42) - 0.05 }
    private var maxVal: Double { (duprData.max() ?? 3.67) + 0.05 }
    private var valueRange: Double { maxVal - minVal }

    var body: some View {
        Button {
            showDUPRDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    StatsSectionHeader(title: "DUPR Rating Trend", icon: "waveform.path.ecg")
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }

                // Current DUPR badge + trend
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current DUPR")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f", duprData.last ?? 3.67))
                            .font(.title2.weight(.heavy))
                            .foregroundStyle(Color.primary)
                    }

                    // Amber pill badge
                    Text(String(format: "%.2f", duprData.last ?? 3.67))
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(Color.dinkrAmber)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.dinkrAmber.opacity(0.15))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.dinkrAmber.opacity(0.4), lineWidth: 1))

                    Spacer()

                    // Trend indicator
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.dinkrGreen)
                        Text("+0.25 this season")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.dinkrGreen.opacity(0.1))
                    .clipShape(Capsule())
                }

                // Line chart canvas
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height

                    ZStack {
                        // Grid lines
                        ForEach(0..<4, id: \.self) { i in
                            let y = h * CGFloat(i) / 3.0
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: w, y: y))
                            }
                            .stroke(Color.secondary.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        }

                        // Fill under curve
                        DUPRFillShape(data: duprData, minVal: minVal, valueRange: valueRange, progress: lineProgress)
                            .fill(
                                LinearGradient(
                                    colors: [Color.dinkrGreen.opacity(0.25), Color.dinkrGreen.opacity(0.02)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        // Line
                        DUPRLinePath(data: duprData, minVal: minVal, valueRange: valueRange, progress: lineProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.dinkrGreen.opacity(0.7), Color.dinkrGreen],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                            )

                        // Dots at each data point
                        ForEach(duprData.indices, id: \.self) { i in
                            let x = w * CGFloat(i) / CGFloat(duprData.count - 1)
                            let normalized = (duprData[i] - minVal) / valueRange
                            let y = h * (1.0 - CGFloat(normalized))

                            ZStack {
                                Circle()
                                    .fill(Color.dinkrGreen)
                                    .frame(width: 9, height: 9)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 4, height: 4)
                            }
                            .position(x: x, y: y)
                            .opacity(lineProgress > CGFloat(i) / CGFloat(duprData.count - 1) ? 1 : 0)
                            .animation(.easeIn(duration: 0.15).delay(Double(i) * 0.1 + 0.4), value: lineProgress)
                        }
                    }
                }
                .frame(height: 110)
                .clipped()

                // Month labels row
                HStack(spacing: 0) {
                    ForEach(monthLabels, id: \.self) { label in
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(16)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDUPRDetail) {
            DUPRDetailView()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) {
                lineProgress = 1.0
            }
        }
    }
}

// MARK: - DUPR Chart Shapes

private struct DUPRLinePath: Shape {
    let data: [Double]
    let minVal: Double
    let valueRange: Double
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard data.count > 1 else { return Path() }
        var path = Path()
        let w = rect.width
        let h = rect.height

        func point(at i: Int) -> CGPoint {
            let x = w * CGFloat(i) / CGFloat(data.count - 1)
            let normalized = (data[i] - minVal) / valueRange
            let y = h * (1.0 - CGFloat(normalized))
            return CGPoint(x: x, y: y)
        }

        path.move(to: point(at: 0))
        for i in 1..<data.count {
            let prev = point(at: i - 1)
            let curr = point(at: i)
            let midX = (prev.x + curr.x) / 2
            path.addCurve(to: curr,
                          control1: CGPoint(x: midX, y: prev.y),
                          control2: CGPoint(x: midX, y: curr.y))
        }

        // Trim to progress
        return path.trimmedPath(from: 0, to: progress)
    }
}

private struct DUPRFillShape: Shape {
    let data: [Double]
    let minVal: Double
    let valueRange: Double
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard data.count > 1 else { return Path() }
        var path = Path()
        let w = rect.width
        let h = rect.height

        func point(at i: Int) -> CGPoint {
            let x = w * CGFloat(i) / CGFloat(data.count - 1)
            let normalized = (data[i] - minVal) / valueRange
            let y = h * (1.0 - CGFloat(normalized))
            return CGPoint(x: x, y: y)
        }

        let clampedCount = max(2, Int(CGFloat(data.count - 1) * progress) + 1)
        let endIndex = min(clampedCount, data.count) - 1

        path.move(to: CGPoint(x: 0, y: h))
        path.addLine(to: point(at: 0))

        for i in 1...endIndex {
            let prev = point(at: i - 1)
            let curr = point(at: i)
            let midX = (prev.x + curr.x) / 2
            path.addCurve(to: curr,
                          control1: CGPoint(x: midX, y: prev.y),
                          control2: CGPoint(x: midX, y: curr.y))
        }

        path.addLine(to: CGPoint(x: point(at: endIndex).x, y: h))
        path.closeSubpath()
        return path
    }
}

// MARK: - Section 3: Performance Grid

private struct PerformanceGridSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StatsSectionHeader(title: "Performance Highlights", icon: "sparkles")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                PerfTile(
                    icon: "flame.fill",
                    value: "7",
                    label: "Longest Win Streak",
                    accent: Color.dinkrCoral
                )
                PerfTile(
                    icon: "calendar.badge.checkmark",
                    value: "78%",
                    label: "Best Month (Feb)",
                    accent: Color.dinkrGreen
                )
                PerfTile(
                    icon: "person.2.fill",
                    value: "Doubles",
                    label: "Favorite Format",
                    accent: Color.dinkrSky
                )
                PerfTile(
                    icon: "clock.fill",
                    value: "52 min",
                    label: "Avg Game Duration",
                    accent: Color.dinkrAmber
                )
            }
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct PerfTile: View {
    let icon: String
    let value: String
    let label: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(accent)

            Text(value)
                .font(.title3.weight(.heavy))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(accent.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accent.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Section 4: Court Heatmap

private struct CourtHeatmapSection: View {
    // 60 days of mock activity: 0 = no game, 1 = 1 game, 2+ = 2+ games
    private let activityData: [Int] = {
        // Seeded deterministic mock data for 60 days
        let pattern = [0, 1, 2, 0, 1, 0, 0,
                       1, 0, 2, 1, 0, 2, 1,
                       0, 0, 1, 2, 0, 1, 0,
                       2, 1, 0, 0, 2, 1, 0,
                       1, 2, 0, 1, 0, 0, 2,
                       1, 0, 1, 2, 0, 1, 0,
                       0, 2, 1, 0, 2, 1, 0,
                       1, 0, 2, 0, 1, 1, 0,
                       2, 1, 0, 2, 1]
        return Array(pattern.prefix(60))
    }()

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
    private let squareSize: CGFloat = 13
    private let spacing: CGFloat = 3

    // DinkrGroup into columns of 7 (weeks)
    private var columns: [[Int]] {
        stride(from: 0, to: activityData.count, by: 7).map { start in
            Array(activityData[start..<min(start + 7, activityData.count)])
        }
    }

    private func fillColor(for activity: Int) -> Color {
        switch activity {
        case 0: return Color.secondary.opacity(0.15)
        case 1: return Color.dinkrGreen.opacity(0.45)
        default: return Color.dinkrGreen
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StatsSectionHeader(title: "Activity Heatmap", icon: "calendar.circle.fill")

            Text("Last 60 days")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: spacing) {
                // Day-of-week labels column
                VStack(alignment: .trailing, spacing: spacing) {
                    ForEach(dayLabels, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 12, height: squareSize)
                    }
                }

                // Activity squares
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(columns.indices, id: \.self) { colIdx in
                        VStack(spacing: spacing) {
                            ForEach(columns[colIdx].indices, id: \.self) { rowIdx in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(fillColor(for: columns[colIdx][rowIdx]))
                                    .frame(width: squareSize, height: squareSize)
                            }
                            // Pad incomplete last column
                            if colIdx == columns.count - 1 && columns[colIdx].count < 7 {
                                ForEach(0..<(7 - columns[colIdx].count), id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.clear)
                                        .frame(width: squareSize, height: squareSize)
                                }
                            }
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: 12) {
                Spacer()
                Text("Less")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                HStack(spacing: 3) {
                    ForEach([0, 1, 2], id: \.self) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(fillColor(for: level))
                            .frame(width: 11, height: 11)
                    }
                }
                Text("More")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Section 5: Top Partners

private struct StatsPartnerData: Identifiable {
    let id: String
    let name: String
    let initials: String
    let gamesTogther: Int
    let winRate: Double
    let accentColor: Color
}

private struct TopPartnersSection: View {
    private let partners: [StatsPartnerData] = [
        StatsPartnerData(id: "p1", name: "Maria Chen",    initials: "MC", gamesTogther: 22, winRate: 0.73, accentColor: Color.dinkrSky),
        StatsPartnerData(id: "p2", name: "Jordan Smith",  initials: "JS", gamesTogther: 17, winRate: 0.59, accentColor: Color.dinkrGreen),
        StatsPartnerData(id: "p3", name: "Sarah Johnson", initials: "SJ", gamesTogther: 14, winRate: 0.79, accentColor: Color.dinkrAmber),
        StatsPartnerData(id: "p4", name: "Chris Park",    initials: "CP", gamesTogther: 11, winRate: 0.64, accentColor: Color.dinkrCoral),
        StatsPartnerData(id: "p5", name: "Riley Torres",  initials: "RT", gamesTogther: 8,  winRate: 0.88, accentColor: Color(red: 0.55, green: 0.35, blue: 0.85)),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StatsSectionHeader(title: "Top Partners", icon: "person.2.circle.fill")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(partners) { partner in
                        PartnerCard(partner: partner)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct PartnerCard: View {
    let partner: StatsPartnerData

    var body: some View {
        VStack(spacing: 10) {
            // Avatar
            ZStack {
                Circle()
                    .fill(partner.accentColor.opacity(0.18))
                    .frame(width: 54, height: 54)
                Circle()
                    .stroke(partner.accentColor.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 54, height: 54)
                Text(partner.initials)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(partner.accentColor)
            }

            // Name
            Text(partner.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 80)

            // Games together
            Text("\(partner.gamesTogther) games")
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Win rate pill
            Text("\(Int(partner.winRate * 100))% win rate")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(partner.accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(partner.accentColor.opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(partner.accentColor.opacity(0.3), lineWidth: 1))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StatsView(user: User.mockCurrentUser)
    }
}

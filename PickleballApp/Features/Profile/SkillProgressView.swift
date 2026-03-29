import SwiftUI

// MARK: - Models

struct SkillDataPoint: Identifiable {
    let id: String
    let date: Date
    let rating: Double
}

extension SkillDataPoint {
    /// 12 mock data points spanning ~6 months, 3.25 → 4.0 with natural variance.
    static let mockHistory: [SkillDataPoint] = {
        let cal = Calendar.current
        let now = Date()
        func daysAgo(_ n: Int) -> Date {
            cal.date(byAdding: .day, value: -n, to: now) ?? now
        }
        return [
            SkillDataPoint(id: "dp1",  date: daysAgo(180), rating: 3.25),
            SkillDataPoint(id: "dp2",  date: daysAgo(162), rating: 3.30),
            SkillDataPoint(id: "dp3",  date: daysAgo(144), rating: 3.25),
            SkillDataPoint(id: "dp4",  date: daysAgo(126), rating: 3.40),
            SkillDataPoint(id: "dp5",  date: daysAgo(108), rating: 3.50),
            SkillDataPoint(id: "dp6",  date: daysAgo(90),  rating: 3.45),
            SkillDataPoint(id: "dp7",  date: daysAgo(72),  rating: 3.60),
            SkillDataPoint(id: "dp8",  date: daysAgo(54),  rating: 3.70),
            SkillDataPoint(id: "dp9",  date: daysAgo(36),  rating: 3.65),
            SkillDataPoint(id: "dp10", date: daysAgo(24),  rating: 3.80),
            SkillDataPoint(id: "dp11", date: daysAgo(12),  rating: 3.90),
            SkillDataPoint(id: "dp12", date: daysAgo(2),   rating: 4.00),
        ]
    }()
}

// MARK: - Skill Line Chart

private struct SkillLineChart: View {
    let dataPoints: [SkillDataPoint]
    @Binding var selectedPoint: SkillDataPoint?

    private let yMin: Double = 2.75
    private let yMax: Double = 4.50
    private let yLabels: [Double] = [3.0, 3.5, 4.0, 4.5]

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                ZStack(alignment: .topLeading) {
                    // Y-axis gridlines + labels
                    ForEach(yLabels, id: \.self) { label in
                        let y = yPosition(value: label, height: h)
                        HStack(spacing: 6) {
                            Text(String(format: "%.1f", label))
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(Color.secondary.opacity(0.6))
                                .frame(width: 28, alignment: .trailing)
                            Rectangle()
                                .fill(Color.secondary.opacity(0.12))
                                .frame(height: 1)
                        }
                        .frame(width: w, height: 1)
                        .offset(y: y - 0.5)
                    }

                    // Chart area (offset past Y label width)
                    let chartLeft: CGFloat = 36
                    let chartW = w - chartLeft - 8

                    // Fill path
                    fillPath(points: dataPoints, chartLeft: chartLeft, chartW: chartW, height: h)
                        .fill(
                            LinearGradient(
                                colors: [Color.dinkrGreen.opacity(0.15), Color.dinkrGreen.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Stroke path
                    linePath(points: dataPoints, chartLeft: chartLeft, chartW: chartW, height: h)
                        .stroke(Color.dinkrGreen, style: StrokeStyle(lineWidth: 2, lineJoin: .round))

                    // Data point dots + tap targets
                    ForEach(dataPoints) { point in
                        let pos = pointPosition(point: point, chartLeft: chartLeft, chartW: chartW, height: h)
                        let isSelected = selectedPoint?.id == point.id

                        ZStack {
                            Circle()
                                .fill(Color.dinkrGreen)
                                .frame(width: isSelected ? 10 : 6, height: isSelected ? 10 : 6)
                            if isSelected {
                                Circle()
                                    .stroke(Color.dinkrGreen.opacity(0.3), lineWidth: 3)
                                    .frame(width: 16, height: 16)
                            }
                        }
                        .position(pos)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedPoint = (selectedPoint?.id == point.id) ? nil : point
                            }
                        }
                    }

                    // Callout bubble
                    if let sel = selectedPoint {
                        let pos = pointPosition(point: sel, chartLeft: chartLeft, chartW: chartW, height: h)
                        calloutBubble(for: sel)
                            .position(
                                x: min(max(pos.x, 60), w - 60),
                                y: max(pos.y - 44, 24)
                            )
                    }
                }
            }
            .frame(height: 160)

            // X-axis month labels
            xAxisLabels
        }
    }

    // MARK: Helpers

    private func xPosition(point: SkillDataPoint, chartLeft: CGFloat, chartW: CGFloat) -> CGFloat {
        guard dataPoints.count > 1 else { return chartLeft }
        let first = dataPoints.first!.date.timeIntervalSince1970
        let last  = dataPoints.last!.date.timeIntervalSince1970
        let t = (point.date.timeIntervalSince1970 - first) / (last - first)
        return chartLeft + CGFloat(t) * chartW
    }

    private func yPosition(value: Double, height: CGFloat) -> CGFloat {
        let t = (value - yMin) / (yMax - yMin)
        return height - CGFloat(t) * height
    }

    private func pointPosition(point: SkillDataPoint, chartLeft: CGFloat, chartW: CGFloat, height: CGFloat) -> CGPoint {
        CGPoint(
            x: xPosition(point: point, chartLeft: chartLeft, chartW: chartW),
            y: yPosition(value: point.rating, height: height)
        )
    }

    private func linePath(points: [SkillDataPoint], chartLeft: CGFloat, chartW: CGFloat, height: CGFloat) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        let positions = points.map { pointPosition(point: $0, chartLeft: chartLeft, chartW: chartW, height: height) }
        path.move(to: positions[0])
        for i in 1..<positions.count {
            let prev = positions[i - 1]
            let curr = positions[i]
            let mid = CGPoint(x: (prev.x + curr.x) / 2, y: (prev.y + curr.y) / 2)
            path.addQuadCurve(to: mid, control: prev)
            path.addQuadCurve(to: curr, control: mid)
        }
        return path
    }

    private func fillPath(points: [SkillDataPoint], chartLeft: CGFloat, chartW: CGFloat, height: CGFloat) -> Path {
        var path = linePath(points: points, chartLeft: chartLeft, chartW: chartW, height: height)
        guard let last = points.last, let first = points.first else { return path }
        let lastX = xPosition(point: last, chartLeft: chartLeft, chartW: chartW)
        let firstX = xPosition(point: first, chartLeft: chartLeft, chartW: chartW)
        path.addLine(to: CGPoint(x: lastX, y: height))
        path.addLine(to: CGPoint(x: firstX, y: height))
        path.closeSubpath()
        return path
    }

    @ViewBuilder
    private func calloutBubble(for point: SkillDataPoint) -> some View {
        VStack(spacing: 2) {
            Text(String(format: "%.2f", point.rating))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(Color.dinkrGreen)
            Text(point.date.formatted(.dateTime.month(.abbreviated).day()))
                .font(.system(size: 10))
                .foregroundColor(Color.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.dinkrGreen.opacity(0.3), lineWidth: 1)
        )
    }

    private var xAxisLabels: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let chartLeft: CGFloat = 36
            let chartW = w - chartLeft - 8

            // Only show one label per unique month
            let uniqueMonths: [SkillDataPoint] = {
                var seen = Set<String>()
                var result: [SkillDataPoint] = []
                let fmt = DateFormatter()
                fmt.dateFormat = "MMM"
                for dp in dataPoints {
                    let key = fmt.string(from: dp.date)
                    if seen.insert(key).inserted { result.append(dp) }
                }
                return result
            }()

            ForEach(uniqueMonths) { point in
                let x = xPosition(point: point, chartLeft: chartLeft, chartW: chartW)
                let fmt = DateFormatter()
                let _ = { fmt.dateFormat = "MMM" }()
                Text(fmt.string(from: point.date))
                    .font(.system(size: 10))
                    .foregroundColor(Color.secondary.opacity(0.7))
                    .position(x: x, y: 8)
            }
        }
        .frame(height: 18)
    }
}

// MARK: - Stat Tile

private struct StatTile: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.secondary)
            }
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(accentColor)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(Color.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Skill Category Bar

private struct SkillCategoryRow: View {
    let label: String
    let score: Double     // out of 10
    let isStrongest: Bool

    private let barMax: Double = 10.0

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                HStack(spacing: 6) {
                    Text(label)
                        .font(.system(size: 13, weight: isStrongest ? .bold : .regular))
                        .foregroundColor(isStrongest ? Color.primary : Color.secondary)
                    if isStrongest {
                        Text("★")
                            .font(.system(size: 11))
                            .foregroundColor(Color.dinkrAmber)
                    }
                }
                Spacer()
                Text(String(format: "%.1f/10", score))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(isStrongest ? Color.dinkrGreen : Color.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.12))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(isStrongest ? Color.dinkrGreen : Color.dinkrSky)
                        .frame(width: geo.size.width * CGFloat(score / barMax), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Recent Rating Row

private struct RecentRatingRow: View {
    let result: GameResult
    let newRating: Double
    let oldRating: Double

    private var delta: Double { newRating - oldRating }

    var body: some View {
        HStack(spacing: 12) {
            // W/L badge
            Text(result.isWin ? "W" : "L")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color.white)
                .frame(width: 28, height: 28)
                .background(result.isWin ? Color.dinkrGreen : Color.dinkrCoral)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text("vs \(result.opponentName)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.primary)
                Text(result.scoreDisplay + " · " + result.playedAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 11))
                    .foregroundColor(Color.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f", newRating))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.primary)
                HStack(spacing: 2) {
                    Image(systemName: delta >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                    Text(String(format: "%.2f", abs(delta)))
                        .font(.system(size: 11, design: .monospaced))
                }
                .foregroundColor(delta >= 0 ? Color.dinkrGreen : Color.dinkrCoral)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
    }
}

// MARK: - SkillProgressView

struct SkillProgressView: View {
    @State private var selectedDataPoint: SkillDataPoint? = nil

    private let dataPoints: [SkillDataPoint] = SkillDataPoint.mockHistory

    private var currentRating: Double { dataPoints.last?.rating ?? 0 }
    private var firstRating: Double   { dataPoints.first?.rating ?? 0 }
    private var ratingGain: Double    { currentRating - firstRating }

    private let skillCategories: [(name: String, score: Double, strongest: Bool)] = [
        ("Net Play",          8.2, true),
        ("Dinking",           7.4, false),
        ("Third Shot Drop",   6.8, false),
        ("Serving",           7.1, false),
        ("Reset",             6.2, false),
    ]

    // Interleave mock results with simulated rating history for the last 5 games
    private var recentRatedGames: [(result: GameResult, newRating: Double, oldRating: Double)] {
        let results = Array(GameResult.mockResults.prefix(5))
        let ratingSteps: [(Double, Double)] = [
            (4.00, 3.92),
            (3.92, 3.85),
            (3.85, 3.80),
            (3.80, 3.72),
            (3.72, 3.65),
        ]
        return zip(results, ratingSteps).map { (result: $0.0, newRating: $0.1.0, oldRating: $0.1.1) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header card
                    headerCard

                    // Line chart
                    chartCard

                    // Stat tiles
                    statTilesRow

                    // Strengths / Weaknesses
                    strengthsCard

                    // Recent rating history
                    recentHistorySection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Skill Progress")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: Sub-sections

    private var headerCard: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Rating")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.secondary)

                Text(String(format: "%.1f", currentRating))
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.dinkrNavy)

                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(Color.dinkrGreen)
                    Text(String(format: "+%.2f since joining", ratingGain))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.dinkrGreen)
                }
            }

            Spacer()

            VStack(spacing: 8) {
                // Level badge
                Text("Advanced")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.dinkrNavy)
                    .clipShape(Capsule())

                Text("4.0 Level")
                    .font(.system(size: 11))
                    .foregroundColor(Color.secondary)

                // Progress ring placeholder
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: CGFloat((currentRating - 2.0) / 3.0))
                        .stroke(Color.dinkrGreen, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 52, height: 52)
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Rating History")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.primary)
                Spacer()
                Text("6 months")
                    .font(.system(size: 12))
                    .foregroundColor(Color.secondary)
            }

            SkillLineChart(dataPoints: dataPoints, selectedPoint: $selectedDataPoint)
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    private var statTilesRow: some View {
        HStack(spacing: 10) {
            StatTile(title: "Win Rate",     value: "68%",  subtitle: "↑ 4% vs last month", icon: "🏆", accentColor: Color.dinkrGreen)
            StatTile(title: "Avg Rally",    value: "8.4",  subtitle: "shots per rally",     icon: "🎯", accentColor: Color.dinkrSky)
            StatTile(title: "Best Streak",  value: "7W",   subtitle: "current record",      icon: "🔥", accentColor: Color.dinkrAmber)
        }
    }

    private var strengthsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Skills Breakdown")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.primary)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.dinkrGreen)
                        .frame(width: 8, height: 8)
                    Text("Strongest")
                        .font(.system(size: 11))
                        .foregroundColor(Color.secondary)
                }
            }

            VStack(spacing: 0) {
                ForEach(skillCategories, id: \.name) { category in
                    SkillCategoryRow(
                        label: category.name,
                        score: category.score,
                        isStrongest: category.strongest
                    )
                    if category.name != skillCategories.last?.name {
                        Divider().opacity(0.5)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    private var recentHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Rated Games")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.primary)

            VStack(spacing: 8) {
                ForEach(recentRatedGames, id: \.result.id) { entry in
                    RecentRatingRow(
                        result: entry.result,
                        newRating: entry.newRating,
                        oldRating: entry.oldRating
                    )
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SkillProgressView()
}

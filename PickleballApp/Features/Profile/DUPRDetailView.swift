import SwiftUI

// MARK: - DUPRDetailView

struct DUPRDetailView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: State
    @State private var selectedRange: TimeRange = .threeMonths
    @State private var dragIndex: Int? = nil
    @State private var dragLocation: CGFloat = 0
    @State private var lineProgress: CGFloat = 0
    @State private var expandedEntryId: String? = nil

    // MARK: - Time Range

    enum TimeRange: String, CaseIterable {
        case oneMonth  = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear   = "1Y"
        case all       = "All"

        var days: Int {
            switch self {
            case .oneMonth:    return 30
            case .threeMonths: return 90
            case .sixMonths:   return 180
            case .oneYear:     return 365
            case .all:         return Int.max
            }
        }
    }

    // MARK: - Filtered Data

    private var allData: [DUPRDataPoint] { DUPRDataPoint.mockHistory }

    private var filteredData: [DUPRDataPoint] {
        guard selectedRange != .all else { return allData }
        let cutoff = Calendar.current.date(
            byAdding: .day, value: -selectedRange.days, to: Date()
        ) ?? Date.distantPast
        let result = allData.filter { $0.date >= cutoff }
        return result.isEmpty ? allData : result
    }

    private var currentRating: Double { filteredData.last?.rating ?? 3.67 }
    private var firstRating: Double   { filteredData.first?.rating ?? 3.42 }
    private var ratingChange: Double  { currentRating - firstRating }

    private var minRating: Double { (filteredData.map(\.rating).min() ?? 3.42) - 0.05 }
    private var maxRating: Double { (filteredData.map(\.rating).max() ?? 3.67) + 0.05 }
    private var ratingRange: Double  { maxRating - minRating }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerCard
                    timeRangePicker
                    lineChartCard
                    ratingBreakdownCard
                    historyTimeline
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 48)
            }
            .background(Color.appBackground)
            .navigationTitle("DUPR History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current DUPR")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(String(format: "%.2f", currentRating))
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(Color.primary)

                    // Trend arrow
                    Image(systemName: ratingChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(ratingChange >= 0 ? Color.dinkrGreen : Color.dinkrCoral)
                }

                // 3-month change label
                let label3M: String = {
                    let pts = allData.filter {
                        $0.date >= (Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date())
                    }
                    let delta = (pts.last?.rating ?? currentRating) - (pts.first?.rating ?? currentRating)
                    return String(format: "%+.2f 3-month change", delta)
                }()

                Text(label3M)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ratingChange >= 0 ? Color.dinkrGreen : Color.dinkrCoral)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background((ratingChange >= 0 ? Color.dinkrGreen : Color.dinkrCoral).opacity(0.12))
                    .clipShape(Capsule())
            }

            Spacer()

            // Amber DUPR badge
            VStack(spacing: 4) {
                Text(String(format: "%.2f", currentRating))
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(Color.dinkrAmber)
                Text("DUPR")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.dinkrAmber.opacity(0.7))
            }
            .frame(width: 72, height: 72)
            .background(Color.dinkrAmber.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.dinkrAmber.opacity(0.35), lineWidth: 1.5))
        }
        .padding(20)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedRange = range
                        lineProgress = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            lineProgress = 1.0
                        }
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(selectedRange == range ? Color.white : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selectedRange == range
                                ? Color.dinkrGreen
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                }
            }
        }
        .padding(4)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Line Chart Card

    private var lineChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Drag tooltip
            if let idx = dragIndex, idx < filteredData.count {
                let pt = filteredData[idx]
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pt.date, style: .date)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f", pt.rating))
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(Color.primary)
                    }
                    Spacer()
                    changeChip(change: pt.change)
                }
                .padding(.horizontal, 4)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                HStack {
                    Text("Drag to explore")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.horizontal, 4)
            }

            // Chart
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                ZStack {
                    // Horizontal grid lines (4 lines)
                    ForEach(0..<5, id: \.self) { i in
                        let y = h * CGFloat(i) / 4.0
                        Path { p in
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: w, y: y))
                        }
                        .stroke(Color.secondary.opacity(0.08),
                                style: StrokeStyle(lineWidth: 1, dash: [4, 5]))
                    }

                    // Gradient fill
                    DUPRDetailFillShape(
                        data: filteredData.map(\.rating),
                        minVal: minRating,
                        valueRange: ratingRange,
                        progress: lineProgress
                    )
                    .fill(
                        LinearGradient(
                            colors: [Color.dinkrGreen.opacity(0.30), Color.dinkrGreen.opacity(0.0)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                    // Line
                    DUPRDetailLinePath(
                        data: filteredData.map(\.rating),
                        minVal: minRating,
                        valueRange: ratingRange,
                        progress: lineProgress
                    )
                    .stroke(
                        LinearGradient(
                            colors: [Color.dinkrGreen.opacity(0.6), Color.dinkrGreen],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )

                    // Min / max annotations
                    let ratings = filteredData.map(\.rating)
                    if let minIdx = ratings.indices.min(by: { ratings[$0] < ratings[$1] }),
                       let maxIdx = ratings.indices.max(by: { ratings[$0] < ratings[$1] }) {

                        let minX = chartX(index: minIdx, count: ratings.count, width: w)
                        let minY = chartY(value: ratings[minIdx], height: h)
                        let maxX = chartX(index: maxIdx, count: ratings.count, width: w)
                        let maxY = chartY(value: ratings[maxIdx], height: h)

                        // Min label
                        annotationLabel(
                            text: String(format: "%.2f", ratings[minIdx]),
                            color: Color.dinkrCoral,
                            x: minX, y: minY + 16, width: w
                        )

                        // Max label
                        annotationLabel(
                            text: String(format: "%.2f", ratings[maxIdx]),
                            color: Color.dinkrGreen,
                            x: maxX, y: maxY - 16, width: w
                        )
                    }

                    // Data point dots
                    ForEach(filteredData.indices, id: \.self) { i in
                        let x = chartX(index: i, count: filteredData.count, width: w)
                        let y = chartY(value: filteredData[i].rating, height: h)
                        let isSelected = dragIndex == i

                        ZStack {
                            if isSelected {
                                Circle()
                                    .fill(Color.dinkrGreen.opacity(0.2))
                                    .frame(width: 22, height: 22)
                            }
                            Circle()
                                .fill(Color.dinkrGreen)
                                .frame(width: isSelected ? 11 : 7, height: isSelected ? 11 : 7)
                            Circle()
                                .fill(Color.white)
                                .frame(width: isSelected ? 5 : 3, height: isSelected ? 5 : 3)
                        }
                        .position(x: x, y: y)
                        .opacity(lineProgress > CGFloat(i) / CGFloat(max(filteredData.count - 1, 1)) ? 1 : 0)
                        .animation(.easeIn(duration: 0.1).delay(Double(i) * 0.07 + 0.3), value: lineProgress)
                    }

                    // Drag vertical line
                    if let idx = dragIndex, idx < filteredData.count {
                        let x = chartX(index: idx, count: filteredData.count, width: w)
                        Path { p in
                            p.move(to: CGPoint(x: x, y: 0))
                            p.addLine(to: CGPoint(x: x, y: h))
                        }
                        .stroke(Color.dinkrGreen.opacity(0.4),
                                style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    }
                }
                // Drag gesture
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let x = value.location.x
                            dragLocation = x
                            let idx = closestIndex(to: x, count: filteredData.count, width: w)
                            withAnimation(.easeOut(duration: 0.1)) {
                                dragIndex = idx
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.easeOut(duration: 0.3)) {
                                dragIndex = nil
                            }
                        }
                )
            }
            .frame(height: 160)
            .clipped()

            // X-axis date labels
            let step = max(1, filteredData.count / 4)
            HStack(spacing: 0) {
                ForEach(Array(stride(from: 0, to: filteredData.count, by: step)), id: \.self) { i in
                    Text(filteredData[i].date, format: .dateTime.month(.abbreviated).day())
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) {
                lineProgress = 1.0
            }
        }
        .onChange(of: selectedRange) { _, _ in
            lineProgress = 0
            withAnimation(.easeInOut(duration: 1.0).delay(0.1)) {
                lineProgress = 1.0
            }
        }
    }

    // MARK: - Chart Helpers

    private func chartX(index: Int, count: Int, width: CGFloat) -> CGFloat {
        guard count > 1 else { return width / 2 }
        return width * CGFloat(index) / CGFloat(count - 1)
    }

    private func chartY(value: Double, height: CGFloat) -> CGFloat {
        let normalized = (value - minRating) / ratingRange
        return height * (1.0 - CGFloat(normalized))
    }

    private func closestIndex(to x: CGFloat, count: Int, width: CGFloat) -> Int {
        guard count > 1 else { return 0 }
        let step = width / CGFloat(count - 1)
        let raw = x / step
        return max(0, min(count - 1, Int(raw.rounded())))
    }

    private func annotationLabel(
        text: String, color: Color,
        x: CGFloat, y: CGFloat, width: CGFloat
    ) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
            .position(
                x: min(max(x, 22), width - 22),
                y: y
            )
    }

    // MARK: - Rating Breakdown Card

    private var ratingBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.dinkrGreen)
                Text("Rating Breakdown")
                    .font(.headline.weight(.bold))
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                BreakdownTile(label: "Singles DUPR",   value: "3.45", accent: Color.dinkrSky,   icon: "person.fill")
                BreakdownTile(label: "Doubles DUPR",   value: "3.67", accent: Color.dinkrGreen, icon: "person.2.fill", isBadged: true)
                BreakdownTile(label: "Verified Matches", value: "28",  accent: Color.dinkrAmber, icon: "checkmark.seal.fill")
                BreakdownTile(label: "Reliability",    value: "95%",  accent: Color(red: 0.55, green: 0.35, blue: 0.85), icon: "shield.fill")
            }
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - History Timeline

    private var historyTimeline: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.dinkrGreen)
                Text("Match History")
                    .font(.headline.weight(.bold))
                Spacer()
                Text("\(filteredData.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(filteredData.reversed()) { point in
                    historyRow(point: point)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }

    private func historyRow(point: DUPRDataPoint) -> some View {
        let isExpanded = expandedEntryId == point.id

        return VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    expandedEntryId = isExpanded ? nil : point.id
                }
            } label: {
                HStack(spacing: 12) {
                    // Date + rating column
                    VStack(alignment: .leading, spacing: 2) {
                        Text(point.date, format: .dateTime.month(.abbreviated).day().year())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f", point.rating))
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(Color.primary)
                    }

                    Spacer()

                    // Opponent
                    if let opp = point.opponentName {
                        Text("vs \(opp)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    // Change chip
                    changeChip(change: point.change)

                    // Expand chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.appBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    isExpanded
                                        ? Color.dinkrGreen.opacity(0.3)
                                        : Color.secondary.opacity(0.1),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(.plain)

            // Expanded game detail mini-card
            if isExpanded {
                gameDetailMiniCard(point: point)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 4)
            }
        }
    }

    private func gameDetailMiniCard(point: DUPRDataPoint) -> some View {
        HStack(spacing: 16) {
            // Result badge
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(point.isWin ? Color.dinkrGreen.opacity(0.12) : Color.dinkrCoral.opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(point.isWin ? "W" : "L")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(point.isWin ? Color.dinkrGreen : Color.dinkrCoral)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(point.opponentName.map { "vs \($0)" } ?? "Match")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
                if let gid = point.gameId {
                    Text("Game ID: \(gid)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(point.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f", point.rating))
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Color.primary)
                changeChip(change: point.change, compact: true)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.dinkrGreen.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Change Chip

    @ViewBuilder
    private func changeChip(change: Double, compact: Bool = false) -> some View {
        let isPositive = change >= 0
        let color = isPositive ? Color.dinkrGreen : Color.dinkrCoral
        let symbol = isPositive ? "+" : ""
        HStack(spacing: 3) {
            Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                .font(.system(size: compact ? 8 : 9, weight: .bold))
            Text("\(symbol)\(String(format: "%.2f", change))")
                .font(.system(size: compact ? 10 : 11, weight: .bold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 3 : 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 0.8))
    }
}

// MARK: - Breakdown Tile

private struct BreakdownTile: View {
    let label: String
    let value: String
    let accent: Color
    let icon: String
    var isBadged: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(value)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.primary)
                    if isBadged {
                        Text("main")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Color.dinkrGreen)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.dinkrGreen.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(accent.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accent.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

// MARK: - Chart Shapes

private struct DUPRDetailLinePath: Shape {
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

        func pt(_ i: Int) -> CGPoint {
            let x = w * CGFloat(i) / CGFloat(data.count - 1)
            let n = (data[i] - minVal) / valueRange
            return CGPoint(x: x, y: h * (1.0 - CGFloat(n)))
        }

        path.move(to: pt(0))
        for i in 1..<data.count {
            let p = pt(i - 1), c = pt(i)
            let mx = (p.x + c.x) / 2
            path.addCurve(to: c,
                          control1: CGPoint(x: mx, y: p.y),
                          control2: CGPoint(x: mx, y: c.y))
        }
        return path.trimmedPath(from: 0, to: progress)
    }
}

private struct DUPRDetailFillShape: Shape {
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

        func pt(_ i: Int) -> CGPoint {
            let x = w * CGFloat(i) / CGFloat(data.count - 1)
            let n = (data[i] - minVal) / valueRange
            return CGPoint(x: x, y: h * (1.0 - CGFloat(n)))
        }

        let clampedCount = max(2, Int(CGFloat(data.count - 1) * progress) + 1)
        let endIdx = min(clampedCount, data.count) - 1

        path.move(to: CGPoint(x: 0, y: h))
        path.addLine(to: pt(0))

        for i in 1...endIdx {
            let p = pt(i - 1), c = pt(i)
            let mx = (p.x + c.x) / 2
            path.addCurve(to: c,
                          control1: CGPoint(x: mx, y: p.y),
                          control2: CGPoint(x: mx, y: c.y))
        }

        path.addLine(to: CGPoint(x: pt(endIdx).x, y: h))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    DUPRDetailView()
        .preferredColorScheme(.dark)
}

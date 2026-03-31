import SwiftUI

// MARK: - Market Insights View

struct MarketInsightsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    trendingGearSection
                    priceTrendsSection
                    bestTimeToBuyCard
                    categoryBreakdownSection
                    recentlySoldSection
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Market Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .tint(Color.dinkrGreen)
                }
            }
        }
    }

    // MARK: - Trending Gear

    private var trendingGearSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text("🔥")
                    .font(.title3)
                Text("Trending Gear")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.dinkrCoral)
                Spacer()
                Text("This week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                ForEach(Array(InsightsData.trendingItems.enumerated()), id: \.offset) { index, item in
                    TrendingRowView(rank: index + 1, item: item)
                    if index < InsightsData.trendingItems.count - 1 {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }

    // MARK: - Price Trends Bar Chart (manual, no Charts import)

    private var priceTrendsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Avg Paddle Prices")
                    .font(.headline.weight(.bold))
                Spacer()
                Text("Last 6 months")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            let maxPrice: Double = (InsightsData.monthlyPrices.map { $0.avgPrice }.max() ?? 200) * 1.15
            let barColor = Color.dinkrGreen

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(InsightsData.monthlyPrices) { data in
                    VStack(spacing: 6) {
                        Text("$\(Int(data.avgPrice))")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.dinkrNavy)

                        GeometryReader { geo in
                            VStack {
                                Spacer(minLength: 0)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [barColor, barColor.opacity(0.6)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(
                                        height: max(4, geo.size.height * CGFloat(data.avgPrice / maxPrice))
                                    )
                            }
                        }

                        Text(data.month)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 130)

            HStack {
                Circle()
                    .fill(Color.dinkrGreen)
                    .frame(width: 8, height: 8)
                Text("Average resale price (USD)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Best Time to Buy Tip Card

    private var bestTimeToBuyCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.dinkrAmber.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.dinkrAmber)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Best Time to Buy")
                    .font(.subheadline.weight(.bold))
                Text("Paddle prices drop ~15% after major tournaments. Look for deals in Jan, May, and Sep.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.dinkrAmber.opacity(0.08), Color.dinkrAmber.opacity(0.02)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.dinkrAmber.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Category Breakdown (manual pie chart)

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Sales by Category")
                .font(.headline.weight(.bold))

            HStack(spacing: 20) {
                PieChartView(slices: InsightsData.categorySlices)
                    .frame(width: 130, height: 130)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(InsightsData.categorySlices) { slice in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(slice.color)
                                .frame(width: 10, height: 10)
                            Text(slice.label)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(Int(slice.percent))%")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(slice.color)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Recently Sold

    private var recentlySoldSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recently Sold")
                    .font(.headline.weight(.bold))
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Color.dinkrGreen)
                    .font(.subheadline)
            }

            VStack(spacing: 0) {
                ForEach(Array(InsightsData.recentlySold.enumerated()), id: \.offset) { index, item in
                    RecentlySoldRowView(item: item)
                    if index < InsightsData.recentlySold.count - 1 {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }
}

// MARK: - Subviews

struct TrendingRowView: View {
    let rank: Int
    let item: InsightsData.TrendingItem

    private var rankColor: Color {
        switch rank {
        case 1: return Color.dinkrCoral
        case 2: return Color.dinkrAmber
        case 3: return Color.dinkrSky
        default: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Text("#\(rank)")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(rankColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                Text(item.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .font(.caption2)
                    .foregroundStyle(Color.dinkrGreen)
                Text("\(item.searchCount) searches")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrGreen)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

struct RecentlySoldRowView: View {
    let item: InsightsData.SoldItem

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.10))
                    .frame(width: 36, height: 36)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.dinkrGreen)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                Text(item.timeAgo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("$\(Int(item.price))")
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(Color.dinkrCoral)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Manual Pie Chart

struct PieSlice: Identifiable {
    let id = UUID()
    let label: String
    let percent: Double
    let color: Color
}

struct PieChartView: View {
    let slices: [PieSlice]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size / 2

            ZStack {
                ForEach(Array(slices.enumerated()), id: \.offset) { index, slice in
                    let (startAngle, endAngle) = angleRange(for: index)
                    PieSliceShape(
                        center: center,
                        radius: radius,
                        startAngle: startAngle,
                        endAngle: endAngle
                    )
                    .fill(slice.color)
                }

                // Center circle for donut effect
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: size * 0.45, height: size * 0.45)
            }
        }
    }

    private func angleRange(for index: Int) -> (Angle, Angle) {
        let total = slices.reduce(0) { $0 + $1.percent }
        var start: Double = -90
        for i in 0..<index {
            start += (slices[i].percent / total) * 360
        }
        let end = start + (slices[index].percent / total) * 360
        return (.degrees(start), .degrees(end))
    }
}

struct PieSliceShape: Shape {
    let center: CGPoint
    let radius: CGFloat
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Mock Data

enum InsightsData {
    struct TrendingItem {
        let name: String
        let category: String
        let searchCount: Int
    }

    struct MonthlyPrice: Identifiable {
        let id = UUID()
        let month: String
        let avgPrice: Double
    }

    struct SoldItem {
        let name: String
        let price: Double
        let timeAgo: String
    }

    static let trendingItems: [TrendingItem] = [
        TrendingItem(name: "Selkirk Vanguard Power Air", category: "Paddles", searchCount: 312),
        TrendingItem(name: "JOOLA Hyperion CAS 16", category: "Paddles", searchCount: 278),
        TrendingItem(name: "Electrum Model E Pro", category: "Paddles", searchCount: 241),
        TrendingItem(name: "HEAD Tour Team Backpack", category: "Bags", searchCount: 189),
        TrendingItem(name: "K-Swiss Hypercourt Express", category: "Shoes", searchCount: 163),
    ]

    static let monthlyPrices: [MonthlyPrice] = [
        MonthlyPrice(month: "Oct", avgPrice: 142),
        MonthlyPrice(month: "Nov", avgPrice: 155),
        MonthlyPrice(month: "Dec", avgPrice: 168),
        MonthlyPrice(month: "Jan", avgPrice: 131),
        MonthlyPrice(month: "Feb", avgPrice: 147),
        MonthlyPrice(month: "Mar", avgPrice: 153),
    ]

    static let categorySlices: [PieSlice] = [
        PieSlice(label: "Paddles",     percent: 48, color: Color.dinkrCoral),
        PieSlice(label: "Shoes",       percent: 18, color: Color.dinkrSky),
        PieSlice(label: "Bags",        percent: 14, color: Color.dinkrNavy),
        PieSlice(label: "Apparel",     percent: 11, color: .purple),
        PieSlice(label: "Other",       percent: 9,  color: Color.dinkrAmber),
    ]

    static let recentlySold: [SoldItem] = [
        SoldItem(name: "Selkirk Amped Invikta",      price: 135, timeAgo: "2 min ago"),
        SoldItem(name: "Franklin Ben Johns Pro",      price: 95,  timeAgo: "18 min ago"),
        SoldItem(name: "HEAD Radical Pro",            price: 110, timeAgo: "1 hr ago"),
        SoldItem(name: "Gamma Overgrip 30-Pack",      price: 18,  timeAgo: "3 hrs ago"),
        SoldItem(name: "ONIX Pure 2 Outdoor 6-Pack",  price: 22,  timeAgo: "5 hrs ago"),
    ]
}

#Preview {
    MarketInsightsView()
}

import SwiftUI

// MARK: - PaddleSpec Model

struct PaddleSpec: Identifiable {
    var id: String
    var brand: String
    var model: String
    var price: Double
    var weight: String
    var gripSize: String
    var coreThickness: String
    var coreMaterial: String
    var faceMaterial: String
    var shape: String
    var powerRating: Int
    var controlRating: Int
    var spinRating: Int
    var popRating: Int
    var bestFor: String
    var priceCategory: String
}

// MARK: - Mock Data

extension PaddleSpec {
    static let mockPaddles: [PaddleSpec] = [
        PaddleSpec(
            id: "ps_001", brand: "Selkirk", model: "Power Air",
            price: 229.99, weight: "7.6 oz", gripSize: "4 1/4\"",
            coreThickness: "16mm", coreMaterial: "Polypropylene",
            faceMaterial: "Raw Carbon", shape: "Standard",
            powerRating: 8, controlRating: 7, spinRating: 9, popRating: 8,
            bestFor: "Power players", priceCategory: "Premium"
        ),
        PaddleSpec(
            id: "ps_002", brand: "JOOLA", model: "Ben Johns Hyperion CAS 16",
            price: 249.99, weight: "7.9 oz", gripSize: "4 1/8\"",
            coreThickness: "16mm", coreMaterial: "Carbon Fiber",
            faceMaterial: "T700 Carbon", shape: "Elongated",
            powerRating: 9, controlRating: 8, spinRating: 9, popRating: 9,
            bestFor: "All-around elite", priceCategory: "Pro"
        ),
        PaddleSpec(
            id: "ps_003", brand: "Franklin", model: "Ben Johns Signature",
            price: 89.99, weight: "7.8 oz", gripSize: "4 1/4\"",
            coreThickness: "14mm", coreMaterial: "Polypropylene",
            faceMaterial: "Fiberglass", shape: "Standard",
            powerRating: 6, controlRating: 7, spinRating: 5, popRating: 6,
            bestFor: "Beginners & 3.0-3.5", priceCategory: "Budget"
        ),
        PaddleSpec(
            id: "ps_004", brand: "Engage", model: "Pursuit EX",
            price: 179.99, weight: "8.1 oz", gripSize: "4 1/4\"",
            coreThickness: "19mm", coreMaterial: "Polypropylene",
            faceMaterial: "Fiberglass", shape: "Standard",
            powerRating: 6, controlRating: 9, spinRating: 6, popRating: 7,
            bestFor: "Control game", priceCategory: "Premium"
        ),
        PaddleSpec(
            id: "ps_005", brand: "CRBN", model: "CRBN-1",
            price: 219.99, weight: "7.5 oz", gripSize: "4 1/8\"",
            coreThickness: "16mm", coreMaterial: "Carbon Fiber",
            faceMaterial: "Raw Carbon", shape: "Elongated",
            powerRating: 8, controlRating: 8, spinRating: 10, popRating: 8,
            bestFor: "Spin specialists", priceCategory: "Premium"
        ),
        PaddleSpec(
            id: "ps_006", brand: "Paddletek", model: "Tempest Wave Pro",
            price: 149.99, weight: "7.7 oz", gripSize: "4 3/8\"",
            coreThickness: "13mm", coreMaterial: "Polypropylene",
            faceMaterial: "Fiberglass", shape: "Standard",
            powerRating: 7, controlRating: 8, spinRating: 6, popRating: 7,
            bestFor: "All-around mid-level", priceCategory: "Mid-range"
        ),
        PaddleSpec(
            id: "ps_007", brand: "ProXR", model: "Prism",
            price: 189.99, weight: "7.6 oz", gripSize: "4 1/4\"",
            coreThickness: "16mm", coreMaterial: "Carbon Fiber",
            faceMaterial: "T700 Carbon", shape: "Hybrid",
            powerRating: 8, controlRating: 7, spinRating: 8, popRating: 9,
            bestFor: "Power & pop", priceCategory: "Premium"
        ),
        PaddleSpec(
            id: "ps_008", brand: "HEAD", model: "Radical Tour",
            price: 139.99, weight: "8.0 oz", gripSize: "4 3/8\"",
            coreThickness: "14mm", coreMaterial: "Polypropylene",
            faceMaterial: "Fiberglass", shape: "Standard",
            powerRating: 7, controlRating: 7, spinRating: 6, popRating: 7,
            bestFor: "Recreational to 4.0", priceCategory: "Mid-range"
        )
    ]

    /// Value rating derived from price vs performance
    var valueRating: Int {
        let avgPerf = Double(powerRating + controlRating + spinRating + popRating) / 4.0
        switch price {
        case ..<100: return min(10, Int(avgPerf) + 2)
        case 100..<160: return min(10, Int(avgPerf) + 1)
        case 160..<200: return Int(avgPerf)
        default: return max(1, Int(avgPerf) - 1)
        }
    }
}

// MARK: - Radar Chart

struct RadarChartView: View {
    let paddleA: PaddleSpec?
    let paddleB: PaddleSpec?

    private let labels = ["Power", "Control", "Spin", "Pop", "Value"]
    private let axisCount = 5
    private let levels = 5

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size * 0.38

            ZStack {
                // Background grid rings
                ForEach(1...levels, id: \.self) { level in
                    let r = radius * CGFloat(level) / CGFloat(levels)
                    Path { path in
                        for i in 0..<axisCount {
                            let pt = point(for: i, radius: r, center: center)
                            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
                        }
                        path.closeSubpath()
                    }
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                }

                // Axis lines
                ForEach(0..<axisCount, id: \.self) { i in
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: point(for: i, radius: radius, center: center))
                    }
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                }

                // Paddle A fill
                if let a = paddleA {
                    radarPath(ratings: ratingsFor(a), radius: radius, center: center)
                        .fill(Color.dinkrGreen.opacity(0.25))
                    radarPath(ratings: ratingsFor(a), radius: radius, center: center)
                        .stroke(Color.dinkrGreen, lineWidth: 2)
                }

                // Paddle B fill
                if let b = paddleB {
                    radarPath(ratings: ratingsFor(b), radius: radius, center: center)
                        .fill(Color.dinkrCoral.opacity(0.25))
                    radarPath(ratings: ratingsFor(b), radius: radius, center: center)
                        .stroke(Color.dinkrCoral, lineWidth: 2)
                }

                // Axis labels
                ForEach(0..<axisCount, id: \.self) { i in
                    let labelPt = point(for: i, radius: radius + 22, center: center)
                    Text(labels[i])
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .position(labelPt)
                }
            }
        }
    }

    private func ratingsFor(_ p: PaddleSpec) -> [Int] {
        [p.powerRating, p.controlRating, p.spinRating, p.popRating, p.valueRating]
    }

    private func angle(for index: Int) -> Double {
        let slice = (2.0 * .pi) / Double(axisCount)
        return slice * Double(index) - (.pi / 2)
    }

    private func point(for index: Int, radius: CGFloat, center: CGPoint) -> CGPoint {
        let a = angle(for: index)
        return CGPoint(
            x: center.x + radius * CGFloat(cos(a)),
            y: center.y + radius * CGFloat(sin(a))
        )
    }

    private func radarPath(ratings: [Int], radius: CGFloat, center: CGPoint) -> Path {
        Path { path in
            for (i, rating) in ratings.enumerated() {
                let r = radius * CGFloat(rating) / 10.0
                let pt = point(for: i, radius: r, center: center)
                if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }
            path.closeSubpath()
        }
    }
}

// MARK: - Dot Rating Bar

struct DotRatingBar: View {
    let value: Int
    let maxValue: Int
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<maxValue, id: \.self) { i in
                Circle()
                    .fill(i < value ? color : Color.secondary.opacity(0.2))
                    .frame(width: 7, height: 7)
            }
        }
    }
}

// MARK: - Comparison Row

struct CompareRow: View {
    let label: String
    let valueA: String
    let valueB: String
    let winnerA: Bool?   // nil = no winner (equal or not applicable)
    let winnerB: Bool?
    let ratingA: Int?
    let ratingB: Int?
    var isAlternate: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            // Value A
            ZStack {
                if winnerA == true {
                    Color.dinkrGreen.opacity(0.15)
                } else {
                    Color.clear
                }
                if let ra = ratingA {
                    DotRatingBar(value: ra, maxValue: 10, color: Color.dinkrGreen)
                        .padding(.horizontal, 8)
                } else {
                    Text(valueA)
                        .font(.caption.weight(winnerA == true ? .bold : .regular))
                        .foregroundStyle(winnerA == true ? Color.dinkrGreen : .primary)
                        .padding(.horizontal, 8)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)

            // Label
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(width: 90)
                .frame(height: 36)
                .background(isAlternate ? Color.cardBackground.opacity(0.5) : Color.clear)

            // Value B
            ZStack {
                if winnerB == true {
                    Color.dinkrCoral.opacity(0.15)
                } else {
                    Color.clear
                }
                if let rb = ratingB {
                    DotRatingBar(value: rb, maxValue: 10, color: Color.dinkrCoral)
                        .padding(.horizontal, 8)
                } else {
                    Text(valueB)
                        .font(.caption.weight(winnerB == true ? .bold : .regular))
                        .foregroundStyle(winnerB == true ? Color.dinkrCoral : .primary)
                        .padding(.horizontal, 8)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
        }
        .background(isAlternate ? Color.cardBackground.opacity(0.3) : Color.clear)
    }
}

// MARK: - Paddle Picker Sheet

struct PaddlePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (PaddleSpec) -> Void
    let exclude: PaddleSpec?

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var available: [PaddleSpec] {
        PaddleSpec.mockPaddles.filter { $0.id != exclude?.id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(available) { paddle in
                        Button {
                            onSelect(paddle)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(paddle.priceCategory)
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(priceCategoryColor(paddle.priceCategory))
                                        .clipShape(Capsule())
                                    Spacer()
                                }
                                Image(systemName: "figure.pickleball")
                                    .font(.system(size: 28))
                                    .foregroundStyle(Color.dinkrGreen.opacity(0.7))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)

                                Text(paddle.brand)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(paddle.model)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                                Text("$\(String(format: "%.2f", paddle.price))")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Color.dinkrCoral)
                            }
                            .padding(10)
                            .background(Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Select Paddle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.dinkrCoral)
                }
            }
        }
    }

    private func priceCategoryColor(_ cat: String) -> Color {
        switch cat {
        case "Budget": return Color.dinkrGreen
        case "Mid-range": return Color.dinkrSky
        case "Premium": return Color.dinkrAmber
        case "Pro": return Color.dinkrCoral
        default: return .secondary
        }
    }
}

// MARK: - Paddle Column Header Card

struct PaddleColumnHeader: View {
    let paddle: PaddleSpec?
    let accentColor: Color
    let label: String   // "Paddle A" / "Paddle B"
    let onTap: () -> Void
    let onWishlist: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Button(action: onTap) {
                VStack(spacing: 6) {
                    if let p = paddle {
                        Image(systemName: "figure.pickleball")
                            .font(.system(size: 28))
                            .foregroundStyle(accentColor.opacity(0.8))
                        Text(p.brand)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(p.model)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        Text("$\(String(format: "%.2f", p.price))")
                            .font(.subheadline.weight(.heavy))
                            .foregroundStyle(accentColor)
                    } else {
                        Image(systemName: "plus.circle.dashed")
                            .font(.system(size: 28))
                            .foregroundStyle(accentColor.opacity(0.5))
                        Text("Tap to select")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(.secondary.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(paddle == nil ? accentColor.opacity(0.3) : accentColor.opacity(0.6), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)

            if paddle != nil {
                Button(action: onWishlist) {
                    Label("Wishlist", systemImage: "heart")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(accentColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - PaddleCompareView

struct PaddleCompareView: View {
    @State private var paddleA: PaddleSpec? = PaddleSpec.mockPaddles[0]
    @State private var paddleB: PaddleSpec? = PaddleSpec.mockPaddles[1]
    @State private var showPickerForA = false
    @State private var showPickerForB = false
    @State private var wishlistA = false
    @State private var wishlistB = false

    var priceDifference: Double? {
        guard let a = paddleA, let b = paddleB else { return nil }
        return a.price - b.price
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Column headers
                HStack(alignment: .top, spacing: 10) {
                    PaddleColumnHeader(
                        paddle: paddleA,
                        accentColor: Color.dinkrGreen,
                        label: "Paddle A",
                        onTap: { showPickerForA = true },
                        onWishlist: {
                            withAnimation(.spring(response: 0.3)) { wishlistA.toggle() }
                        }
                    )

                    VStack {
                        Text("VS")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 28)
                    .padding(.top, 28)

                    PaddleColumnHeader(
                        paddle: paddleB,
                        accentColor: Color.dinkrCoral,
                        label: "Paddle B",
                        onTap: { showPickerForB = true },
                        onWishlist: {
                            withAnimation(.spring(response: 0.3)) { wishlistB.toggle() }
                        }
                    )
                }
                .padding(.horizontal)

                // Wishlist confirmations
                HStack(spacing: 10) {
                    if wishlistA {
                        Label("Added to Wishlist", systemImage: "heart.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen)
                            .frame(maxWidth: .infinity)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Spacer().frame(maxWidth: .infinity)
                    }
                    Spacer().frame(width: 28)
                    if wishlistB {
                        Label("Added to Wishlist", systemImage: "heart.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrCoral)
                            .frame(maxWidth: .infinity)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Spacer().frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                .animation(.spring(response: 0.4), value: wishlistA)
                .animation(.spring(response: 0.4), value: wishlistB)

                // Price difference callout
                if let diff = priceDifference, diff != 0 {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(Color.dinkrAmber)
                        let cheaper = diff > 0 ? (paddleB?.model ?? "Paddle B") : (paddleA?.model ?? "Paddle A")
                        let saving = abs(diff)
                        Text("\(cheaper) saves you **$\(String(format: "%.0f", saving))**")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.dinkrAmber.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                }

                // Radar chart
                if paddleA != nil || paddleB != nil {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Performance Radar")
                                .font(.system(size: 13, weight: .bold))
                            Spacer()
                            if paddleA != nil {
                                HStack(spacing: 4) {
                                    Circle().fill(Color.dinkrGreen).frame(width: 8, height: 8)
                                    Text(paddleA?.brand ?? "").font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            if paddleB != nil {
                                HStack(spacing: 4) {
                                    Circle().fill(Color.dinkrCoral).frame(width: 8, height: 8)
                                    Text(paddleB?.brand ?? "").font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)

                        RadarChartView(paddleA: paddleA, paddleB: paddleB)
                            .frame(height: 220)
                            .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 12)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }

                // Spec comparison table
                VStack(spacing: 0) {
                    // Section header
                    HStack {
                        Text(paddleA?.brand ?? "Paddle A")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.dinkrGreen)
                            .frame(maxWidth: .infinity)
                        Text("SPEC")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(.secondary)
                            .frame(width: 90)
                        Text(paddleB?.brand ?? "Paddle B")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.dinkrCoral)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .background(Color.cardBackground)

                    Divider()

                    compareRows
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
                .padding(.horizontal)

                Spacer(minLength: 32)
            }
            .padding(.top, 12)
        }
        .navigationTitle("Compare Paddles")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPickerForA) {
            PaddlePickerSheet(onSelect: { paddleA = $0 }, exclude: paddleB)
        }
        .sheet(isPresented: $showPickerForB) {
            PaddlePickerSheet(onSelect: { paddleB = $0 }, exclude: paddleA)
        }
    }

    @ViewBuilder
    var compareRows: some View {
        let a = paddleA
        let b = paddleB

        // Price
        CompareRow(
            label: "Price",
            valueA: a.map { "$\(String(format: "%.2f", $0.price))" } ?? "—",
            valueB: b.map { "$\(String(format: "%.2f", $0.price))" } ?? "—",
            winnerA: lowerWins(a?.price, b?.price),
            winnerB: lowerWins(b?.price, a?.price),
            ratingA: nil, ratingB: nil,
            isAlternate: false
        )
        Divider()

        // Category
        CompareRow(
            label: "Category",
            valueA: a?.priceCategory ?? "—",
            valueB: b?.priceCategory ?? "—",
            winnerA: nil, winnerB: nil,
            ratingA: nil, ratingB: nil,
            isAlternate: true
        )
        Divider()

        // Weight
        CompareRow(
            label: "Weight",
            valueA: a?.weight ?? "—",
            valueB: b?.weight ?? "—",
            winnerA: lowerWeightWins(a?.weight, b?.weight),
            winnerB: lowerWeightWins(b?.weight, a?.weight),
            ratingA: nil, ratingB: nil,
            isAlternate: false
        )
        Divider()

        // Grip Size
        CompareRow(
            label: "Grip Size",
            valueA: a?.gripSize ?? "—",
            valueB: b?.gripSize ?? "—",
            winnerA: nil, winnerB: nil,
            ratingA: nil, ratingB: nil,
            isAlternate: true
        )
        Divider()

        // Core Thickness
        CompareRow(
            label: "Core",
            valueA: a?.coreThickness ?? "—",
            valueB: b?.coreThickness ?? "—",
            winnerA: nil, winnerB: nil,
            ratingA: nil, ratingB: nil,
            isAlternate: false
        )
        Divider()

        // Core Material
        CompareRow(
            label: "Core Mat.",
            valueA: a?.coreMaterial ?? "—",
            valueB: b?.coreMaterial ?? "—",
            winnerA: nil, winnerB: nil,
            ratingA: nil, ratingB: nil,
            isAlternate: true
        )
        Divider()

        // Face Material
        CompareRow(
            label: "Face Mat.",
            valueA: a?.faceMaterial ?? "—",
            valueB: b?.faceMaterial ?? "—",
            winnerA: nil, winnerB: nil,
            ratingA: nil, ratingB: nil,
            isAlternate: false
        )
        Divider()

        // Shape
        CompareRow(
            label: "Shape",
            valueA: a?.shape ?? "—",
            valueB: b?.shape ?? "—",
            winnerA: nil, winnerB: nil,
            ratingA: nil, ratingB: nil,
            isAlternate: true
        )
        Divider()

        // Power
        CompareRow(
            label: "Power",
            valueA: "\(a?.powerRating ?? 0)/10",
            valueB: "\(b?.powerRating ?? 0)/10",
            winnerA: higherWins(a?.powerRating, b?.powerRating),
            winnerB: higherWins(b?.powerRating, a?.powerRating),
            ratingA: a?.powerRating,
            ratingB: b?.powerRating,
            isAlternate: false
        )
        Divider()

        // Control
        CompareRow(
            label: "Control",
            valueA: "\(a?.controlRating ?? 0)/10",
            valueB: "\(b?.controlRating ?? 0)/10",
            winnerA: higherWins(a?.controlRating, b?.controlRating),
            winnerB: higherWins(b?.controlRating, a?.controlRating),
            ratingA: a?.controlRating,
            ratingB: b?.controlRating,
            isAlternate: true
        )
        Divider()

        // Spin
        CompareRow(
            label: "Spin",
            valueA: "\(a?.spinRating ?? 0)/10",
            valueB: "\(b?.spinRating ?? 0)/10",
            winnerA: higherWins(a?.spinRating, b?.spinRating),
            winnerB: higherWins(b?.spinRating, a?.spinRating),
            ratingA: a?.spinRating,
            ratingB: b?.spinRating,
            isAlternate: false
        )
        Divider()

        // Pop
        CompareRow(
            label: "Pop",
            valueA: "\(a?.popRating ?? 0)/10",
            valueB: "\(b?.popRating ?? 0)/10",
            winnerA: higherWins(a?.popRating, b?.popRating),
            winnerB: higherWins(b?.popRating, a?.popRating),
            ratingA: a?.popRating,
            ratingB: b?.popRating,
            isAlternate: true
        )
        Divider()

        // Value
        CompareRow(
            label: "Value",
            valueA: "\(a?.valueRating ?? 0)/10",
            valueB: "\(b?.valueRating ?? 0)/10",
            winnerA: higherWins(a?.valueRating, b?.valueRating),
            winnerB: higherWins(b?.valueRating, a?.valueRating),
            ratingA: a?.valueRating,
            ratingB: b?.valueRating,
            isAlternate: false
        )
        Divider()

        // Best For
        CompareRow(
            label: "Best For",
            valueA: a?.bestFor ?? "—",
            valueB: b?.bestFor ?? "—",
            winnerA: nil, winnerB: nil,
            ratingA: nil, ratingB: nil,
            isAlternate: true
        )
    }

    // MARK: - Winner helpers

    private func higherWins(_ a: Int?, _ b: Int?) -> Bool? {
        guard let a, let b else { return nil }
        if a == b { return nil }
        return a > b
    }

    private func lowerWins(_ a: Double?, _ b: Double?) -> Bool? {
        guard let a, let b else { return nil }
        if a == b { return nil }
        return a < b
    }

    private func lowerWeightWins(_ a: String?, _ b: String?) -> Bool? {
        guard let a, let b else { return nil }
        let aVal = Double(a.components(separatedBy: " ").first ?? "") ?? 0
        let bVal = Double(b.components(separatedBy: " ").first ?? "") ?? 0
        if aVal == bVal { return nil }
        return aVal < bVal
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PaddleCompareView()
    }
}

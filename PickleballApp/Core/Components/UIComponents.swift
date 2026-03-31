import SwiftUI

// MARK: - AvatarGroupView
// Overlapping avatar stack (GitHub contributors style)

struct AvatarGroupView: View {
    let names: [String]
    var size: CGFloat = 32
    var maxVisible: Int = 4

    private var visibleNames: [String] { Array(names.prefix(maxVisible)) }
    private var overflowCount: Int { max(0, names.count - maxVisible) }

    private func tint(for index: Int) -> Color {
        let palette: [Color] = [Color.dinkrGreen, Color.dinkrNavy, Color.dinkrCoral, Color.dinkrSky]
        return palette[index % palette.count]
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last  = parts.dropFirst().first?.prefix(1) ?? ""
        return (first + last).uppercased()
    }

    var body: some View {
        HStack(spacing: -(size * 0.3)) {
            ForEach(Array(visibleNames.enumerated()), id: \.offset) { index, name in
                avatarCircle(label: initials(for: name), fill: tint(for: index))
                    .zIndex(Double(visibleNames.count - index))
            }

            if overflowCount > 0 {
                avatarCircle(label: "+\(overflowCount)", fill: Color.secondary.opacity(0.4))
                    .zIndex(0)
            }
        }
    }

    // MARK: Private helpers

    private func avatarCircle(label: String, fill: Color) -> some View {
        ZStack {
            Circle()
                .fill(fill)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white, lineWidth: max(1.5, size * 0.06))
                )
            Text(label)
                .font(.system(size: size * 0.35, weight: .semibold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
    }
}

// MARK: - AnimatedCounterView
// Spring-animated number counter; supports decimals, prefix, suffix

struct AnimatedCounterView: View {
    let count: Int
    var color: Color = .primary
    var font: Font = .title
    var prefix: String = ""
    var suffix: String = ""

    @State private var displayValue: Double = 0

    var body: some View {
        Text("\(prefix)\(formattedValue)\(suffix)")
            .font(font)
            .foregroundStyle(color)
            .monospacedDigit()
            .onAppear { animateToCount() }
            .onChange(of: count) { _ in animateToCount() }
    }

    // Format to at most 2 decimal places, trimming trailing zeros
    private var formattedValue: String {
        if displayValue == displayValue.rounded(.towardZero) {
            return "\(Int(displayValue))"
        }
        return String(format: "%.2f", displayValue)
    }

    private func animateToCount() {
        displayValue = 0
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            displayValue = Double(count)
        }
    }
}

// Convenience overload for decimal values (e.g. DUPR rating "3.67")
struct AnimatedDecimalCounterView: View {
    let value: Double
    var color: Color = .primary
    var font: Font = .title
    var prefix: String = ""
    var suffix: String = ""
    var decimalPlaces: Int = 2

    @State private var displayValue: Double = 0

    var body: some View {
        Text("\(prefix)\(formattedValue)\(suffix)")
            .font(font)
            .foregroundStyle(color)
            .monospacedDigit()
            .onAppear { animateToValue() }
            .onChange(of: value) { _ in animateToValue() }
    }

    private var formattedValue: String {
        String(format: "%.\(decimalPlaces)f", displayValue)
    }

    private func animateToValue() {
        displayValue = 0
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            displayValue = value
        }
    }
}

// MARK: - CountdownTimerView
// Live countdown that updates every minute; color shifts green → amber → coral

struct CountdownTimerView: View {
    let targetDate: Date

    @State private var now: Date = Date()

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var secondsRemaining: TimeInterval {
        targetDate.timeIntervalSince(now)
    }

    private var label: String {
        let secs = secondsRemaining
        guard secs > 0 else { return "Starting now!" }

        let totalMinutes = Int(secs / 60)
        let days    = totalMinutes / (60 * 24)
        let hours   = (totalMinutes % (60 * 24)) / 60
        let minutes = totalMinutes % 60

        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "In \(hours)h \(minutes)m"
        } else {
            return "In \(minutes)m"
        }
    }

    private var labelColor: Color {
        let secs = secondsRemaining
        if secs <= 0          { return Color.dinkrCoral }
        if secs < 3600        { return Color.dinkrCoral }   // < 1 hour
        if secs < 86400       { return Color.dinkrAmber }   // < 1 day
        return Color.dinkrGreen
    }

    var body: some View {
        Text(label)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(labelColor)
            .onReceive(timer) { newDate in now = newDate }
    }
}

// MARK: - PulsingStatusDot
// Animated status indicator for LIVE badges, online indicators

struct PulsingStatusDot: View {
    var color: Color
    var size: CGFloat = 8

    @State private var scale: CGFloat = 1.0

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.9)
                    .repeatForever(autoreverses: true)
                ) {
                    scale = 1.3
                }
            }
    }
}

// MARK: - FilterChipRow
// Horizontal scrollable filter chips

struct FilterChipRow: View {
    let items: [String]
    @Binding var selected: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    chipButton(for: item)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func chipButton(for item: String) -> some View {
        let isSelected = item == selected

        Button {
            selected = item
        } label: {
            Text(item)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.white : Color.dinkrGreen)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background {
                    Capsule()
                        .fill(isSelected ? Color.dinkrGreen : Color.clear)
                }
                .overlay {
                    Capsule()
                        .strokeBorder(Color.dinkrGreen, lineWidth: isSelected ? 0 : 1.5)
                }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Previews

#Preview("AvatarGroupView") {
    VStack(spacing: 24) {
        AvatarGroupView(names: ["Alice Brown", "Bob Smith", "Carol Jones"], size: 36)
        AvatarGroupView(names: ["Alice Brown", "Bob Smith", "Carol Jones", "Dan Lee", "Eve Park", "Frank Wu"], size: 32, maxVisible: 4)
        AvatarGroupView(names: ["Alice Brown", "Bob Smith"], size: 44)
    }
    .padding()
}

#Preview("AnimatedCounterView") {
    VStack(spacing: 16) {
        AnimatedCounterView(count: 1247, color: Color.dinkrGreen, font: .largeTitle)
        AnimatedCounterView(count: 75, color: Color.dinkrCoral, font: .title2, suffix: "%")
        AnimatedDecimalCounterView(value: 3.67, color: Color.dinkrAmber, font: .title, suffix: " DUPR")
    }
    .padding()
}

#Preview("CountdownTimerView") {
    VStack(spacing: 12) {
        CountdownTimerView(targetDate: Date().addingTimeInterval(90061))   // ~1 day
        CountdownTimerView(targetDate: Date().addingTimeInterval(3000))    // < 1 hour
        CountdownTimerView(targetDate: Date().addingTimeInterval(-10))     // past
    }
    .padding()
}

#Preview("PulsingStatusDot") {
    HStack(spacing: 16) {
        PulsingStatusDot(color: Color.dinkrGreen, size: 10)
        PulsingStatusDot(color: Color.dinkrCoral, size: 12)
        PulsingStatusDot(color: Color.dinkrAmber, size: 8)
    }
    .padding()
}

#Preview("FilterChipRow") {
    struct Wrapper: View {
        @State private var selected = "All"
        var body: some View {
            FilterChipRow(items: ["All", "Tournament", "Social", "Clinic", "Charity"], selected: $selected)
                .padding(.vertical)
        }
    }
    return Wrapper()
}

// MARK: - FlowLayout
/// A wrapping flow layout that arranges children left-to-right, wrapping when needed.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        y += rowHeight
        return CGSize(width: maxWidth, height: y)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

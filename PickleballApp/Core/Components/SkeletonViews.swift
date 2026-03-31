import SwiftUI

// MARK: - Shimmer Modifier

/// Animates a silver highlight gradient sliding left-to-right over any view.
/// Apply via `.shimmer()` on any `View`.
struct ShimmerViewModifier: ViewModifier {
    @State private var shimmerOffset: CGFloat = -1.0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            .init(color: Color.clear,                                   location: 0.0),
                            .init(color: Color(UIColor.systemGray4).opacity(0.55),      location: 0.40),
                            .init(color: Color(UIColor.systemGray3).opacity(0.80),      location: 0.50),
                            .init(color: Color(UIColor.systemGray4).opacity(0.55),      location: 0.60),
                            .init(color: Color.clear,                                   location: 1.0),
                        ],
                        startPoint: UnitPoint(x: shimmerOffset,       y: 0.5),
                        endPoint:   UnitPoint(x: shimmerOffset + 1.0, y: 0.5)
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: shimmerOffset * geo.size.width)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.4)
                    .repeatForever(autoreverses: false)
                ) {
                    shimmerOffset = 1.0
                }
            }
    }
}

extension View {
    /// Applies a left-to-right silver shimmer animation.
    func shimmer() -> some View {
        modifier(ShimmerViewModifier())
    }
}

// MARK: - SkeletonBox

/// A grey rounded rectangle with shimmer applied. The building block for all skeleton layouts.
struct SkeletonBox: View {
    var width: CGFloat?          // nil = fill available width
    var height: CGFloat
    var cornerRadius: CGFloat = 8

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color(UIColor.systemGray5))
            .frame(width: width, height: height)
            .shimmer()
    }
}

// MARK: - SkeletonGameCard

/// Matches `GameCardView` layout: accent strip, title line, two tag lines, avatar + name line, progress bar.
struct SkeletonGameCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Accent strip (mirrors the 6pt gradient strip at the top of GameCardView)
            SkeletonBox(height: 6, cornerRadius: 0)
                .clipShape(
                    .rect(
                        topLeadingRadius: 18,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 18
                    )
                )

            VStack(alignment: .leading, spacing: 12) {

                // Row 1: title + countdown badge
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonBox(width: 160, height: 14)
                        SkeletonBox(width: 110, height: 10)
                    }
                    Spacer()
                    SkeletonBox(width: 56, height: 22, cornerRadius: 11)
                }

                // Row 2: two tag pills (format + skill range)
                HStack(spacing: 6) {
                    SkeletonBox(width: 68, height: 20, cornerRadius: 10)
                    SkeletonBox(width: 80, height: 20, cornerRadius: 10)
                    Spacer()
                }

                // Row 3: avatar circle + name line
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(UIColor.systemGray5))
                        .frame(width: 24, height: 24)
                        .shimmer()
                    SkeletonBox(width: 90, height: 11)
                    Spacer()
                    SkeletonBox(width: 36, height: 20, cornerRadius: 10)
                }

                // Row 4: progress bar (label row + bar)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        SkeletonBox(width: 70, height: 9)
                        Spacer()
                        SkeletonBox(width: 44, height: 9)
                    }
                    SkeletonBox(height: 4, cornerRadius: 3)
                }
            }
            .padding(14)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

// MARK: - SkeletonPlayerCard

/// Matches `PlayerCardView` layout: avatar circle, name + skill badge, play-style box, stat row boxes.
struct SkeletonPlayerCard: View {
    var body: some View {
        PickleballCard {
            HStack(spacing: 14) {

                // Avatar circle
                Circle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(width: 52, height: 52)
                    .shimmer()

                VStack(alignment: .leading, spacing: 6) {

                    // Name + skill badge
                    HStack(spacing: 8) {
                        SkeletonBox(width: 110, height: 14)
                        SkeletonBox(width: 44, height: 20, cornerRadius: 10)
                    }

                    // Play-style badge box
                    SkeletonBox(width: 80, height: 20, cornerRadius: 10)

                    // Stat row (games + win rate)
                    HStack(spacing: 12) {
                        SkeletonBox(width: 70, height: 11)
                        SkeletonBox(width: 60, height: 11)
                    }
                }

                Spacer()

                // Follow button placeholder
                SkeletonBox(width: 64, height: 28, cornerRadius: 14)
            }
            .padding(14)
        }
    }
}

// MARK: - SkeletonEventCard

/// Matches `EventCardView` layout: image placeholder banner, title line, date line, chip boxes.
struct SkeletonEventCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Image placeholder banner (mirrors 120pt gradient banner)
            SkeletonBox(height: 120, cornerRadius: 0)
                .clipShape(
                    .rect(
                        topLeadingRadius: 18,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 18
                    )
                )

            VStack(alignment: .leading, spacing: 10) {

                // Type chip
                SkeletonBox(width: 68, height: 20, cornerRadius: 10)

                // Title lines
                SkeletonBox(height: 16)
                SkeletonBox(width: 150, height: 14)

                // Date + location line
                HStack(spacing: 12) {
                    SkeletonBox(width: 90, height: 11)
                    SkeletonBox(width: 110, height: 11)
                }

                // Footer: fee chip + register button placeholder
                HStack {
                    SkeletonBox(width: 52, height: 22, cornerRadius: 11)
                    Spacer()
                    SkeletonBox(width: 88, height: 28, cornerRadius: 14)
                }
            }
            .padding(14)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

// MARK: - SkeletonPostCard

/// Matches `PostCardView` layout: avatar + name header, 3 content lines, action row.
struct SkeletonPostCard: View {
    var body: some View {
        PickleballCard {
            VStack(alignment: .leading, spacing: 12) {

                // Header: avatar + name/timestamp
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color(UIColor.systemGray5))
                        .frame(width: 40, height: 40)
                        .shimmer()

                    VStack(alignment: .leading, spacing: 5) {
                        SkeletonBox(width: 100, height: 13)
                        SkeletonBox(width: 64, height: 10)
                    }

                    Spacer()

                    SkeletonBox(width: 42, height: 18, cornerRadius: 9)
                }

                // Content lines (3)
                VStack(alignment: .leading, spacing: 7) {
                    SkeletonBox(height: 13)
                    SkeletonBox(height: 13)
                    SkeletonBox(width: 200, height: 13)
                }

                Divider()

                // Action row: like, comment, share placeholders
                HStack(spacing: 20) {
                    SkeletonBox(width: 52, height: 18, cornerRadius: 9)
                    SkeletonBox(width: 52, height: 18, cornerRadius: 9)
                    Spacer()
                    SkeletonBox(width: 24, height: 18, cornerRadius: 9)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - SkeletonGroupRow

/// Matches `PremiumGroupCard` list row layout: square icon block, two text lines, member count box.
struct SkeletonGroupRow: View {
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.cardBackground)

            HStack(spacing: 14) {

                // Left accent strip placeholder
                SkeletonBox(width: 4, height: 40, cornerRadius: 2)
                    .padding(.leading, 8)

                // Icon block
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(UIColor.systemGray5))
                    .frame(width: 54, height: 54)
                    .shimmer()
                    .padding(.leading, 6)

                VStack(alignment: .leading, spacing: 6) {
                    // Name line
                    SkeletonBox(width: 130, height: 14)
                    // Type pill + activity text
                    HStack(spacing: 6) {
                        SkeletonBox(width: 60, height: 18, cornerRadius: 9)
                        SkeletonBox(width: 90, height: 11)
                    }
                    // Member count box
                    SkeletonBox(width: 80, height: 11)
                }

                Spacer()

                SkeletonBox(width: 48, height: 26, cornerRadius: 13)
                    .padding(.trailing, 14)
            }
            .padding(.vertical, 14)
        }
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview("Skeleton Gallery") {
    ScrollView {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("SkeletonGameCard")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonGameCard().padding(.horizontal)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("SkeletonPlayerCard")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                SkeletonPlayerCard().padding(.horizontal)
                SkeletonPlayerCard().padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("SkeletonEventCard")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                SkeletonEventCard().padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("SkeletonPostCard")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                SkeletonPostCard().padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("SkeletonGroupRow")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                SkeletonGroupRow().padding(.horizontal)
                SkeletonGroupRow().padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    .background(Color(UIColor.systemGroupedBackground))
}

import SwiftUI

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    let isActive: Bool

    @State private var phase: CGFloat = -1.0

    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay(
                    GeometryReader { geometry in
                        LinearGradient(
                            stops: [
                                .init(color: Color(UIColor.systemGray5).opacity(0.0), location: 0.0),
                                .init(color: Color(UIColor.systemGray4).opacity(0.6), location: 0.45),
                                .init(color: Color(UIColor.systemGray3).opacity(0.8), location: 0.5),
                                .init(color: Color(UIColor.systemGray4).opacity(0.6), location: 0.55),
                                .init(color: Color(UIColor.systemGray5).opacity(0.0), location: 1.0),
                            ],
                            startPoint: UnitPoint(x: phase, y: 0.5),
                            endPoint: UnitPoint(x: phase + 1.0, y: 0.5)
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: phase * geometry.size.width)
                    }
                    .clipped()
                )
                .onAppear {
                    withAnimation(
                        .linear(duration: 1.4)
                        .repeatForever(autoreverses: false)
                    ) {
                        phase = 1.0
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    func shimmer(isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}

// MARK: - Skeleton Shape Helpers

private struct SkeletonRect: View {
    var width: CGFloat? = nil
    var height: CGFloat = 14
    var cornerRadius: CGFloat = 6

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color(UIColor.systemGray5))
            .frame(width: width, height: height)
            .shimmer()
    }
}

private struct SkeletonCircle: View {
    var size: CGFloat = 40

    var body: some View {
        Circle()
            .fill(Color(UIColor.systemGray5))
            .frame(width: size, height: size)
            .shimmer()
    }
}

// MARK: - Generic Skeleton Row

struct SkeletonRow: View {
    var hasAvatar: Bool = true
    var titleWidth: CGFloat? = nil
    var subtitleWidth: CGFloat? = nil

    var body: some View {
        HStack(spacing: 12) {
            if hasAvatar {
                SkeletonCircle(size: 44)
            }

            VStack(alignment: .leading, spacing: 8) {
                SkeletonRect(width: titleWidth ?? randomWidth(min: 120, max: 200), height: 14)
                SkeletonRect(width: subtitleWidth ?? randomWidth(min: 80, max: 150), height: 11)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func randomWidth(min: CGFloat, max: CGFloat) -> CGFloat {
        CGFloat.random(in: min...max)
    }
}

// MARK: - Game Card Skeleton

struct GameCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: avatar + host name + badge
            HStack(spacing: 10) {
                SkeletonCircle(size: 36)

                VStack(alignment: .leading, spacing: 6) {
                    SkeletonRect(width: 110, height: 13)
                    SkeletonRect(width: 70, height: 10)
                }

                Spacer()

                SkeletonRect(width: 56, height: 24, cornerRadius: 12)
            }

            // Court name line
            SkeletonRect(width: 180, height: 15, cornerRadius: 6)

            // Date / time row
            HStack(spacing: 16) {
                SkeletonRect(width: 90, height: 11)
                SkeletonRect(width: 60, height: 11)
            }

            // Skill range + spots row
            HStack(spacing: 8) {
                SkeletonRect(width: 72, height: 22, cornerRadius: 11)
                SkeletonRect(width: 72, height: 22, cornerRadius: 11)
                Spacer()
                SkeletonRect(width: 50, height: 22, cornerRadius: 11)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Event Card Skeleton

struct EventCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Banner image placeholder
            SkeletonRect(height: 120, cornerRadius: 0)
                .shimmer(isActive: true)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 16,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 16
                    )
                )

            VStack(alignment: .leading, spacing: 10) {
                // Category badge
                SkeletonRect(width: 64, height: 20, cornerRadius: 10)

                // Title
                SkeletonRect(height: 16, cornerRadius: 6)
                SkeletonRect(width: 140, height: 13, cornerRadius: 6)

                // Date + location row
                HStack(spacing: 16) {
                    SkeletonRect(width: 80, height: 11)
                    SkeletonRect(width: 100, height: 11)
                }

                // Footer: price + attendees
                HStack {
                    SkeletonRect(width: 55, height: 22, cornerRadius: 11)
                    Spacer()
                    HStack(spacing: -8) {
                        ForEach(0..<3, id: \.self) { _ in
                            SkeletonCircle(size: 26)
                        }
                    }
                }
            }
            .padding(14)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Post Card Skeleton

struct PostCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author row
            HStack(spacing: 10) {
                SkeletonCircle(size: 40)

                VStack(alignment: .leading, spacing: 6) {
                    SkeletonRect(width: 100, height: 13)
                    SkeletonRect(width: 60, height: 10)
                }

                Spacer()

                SkeletonRect(width: 28, height: 28, cornerRadius: 6)
            }

            // Body text lines
            VStack(alignment: .leading, spacing: 7) {
                SkeletonRect(height: 13)
                SkeletonRect(height: 13)
                SkeletonRect(width: 200, height: 13)
            }

            // Image placeholder (appears ~60% of the time conceptually; always shown in skeleton)
            SkeletonRect(height: 160, cornerRadius: 12)

            // Action bar
            HStack(spacing: 24) {
                SkeletonRect(width: 50, height: 18, cornerRadius: 9)
                SkeletonRect(width: 50, height: 18, cornerRadius: 9)
                SkeletonRect(width: 50, height: 18, cornerRadius: 9)
                Spacer()
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Listing Card Skeleton

struct ListingCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Product image placeholder
            SkeletonRect(height: 140, cornerRadius: 0)
                .shimmer(isActive: true)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 14,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 14
                    )
                )

            VStack(alignment: .leading, spacing: 8) {
                // Condition badge
                SkeletonRect(width: 52, height: 18, cornerRadius: 9)

                // Item title
                SkeletonRect(height: 15, cornerRadius: 6)
                SkeletonRect(width: 110, height: 12, cornerRadius: 6)

                // Price + seller row
                HStack {
                    SkeletonRect(width: 60, height: 20, cornerRadius: 8)
                    Spacer()
                    SkeletonCircle(size: 24)
                }
            }
            .padding(12)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview("Skeleton Gallery") {
    ScrollView {
        VStack(spacing: 20) {
            Text("Game Card").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            GameCardSkeleton().padding(.horizontal)

            Text("Event Card").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            EventCardSkeleton().padding(.horizontal)

            Text("Post Card").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            PostCardSkeleton().padding(.horizontal)

            Text("Listing Card").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            ListingCardSkeleton().padding(.horizontal)

            Text("Skeleton Rows").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            VStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonRow()
                    Divider().padding(.leading, 72)
                }
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    .background(Color(UIColor.systemGroupedBackground))
}

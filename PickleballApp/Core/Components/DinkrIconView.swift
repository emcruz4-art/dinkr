import SwiftUI

/// Renders the Dinkr app icon design at any size from 20pt to 1024pt.
/// Suitable for use in-app and for icon asset generation via ImageRenderer.
struct DinkrIconView: View {
    var size: CGFloat = 60

    // Derived geometry
    private var cornerRadius: CGFloat { size * 0.22 }
    private var logoSize: CGFloat { size * 0.48 }
    private var ballRegionSize: CGFloat { size * 0.28 }
    private var ballDotSize: CGFloat { size * 0.045 }

    var body: some View {
        ZStack {
            // — Base: navy background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.dinkrNavy)
                .frame(width: size, height: size)

            // — Subtle radial gradient overlay (lighter top-left, darker bottom-right)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.15),
                            Color.black.opacity(0.18)
                        ]),
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size * 1.1
                    )
                )
                .frame(width: size, height: size)

            // — Centered logo: paddle + "dinkr" wordmark in white
            DinkrLogoView(
                size: logoSize,
                showWordmark: true,
                tintColor: Color.white
            )
            .offset(y: -size * 0.02)  // slight upward nudge to balance ball element

            // — Decorative pickleball in bottom-right corner
            pickleballDecoration
                .frame(width: ballRegionSize, height: ballRegionSize)
                .offset(
                    x:  size * 0.28,
                    y:  size * 0.28
                )
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    // MARK: - Pickleball decoration

    /// Tiny white circle with a simplified hole-dot pattern mimicking a pickleball.
    private var pickleballDecoration: some View {
        ZStack {
            // Ball body
            Circle()
                .fill(Color.white.opacity(0.22))
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: ballDotSize * 0.6)
                )

            // Hole dots — 3x3 sparse grid approximating pickleball pattern
            ForEach(dotOffsets, id: \.id) { item in
                Circle()
                    .fill(Color.dinkrNavy.opacity(0.55))
                    .frame(width: ballDotSize, height: ballDotSize)
                    .offset(x: item.x * ballRegionSize * 0.28,
                            y: item.y * ballRegionSize * 0.28)
            }
        }
    }

    private struct DotOffset: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
    }

    private var dotOffsets: [DotOffset] {
        // A 3-column ring of dots suggesting the pickleball hole pattern
        let positions: [(CGFloat, CGFloat)] = [
            ( 0,    -1   ),
            ( 0.87, -0.5 ),
            ( 0.87,  0.5 ),
            ( 0,     1   ),
            (-0.87,  0.5 ),
            (-0.87, -0.5 )
        ]
        return positions.enumerated().map { idx, pos in
            DotOffset(id: idx, x: pos.0, y: pos.1)
        }
    }
}

// MARK: - Preview

#Preview("Icon Sizes") {
    ZStack {
        Color(UIColor.systemGroupedBackground).ignoresSafeArea()
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                DinkrIconView(size: 60)
                DinkrIconView(size: 120)
                DinkrIconView(size: 180)
            }
            HStack(spacing: 16) {
                DinkrIconView(size: 29)
                DinkrIconView(size: 40)
                DinkrIconView(size: 20)
            }
        }
        .padding()
    }
}

import SwiftUI

/// Full-resolution app icon — renders at any size.
/// Use size: 1024 for export, or smaller for previews.
struct AppIconView: View {
    var size: CGFloat = 1024

    private var paddleWidth: CGFloat { size * 0.38 }
    private var paddleHeight: CGFloat { size * 0.55 }

    var body: some View {
        ZStack {
            // Background: deep navy → rich green diagonal gradient
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.13, blue: 0.22),   // deep navy
                    Color(red: 0.10, green: 0.18, blue: 0.29),   // dinkrNavy
                    Color(red: 0.08, green: 0.52, blue: 0.28),   // mid green
                    Color(red: 0.18, green: 0.74, blue: 0.38),   // dinkrGreen
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle radial glow behind paddle
            RadialGradient(
                colors: [
                    Color.white.opacity(0.12),
                    Color.clear
                ],
                center: .center,
                startRadius: size * 0.05,
                endRadius: size * 0.45
            )

            // Subtle grid pattern in background
            AppIconCourtLines(size: size)
                .opacity(0.08)

            // The paddle + ball
            VStack(spacing: -size * 0.04) {
                // Paddle
                AppIconPaddle(width: paddleWidth, height: paddleHeight)

                // Ball
                AppIconBall(size: size * 0.14)
                    .offset(x: size * 0.18, y: -size * 0.02)
            }
            .offset(y: -size * 0.03)

            // "dinkr" wordmark at bottom
            VStack {
                Spacer()
                Text("dinkr")
                    .font(.system(size: size * 0.12, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .tracking(size * 0.004)
                    .padding(.bottom, size * 0.07)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.225)) // iOS app icon corner radius
    }
}

// MARK: - Paddle

private struct AppIconPaddle: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            // Shadow layer
            AppIconPaddleShape()
                .fill(Color.black.opacity(0.35))
                .frame(width: width, height: height)
                .blur(radius: width * 0.06)
                .offset(x: width * 0.04, y: width * 0.06)

            // Main paddle body — white with subtle gradient
            AppIconPaddleShape()
                .fill(
                    LinearGradient(
                        colors: [.white, Color(white: 0.88)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: width, height: height)

            // Paddle face accent — green zone on head
            AppIconPaddleHeadShape(headFraction: 0.62)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.74, blue: 0.38).opacity(0.25),
                            Color(red: 0.08, green: 0.52, blue: 0.28).opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width, height: height)

            // Hole pattern on paddle face
            AppIconPaddleHolePattern(width: width, height: height)
        }
    }
}

private struct AppIconPaddleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Head: top 62%
        let headH = h * 0.62
        let headW = w * 0.9
        let headX = (w - headW) / 2
        let r = headW * 0.26
        path.addRoundedRect(in: CGRect(x: headX, y: 0, width: headW, height: headH),
                            cornerSize: CGSize(width: r, height: r))

        // Neck bridge
        let neckW = w * 0.3
        let neckX = (w - neckW) / 2
        path.addRect(CGRect(x: neckX, y: headH - 3, width: neckW, height: h * 0.08))

        // Handle
        let handleW = w * 0.3
        let handleH = h * 0.34
        let handleX = (w - handleW) / 2
        let hr = handleW * 0.32
        path.addRoundedRect(in: CGRect(x: handleX, y: headH + h * 0.04, width: handleW, height: handleH),
                            cornerSize: CGSize(width: hr, height: hr))

        return path
    }
}

private struct AppIconPaddleHeadShape: Shape {
    var headFraction: CGFloat = 0.62
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let headH = h * headFraction
        let headW = w * 0.9
        let headX = (w - headW) / 2
        let r = headW * 0.26
        path.addRoundedRect(in: CGRect(x: headX, y: 0, width: headW, height: headH),
                            cornerSize: CGSize(width: r, height: r))
        return path
    }
}

private struct AppIconPaddleHolePattern: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        let holeSize = width * 0.055
        let cols = 4
        let rows = 5
        let headH = height * 0.56
        let headW = width * 0.78
        let startX = (width - headW) / 2 + holeSize
        let startY = height * 0.05

        ForEach(0..<rows, id: \.self) { row in
            ForEach(0..<cols, id: \.self) { col in
                Circle()
                    .fill(Color.black.opacity(0.08))
                    .frame(width: holeSize, height: holeSize)
                    .position(
                        x: startX + CGFloat(col) * (headW - holeSize * 2) / CGFloat(cols - 1),
                        y: startY + CGFloat(row) * (headH - holeSize * 2) / CGFloat(rows - 1)
                    )
            }
        }
    }
}

// MARK: - Ball

private struct AppIconBall: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(white: 0.98), Color(white: 0.82)],
                        center: .init(x: 0.35, y: 0.3),
                        startRadius: size * 0.05,
                        endRadius: size * 0.5
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: size * 0.08, x: size * 0.04, y: size * 0.05)
                .frame(width: size, height: size)

            // Pickleball hole pattern (simplified dots)
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(Color(white: 0.65).opacity(0.6))
                    .frame(width: size * 0.08, height: size * 0.08)
                    .offset(
                        x: cos(Double(i) * .pi / 2) * size * 0.2,
                        y: sin(Double(i) * .pi / 2) * size * 0.2
                    )
            }
        }
    }
}

// MARK: - Court Lines Background

private struct AppIconCourtLines: View {
    let size: CGFloat
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width
            let h = sz.height

            // Kitchen line
            var p1 = Path()
            p1.move(to: CGPoint(x: w * 0.1, y: h * 0.55))
            p1.addLine(to: CGPoint(x: w * 0.9, y: h * 0.55))
            ctx.stroke(p1, with: .color(.white), style: StrokeStyle(lineWidth: size * 0.006))

            // Center line
            var p2 = Path()
            p2.move(to: CGPoint(x: w * 0.5, y: h * 0.15))
            p2.addLine(to: CGPoint(x: w * 0.5, y: h * 0.55))
            ctx.stroke(p2, with: .color(.white), style: StrokeStyle(lineWidth: size * 0.004))

            // Left side line
            var p3 = Path()
            p3.move(to: CGPoint(x: w * 0.1, y: h * 0.15))
            p3.addLine(to: CGPoint(x: w * 0.1, y: h * 0.85))
            ctx.stroke(p3, with: .color(.white), style: StrokeStyle(lineWidth: size * 0.004))

            // Right side line
            var p4 = Path()
            p4.move(to: CGPoint(x: w * 0.9, y: h * 0.15))
            p4.addLine(to: CGPoint(x: w * 0.9, y: h * 0.85))
            ctx.stroke(p4, with: .color(.white), style: StrokeStyle(lineWidth: size * 0.004))
        }
    }
}

// MARK: - Previews

#Preview("1024pt") {
    AppIconView(size: 400)
}

#Preview("Small") {
    HStack(spacing: 8) {
        AppIconView(size: 60)
        AppIconView(size: 40)
        AppIconView(size: 29)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}

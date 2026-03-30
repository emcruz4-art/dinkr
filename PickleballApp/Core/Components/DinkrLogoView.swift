import SwiftUI

struct DinkrLogoView: View {
    var size: CGFloat = 40
    var showWordmark: Bool = true
    var tintColor: Color = Color.dinkrGreen

    private var paddleWidth: CGFloat { size * 0.52 }
    private var paddleHeight: CGFloat { size * 0.76 }

    var body: some View {
        HStack(spacing: size * 0.14) {
            // Paddle icon — proper silhouette shape, rotated for brand flair
            ZStack {
                // Shadow
                LogoPaddleShape()
                    .fill(Color.black.opacity(0.18))
                    .frame(width: paddleWidth, height: paddleHeight)
                    .blur(radius: paddleWidth * 0.07)
                    .offset(x: paddleWidth * 0.05, y: paddleWidth * 0.05)
                    .rotationEffect(.degrees(-18))

                // Paddle body
                LogoPaddleShape()
                    .fill(tintColor)
                    .frame(width: paddleWidth, height: paddleHeight)
                    .rotationEffect(.degrees(-18))

                // Pickleball — offset to upper-right of paddle
                Circle()
                    .fill(tintColor.opacity(0.7))
                    .overlay(
                        Circle()
                            .strokeBorder(tintColor, lineWidth: size * 0.018)
                    )
                    .frame(width: size * 0.22, height: size * 0.22)
                    .offset(x: size * 0.28, y: -size * 0.26)
            }
            .frame(width: size, height: size)

            if showWordmark {
                Text("dinkr")
                    .font(.system(size: size * 0.52, weight: .heavy, design: .rounded))
                    .foregroundStyle(tintColor)
            }
        }
    }
}

// MARK: - Logo Paddle Shape
// Self-contained path — does not depend on AppIconView internals.

private struct LogoPaddleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Head: top 62% of height
        let headH = h * 0.62
        let headW = w * 0.9
        let headX = (w - headW) / 2
        let r = headW * 0.26
        path.addRoundedRect(
            in: CGRect(x: headX, y: 0, width: headW, height: headH),
            cornerSize: CGSize(width: r, height: r)
        )

        // Neck bridge
        let neckW = w * 0.28
        let neckX = (w - neckW) / 2
        path.addRect(CGRect(x: neckX, y: headH - 2, width: neckW, height: h * 0.07))

        // Handle: bottom portion
        let handleW = w * 0.28
        let handleH = h * 0.33
        let handleX = (w - handleW) / 2
        let hr = handleW * 0.35
        path.addRoundedRect(
            in: CGRect(x: handleX, y: headH + h * 0.05, width: handleW, height: handleH),
            cornerSize: CGSize(width: hr, height: hr)
        )

        return path
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 20) {
        DinkrLogoView(size: 40)
        DinkrLogoView(size: 60, showWordmark: false)
        DinkrLogoView(size: 32, tintColor: .white)
            .padding()
            .background(Color.dinkrNavy)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        DinkrLogoView(size: 52, tintColor: Color.dinkrGreen)
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
}

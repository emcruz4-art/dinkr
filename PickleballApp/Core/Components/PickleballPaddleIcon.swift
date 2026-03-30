import SwiftUI

/// Scalable pickleball paddle silhouette drawn with SwiftUI Path.
struct PickleballPaddleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Head: top 62% of height, nearly-square with large corner radius
        let headHeight = h * 0.62
        let headWidth = w * 0.88
        let headX = (w - headWidth) / 2
        let headRadius = headWidth * 0.28
        let headRect = CGRect(x: headX, y: 0, width: headWidth, height: headHeight)
        path.addRoundedRect(in: headRect, cornerSize: CGSize(width: headRadius, height: headRadius))

        // Neck: small tapered bridge
        let neckTop = headHeight - 4
        let neckWidth = w * 0.28
        let neckX = (w - neckWidth) / 2
        path.addRect(CGRect(x: neckX, y: neckTop, width: neckWidth, height: h * 0.07))

        // Handle: bottom 35%
        let handleTop = headHeight + h * 0.05
        let handleWidth = w * 0.28
        let handleX = (w - handleWidth) / 2
        let handleRadius = handleWidth * 0.35
        let handleRect = CGRect(x: handleX, y: handleTop, width: handleWidth, height: h * 0.33)
        path.addRoundedRect(in: handleRect, cornerSize: CGSize(width: handleRadius, height: handleRadius))

        return path
    }
}

struct PickleballPaddleIcon: View {
    var size: CGFloat = 24
    var color: Color = Color.dinkrGreen

    var body: some View {
        PickleballPaddleShape()
            .fill(color)
            .frame(width: size * 0.7, height: size)
    }
}

#Preview {
    HStack(spacing: 20) {
        PickleballPaddleIcon(size: 24)
        PickleballPaddleIcon(size: 48)
        PickleballPaddleIcon(size: 80, color: Color.dinkrNavy)
        PickleballPaddleIcon(size: 100, color: Color.dinkrCoral)
    }
    .padding()
}

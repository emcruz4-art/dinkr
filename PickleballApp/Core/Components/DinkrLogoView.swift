import SwiftUI

struct DinkrLogoView: View {
    var size: CGFloat = 40
    var showWordmark: Bool = true
    var tintColor: Color = Color.dinkrGreen

    var body: some View {
        HStack(spacing: 6) {
            // Paddle icon
            ZStack {
                // Paddle body
                RoundedRectangle(cornerRadius: size * 0.18)
                    .fill(tintColor)
                    .frame(width: size * 0.6, height: size * 0.76)
                    .rotationEffect(.degrees(-20))
                // Paddle handle notch
                Rectangle()
                    .fill(tintColor)
                    .frame(width: size * 0.18, height: size * 0.28)
                    .offset(y: size * 0.44)
                    .rotationEffect(.degrees(-20))
                // Ball
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.22, height: size * 0.22)
                    .offset(x: size * 0.28, y: -size * 0.24)
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

#Preview {
    VStack(spacing: 20) {
        DinkrLogoView(size: 40)
        DinkrLogoView(size: 60, showWordmark: false)
        DinkrLogoView(size: 32, tintColor: .white)
            .padding()
            .background(Color.dinkrNavy)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
}

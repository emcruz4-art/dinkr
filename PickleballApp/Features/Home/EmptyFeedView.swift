import SwiftUI

// MARK: - EmptyFeedView (generic)

struct EmptyFeedView: View {
    let title: String
    let message: String
    let ctaLabel: String?
    let action: (() -> Void)?

    // Bouncing pickleball animation state
    @State private var bounceOffset: CGFloat = 0
    @State private var ballScale: CGFloat = 1.0
    @State private var shadowScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Bouncing pickleball
            ZStack {
                // Shadow ellipse that shrinks as ball rises
                Ellipse()
                    .fill(Color.dinkrNavy.opacity(0.12))
                    .frame(width: 50 * shadowScale, height: 10 * shadowScale)
                    .offset(y: 44)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .overlay(
                        // Hole pattern dots
                        ZStack {
                            ForEach(0..<8, id: \.self) { i in
                                Circle()
                                    .fill(Color.white.opacity(0.25))
                                    .frame(width: 5, height: 5)
                                    .offset(
                                        x: 18 * cos(Double(i) * .pi / 4),
                                        y: 18 * sin(Double(i) * .pi / 4)
                                    )
                            }
                            Circle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 5, height: 5)
                        }
                    )
                    .scaleEffect(ballScale)
                    .offset(y: bounceOffset)
            }
            .frame(height: 100)
            .onAppear {
                startBounceAnimation()
            }

            // Text
            VStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dinkrNavy)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
            }

            // CTA button
            if let label = ctaLabel, let action {
                Button(action: {
                    HapticManager.medium()
                    action()
                }) {
                    Text(label)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.dinkrGreen)
                        .clipShape(Capsule())
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func startBounceAnimation() {
        // Ball rises quickly, falls with deceleration (gravity feel)
        withAnimation(
            .timingCurve(0.33, 1, 0.68, 1, duration: 0.45)
            .repeatForever(autoreverses: false)
            .speed(1)
        ) {
            bounceOffset = -40
        }

        withAnimation(
            .timingCurve(0.33, 0, 0.66, 0, duration: 0.45)
            .delay(0.45)
            .repeatForever(autoreverses: false)
        ) {
            bounceOffset = 0
        }

        // Squash slightly on landing
        withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
            ballScale = 1.04
            shadowScale = 0.7
        }
    }
}

// MARK: - EmptyGamesView

struct EmptyGamesView: View {
    let onFind: (() -> Void)?
    let onHost: (() -> Void)?

    @State private var lineProgress: CGFloat = 0
    @State private var courtOpacity: Double = 0

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Animated court lines drawing in
            CourtLinesIllustration(lineProgress: lineProgress)
                .frame(width: 160, height: 100)
                .opacity(courtOpacity)
                .onAppear {
                    withAnimation(.easeOut(duration: 1.2)) {
                        lineProgress = 1.0
                        courtOpacity = 1.0
                    }
                }

            VStack(spacing: 10) {
                Text("No Games Near You")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dinkrNavy)

                Text("There aren't any open games in your area right now. Be the first to host or search a wider area.")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 28)
            }

            HStack(spacing: 14) {
                if let onFind {
                    Button(action: {
                        HapticManager.medium()
                        onFind()
                    }) {
                        Label("Find Games", systemImage: "magnifyingglass")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.dinkrGreen)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 13)
                            .background(Color.dinkrGreen.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                if let onHost {
                    Button(action: {
                        HapticManager.medium()
                        onHost()
                    }) {
                        Label("Host a Game", systemImage: "plus")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 13)
                            .background(Color.dinkrGreen)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// Court lines that draw in progressively
private struct CourtLinesIllustration: View {
    let lineProgress: CGFloat

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let stroke = StrokeStyle(lineWidth: 2.5, lineCap: .round)
            let color = Color.dinkrSky.opacity(0.9)

            // Outer rectangle
            drawLine(context: context, from: CGPoint(x: 0, y: 0),
                     to: CGPoint(x: w * lineProgress, y: 0), color: color, style: stroke)
            drawLine(context: context, from: CGPoint(x: w, y: 0),
                     to: CGPoint(x: w, y: h * lineProgress), color: color, style: stroke)
            drawLine(context: context, from: CGPoint(x: w, y: h),
                     to: CGPoint(x: w * (1 - lineProgress), y: h), color: color, style: stroke)
            drawLine(context: context, from: CGPoint(x: 0, y: h),
                     to: CGPoint(x: 0, y: h * (1 - lineProgress)), color: color, style: stroke)

            // Center line (vertical)
            if lineProgress > 0.5 {
                let p = (lineProgress - 0.5) * 2
                drawLine(context: context, from: CGPoint(x: w / 2, y: 0),
                         to: CGPoint(x: w / 2, y: h * p), color: color, style: stroke)
            }

            // Kitchen boxes (non-volley zone) top and bottom
            if lineProgress > 0.7 {
                let p = (lineProgress - 0.7) / 0.3
                let kitchenH = h * 0.22
                // Top kitchen
                drawLine(context: context, from: CGPoint(x: 0, y: kitchenH),
                         to: CGPoint(x: w * p, y: kitchenH), color: color.opacity(0.7), style: stroke)
                // Bottom kitchen
                drawLine(context: context, from: CGPoint(x: 0, y: h - kitchenH),
                         to: CGPoint(x: w * p, y: h - kitchenH), color: color.opacity(0.7), style: stroke)
            }
        }
    }

    private func drawLine(context: GraphicsContext, from: CGPoint, to: CGPoint,
                          color: Color, style: StrokeStyle) {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        context.stroke(path, with: .color(color), style: style)
    }
}

// MARK: - EmptyEventsView

struct EmptyEventsView: View {
    let onBrowse: (() -> Void)?

    @State private var dotScale: CGFloat = 0.6
    @State private var dotOpacity: Double = 0.4
    @State private var calendarOffset: CGFloat = 8
    @State private var calendarOpacity: Double = 0

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Calendar with pulsing dot
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.dinkrAmber.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.dinkrAmber.opacity(0.4), lineWidth: 1.5)
                    )
                    .offset(y: calendarOffset)
                    .opacity(calendarOpacity)

                Image(systemName: "calendar")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Color.dinkrAmber)
                    .offset(y: calendarOffset)
                    .opacity(calendarOpacity)

                // Pulsing dot (new event indicator)
                Circle()
                    .fill(Color.dinkrCoral)
                    .frame(width: 14, height: 14)
                    .scaleEffect(dotScale)
                    .opacity(dotOpacity)
                    .offset(x: 30, y: -30 + calendarOffset)
            }
            .frame(height: 110)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                    calendarOffset = 0
                    calendarOpacity = 1
                }
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true).delay(0.6)) {
                    dotScale = 1.2
                    dotOpacity = 1.0
                }
            }

            VStack(spacing: 10) {
                Text("No Upcoming Events")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dinkrNavy)

                Text("There are no events on the calendar yet. Check back soon or browse all regions.")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 28)
            }

            if let onBrowse {
                Button(action: {
                    HapticManager.medium()
                    onBrowse()
                }) {
                    Text("Browse All Events")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.dinkrAmber)
                        .clipShape(Capsule())
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - EmptyMarketView

struct EmptyMarketView: View {
    let onSell: (() -> Void)?

    @State private var paddleAngle: Double = -15
    @State private var paddleY: CGFloat = 0

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Bouncing paddle illustration
            ZStack {
                // Shadow
                Ellipse()
                    .fill(Color.dinkrNavy.opacity(0.08))
                    .frame(width: 60, height: 10)
                    .offset(y: 48)
                    .scaleEffect(x: paddleY > 0 ? 0.6 : 1.0)

                PaddleShape()
                    .fill(
                        LinearGradient(
                            colors: [Color.dinkrCoral, Color.dinkrCoral.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 55, height: 90)
                    .rotationEffect(.degrees(paddleAngle))
                    .offset(y: paddleY)
            }
            .frame(height: 120)
            .onAppear {
                withAnimation(
                    .interpolatingSpring(stiffness: 180, damping: 12)
                    .repeatForever(autoreverses: true)
                ) {
                    paddleY = -18
                    paddleAngle = 15
                }
            }

            VStack(spacing: 10) {
                Text("No Listings Yet")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dinkrNavy)

                Text("The marketplace is empty right now. List your gear and be the first seller!")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 28)
            }

            if let onSell {
                Button(action: {
                    HapticManager.medium()
                    onSell()
                }) {
                    Label("Sell Your Gear", systemImage: "tag.fill")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.dinkrCoral)
                        .clipShape(Capsule())
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// Simple paddle silhouette
private struct PaddleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let headH = h * 0.68

        // Head (rounded rectangle)
        path.addRoundedRect(
            in: CGRect(x: 0, y: 0, width: w, height: headH),
            cornerSize: CGSize(width: w * 0.45, height: w * 0.45)
        )

        // Grip trapezoid
        let gripW: CGFloat = w * 0.28
        let gripX = (w - gripW) / 2
        path.move(to: CGPoint(x: w * 0.2, y: headH))
        path.addLine(to: CGPoint(x: gripX, y: h))
        path.addLine(to: CGPoint(x: gripX + gripW, y: h))
        path.addLine(to: CGPoint(x: w * 0.8, y: headH))
        path.closeSubpath()

        return path
    }
}

// MARK: - EmptyGroupsView

struct EmptyGroupsView: View {
    let onDiscover: (() -> Void)?

    @State private var circleMergeProgress: CGFloat = 0
    @State private var circleOpacity: Double = 0

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Three circles merging into one
            MergingCirclesIllustration(progress: circleMergeProgress)
                .frame(width: 140, height: 80)
                .opacity(circleOpacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                        circleMergeProgress = 1.0
                        circleOpacity = 1.0
                    }
                    // Fade in once
                    withAnimation(.easeOut(duration: 0.4)) {
                        circleOpacity = 1.0
                    }
                }

            VStack(spacing: 10) {
                Text("No Groups Yet")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dinkrNavy)

                Text("You haven't joined any groups. Discover local clubs and squads to play with regularly.")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 28)
            }

            if let onDiscover {
                Button(action: {
                    HapticManager.medium()
                    onDiscover()
                }) {
                    Label("Discover Groups", systemImage: "person.3.fill")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.dinkrSky)
                        .clipShape(Capsule())
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// Three circles that drift inward and blend
private struct MergingCirclesIllustration: View {
    let progress: CGFloat  // 0 = spread apart, 1 = merged

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let spread: CGFloat = 38 * (1 - progress * 0.72)
            let size: CGFloat = 50

            ZStack {
                Circle()
                    .fill(Color.dinkrSky.opacity(0.55))
                    .frame(width: size, height: size)
                    .offset(x: -spread, y: 0)

                Circle()
                    .fill(Color.dinkrGreen.opacity(0.55))
                    .frame(width: size, height: size)
                    .offset(x: spread, y: 0)

                Circle()
                    .fill(Color.dinkrAmber.opacity(0.55))
                    .frame(width: size * 0.8, height: size * 0.8)
                    .offset(x: 0, y: -spread * 0.6)
            }
            .position(x: w / 2, y: h / 2)
        }
    }
}

// MARK: - Previews

#Preview("Generic Empty") {
    EmptyFeedView(
        title: "Nothing Here Yet",
        message: "Content will appear here once it's available.",
        ctaLabel: "Refresh",
        action: {}
    )
}

#Preview("Empty Games") {
    EmptyGamesView(onFind: {}, onHost: {})
}

#Preview("Empty Events") {
    EmptyEventsView(onBrowse: {})
}

#Preview("Empty Market") {
    EmptyMarketView(onSell: {})
}

#Preview("Empty Groups") {
    EmptyGroupsView(onDiscover: {})
}

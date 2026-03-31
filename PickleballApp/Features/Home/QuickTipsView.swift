import SwiftUI

// MARK: - QuickTipsView
// Coach-mark style onboarding overlay shown once for new users.
// Presents a dimmed full-screen background with a spotlight hole cut out
// over the relevant UI region, plus a tip card, progress dots, and Next/Skip.

struct QuickTipsView: View {

    // MARK: Stored state
    @AppStorage("hasSeenTips") private var hasSeenTips: Bool = false

    // MARK: Geometry anchors passed in from HomeView
    /// Each anchor describes where the spotlight should focus.
    /// HomeView passes these via preference keys / GeometryReader proxies.
    var spotlightFrames: [CGRect]

    // MARK: Local state
    @State private var currentIndex: Int = 0
    @State private var cardOffset: CGFloat = 0
    @State private var cardOpacity: Double = 1

    // MARK: Tips data
    private let tips: [Tip] = [
        Tip(
            icon: "person.crop.circle.badge.clock",
            iconColor: Color.dinkrSky,
            title: "Check who's playing near you!",
            body: "Stories show live check-ins from players at courts around you.",
            spotlightIndex: 0
        ),
        Tip(
            icon: "square.grid.2x2.fill",
            iconColor: Color.dinkrGreen,
            title: "Your personalized game hub",
            body: "The bento grid surfaces upcoming games, stats, and events tailored to you.",
            spotlightIndex: 1
        ),
        Tip(
            icon: "bolt.fill",
            iconColor: Color.dinkrAmber,
            title: "Host or find a game instantly",
            body: "Tap Host or Find to set up or join a game in seconds.",
            spotlightIndex: 2
        ),
        Tip(
            icon: "rectangle.grid.1x2.fill",
            iconColor: Color.dinkrCoral,
            title: "Explore everything Dinkr has to offer",
            body: "Use the tabs below to browse Play, Groups, Events, Market, and your Profile.",
            spotlightIndex: 3
        )
    ]

    private var currentTip: Tip { tips[currentIndex] }
    private var isLast: Bool { currentIndex == tips.count - 1 }

    // MARK: Body

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Dimmed background with spotlight cutout
                dimmingLayer(proxy: proxy)

                // Tip card
                VStack {
                    Spacer()
                    tipCard
                        .padding(.horizontal, 24)
                        .padding(.bottom, max(proxy.safeAreaInsets.bottom + 16, 36))
                        .offset(y: cardOffset)
                        .opacity(cardOpacity)
                }
            }
            .ignoresSafeArea()
        }
        .transition(.opacity)
    }

    // MARK: - Dimming + spotlight

    @ViewBuilder
    private func dimmingLayer(proxy: GeometryProxy) -> some View {
        let spotlightRect = spotlightRect(for: currentIndex, proxy: proxy)

        Color.black
            .opacity(0.62)
            .mask(
                // Invert: cut a clear hole in the dim layer at the spotlight rect
                Rectangle()
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.black)  // "erase" the hole
                            .frame(
                                width: spotlightRect.width + 16,
                                height: spotlightRect.height + 16
                            )
                            .position(
                                x: spotlightRect.midX,
                                y: spotlightRect.midY
                            )
                    )
                    .compositingGroup()
                    .luminanceToAlpha()
                    .allowsHitTesting(false)
            )
    }

    // MARK: - Tip card

    private var tipCard: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(currentTip.iconColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: currentTip.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(currentTip.iconColor)
            }

            // Text
            VStack(spacing: 6) {
                Text(currentTip.title)
                    .font(.headline)
                    .foregroundStyle(Color.dinkrNavy)
                    .multilineTextAlignment(.center)

                Text(currentTip.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Progress dots
            progressDots

            // Buttons
            HStack(spacing: 12) {
                // Skip
                Button {
                    finish()
                } label: {
                    Text("Skip")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                // Next / Done
                Button {
                    if isLast { finish() } else { advance() }
                } label: {
                    Text(isLast ? "Get Started" : "Next")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.dinkrGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 8)
        )
    }

    // MARK: - Progress dots

    private var progressDots: some View {
        HStack(spacing: 7) {
            ForEach(0..<tips.count, id: \.self) { idx in
                Capsule()
                    .fill(idx == currentIndex ? Color.dinkrGreen : Color.secondary.opacity(0.3))
                    .frame(width: idx == currentIndex ? 20 : 7, height: 7)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentIndex)
            }
        }
    }

    // MARK: - Actions

    private func advance() {
        animateTransition {
            currentIndex = min(currentIndex + 1, tips.count - 1)
        }
    }

    private func finish() {
        withAnimation(.easeOut(duration: 0.25)) {
            hasSeenTips = true
        }
    }

    private func animateTransition(update: @escaping () -> Void) {
        // Slide out
        withAnimation(.easeIn(duration: 0.18)) {
            cardOffset = -20
            cardOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            update()
            cardOffset = 30
            // Slide in with spring
            withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
                cardOffset = 0
                cardOpacity = 1
            }
        }
    }

    // MARK: - Spotlight rect resolver

    /// Returns a CGRect in global coordinates for the spotlight at the given tip index.
    /// Falls back to a sensible default frame when the caller has not provided a match.
    private func spotlightRect(for tipIndex: Int, proxy: GeometryProxy) -> CGRect {
        let full = CGRect(origin: .zero, size: proxy.size)

        if tipIndex < spotlightFrames.count {
            let r = spotlightFrames[tipIndex]
            // Guard against zero-size anchors
            if r.width > 8 && r.height > 8 { return r }
        }

        // Default fallback strips
        let w = full.width
        switch tipIndex {
        case 0: // Stories bar — top strip
            return CGRect(x: 0, y: proxy.safeAreaInsets.top + 60, width: w, height: 90)
        case 1: // Bento grid — upper-middle
            return CGRect(x: 16, y: proxy.safeAreaInsets.top + 165, width: w - 32, height: 140)
        case 2: // Quick actions — mid strip
            return CGRect(x: 16, y: proxy.safeAreaInsets.top + 320, width: w - 32, height: 100)
        case 3: // Nav tabs — bottom strip
            return CGRect(x: 0, y: proxy.size.height - proxy.safeAreaInsets.bottom - 60, width: w, height: 50 + proxy.safeAreaInsets.bottom)
        default:
            return full.insetBy(dx: 32, dy: full.height * 0.25)
        }
    }
}

// MARK: - Tip model

private struct Tip {
    let icon: String
    let iconColor: Color
    let title: String
    let body: String
    let spotlightIndex: Int
}

// MARK: - Preview

#Preview("QuickTipsView") {
    struct Wrapper: View {
        @AppStorage("hasSeenTips") private var hasSeenTips = false
        var body: some View {
            ZStack {
                // Simulated background
                LinearGradient(
                    colors: [Color.dinkrNavy.opacity(0.08), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack { Text("HomeView content here").foregroundStyle(.secondary) }

                if !hasSeenTips {
                    QuickTipsView(spotlightFrames: [])
                        .transition(.opacity)
                }
            }
            .onAppear { hasSeenTips = false }
        }
    }
    return Wrapper()
}

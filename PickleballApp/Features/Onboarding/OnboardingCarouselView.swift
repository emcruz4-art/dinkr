import SwiftUI

// MARK: - OnboardingPage Model

struct OnboardingPage: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let imageName: String
    let gradient: [Color]
    let accentEmoji: String
}

// MARK: - Page Data

private let onboardingPages: [OnboardingPage] = [
    OnboardingPage(
        id: 0,
        title: "Welcome to Dinkr",
        subtitle: "Your game. Your court. Your crew.",
        imageName: "figure.pickleball",
        gradient: [Color.dinkrGreen, Color.dinkrSky],
        accentEmoji: "🏓"
    ),
    OnboardingPage(
        id: 1,
        title: "Find Your Next Game",
        subtitle: "Join pickup sessions, clinics, and tournaments near you.",
        imageName: "calendar.badge.plus",
        gradient: [Color.dinkrNavy, Color.dinkrSky],
        accentEmoji: "📅"
    ),
    OnboardingPage(
        id: 2,
        title: "Meet Your People",
        subtitle: "Match with players at your skill level. Build your crew.",
        imageName: "person.2.fill",
        gradient: [Color.dinkrCoral, Color.dinkrAmber],
        accentEmoji: "🤝"
    ),
    OnboardingPage(
        id: 3,
        title: "Track Your Progress",
        subtitle: "Earn badges, climb leaderboards, build your streak.",
        imageName: "chart.line.uptrend.xyaxis",
        gradient: [Color.dinkrAmber, Color.dinkrCoral],
        accentEmoji: "🏆"
    ),
    OnboardingPage(
        id: 4,
        title: "Gear Up",
        subtitle: "Buy and sell paddles, bags, and accessories with your community.",
        imageName: "bag.fill",
        gradient: [Color.dinkrSky, Color.dinkrGreen],
        accentEmoji: "🎒"
    )
]

// MARK: - Single Page View

private struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var isFloating = false
    @State private var emojiBounced = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: page.gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // SF Symbol icon with floating animation
                Image(systemName: page.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
                    .offset(y: isFloating ? -8 : 8)
                    .animation(
                        .easeInOut(duration: 3).repeatForever(autoreverses: true),
                        value: isFloating
                    )
                    .onAppear {
                        isFloating = true
                    }

                // Accent emoji with spring bounce
                Text(page.accentEmoji)
                    .font(.system(size: 60))
                    .scaleEffect(emojiBounced ? 1.0 : 0.4)
                    .opacity(emojiBounced ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.15), value: emojiBounced)
                    .onAppear {
                        emojiBounced = true
                    }

                // Title
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Subtitle
                Text(page.subtitle)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 40)

                Spacer()
                Spacer()
            }
        }
    }
}

// MARK: - Custom Page Dots

private struct PageDots: View {
    let pageCount: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
}

// MARK: - OnboardingCarouselView

struct OnboardingCarouselView: View {
    let onComplete: () -> Void

    @State private var currentPage = 0

    private var isLastPage: Bool {
        currentPage == onboardingPages.count - 1
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Page TabView
            TabView(selection: $currentPage) {
                ForEach(onboardingPages) { page in
                    OnboardingPageView(page: page)
                        .tag(page.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Bottom controls overlay
            VStack(spacing: 16) {
                PageDots(pageCount: onboardingPages.count, currentPage: currentPage)

                // Continue / Get Started button
                Button {
                    if isLastPage {
                        onComplete()
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            currentPage += 1
                        }
                    }
                } label: {
                    Text(isLastPage ? "Get Started" : "Continue")
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(Color.dinkrNavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 32)

                // Skip button — only on non-last pages
                if !isLastPage {
                    Button {
                        onComplete()
                    } label: {
                        Text("Skip")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.vertical, 4)
                    }
                } else {
                    // Placeholder to maintain consistent spacing
                    Color.clear
                        .frame(height: 24)
                }
            }
            .padding(.bottom, 48)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Preview

#Preview {
    OnboardingCarouselView {
        print("Onboarding complete")
    }
}

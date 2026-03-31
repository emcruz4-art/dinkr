import SwiftUI
import AuthenticationServices

// MARK: - OnboardingView (First-Run 5-Screen Flow)

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(AuthService.self) private var authService

    @State private var currentPage = 0
    @State private var selectedSkill: SkillLevel = .intermediate30
    @State private var selectedStyles: Set<PlayStyle> = []
    @State private var locationGranted = false
    @State private var showAuthLanding = false

    private let pageCount = 5

    var body: some View {
        ZStack {
            if showAuthLanding {
                AuthLandingView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else {
                firstRunOnboarding
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showAuthLanding)
    }

    // MARK: - First-Run Onboarding

    private var firstRunOnboarding: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                WelcomeScreen(
                    onGetStarted: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { currentPage = 1 }
                    },
                    onAlreadyHaveAccount: {
                        withAnimation(.easeInOut(duration: 0.4)) { showAuthLanding = true }
                    }
                )
                .tag(0)

                SkillSetupScreen(selectedSkill: $selectedSkill) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { currentPage = 2 }
                }
                .tag(1)

                PlayStyleScreen(selectedStyles: $selectedStyles) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { currentPage = 3 }
                }
                .tag(2)

                FindCourtsScreen(locationGranted: $locationGranted) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { currentPage = 4 }
                }
                .tag(3)

                AllSetScreen(selectedSkill: selectedSkill) {
                    hasCompletedOnboarding = true
                    Task {
                        try? await authService.signIn(
                            email: "demo@pickleballapp.com",
                            password: "demo"
                        )
                    }
                }
                .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Custom capsule page dots — only on pages 0-3
            if currentPage < 4 {
                OnboardingPageDots(pageCount: pageCount, currentPage: currentPage)
                    .padding(.bottom, 16)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Custom Page Dots

private struct OnboardingPageDots: View {
    let pageCount: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.dinkrGreen : Color.white.opacity(0.35))
                    .frame(
                        width: index == currentPage ? 22 : 8,
                        height: 8
                    )
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

// MARK: - Screen 1: Welcome

private struct WelcomeScreen: View {
    let onGetStarted: () -> Void
    let onAlreadyHaveAccount: () -> Void

    @State private var paddleAngle: Double = 0
    @State private var appeared = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.dinkrNavy, Color.dinkrNavy.opacity(0.88)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                DinkrLogoView(size: 88, showWordmark: true, tintColor: .white)
                    .scaleEffect(appeared ? 1.0 : 0.6)
                    .opacity(appeared ? 1.0 : 0.0)
                    .animation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.1), value: appeared)

                // Tagline
                Text("Your game. Your court. Your crew.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 16)
                    .opacity(appeared ? 1.0 : 0.0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)

                Spacer()

                // Animated paddle icon
                Image(systemName: "figure.pickleball")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.dinkrGreen)
                    .rotationEffect(.degrees(paddleAngle))
                    .shadow(color: Color.dinkrGreen.opacity(0.4), radius: 16, x: 0, y: 4)
                    .opacity(appeared ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5).delay(0.45), value: appeared)
                    .onAppear {
                        withAnimation(
                            .easeInOut(duration: 1.6)
                            .repeatForever(autoreverses: true)
                        ) {
                            paddleAngle = 15
                        }
                        withAnimation(
                            .easeInOut(duration: 1.6)
                            .repeatForever(autoreverses: true)
                            .delay(1.6)
                        ) {
                            paddleAngle = -15
                        }
                    }

                Spacer()
                Spacer()

                // Buttons
                VStack(spacing: 14) {
                    Button(action: onGetStarted) {
                        Text("Get Started")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.dinkrGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.dinkrGreen.opacity(0.4), radius: 12, x: 0, y: 4)
                    }
                    .buttonStyle(ScalePressButtonStyle())

                    Button(action: onAlreadyHaveAccount) {
                        Text("I already have an account")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
                .opacity(appeared ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.5).delay(0.55), value: appeared)
            }
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Screen 2: Skill Setup

private struct SkillSetupScreen: View {
    @Binding var selectedSkill: SkillLevel
    let onNext: () -> Void

    private let skillDescriptions: [SkillLevel: String] = [
        .beginner20:      "Just learning",
        .beginner25:      "Getting comfortable",
        .intermediate30:  "Comfortable with basics",
        .intermediate35:  "Solid & improving",
        .advanced40:      "Strong all-around",
        .advanced45:      "Competitive player",
        .pro50:           "Pro / Tournament level"
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("What's your skill level?")
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(Color.dinkrNavy)
                        .multilineTextAlignment(.center)
                    Text("We'll match you with games at your level")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 56)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(SkillLevel.allCases, id: \.self) { level in
                            SkillLevelCard(
                                level: level,
                                description: skillDescriptions[level] ?? "",
                                isSelected: selectedSkill == level
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                    selectedSkill = level
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }

                Spacer(minLength: 0)
            }

            // Floating next button
            VStack {
                Spacer()
                Button(action: onNext) {
                    Text("Next →")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.dinkrGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(ScalePressButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

private struct SkillLevelCard: View {
    let level: SkillLevel
    let description: String
    let isSelected: Bool
    let onTap: () -> Void

    private var levelColor: Color {
        switch level.color {
        case "blue":   return Color.dinkrSky
        case "orange": return Color.dinkrCoral
        case "red":    return Color.red
        default:       return Color.dinkrGreen
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Color swatch
                RoundedRectangle(cornerRadius: 6)
                    .fill(levelColor)
                    .frame(width: 6, height: 40)

                VStack(alignment: .leading, spacing: 3) {
                    Text(level.label)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.dinkrGreen)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.dinkrGreen.opacity(0.07) : Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.dinkrGreen : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Screen 3: Play Style

private struct PlayStyleScreen: View {
    @Binding var selectedStyles: Set<PlayStyle>
    let onNext: () -> Void

    private let styleDescriptions: [PlayStyle: String] = [
        .competitive:  "Win-focused, rated play",
        .recreational: "Fun & social games",
        .drillFocused: "Practice & skill-building",
        .dinkCulture:  "Chill kitchen rallies",
        .allAround:    "A bit of everything"
    ]

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("How do you like to play?")
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(Color.dinkrNavy)
                        .multilineTextAlignment(.center)
                    Text("Pick all that apply")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 56)
                .padding(.horizontal, 24)
                .padding(.bottom, 28)

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(PlayStyle.allCases, id: \.self) { style in
                            PlayStyleCard(
                                style: style,
                                description: styleDescriptions[style] ?? "",
                                isSelected: selectedStyles.contains(style)
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                    if selectedStyles.contains(style) {
                                        selectedStyles.remove(style)
                                    } else {
                                        selectedStyles.insert(style)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }

            VStack {
                Spacer()
                Button(action: onNext) {
                    Text("Next →")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.dinkrGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(ScalePressButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

private struct PlayStyleCard: View {
    let style: PlayStyle
    let description: String
    let isSelected: Bool
    let onTap: () -> Void

    private var styleColor: Color {
        switch style.color {
        case "dinkrCoral":  return Color.dinkrCoral
        case "dinkrSky":    return Color.dinkrSky
        case "dinkrAmber":  return Color.dinkrAmber
        case "dinkrNavy":   return Color.dinkrNavy
        default:            return Color.dinkrGreen
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Image(systemName: style.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(isSelected ? .white : styleColor)

                Text(style.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : Color.primary)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : Color.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? styleColor : Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? styleColor : Color.clear, lineWidth: 2)
                    )
            )
            .shadow(color: isSelected ? styleColor.opacity(0.3) : .clear, radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Screen 4: Find Courts

private let mockNearbyCourts: [(name: String, distance: String)] = [
    ("Bartholomew District Park", "0.4 mi"),
    ("Austin High School Courts", "1.1 mi"),
    ("Disch-Falk Field Complex", "2.3 mi")
]

private struct FindCourtsScreen: View {
    @Binding var locationGranted: Bool
    let onNext: () -> Void

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("Courts near you")
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(Color.dinkrNavy)
                        .multilineTextAlignment(.center)
                    Text("Find pickup games at courts in your area")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 56)
                .padding(.horizontal, 24)
                .padding(.bottom, 28)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Location permission card
                        VStack(spacing: 14) {
                            Image(systemName: locationGranted ? "location.fill" : "location.circle")
                                .font(.system(size: 44))
                                .foregroundStyle(locationGranted ? Color.dinkrGreen : Color.dinkrSky)

                            Text(locationGranted ? "Austin, TX" : "Enable location to see nearby courts")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(locationGranted ? Color.dinkrGreen : Color.primary)
                                .multilineTextAlignment(.center)

                            if !locationGranted {
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        locationGranted = true
                                    }
                                } label: {
                                    Label("Enable Location", systemImage: "location.fill")
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Color.dinkrGreen)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(ScalePressButtonStyle())
                            }
                        }
                        .padding(20)
                        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(locationGranted ? Color.dinkrGreen.opacity(0.4) : Color.clear, lineWidth: 1.5)
                        )

                        // Mock nearby courts — shown when location granted
                        if locationGranted {
                            VStack(spacing: 10) {
                                ForEach(mockNearbyCourts, id: \.name) { court in
                                    NearbyCourtRow(name: court.name, distance: court.distance)
                                }
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }

            VStack {
                Spacer()
                Button(action: onNext) {
                    Text("Next →")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.dinkrGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(ScalePressButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

private struct NearbyCourtRow: View {
    let name: String
    let distance: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.dinkrCoral)

            Text(name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.primary)

            Spacer()

            Text(distance)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.dinkrGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.dinkrGreen.opacity(0.12), in: Capsule())
        }
        .padding(14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Screen 5: All Set

private struct AllSetScreen: View {
    let selectedSkill: SkillLevel
    let onComplete: () -> Void

    @State private var burst = false

    private let confettiColors: [Color] = [
        Color.dinkrGreen, Color.dinkrCoral, Color.dinkrAmber, Color.dinkrSky, Color.dinkrNavy
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Confetti celebration
                ZStack {
                    ForEach(0..<5) { i in
                        let angle = Double(i) / 5.0 * 360.0
                        let radians = angle * .pi / 180
                        let distance: CGFloat = burst ? 100 : 0

                        Circle()
                            .fill(confettiColors[i])
                            .frame(width: burst ? 20 : 8, height: burst ? 20 : 8)
                            .offset(
                                x: cos(radians) * distance,
                                y: sin(radians) * distance
                            )
                            .opacity(burst ? 1.0 : 0.0)
                            .animation(
                                .spring(response: 0.55, dampingFraction: 0.65)
                                    .delay(Double(i) * 0.06),
                                value: burst
                            )
                    }

                    // Center trophy
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.dinkrAmber)
                        .scaleEffect(burst ? 1.0 : 0.4)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: burst)
                }
                .frame(width: 240, height: 240)

                // Headline
                Text("Welcome to Dinkr!")
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(Color.dinkrNavy)
                    .multilineTextAlignment(.center)
                    .scaleEffect(burst ? 1.0 : 0.8)
                    .opacity(burst ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.2), value: burst)

                Text("You're all set to find your first game.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                    .opacity(burst ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.4).delay(0.35), value: burst)

                // Skill badge
                HStack(spacing: 8) {
                    Text("Your level:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    SkillBadge(level: selectedSkill)
                }
                .padding(.top, 18)
                .opacity(burst ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.4).delay(0.45), value: burst)

                Spacer()

                // CTA button
                Button(action: onComplete) {
                    Text("Find Your First Game →")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.dinkrGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.dinkrGreen.opacity(0.4), radius: 12, x: 0, y: 4)
                }
                .buttonStyle(ScalePressButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
                .opacity(burst ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.4).delay(0.55), value: burst)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                burst = true
            }
        }
    }
}

// MARK: - Animated Court Line Pattern

private struct CourtLinePattern: View {
    @State private var drawProgress: Double = 0

    var body: some View {
        Canvas { ctx, size in
            let path = fullCourtLinePath(size: size, progress: drawProgress)
            ctx.stroke(path, with: .color(.white.opacity(0.06)), lineWidth: 1.5)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2)) {
                drawProgress = 1.0
            }
        }
    }
}

private func fullCourtLinePath(size: CGSize, progress: Double) -> Path {
    var path = Path()
    let w = size.width
    let h = size.height
    let margin: CGFloat = 20

    // Horizontal baselines
    let horizontals: [CGFloat] = [0.18, 0.38, 0.62, 0.82]
    for ratio in horizontals {
        let y = h * ratio
        let endX = margin + (w - margin * 2) * progress
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: endX, y: y))
    }

    // Side lines
    let topY = h * 0.18
    let botY = h * 0.82
    let sideEndY = topY + (botY - topY) * progress
    path.move(to: CGPoint(x: margin, y: topY))
    path.addLine(to: CGPoint(x: margin, y: sideEndY))
    path.move(to: CGPoint(x: w - margin, y: topY))
    path.addLine(to: CGPoint(x: w - margin, y: sideEndY))

    // Center vertical line
    path.move(to: CGPoint(x: w / 2, y: topY))
    path.addLine(to: CGPoint(x: w / 2, y: sideEndY))

    // NVZ / kitchen lines
    let nvzOffset = h * 0.12
    let centerY = h * 0.5
    let nvzEndX = margin + (w - margin * 2) * progress
    path.move(to: CGPoint(x: margin, y: centerY - nvzOffset))
    path.addLine(to: CGPoint(x: nvzEndX, y: centerY - nvzOffset))
    path.move(to: CGPoint(x: margin, y: centerY + nvzOffset))
    path.addLine(to: CGPoint(x: nvzEndX, y: centerY + nvzOffset))

    return path
}

// MARK: - Floating Pickleball Illustration

private struct PickleballIllustration: View {
    @State private var spin: Double = 0
    @State private var floatOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Main ball body
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 180, height: 180)

            // Outer dashed border
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                .foregroundStyle(Color.white.opacity(0.1))
                .frame(width: 180, height: 180)

            // Surface seam lines (pickleball has distinctive hole pattern suggested by lines)
            ForEach(0..<4) { i in
                Ellipse()
                    .stroke(Color.white.opacity(0.07), lineWidth: 1.2)
                    .frame(width: 180, height: 60)
                    .rotationEffect(.degrees(Double(i) * 45))
            }

            // Inner circle
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                .frame(width: 90, height: 90)
        }
        .rotationEffect(.degrees(spin))
        .offset(y: floatOffset)
        .onAppear {
            withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) {
                spin = 360
            }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                floatOffset = -14
            }
        }
    }
}

// MARK: - AuthLandingView

struct AuthLandingView: View {
    @Environment(AuthService.self) private var authService
    @State private var showEmailSignIn = false
    @State private var showEmailSignUp = false
    @State private var logoFloat: CGFloat = 0
    @State private var logoAppeared = false
    @State private var taglineAppeared = false
    @State private var sheetAppeared = false
    @State private var errorMessage: String? = nil

    var body: some View {
        ZStack {
            // Full-screen navy background
            Color.dinkrNavy.ignoresSafeArea()

            // Animated court lines
            CourtLinePattern()

            // Floating pickleball illustration (top-right, low opacity)
            VStack {
                HStack {
                    Spacer()
                    PickleballIllustration()
                        .offset(x: 60, y: -30)
                }
                Spacer()
            }
            .ignoresSafeArea()

            // Main content
            VStack(spacing: 0) {
                Spacer()

                // Logo + tagline zone
                VStack(spacing: 20) {
                    DinkrLogoView(size: 88, showWordmark: true, tintColor: .white)
                        .scaleEffect(logoAppeared ? 1.0 : 0.55)
                        .opacity(logoAppeared ? 1.0 : 0.0)
                        .offset(y: logoFloat)
                        .animation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.1), value: logoAppeared)
                        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(0.8), value: logoFloat)

                    Text("Your game. Your court. Your crew.")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .opacity(taglineAppeared ? 1.0 : 0.0)
                        .offset(y: taglineAppeared ? 0 : 14)
                        .animation(.easeOut(duration: 0.55).delay(0.35), value: taglineAppeared)
                }

                Spacer()
                Spacer()

                // Auth sheet
                bottomSheet
            }
        }
        .onAppear {
            logoAppeared = true
            taglineAppeared = true
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(0.9)) {
                logoFloat = -5
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.5)) {
                sheetAppeared = true
            }
        }
        .sheet(isPresented: $showEmailSignIn) {
            EmailSignInView()
                .environment(authService)
        }
        .sheet(isPresented: $showEmailSignUp) {
            EmailSignUpView()
                .environment(authService)
        }
    }

    // MARK: Bottom Sheet

    private var bottomSheet: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {

                // Error banner
                if let error = errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(Color.dinkrCoral)
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Color.dinkrCoral)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Button {
                            withAnimation { errorMessage = nil }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.dinkrCoral.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Sign In with Apple
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { _ in
                    Task {
                        do {
                            try await authService.signInWithApple()
                        } catch {
                            withAnimation { errorMessage = error.localizedDescription }
                        }
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                .overlay(loadingOverlay)

                // Google Sign In
                PremiumGoogleSignInButton {
                    Task {
                        do {
                            try await authService.signInWithGoogle()
                        } catch {
                            withAnimation { errorMessage = error.localizedDescription }
                        }
                    }
                }
                .overlay(loadingOverlay)

                // Divider
                HStack(spacing: 14) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 1)
                    Text("or")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.vertical, 2)

                // Email sign in: ghost button
                Button {
                    showEmailSignIn = true
                } label: {
                    Text("Sign in with Email")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.06))
                                )
                        )
                }
                .disabled(authService.isLoading)
                .buttonStyle(ScalePressButtonStyle())

                // Create account
                Button {
                    showEmailSignUp = true
                } label: {
                    HStack(spacing: 4) {
                        Text("New to Dinkr?")
                            .foregroundStyle(.white.opacity(0.55))
                        Text("Create account")
                            .foregroundStyle(.white.opacity(0.9))
                            .fontWeight(.semibold)
                    }
                    .font(.footnote)
                }
                .disabled(authService.isLoading)
                .padding(.top, 2)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 48)
        }
        .background(
            Color.dinkrNavy.opacity(0.94)
                .background(.ultraThinMaterial)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 30,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 30
                    )
                )
                .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: -6)
        )
        .offset(y: sheetAppeared ? 0 : 320)
        .opacity(sheetAppeared ? 1 : 0)
    }

    @ViewBuilder
    private var loadingOverlay: some View {
        if authService.isLoading {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.3))
            ProgressView()
                .tint(.white)
        }
    }
}

// MARK: - Scale Press Button Style

struct ScalePressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Premium Google Sign In Button

private struct PremiumGoogleSignInButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Google "G" multicolor gradient
                Text("G")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.26, green: 0.52, blue: 0.96),
                                Color(red: 0.92, green: 0.26, blue: 0.21),
                                Color(red: 0.98, green: 0.74, blue: 0.02),
                                Color(red: 0.20, green: 0.66, blue: 0.33)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 20, height: 20)

                Text("Continue with Google")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(UIColor.label))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(ScalePressButtonStyle())
    }
}

// MARK: - EmailSignInView

struct EmailSignInView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var showForgotAlert = false
    @State private var forgotEmail = ""
    @FocusState private var focusedField: SignInField?

    enum SignInField: Hashable {
        case email, password
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dinkrNavy.ignoresSafeArea()

                // Subtle court lines
                Canvas { ctx, size in
                    let path = fullCourtLinePath(size: size, progress: 1.0)
                    ctx.stroke(path, with: .color(.white.opacity(0.03)), lineWidth: 1.2)
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {

                        // Header
                        VStack(spacing: 10) {
                            DinkrLogoView(size: 52, showWordmark: true, tintColor: Color.dinkrGreen)
                            Text("Welcome back")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                            Text("Sign in to your Dinkr account")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        .padding(.top, 12)

                        // Error banner
                        if let error = authService.error {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(Color.dinkrCoral)
                                    .font(.footnote)
                                Text(error)
                                    .font(.footnote)
                                    .foregroundStyle(Color.dinkrCoral)
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.dinkrCoral.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // Fields
                        VStack(spacing: 16) {
                            DarkAuthTextField(
                                label: "Email",
                                placeholder: "you@example.com",
                                text: $email,
                                systemImage: "envelope",
                                keyboardType: .emailAddress,
                                textContentType: .emailAddress,
                                autocapitalization: .never,
                                isFocused: focusedField == .email
                            )
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }

                            DarkAuthSecureField(
                                label: "Password",
                                placeholder: "Enter your password",
                                text: $password,
                                systemImage: "lock",
                                isFocused: focusedField == .password
                            )
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit { signIn() }
                        }

                        // Forgot password
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                forgotEmail = email
                                showForgotAlert = true
                            }
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.dinkrSky)
                        }

                        // Sign In button
                        GradientSubmitButton(
                            title: "Sign In",
                            isLoading: authService.isLoading,
                            isEnabled: canSignIn,
                            action: signIn
                        )

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
        .alert("Reset Password", isPresented: $showForgotAlert) {
            TextField("Your email address", text: $forgotEmail)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Button("Send Reset Email") {}
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("We'll send a password reset link to your email.")
        }
    }

    private var canSignIn: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && password.count >= 6
    }

    private func signIn() {
        guard canSignIn else { return }
        focusedField = nil
        Task {
            do {
                try await authService.signIn(
                    email: email.trimmingCharacters(in: .whitespaces),
                    password: password
                )
            } catch {}
        }
    }
}

// MARK: - EmailSignUpView

struct EmailSignUpView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreedToTerms = false
    @State private var showSkillAssessment = false
    @FocusState private var focusedField: SignUpField?

    enum SignUpField: Hashable {
        case displayName, email, password, confirmPassword
    }

    // MARK: Password Strength

    private enum PasswordStrength: String {
        case empty = ""
        case weak = "Weak"
        case fair = "Fair"
        case strong = "Strong"

        var gradientColors: [Color] {
            switch self {
            case .empty: return [Color.secondary.opacity(0.2), Color.secondary.opacity(0.2)]
            case .weak: return [Color.dinkrCoral, Color.dinkrCoral.opacity(0.7)]
            case .fair: return [Color.dinkrAmber, Color.dinkrAmber.opacity(0.7)]
            case .strong: return [Color.dinkrGreen, Color.dinkrSky]
            }
        }

        var labelColor: Color {
            switch self {
            case .empty: return .secondary
            case .weak: return Color.dinkrCoral
            case .fair: return Color.dinkrAmber
            case .strong: return Color.dinkrGreen
            }
        }

        var fillFraction: CGFloat {
            switch self {
            case .empty: return 0
            case .weak: return 0.33
            case .fair: return 0.66
            case .strong: return 1.0
            }
        }
    }

    private var passwordStrength: PasswordStrength {
        guard !password.isEmpty else { return .empty }
        let hasSpecial = password.rangeOfCharacter(from: .init(charactersIn: "!@#$%^&*()_+-=[]{}|;':\",./<>?")) != nil
        let hasUpper = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        let longEnough = password.count >= 10
        let score = [hasSpecial, hasUpper, hasNumber, longEnough, password.count >= 8].filter { $0 }.count
        if score <= 2 { return .weak }
        if score <= 3 { return .fair }
        return .strong
    }

    private var passwordsMatch: Bool {
        !confirmPassword.isEmpty && password == confirmPassword
    }

    private var canCreate: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
            && email.contains("@")
            && passwordStrength != .empty
            && passwordStrength != .weak
            && passwordsMatch
            && agreedToTerms
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dinkrNavy.ignoresSafeArea()

                Canvas { ctx, size in
                    let path = fullCourtLinePath(size: size, progress: 1.0)
                    ctx.stroke(path, with: .color(.white.opacity(0.03)), lineWidth: 1.2)
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Header
                        VStack(spacing: 10) {
                            DinkrLogoView(size: 52, showWordmark: true, tintColor: Color.dinkrGreen)
                            Text("Create your account")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                            Text("Join the Dinkr community")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        .padding(.top, 12)

                        // Error
                        if let error = authService.error {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(Color.dinkrCoral)
                                    .font(.footnote)
                                Text(error)
                                    .font(.footnote)
                                    .foregroundStyle(Color.dinkrCoral)
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.dinkrCoral.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // Fields
                        VStack(spacing: 16) {
                            DarkAuthTextField(
                                label: "Display Name",
                                placeholder: "Your name on Dinkr",
                                text: $displayName,
                                systemImage: "person",
                                keyboardType: .default,
                                textContentType: .name,
                                autocapitalization: .words,
                                isFocused: focusedField == .displayName
                            )
                            .focused($focusedField, equals: .displayName)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .email }

                            DarkAuthTextField(
                                label: "Email",
                                placeholder: "you@example.com",
                                text: $email,
                                systemImage: "envelope",
                                keyboardType: .emailAddress,
                                textContentType: .emailAddress,
                                autocapitalization: .never,
                                isFocused: focusedField == .email
                            )
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }

                            // Password + strength indicator
                            VStack(alignment: .leading, spacing: 8) {
                                DarkAuthSecureField(
                                    label: "Password",
                                    placeholder: "Min. 8 characters",
                                    text: $password,
                                    systemImage: "lock",
                                    isFocused: focusedField == .password
                                )
                                .focused($focusedField, equals: .password)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .confirmPassword }

                                if !password.isEmpty {
                                    VStack(alignment: .leading, spacing: 5) {
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.white.opacity(0.08))
                                                    .frame(height: 5)
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(
                                                        LinearGradient(
                                                            colors: passwordStrength.gradientColors,
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                                    .frame(
                                                        width: geo.size.width * passwordStrength.fillFraction,
                                                        height: 5
                                                    )
                                                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: passwordStrength.fillFraction)
                                            }
                                        }
                                        .frame(height: 5)

                                        Text(passwordStrength.rawValue)
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(passwordStrength.labelColor)
                                    }
                                    .padding(.horizontal, 4)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .animation(.easeOut(duration: 0.2), value: password.isEmpty)

                            // Confirm password
                            VStack(alignment: .leading, spacing: 5) {
                                DarkAuthSecureField(
                                    label: "Confirm Password",
                                    placeholder: "Re-enter your password",
                                    text: $confirmPassword,
                                    systemImage: passwordsMatch ? "lock.fill" : "lock",
                                    isFocused: focusedField == .confirmPassword
                                )
                                .focused($focusedField, equals: .confirmPassword)
                                .submitLabel(.done)
                                .onSubmit { focusedField = nil }

                                if !confirmPassword.isEmpty && !passwordsMatch {
                                    Text("Passwords don't match")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(Color.dinkrCoral)
                                        .padding(.horizontal, 4)
                                        .transition(.opacity)
                                }
                            }
                            .animation(.easeOut(duration: 0.2), value: confirmPassword)
                        }

                        // Terms toggle
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                agreedToTerms.toggle()
                            }
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(agreedToTerms ? Color.dinkrGreen : Color.white.opacity(0.07))
                                        .frame(width: 22, height: 22)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(
                                                    agreedToTerms ? Color.dinkrGreen : Color.white.opacity(0.25),
                                                    lineWidth: 1.5
                                                )
                                        )
                                    if agreedToTerms {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .heavy))
                                            .foregroundStyle(.white)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: agreedToTerms)

                                (Text("I agree to the ")
                                    .foregroundStyle(.white.opacity(0.6))
                                + Text("Terms of Service")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.dinkrSky)
                                + Text(" and ")
                                    .foregroundStyle(.white.opacity(0.6))
                                + Text("Privacy Policy")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.dinkrSky))
                                .font(.footnote)
                            }
                        }
                        .buttonStyle(.plain)

                        // Create Account button
                        GradientSubmitButton(
                            title: "Create Account",
                            isLoading: authService.isLoading,
                            isEnabled: canCreate,
                            action: createAccount
                        )

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
            .sheet(isPresented: $showSkillAssessment) {
                SkillAssessmentView { _ in
                    showSkillAssessment = false
                    dismiss()
                }
            }
        }
    }

    private func createAccount() {
        guard canCreate else { return }
        focusedField = nil
        Task {
            do {
                try await authService.signUp(
                    email: email.trimmingCharacters(in: .whitespaces),
                    password: password,
                    displayName: displayName.trimmingCharacters(in: .whitespaces)
                )
                showSkillAssessment = true
            } catch {}
        }
    }
}

// MARK: - Dark Auth Text Field

private struct DarkAuthTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let systemImage: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences
    var isFocused: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isFocused ? Color.dinkrGreen : .white.opacity(0.55))
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .foregroundStyle(isFocused ? Color.dinkrGreen : .white.opacity(0.45))
                    .frame(width: 18)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)

                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
                    .font(.body)
                    .foregroundStyle(.white)
                    .tint(Color.dinkrGreen)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isFocused ? Color.dinkrGreen : Color.white.opacity(0.12),
                        lineWidth: isFocused ? 1.5 : 1
                    )
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            )
        }
    }
}

// MARK: - Dark Auth Secure Field

private struct DarkAuthSecureField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let systemImage: String
    var isFocused: Bool = false
    @State private var isRevealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isFocused ? Color.dinkrGreen : .white.opacity(0.55))
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .foregroundStyle(isFocused ? Color.dinkrGreen : .white.opacity(0.45))
                    .frame(width: 18)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)

                ZStack {
                    if isRevealed {
                        TextField(placeholder, text: $text)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .font(.body)
                            .foregroundStyle(.white)
                            .tint(Color.dinkrGreen)
                    } else {
                        SecureField(placeholder, text: $text)
                            .font(.body)
                            .foregroundStyle(.white)
                            .tint(Color.dinkrGreen)
                    }
                }

                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .foregroundStyle(.white.opacity(0.45))
                        .font(.footnote)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isFocused ? Color.dinkrGreen : Color.white.opacity(0.12),
                        lineWidth: isFocused ? 1.5 : 1
                    )
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            )
        }
    }
}

// MARK: - Gradient Submit Button

private struct GradientSubmitButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    private var buttonGradient: LinearGradient {
        isEnabled
            ? LinearGradient(
                colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            : LinearGradient(
                colors: [Color.dinkrGreen.opacity(0.3), Color.dinkrGreen.opacity(0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(buttonGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: isEnabled ? Color.dinkrGreen.opacity(0.4) : .clear,
                radius: 10, x: 0, y: 5
            )
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(ScalePressButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

// MARK: - Legacy text field wrappers (kept for any remaining usages)

private struct AuthTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let systemImage: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        DarkAuthTextField(
            label: label,
            placeholder: placeholder,
            text: $text,
            systemImage: systemImage,
            keyboardType: keyboardType,
            textContentType: textContentType,
            autocapitalization: autocapitalization,
            isFocused: false
        )
    }
}

private struct AuthSecureField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let systemImage: String

    var body: some View {
        DarkAuthSecureField(
            label: label,
            placeholder: placeholder,
            text: $text,
            systemImage: systemImage,
            isFocused: false
        )
    }
}

// MARK: - Previews

#Preview("Onboarding (Carousel)") {
    OnboardingView()
        .environment(AuthService())
}

#Preview("Auth Landing") {
    AuthLandingView()
        .environment(AuthService())
}

#Preview("Email Sign In") {
    EmailSignInView()
        .environment(AuthService())
}

#Preview("Email Sign Up") {
    EmailSignUpView()
        .environment(AuthService())
}

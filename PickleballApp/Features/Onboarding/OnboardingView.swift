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
        ZStack(alignment: .top) {
            TabView(selection: $currentPage) {
                WelcomeScreen(
                    onGetStarted: {
                        withAnimation(.easeInOut(duration: 0.35)) { currentPage = 1 }
                    },
                    onAlreadyHaveAccount: {
                        withAnimation(.easeInOut(duration: 0.4)) { showAuthLanding = true }
                    }
                )
                .tag(0)

                SkillSetupScreen(
                    selectedSkill: $selectedSkill,
                    currentPage: $currentPage,
                    onNext: {
                        withAnimation(.easeInOut(duration: 0.35)) { currentPage = 2 }
                    }
                )
                .tag(1)

                PlayStyleScreen(
                    selectedStyles: $selectedStyles,
                    currentPage: $currentPage,
                    onNext: {
                        withAnimation(.easeInOut(duration: 0.35)) { currentPage = 3 }
                    }
                )
                .tag(2)

                FindCourtsScreen(
                    locationGranted: $locationGranted,
                    currentPage: $currentPage,
                    onNext: {
                        withAnimation(.easeInOut(duration: 0.35)) { currentPage = 4 }
                    }
                )
                .tag(3)

                AllSetScreen(
                    selectedSkill: selectedSkill,
                    selectedStyles: selectedStyles
                ) {
                    hasCompletedOnboarding = true
                    withAnimation(.easeInOut(duration: 0.4)) { showAuthLanding = true }
                }
                .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Progress bar overlay — shown on pages 1-3
            if currentPage > 0 && currentPage < 4 {
                OnboardingProgressBar(pageCount: pageCount, currentPage: currentPage)
                    .padding(.top, 60)
                    .padding(.horizontal, 24)
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.25), value: currentPage)
    }
}

// MARK: - Progress Bar

private struct OnboardingProgressBar: View {
    let pageCount: Int
    let currentPage: Int

    // Pages 1-3 are the progress-tracked screens (0 = welcome, 4 = all set)
    private var progress: CGFloat {
        CGFloat(currentPage) / CGFloat(pageCount - 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(height: 4)
                    Capsule()
                        .fill(Color.dinkrGreen)
                        .frame(width: geo.size.width * progress, height: 4)
                        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: progress)
                }
            }
            .frame(height: 4)
        }
        .background(Color.clear)
    }
}

// MARK: - Shared nav helpers

private func skipButton(currentPage: Binding<Int>, target: Int) -> some View {
    Button("Skip") {
        withAnimation(.easeInOut(duration: 0.35)) { currentPage.wrappedValue = target }
    }
    .font(.subheadline.weight(.medium))
    .foregroundStyle(.secondary)
    .padding(.horizontal, 20)
    .padding(.vertical, 10)
    .background(.ultraThinMaterial, in: Capsule())
}

private func backButton(currentPage: Binding<Int>) -> some View {
    Button {
        withAnimation(.easeInOut(duration: 0.35)) {
            if currentPage.wrappedValue > 0 { currentPage.wrappedValue -= 1 }
        }
    } label: {
        Image(systemName: "chevron.left")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.primary)
            .padding(10)
            .background(.ultraThinMaterial, in: Circle())
    }
}

// MARK: - Screen 1: Welcome

private struct WelcomeScreen: View {
    let onGetStarted: () -> Void
    let onAlreadyHaveAccount: () -> Void

    @State private var appeared = false
    @State private var glowPulse: CGFloat = 0.55
    @State private var paddleFloat: CGFloat = 0

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.dinkrNavy, Color(red: 0.06, green: 0.14, blue: 0.26)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Animated court lines
            CourtLinePattern()

            // Glow orb behind logo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.dinkrGreen.opacity(glowPulse), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .offset(y: -60)
                .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: glowPulse)

            // Secondary coral glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.dinkrCoral.opacity(0.18), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .offset(x: 80, y: 120)
                .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(1.2), value: glowPulse)

            VStack(spacing: 0) {
                Spacer()

                // Wordmark + tagline block
                VStack(spacing: 18) {
                    DinkrLogoView(size: 96, showWordmark: true, tintColor: .white)
                        .scaleEffect(appeared ? 1.0 : 0.55)
                        .opacity(appeared ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.62).delay(0.1), value: appeared)

                    Text("Your game. Your court. Your crew.")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .opacity(appeared ? 1.0 : 0.0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(.easeOut(duration: 0.5).delay(0.35), value: appeared)
                }

                Spacer()

                // Animated paddle illustration
                Image(systemName: "figure.pickleball")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.dinkrGreen)
                    .shadow(color: Color.dinkrGreen.opacity(0.55), radius: 24, x: 0, y: 8)
                    .offset(y: paddleFloat)
                    .opacity(appeared ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: appeared)
                    .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: paddleFloat)

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
                            .shadow(color: Color.dinkrGreen.opacity(0.45), radius: 14, x: 0, y: 6)
                    }
                    .buttonStyle(ScalePressButtonStyle())

                    Button(action: onAlreadyHaveAccount) {
                        Text("I already have an account")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 64)
                .opacity(appeared ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.5).delay(0.6), value: appeared)
            }
        }
        .onAppear {
            appeared = true
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true).delay(0.6)) {
                glowPulse = 0.28
            }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true).delay(0.8)) {
                paddleFloat = -14
            }
        }
    }
}

// MARK: - Screen 2: Skill Setup

private struct SkillSetupScreen: View {
    @Binding var selectedSkill: SkillLevel
    @Binding var currentPage: Int
    let onNext: () -> Void

    @State private var showDuprTooltip = false
    @State private var appeared = false

    private let skillDescriptions: [SkillLevel: (desc: String, detail: String)] = [
        .beginner20:     ("Just learning", "Still figuring out the rules and basic strokes"),
        .beginner25:     ("Getting comfortable", "Can rally consistently and serve reliably"),
        .intermediate30: ("Solid basics", "Understands strategy, working on consistency"),
        .intermediate35: ("Improving rapidly", "Strong dinks, competitive in recreational play"),
        .advanced40:     ("Strong all-around", "Competitive in rated play, consistent placement"),
        .advanced45:     ("Tournament player", "Plays tournaments, advanced spin and reset game"),
        .pro50:          ("Pro / Elite", "National-level play and beyond")
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top nav bar
                HStack {
                    backButton(currentPage: $currentPage)
                    Spacer()
                    skipButton(currentPage: $currentPage, target: 2)
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 8)

                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's your skill level?")
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(Color.dinkrNavy)

                    HStack(spacing: 6) {
                        Text("We'll match you with the right games")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                showDuprTooltip.toggle()
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "info.circle")
                                Text("DUPR")
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrSky)
                        }
                        .buttonStyle(.plain)
                    }

                    if showDuprTooltip {
                        DuprTooltipCard()
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(Array(SkillLevel.allCases.enumerated()), id: \.element) { index, level in
                            SkillLevelCard(
                                level: level,
                                description: skillDescriptions[level]?.desc ?? "",
                                detail: skillDescriptions[level]?.detail ?? "",
                                isSelected: selectedSkill == level
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                    selectedSkill = level
                                }
                            }
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                            .animation(
                                .spring(response: 0.45, dampingFraction: 0.72)
                                    .delay(Double(index) * 0.05),
                                value: appeared
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 110)
                }
            }

            // Floating next button
            VStack {
                Spacer()
                Button(action: onNext) {
                    Text("Continue")
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
        .onAppear {
            withAnimation { appeared = true }
        }
    }
}

private struct DuprTooltipCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(Color.dinkrSky)
                Text("What is DUPR?")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.dinkrNavy)
            }
            Text("DUPR (Dynamic Universal Pickleball Rating) is a globally recognized rating system from 2.0 (beginner) to 8.0 (pro). Your score updates after every rated match.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color.dinkrSky.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.dinkrSky.opacity(0.3), lineWidth: 1)
        )
    }
}

private struct SkillLevelCard: View {
    let level: SkillLevel
    let description: String
    let detail: String
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

    private var levelIcon: String {
        switch level {
        case .beginner20:     return "figure.walk"
        case .beginner25:     return "figure.run"
        case .intermediate30: return "figure.pickleball"
        case .intermediate35: return "figure.pickleball"
        case .advanced40:     return "flame"
        case .advanced45:     return "flame.fill"
        case .pro50:          return "trophy.fill"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon badge
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? levelColor : levelColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: levelIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : levelColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(level.label)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.primary)
                        Text(description)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.dinkrGreen)
                        .font(.title3)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.dinkrGreen.opacity(0.07) : Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.dinkrGreen : Color.clear, lineWidth: 2)
                    )
            )
            .shadow(color: isSelected ? Color.dinkrGreen.opacity(0.12) : .clear, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
    }
}

// MARK: - Screen 3: Play Style

private struct PlayStyleScreen: View {
    @Binding var selectedStyles: Set<PlayStyle>
    @Binding var currentPage: Int
    let onNext: () -> Void

    @State private var appeared = false

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
                // Top nav
                HStack {
                    backButton(currentPage: $currentPage)
                    Spacer()
                    skipButton(currentPage: $currentPage, target: 3)
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 8)

                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("How do you like to play?")
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(Color.dinkrNavy)
                    Text("Pick all that apply")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(Array(PlayStyle.allCases.enumerated()), id: \.element) { index, style in
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
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 22)
                            .animation(
                                .spring(response: 0.45, dampingFraction: 0.72)
                                    .delay(Double(index) * 0.06),
                                value: appeared
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 110)
                }
            }

            VStack {
                Spacer()
                Button(action: onNext) {
                    HStack {
                        Text(selectedStyles.isEmpty ? "Skip for now" : "Continue")
                        if !selectedStyles.isEmpty {
                            Image(systemName: "arrow.right")
                        }
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(selectedStyles.isEmpty ? Color.dinkrNavy.opacity(0.6) : Color.dinkrGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: selectedStyles.isEmpty ? .clear : Color.dinkrGreen.opacity(0.35), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(ScalePressButtonStyle())
                .animation(.easeInOut(duration: 0.2), value: selectedStyles.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            withAnimation { appeared = true }
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

    // SF Symbol illustration composition per style
    @ViewBuilder
    private var illustration: some View {
        ZStack {
            Circle()
                .fill(isSelected ? styleColor.opacity(0.25) : styleColor.opacity(0.1))
                .frame(width: 56, height: 56)

            Image(systemName: style.icon)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(isSelected ? styleColor : styleColor.opacity(0.8))

            // Accent dot
            Circle()
                .fill(isSelected ? Color.white.opacity(0.9) : styleColor.opacity(0.4))
                .frame(width: 8, height: 8)
                .offset(x: 18, y: -18)
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                illustration

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
            .frame(maxWidth: .infinity, minHeight: 140)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? styleColor : Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isSelected ? styleColor : Color.clear, lineWidth: 2)
                    )
            )
            .shadow(color: isSelected ? styleColor.opacity(0.32) : Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
    }
}

// MARK: - Screen 4: Find Courts (mock map + stagger pins)

private let mockNearbyCourts: [(name: String, distance: String, courts: Int)] = [
    ("Bartholomew District Park", "0.4 mi", 6),
    ("Austin High School Courts", "1.1 mi", 4),
    ("Disch-Falk Field Complex", "2.3 mi", 8)
]

private struct FindCourtsScreen: View {
    @Binding var locationGranted: Bool
    @Binding var currentPage: Int
    let onNext: () -> Void

    @State private var pinsVisible: [Bool] = [false, false, false]
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top nav
                HStack {
                    backButton(currentPage: $currentPage)
                    Spacer()
                    skipButton(currentPage: $currentPage, target: 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 8)

                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Courts near you")
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(Color.dinkrNavy)
                    Text("Find pickup games at courts in your area")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Mock map card
                        MockMapView(locationGranted: locationGranted, pinsVisible: pinsVisible)
                            .frame(height: 190)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)

                        // Location permission card
                        if !locationGranted {
                            VStack(spacing: 14) {
                                Image(systemName: "location.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(Color.dinkrSky)

                                VStack(spacing: 4) {
                                    Text("Enable location")
                                        .font(.headline.weight(.semibold))
                                    Text("See courts and games near you in real time")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }

                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        locationGranted = true
                                    }
                                    animatePins()
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
                            .padding(20)
                            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Stagger-animated court rows
                        if locationGranted {
                            VStack(spacing: 10) {
                                ForEach(Array(mockNearbyCourts.enumerated()), id: \.element.name) { index, court in
                                    NearbyCourtRow(
                                        name: court.name,
                                        distance: court.distance,
                                        courtCount: court.courts
                                    )
                                    .opacity(pinsVisible.indices.contains(index) && pinsVisible[index] ? 1 : 0)
                                    .offset(y: pinsVisible.indices.contains(index) && pinsVisible[index] ? 0 : 16)
                                    .animation(
                                        .spring(response: 0.45, dampingFraction: 0.72)
                                            .delay(Double(index) * 0.14),
                                        value: pinsVisible
                                    )
                                }
                            }
                            .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 110)
                }
            }

            VStack {
                Spacer()
                Button(action: onNext) {
                    Text("Continue")
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
        .onAppear {
            appeared = true
            if locationGranted { animatePins() }
        }
    }

    private func animatePins() {
        for i in 0..<pinsVisible.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.22 + 0.3) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.68)) {
                    pinsVisible[i] = true
                }
            }
        }
    }
}

// MARK: - Mock Map View

private struct MockMapView: View {
    let locationGranted: Bool
    let pinsVisible: [Bool]

    private let pinPositions: [(CGFloat, CGFloat)] = [
        (0.35, 0.42),
        (0.58, 0.55),
        (0.20, 0.68)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Map base (simulated tile grid)
                Color(red: 0.90, green: 0.93, blue: 0.89)

                // Road lines
                Canvas { ctx, size in
                    var hPath = Path()
                    hPath.move(to: CGPoint(x: 0, y: size.height * 0.35))
                    hPath.addLine(to: CGPoint(x: size.width, y: size.height * 0.35))
                    hPath.move(to: CGPoint(x: 0, y: size.height * 0.65))
                    hPath.addLine(to: CGPoint(x: size.width, y: size.height * 0.65))
                    ctx.stroke(hPath, with: .color(.white), lineWidth: 5)

                    var vPath = Path()
                    vPath.move(to: CGPoint(x: size.width * 0.38, y: 0))
                    vPath.addLine(to: CGPoint(x: size.width * 0.38, y: size.height))
                    vPath.move(to: CGPoint(x: size.width * 0.70, y: 0))
                    vPath.addLine(to: CGPoint(x: size.width * 0.70, y: size.height))
                    ctx.stroke(vPath, with: .color(.white), lineWidth: 4)
                }

                // Green blocks (parks)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.dinkrGreen.opacity(0.25))
                    .frame(width: geo.size.width * 0.18, height: geo.size.height * 0.22)
                    .position(x: geo.size.width * 0.18, y: geo.size.height * 0.28)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.dinkrGreen.opacity(0.2))
                    .frame(width: geo.size.width * 0.14, height: geo.size.height * 0.18)
                    .position(x: geo.size.width * 0.75, y: geo.size.height * 0.72)

                // Location dot (user) — center
                if locationGranted {
                    ZStack {
                        Circle()
                            .fill(Color.dinkrSky.opacity(0.22))
                            .frame(width: 36, height: 36)
                        Circle()
                            .fill(Color.dinkrSky)
                            .frame(width: 12, height: 12)
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 12, height: 12)
                    }
                    .position(x: geo.size.width * 0.50, y: geo.size.height * 0.50)
                }

                // Court pins with stagger
                ForEach(Array(pinPositions.enumerated()), id: \.offset) { index, pos in
                    OnboardingCourtMapPin(label: "\(mockNearbyCourts[index].courts)")
                        .position(
                            x: geo.size.width * pos.0,
                            y: geo.size.height * pos.1
                        )
                        .scaleEffect(pinsVisible.indices.contains(index) && pinsVisible[index] ? 1.0 : 0.01)
                        .opacity(pinsVisible.indices.contains(index) && pinsVisible[index] ? 1 : 0)

                }

                // Blur overlay if not granted
                if !locationGranted {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                    VStack(spacing: 6) {
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.dinkrNavy.opacity(0.5))
                        Text("Enable location to see courts")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.dinkrNavy.opacity(0.6))
                    }
                }
            }
        }
    }
}

private struct OnboardingCourtMapPin: View {
    let label: String

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.dinkrCoral)
                    .frame(width: 28, height: 28)
                    .shadow(color: Color.dinkrCoral.opacity(0.5), radius: 4, x: 0, y: 2)
                Image(systemName: "figure.pickleball")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
            Triangle()
                .fill(Color.dinkrCoral)
                .frame(width: 8, height: 5)
        }
    }
}

private struct OnboardingTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

private struct NearbyCourtRow: View {
    let name: String
    let distance: String
    let courtCount: Int

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.dinkrCoral.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.dinkrCoral)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
                Text("\(courtCount) courts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(distance)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.dinkrGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.dinkrGreen.opacity(0.12), in: Capsule())
        }
        .padding(14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Screen 5: All Set (confetti + profile preview)

private struct AllSetScreen: View {
    let selectedSkill: SkillLevel
    let selectedStyles: Set<PlayStyle>
    let onComplete: () -> Void

    @State private var burst = false
    @State private var confettiPieces: [OnboardingConfettiPiece] = []

    private let confettiColors: [Color] = [
        Color.dinkrGreen, Color.dinkrCoral, Color.dinkrAmber, Color.dinkrSky, Color.dinkrNavy
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            // Confetti particles
            ForEach(confettiPieces) { piece in
                OnboardingConfettiParticle(piece: piece)
            }

            VStack(spacing: 0) {
                Spacer()

                // Trophy + burst orb
                ZStack {
                    // Glow orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.dinkrAmber.opacity(burst ? 0.35 : 0), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: burst)

                    // Burst ring dots
                    ForEach(0..<8) { i in
                        let angle = Double(i) / 8.0 * 360.0
                        let radians = angle * .pi / 180
                        let distance: CGFloat = burst ? 90 : 0

                        Circle()
                            .fill(confettiColors[i % confettiColors.count])
                            .frame(width: burst ? 10 : 4, height: burst ? 10 : 4)
                            .offset(
                                x: cos(radians) * distance,
                                y: sin(radians) * distance
                            )
                            .opacity(burst ? 1.0 : 0.0)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.58)
                                    .delay(Double(i) * 0.04),
                                value: burst
                            )
                    }

                    // Trophy
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.dinkrAmber, Color.dinkrCoral],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.dinkrAmber.opacity(0.5), radius: 20, x: 0, y: 8)
                        .scaleEffect(burst ? 1.0 : 0.3)
                        .animation(.spring(response: 0.55, dampingFraction: 0.6).delay(0.12), value: burst)
                }
                .frame(width: 240, height: 240)

                // Headline
                VStack(spacing: 6) {
                    Text("Welcome to Dinkr!")
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(Color.dinkrNavy)
                        .multilineTextAlignment(.center)
                        .scaleEffect(burst ? 1.0 : 0.8)
                        .opacity(burst ? 1.0 : 0.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.22), value: burst)

                    Text("You're all set to find your first game.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .opacity(burst ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.4).delay(0.35), value: burst)
                }

                // Profile preview card
                ProfilePreviewCard(skill: selectedSkill, styles: selectedStyles)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .opacity(burst ? 1.0 : 0.0)
                    .offset(y: burst ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.45), value: burst)

                Spacer()

                // CTA
                Button(action: onComplete) {
                    HStack(spacing: 8) {
                        Text("Find Your First Game")
                        Image(systemName: "arrow.right")
                    }
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
                .animation(.easeOut(duration: 0.4).delay(0.6), value: burst)
            }
        }
        .onAppear {
            confettiPieces = (0..<40).map { _ in OnboardingConfettiPiece.random(colors: confettiColors) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                burst = true
            }
        }
    }
}

// MARK: - Profile Preview Card

private struct ProfilePreviewCard: View {
    let skill: SkillLevel
    let styles: Set<PlayStyle>

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                // Avatar placeholder
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.dinkrGreen, Color.dinkrSky],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    Text("D")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Dinkr Player")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.dinkrNavy)
                    SkillBadge(level: skill, compact: true)
                }

                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(Color.dinkrGreen)
            }

            if !styles.isEmpty {
                HStack {
                    Text("Play styles:")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(styles), id: \.self) { style in
                            HStack(spacing: 4) {
                                Image(systemName: style.icon)
                                    .font(.system(size: 11))
                                Text(style.rawValue)
                                    .font(.caption.weight(.semibold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.dinkrGreen.opacity(0.12), in: Capsule())
                            .foregroundStyle(Color.dinkrGreen)
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.dinkrGreen.opacity(0.3), lineWidth: 1.5)
        )
        .shadow(color: Color.dinkrGreen.opacity(0.1), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Confetti System

private struct OnboardingConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let x: CGFloat
    let rotation: Double
    let size: CGFloat
    let speed: Double
    let delay: Double
    let isCircle: Bool

    static func random(colors: [Color]) -> OnboardingConfettiPiece {
        OnboardingConfettiPiece(
            color: colors.randomElement() ?? .dinkrGreen,
            x: CGFloat.random(in: 0.05...0.95),
            rotation: Double.random(in: 0...360),
            size: CGFloat.random(in: 6...14),
            speed: Double.random(in: 1.8...3.2),
            delay: Double.random(in: 0...1.2),
            isCircle: Bool.random()
        )
    }
}

private struct OnboardingConfettiParticle: View {
    let piece: OnboardingConfettiPiece
    @State private var animating = false

    var body: some View {
        GeometryReader { geo in
            Group {
                if piece.isCircle {
                    Circle()
                        .fill(piece.color.opacity(0.85))
                        .frame(width: piece.size, height: piece.size)
                } else {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(piece.color.opacity(0.85))
                        .frame(width: piece.size, height: piece.size * 0.5)
                        .rotationEffect(.degrees(piece.rotation))
                }
            }
            .position(
                x: geo.size.width * piece.x,
                y: animating ? geo.size.height + 20 : -20
            )
            .opacity(animating ? 0 : 1)
        }
        .onAppear {
            withAnimation(
                .easeIn(duration: piece.speed)
                .delay(piece.delay)
            ) {
                animating = true
            }
        }
        .allowsHitTesting(false)
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

    let horizontals: [CGFloat] = [0.18, 0.38, 0.62, 0.82]
    for ratio in horizontals {
        let y = h * ratio
        let endX = margin + (w - margin * 2) * progress
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: endX, y: y))
    }

    let topY = h * 0.18
    let botY = h * 0.82
    let sideEndY = topY + (botY - topY) * progress
    path.move(to: CGPoint(x: margin, y: topY))
    path.addLine(to: CGPoint(x: margin, y: sideEndY))
    path.move(to: CGPoint(x: w - margin, y: topY))
    path.addLine(to: CGPoint(x: w - margin, y: sideEndY))

    path.move(to: CGPoint(x: w / 2, y: topY))
    path.addLine(to: CGPoint(x: w / 2, y: sideEndY))

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
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 180, height: 180)

            Circle()
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                .foregroundStyle(Color.white.opacity(0.1))
                .frame(width: 180, height: 180)

            ForEach(0..<4) { i in
                Ellipse()
                    .stroke(Color.white.opacity(0.07), lineWidth: 1.2)
                    .frame(width: 180, height: 60)
                    .rotationEffect(.degrees(Double(i) * 45))
            }

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
            Color.dinkrNavy.ignoresSafeArea()

            CourtLinePattern()

            VStack {
                HStack {
                    Spacer()
                    PickleballIllustration()
                        .offset(x: 60, y: -30)
                }
                Spacer()
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

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

    private var bottomSheet: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
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

                Canvas { ctx, size in
                    let path = fullCourtLinePath(size: size, progress: 1.0)
                    ctx.stroke(path, with: .color(.white.opacity(0.03)), lineWidth: 1.2)
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {

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

                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                forgotEmail = email
                                showForgotAlert = true
                            }
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.dinkrSky)
                        }

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

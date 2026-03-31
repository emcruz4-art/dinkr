import SwiftUI

// MARK: - DUPR Verification Step

private enum DUPRVerificationStep: Int, CaseIterable {
    case intro = 0
    case enterID = 1
    case confirm = 2
    case success = 3
}

// MARK: - Mock DUPR Stats

private struct DUPRStats {
    let rating: Double
    let gamesPlayed: Int
    let playerName: String
    let location: String
}

// MARK: - DUPRVerificationView

struct DUPRVerificationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var step: DUPRVerificationStep = .intro
    @State private var duprPlayerID: String = ""
    @State private var isLoading = false
    @State private var fetchedStats: DUPRStats? = nil
    @State private var showConfettiTrigger = false
    @State private var pulseVerified = false
    @State private var idFieldError: String? = nil

    // Propagated back to caller so ProfileView can reflect verification
    var onVerified: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Step progress indicator
                    StepProgressBar(currentStep: step.rawValue, totalSteps: 4)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 20)

                    // Step content
                    switch step {
                    case .intro:
                        DUPRIntroStep(onNext: advance)
                    case .enterID:
                        DUPREnterIDStep(
                            playerID: $duprPlayerID,
                            fieldError: idFieldError,
                            isLoading: isLoading,
                            onNext: fetchDUPRStats
                        )
                    case .confirm:
                        if let stats = fetchedStats {
                            DUPRConfirmStep(stats: stats, onConfirm: advance, onBack: back)
                        }
                    case .success:
                        DUPRSuccessStep(
                            pulseVerified: $pulseVerified,
                            showConfetti: $showConfettiTrigger,
                            onDone: {
                                onVerified?()
                                dismiss()
                            }
                        )
                    }

                    Spacer(minLength: 0)
                }
            }
            .navigationTitle("DUPR Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if step != .success {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(Color.dinkrCoral)
                    }
                }
            }
        }
        .overlay(alignment: .top) {
            if showConfettiTrigger {
                ConfettiOverlay()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Navigation

    private func advance() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
            step = DUPRVerificationStep(rawValue: step.rawValue + 1) ?? .success
        }
        if step == .success {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showConfettiTrigger = true
                pulseVerified = true
            }
        }
    }

    private func back() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
            step = DUPRVerificationStep(rawValue: step.rawValue - 1) ?? .intro
        }
    }

    private func fetchDUPRStats() {
        let trimmed = duprPlayerID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            idFieldError = "Please enter your DUPR Player ID."
            return
        }
        guard trimmed.count >= 4 else {
            idFieldError = "Player ID must be at least 4 characters."
            return
        }
        idFieldError = nil
        isLoading = true
        HapticManager.selection()

        // Simulate network fetch (mock data)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            isLoading = false
            fetchedStats = DUPRStats(
                rating: 3.847,
                gamesPlayed: 47,
                playerName: "Alex Rivera",
                location: "Austin, TX"
            )
            advance()
        }
    }
}

// MARK: - Step Progress Bar

private struct StepProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= currentStep ? Color.dinkrGreen : Color.secondary.opacity(0.22))
                    .frame(height: 4)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
            }
        }
    }
}

// MARK: - Step 1: Intro

private struct DUPRIntroStep: View {
    let onNext: () -> Void
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Hero icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.dinkrAmber.opacity(0.22), Color.dinkrAmber.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 96, height: 96)
                    Circle()
                        .stroke(Color.dinkrAmber.opacity(0.35), lineWidth: 1.5)
                        .frame(width: 96, height: 96)
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(Color.dinkrAmber)
                }
                .scaleEffect(appeared ? 1 : 0.7)
                .opacity(appeared ? 1 : 0)
                .padding(.top, 16)

                VStack(spacing: 10) {
                    Text("Verify Your DUPR Rating")
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)
                    Text("Link your DUPR account to unlock smarter matchmaking, credibility with other players, and an official verified badge on your profile.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                // Benefits list
                VStack(spacing: 0) {
                    BenefitRow(
                        icon: "checkmark.seal.fill",
                        color: Color.dinkrGreen,
                        title: "Verified badge on your profile",
                        subtitle: "Stand out as a credible, verified player"
                    )
                    Divider().padding(.leading, 56)
                    BenefitRow(
                        icon: "person.2.fill",
                        color: Color.dinkrSky,
                        title: "Accurate matchmaking",
                        subtitle: "Get matched with players at your real skill level"
                    )
                    Divider().padding(.leading, 56)
                    BenefitRow(
                        icon: "chart.xyaxis.line",
                        color: Color.dinkrAmber,
                        title: "Live rating sync",
                        subtitle: "Your DUPR updates automatically after each match"
                    )
                    Divider().padding(.leading, 56)
                    BenefitRow(
                        icon: "crown.fill",
                        color: Color.dinkrCoral,
                        title: "Leaderboard eligibility",
                        subtitle: "Compete on verified regional leaderboards"
                    )
                }
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.secondary.opacity(0.12), lineWidth: 1))
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)

                Button {
                    HapticManager.selection()
                    onNext()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                }
                .padding(.bottom, 8)
                .opacity(appeared ? 1 : 0)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.1)) {
                appeared = true
            }
        }
    }
}

private struct BenefitRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Step 2: Enter DUPR ID

private struct DUPREnterIDStep: View {
    @Binding var playerID: String
    let fieldError: String?
    let isLoading: Bool
    let onNext: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.dinkrSky)
                        .padding(.top, 16)

                    Text("Enter Your DUPR Player ID")
                        .font(.title3.weight(.bold))
                        .multilineTextAlignment(.center)

                    Text("Find your DUPR Player ID in your DUPR profile under Account Settings. It looks like: DPR-123456")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("DUPR Player ID")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.4)

                    HStack(spacing: 12) {
                        Image(systemName: "person.badge.key.fill")
                            .foregroundStyle(Color.dinkrAmber)
                            .font(.body)

                        TextField("e.g. DPR-123456", text: $playerID)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .keyboardType(.asciiCapable)
                            .focused($isFocused)
                            .font(.body.weight(.medium))
                            .submitLabel(.search)
                            .onSubmit { onNext() }
                    }
                    .padding(14)
                    .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                fieldError != nil ? Color.dinkrCoral
                                    : isFocused ? Color.dinkrGreen
                                    : Color.secondary.opacity(0.2),
                                lineWidth: fieldError != nil ? 1.5 : 1
                            )
                    )

                    if let error = fieldError {
                        HStack(spacing: 5) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                            Text(error)
                                .font(.caption)
                        }
                        .foregroundStyle(Color.dinkrCoral)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }

                // DUPR info callout
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Color.dinkrSky)
                        .font(.callout)
                        .padding(.top, 1)
                    Text("Your DUPR ID is only used to verify your rating. Dinkr does not store your DUPR password or personal information.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(Color.dinkrSky.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.dinkrSky.opacity(0.25), lineWidth: 1))

                Button {
                    isFocused = false
                    onNext()
                } label: {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.85)
                        } else {
                            Text("Look Up My Rating")
                                .font(.headline)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        isLoading
                            ? AnyShapeStyle(Color.dinkrGreen.opacity(0.6))
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            ),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                }
                .disabled(isLoading)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: fieldError)
        }
        .onAppear { isFocused = true }
    }
}

// MARK: - Step 3: Confirm Stats

private struct DUPRConfirmStep: View {
    let stats: DUPRStats
    let onConfirm: () -> Void
    let onBack: () -> Void
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.dinkrGreen)
                        .padding(.top, 16)
                        .scaleEffect(appeared ? 1 : 0.6)
                        .opacity(appeared ? 1 : 0)

                    Text("We Found Your DUPR")
                        .font(.title3.weight(.bold))

                    Text("Does this look right?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Stats card
                VStack(spacing: 0) {
                    StatConfirmRow(
                        label: "Player Name",
                        value: stats.playerName,
                        icon: "person.fill",
                        color: Color.dinkrNavy
                    )
                    Divider().padding(.leading, 54)
                    StatConfirmRow(
                        label: "DUPR Rating",
                        value: String(format: "%.3f", stats.rating),
                        icon: "chart.bar.fill",
                        color: Color.dinkrAmber,
                        valueWeight: .heavy
                    )
                    Divider().padding(.leading, 54)
                    StatConfirmRow(
                        label: "Games Played",
                        value: "\(stats.gamesPlayed) games",
                        icon: "figure.pickleball",
                        color: Color.dinkrGreen
                    )
                    Divider().padding(.leading, 54)
                    StatConfirmRow(
                        label: "Location",
                        value: stats.location,
                        icon: "mappin.circle.fill",
                        color: Color.dinkrSky
                    )
                }
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.dinkrAmber.opacity(0.22), lineWidth: 1))
                .shadow(color: Color.dinkrAmber.opacity(0.08), radius: 10, x: 0, y: 4)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)

                VStack(spacing: 12) {
                    Button {
                        HapticManager.selection()
                        onConfirm()
                    } label: {
                        Text("Yes, That's Me!")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                    }

                    Button {
                        HapticManager.selection()
                        onBack()
                    } label: {
                        Text("Not Me — Try Again")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrCoral)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.dinkrCoral.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.dinkrCoral.opacity(0.3), lineWidth: 1))
                    }
                }
                .padding(.bottom, 8)
                .opacity(appeared ? 1 : 0)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.76).delay(0.1)) {
                appeared = true
            }
        }
    }
}

private struct StatConfirmRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    var valueWeight: Font.Weight = .semibold

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(valueWeight))
                    .foregroundStyle(Color.primary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Step 4: Success

private struct DUPRSuccessStep: View {
    @Binding var pulseVerified: Bool
    @Binding var showConfetti: Bool
    let onDone: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated verified badge
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(Color.dinkrGreen.opacity(pulseVerified ? 0.18 : 0.05))
                    .frame(width: 148, height: 148)
                    .blur(radius: 12)
                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulseVerified)

                // Middle ring
                Circle()
                    .stroke(Color.dinkrGreen.opacity(0.35), lineWidth: 2)
                    .frame(width: 116, height: 116)

                // Badge circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.dinkrGreen.opacity(0.22), Color.dinkrGreen.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(Color.dinkrGreen)
            }
            .scaleEffect(appeared ? 1 : 0.5)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 12) {
                Text("Your DUPR is now verified ✅")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)

                Text("Your verified DUPR badge is now live on your profile. Other players can see your rating is officially confirmed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)

            // Stat chips
            HStack(spacing: 12) {
                SuccessStatChip(value: "3.847", label: "Rating", color: Color.dinkrAmber)
                SuccessStatChip(value: "47", label: "Games", color: Color.dinkrSky)
                SuccessStatChip(value: "Verified", label: "Status", color: Color.dinkrGreen)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)

            Spacer()

            Button {
                HapticManager.selection()
                onDone()
            } label: {
                Text("Back to Profile")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.15)) {
                appeared = true
            }
        }
    }
}

private struct SuccessStatChip: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.heavy))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - Confetti Overlay

private struct ConfettiOverlay: View {
    @State private var particles: [ConfettiParticle] = []

    struct ConfettiParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var color: Color
        var rotation: Double
        var scale: CGFloat
        var opacity: Double
    }

    private let colors: [Color] = [
        Color.dinkrGreen, Color.dinkrAmber, Color.dinkrSky, Color.dinkrCoral, Color.dinkrNavy, .white
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(p.color)
                        .frame(width: 8, height: 14)
                        .scaleEffect(p.scale)
                        .rotationEffect(.degrees(p.rotation))
                        .opacity(p.opacity)
                        .position(x: p.x, y: p.y)
                }
            }
            .onAppear {
                spawnParticles(in: geo.size)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }

    private func spawnParticles(in size: CGSize) {
        particles = (0..<60).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: -20...size.height * 0.3),
                color: colors.randomElement() ?? Color.dinkrGreen,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.3),
                opacity: Double.random(in: 0.7...1.0)
            )
        }

        withAnimation(.easeIn(duration: 2.2)) {
            for i in particles.indices {
                particles[i].y += CGFloat.random(in: size.height * 0.5...size.height * 1.2)
                particles[i].rotation += Double.random(in: 120...480)
                particles[i].opacity = 0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DUPRVerificationView()
}

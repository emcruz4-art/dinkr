import SwiftUI

// MARK: - Feature Item Model

private struct NewFeature: Identifiable {
    let id = UUID()
    let emoji: String
    let iconColor: Color
    let title: String
    let subtitle: String
}

private let currentAppVersion = "1.1"

private let newFeatures: [NewFeature] = [
    NewFeature(
        emoji: "🔴",
        iconColor: Color.dinkrCoral,
        title: "Live Scores",
        subtitle: "Track real-time game scores as they happen on court"
    ),
    NewFeature(
        emoji: "🃏",
        iconColor: Color.dinkrSky,
        title: "Swipe to Discover",
        subtitle: "Find open games Tinder-style — swipe right to join"
    ),
    NewFeature(
        emoji: "📊",
        iconColor: Color.dinkrGreen,
        title: "Weekly Recap",
        subtitle: "Your wins, DUPR trend, and top moments every week"
    ),
    NewFeature(
        emoji: "🏆",
        iconColor: Color.dinkrAmber,
        title: "Team Challenges",
        subtitle: "Company vs company — compete with your whole crew"
    ),
    NewFeature(
        emoji: "📚",
        iconColor: Color.dinkrNavy,
        title: "Practice Library",
        subtitle: "50+ drills and training plans to level up your game"
    ),
]

// MARK: - WhatIsNewView

struct WhatIsNewView: View {
    @AppStorage("lastSeenVersion") private var lastSeenVersion: String = ""
    @Environment(\.dismiss) private var dismiss

    @State private var appearedIndices: Set<Int> = []
    @State private var headerAppeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // MARK: Header
                headerSection
                    .padding(.top, 44)
                    .padding(.bottom, 32)

                // MARK: Feature Cards
                featuresSection
                    .padding(.horizontal, 20)

                // MARK: CTA
                continueButton
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 52)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                headerAppeared = true
            }
            for i in 0..<newFeatures.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + Double(i) * 0.1) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                        _ = appearedIndices.insert(i)
                    }
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 18) {
            // Logo with glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.dinkrGreen.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                DinkrLogoView(size: 72, showWordmark: false, tintColor: Color.dinkrGreen)
            }
            .scaleEffect(headerAppeared ? 1.0 : 0.6)
            .opacity(headerAppeared ? 1 : 0)

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text("What's New in Dinkr \(currentAppVersion)")
                        .font(.title2.weight(.black))
                        .foregroundStyle(Color.dinkrNavy)
                    Text("🎉")
                        .font(.title2)
                }
                .multilineTextAlignment(.center)

                Text("Five features that change the game")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .opacity(headerAppeared ? 1 : 0)
            .offset(y: headerAppeared ? 0 : 10)
            .animation(.easeOut(duration: 0.4).delay(0.2), value: headerAppeared)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Feature Cards

    private var featuresSection: some View {
        VStack(spacing: 12) {
            ForEach(Array(newFeatures.enumerated()), id: \.element.id) { index, feature in
                FeatureCard(feature: feature)
                    .opacity(appearedIndices.contains(index) ? 1 : 0)
                    .offset(y: appearedIndices.contains(index) ? 0 : 20)
            }
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            lastSeenVersion = currentAppVersion
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Text("Continue")
                    .font(.headline.weight(.bold))
                Image(systemName: "arrow.right")
                    .font(.headline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.dinkrGreen.opacity(0.38), radius: 12, x: 0, y: 5)
        }
        .buttonStyle(ScalePressButtonStyle())
    }
}

// MARK: - Feature Card

private struct FeatureCard: View {
    let feature: NewFeature

    var body: some View {
        HStack(spacing: 16) {
            // Emoji badge
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(feature.iconColor.opacity(0.12))
                    .frame(width: 54, height: 54)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(feature.iconColor.opacity(0.2), lineWidth: 1)
                    )
                Text(feature.emoji)
                    .font(.system(size: 26))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.dinkrNavy)
                Text(feature.subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(feature.iconColor)
                .opacity(0.7)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Auto-Show Modifier

extension View {
    /// Presents WhatIsNewView as a sheet if the current version hasn't been seen yet.
    func whatIsNewSheet() -> some View {
        modifier(WhatIsNewSheetModifier())
    }
}

private struct WhatIsNewSheetModifier: ViewModifier {
    @AppStorage("lastSeenVersion") private var lastSeenVersion: String = ""
    @State private var showSheet = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                if lastSeenVersion != currentAppVersion {
                    // Small delay so the tab view settles first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        showSheet = true
                    }
                }
            }
            .sheet(isPresented: $showSheet) {
                WhatIsNewView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
    }
}

// MARK: - Preview

#Preview {
    WhatIsNewView()
}

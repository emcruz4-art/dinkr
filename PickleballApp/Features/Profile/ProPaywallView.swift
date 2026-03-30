import SwiftUI
import StoreKit

// MARK: - ProPaywallView

struct ProPaywallView: View {
    @Environment(StoreService.self) private var storeService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProductID: String = StoreService.ProductID.yearlyPro
    @State private var crownRotation: Double = 0
    @State private var isPurchasing: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    private let features: [(icon: String, text: String)] = [
        ("checkmark.circle.fill", "Unlimited player connections"),
        ("checkmark.circle.fill", "Advanced match analytics"),
        ("checkmark.circle.fill", "Court booking priority"),
        ("checkmark.circle.fill", "Ad-free experience"),
        ("checkmark.circle.fill", "Exclusive Pro badge on profile"),
        ("checkmark.circle.fill", "Early access to new features"),
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.dinkrNavy, Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Dismiss handle
                    dismissHandle

                    // Crown + title block
                    headerBlock
                        .padding(.top, 8)

                    // Feature list
                    featureList
                        .padding(.top, 28)

                    // Product cards
                    productCards
                        .padding(.top, 24)

                    // CTA button
                    ctaButton
                        .padding(.top, 24)

                    // Restore + fine print
                    footerBlock
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            startCrownAnimation()
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Subviews

    private var dismissHandle: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.white.opacity(0.3))
            .frame(width: 36, height: 4)
            .padding(.top, 12)
    }

    private var headerBlock: some View {
        VStack(spacing: 12) {
            // Animated crown
            Text("👑")
                .font(.system(size: 64))
                .rotationEffect(.degrees(crownRotation))
                .shadow(color: Color.dinkrAmber.opacity(0.8), radius: 20, x: 0, y: 0)
                .shadow(color: Color.dinkrAmber.opacity(0.4), radius: 40, x: 0, y: 0)
                .animation(
                    .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                    value: crownRotation
                )

            Text("Dinkr Pro")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.dinkrAmber, Color.dinkrAmber.opacity(0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text("Play smarter. Connect deeper.")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.75))
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(features, id: \.text) { feature in
                HStack(spacing: 12) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.dinkrAmber)
                    Text(feature.text)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.92))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var productCards: some View {
        VStack(spacing: 12) {
            // Monthly card
            productCard(
                id: StoreService.ProductID.monthlyPro,
                title: "Monthly",
                price: "$4.99/month",
                badge: nil
            )

            // Yearly card — selected by default
            productCard(
                id: StoreService.ProductID.yearlyPro,
                title: "Yearly",
                price: "$39.99/year",
                badge: "Save 33% 🔥"
            )
        }
    }

    private func productCard(
        id: String,
        title: String,
        price: String,
        badge: String?
    ) -> some View {
        let isSelected = selectedProductID == id

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedProductID = id
            }
        } label: {
            HStack(spacing: 14) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? Color.dinkrAmber : Color.white.opacity(0.3),
                            lineWidth: isSelected ? 2.5 : 1.5
                        )
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Color.dinkrAmber)
                            .frame(width: 12, height: 12)
                    }
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                    Text(price)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.65))
                }

                Spacer()

                // Badge
                if let badge {
                    Text(badge)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(Color.dinkrCoral)
                        )
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.dinkrAmber.opacity(0.12) : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected ? Color.dinkrAmber : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    private var ctaButton: some View {
        Button {
            Task { await handlePurchase() }
        } label: {
            HStack(spacing: 8) {
                if isPurchasing || storeService.isLoading {
                    ProgressView()
                        .tint(Color.dinkrNavy)
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .bold))
                    Text("Start 7-Day Free Trial")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
            }
            .foregroundStyle(Color.dinkrNavy)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [Color.dinkrAmber, Color.dinkrAmber.opacity(0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            )
            .shadow(color: Color.dinkrAmber.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .disabled(isPurchasing || storeService.isLoading)
    }

    private var footerBlock: some View {
        VStack(spacing: 12) {
            Button {
                Task { await storeService.restorePurchases() }
            } label: {
                Text("Restore Purchases")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .underline()
            }

            Text("Cancel anytime. Auto-renews until cancelled.")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.35))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Actions

    private func handlePurchase() async {
        // If real products are loaded, use them; otherwise show no-op in dev
        if let product = storeService.products.first(where: { $0.id == selectedProductID }) {
            isPurchasing = true
            defer { isPurchasing = false }
            do {
                let success = try await storeService.purchase(product)
                if success { dismiss() }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        } else {
            // Dev build: no App Store products — toggle debug flag and dismiss
            #if DEBUG
            storeService.debugIsPro = true
            dismiss()
            #else
            errorMessage = "Products unavailable. Please try again later."
            showError = true
            #endif
        }
    }

    private func startCrownAnimation() {
        crownRotation = -8
    }
}

// MARK: - ProBadgeView

struct ProBadgeView: View {
    var body: some View {
        HStack(spacing: 4) {
            Text("👑")
                .font(.system(size: 11))
            Text("PRO")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(Color.dinkrNavy)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.dinkrAmber)
                .shadow(color: Color.dinkrAmber.opacity(0.5), radius: 6, x: 0, y: 2)
        )
    }
}

// MARK: - ProGateView

struct ProGateView<Content: View>: View {
    @Environment(StoreService.self) private var storeService
    @Environment(\.dismiss) private var dismiss

    let feature: String
    let content: Content

    @State private var showPaywall: Bool = false

    init(feature: String, @ViewBuilder content: () -> Content) {
        self.feature = feature
        self.content = content()
    }

    var body: some View {
        ZStack {
            if storeService.isPro {
                content
            } else {
                lockedOverlay
            }
        }
        .sheet(isPresented: $showPaywall) {
            ProPaywallView()
                .environment(storeService)
        }
    }

    private var lockedOverlay: some View {
        ZStack {
            // Blurred content hint
            content
                .blur(radius: 12)
                .allowsHitTesting(false)

            // Lock card
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.dinkrAmber.opacity(0.15))
                        .frame(width: 64, height: 64)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Color.dinkrAmber)
                }

                VStack(spacing: 6) {
                    Text(feature)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.dinkrNavy)
                        .multilineTextAlignment(.center)
                    Text("This feature is available with\nDinkr Pro")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.dinkrNavy.opacity(0.6))
                        .multilineTextAlignment(.center)
                }

                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 6) {
                        Text("👑")
                            .font(.system(size: 14))
                        Text("Upgrade to Pro")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Color.dinkrNavy)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(
                        Capsule()
                            .fill(Color.dinkrAmber)
                            .shadow(color: Color.dinkrAmber.opacity(0.4), radius: 8, x: 0, y: 4)
                    )
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
            )
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Preview

#Preview("ProPaywallView") {
    ProPaywallView()
        .environment(StoreService.shared)
}

#Preview("ProBadgeView") {
    ProBadgeView()
        .padding()
        .background(Color.dinkrNavy)
}

#Preview("ProGateView — Locked") {
    ProGateView(feature: "Advanced Analytics") {
        Text("Secret analytics content here")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.cardBackground)
    }
    .environment(StoreService.shared)
}

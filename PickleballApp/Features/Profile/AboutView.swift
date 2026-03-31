import SwiftUI

// MARK: - AboutView

struct AboutView: View {
    @State private var showSocialComingSoon = false
    @State private var showFeedbackAlert = false
    @State private var socialAlertTitle = ""

    var body: some View {
        ZStack(alignment: .top) {
            // dinkrNavy gradient header
            navyGradientHeader

            ScrollView {
                VStack(spacing: 0) {
                    // Header spacer
                    Color.clear.frame(height: 180)

                    // Main content card area
                    VStack(spacing: 20) {
                        taglineSection
                        legalLinksSection
                        acknowledgmentsSection
                        socialLinksSection
                        appStoreSection
                        feedbackSection
                        versionFooter
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 48)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationTitle("About Dinkr")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .alert(socialAlertTitle, isPresented: $showSocialComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This feature is coming soon. Stay tuned!")
        }
        .alert("Send Feedback", isPresented: $showFeedbackAlert) {
            Button("Open Mail App") {
                if let url = URL(string: "mailto:feedback@dinkr.app?subject=Dinkr%20Feedback") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your feedback helps us build a better pickleball community. Tap below to open Mail.")
        }
    }

    // MARK: - Navy Gradient Header

    private var navyGradientHeader: some View {
        ZStack(alignment: .center) {
            LinearGradient(
                colors: [Color.dinkrNavy, Color.dinkrNavy.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Subtle court lines
            Canvas { ctx, size in
                for ratio in [0.3, 0.55, 0.75] as [Double] {
                    var path = Path()
                    path.move(to: CGPoint(x: 24, y: size.height * ratio))
                    path.addLine(to: CGPoint(x: size.width - 24, y: size.height * ratio))
                    ctx.stroke(path, with: .color(.white.opacity(0.04)), lineWidth: 1)
                }
                var center = Path()
                center.move(to: CGPoint(x: size.width / 2, y: size.height * 0.3))
                center.addLine(to: CGPoint(x: size.width / 2, y: size.height * 0.75))
                ctx.stroke(center, with: .color(.white.opacity(0.04)), lineWidth: 1)
            }
            .allowsHitTesting(false)

            VStack(spacing: 10) {
                Color.clear.frame(height: 52) // safe area
                DinkrLogoView(size: 52, tintColor: .white)
                Text("Version 1.0.0 (Build 1)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Color.clear.frame(height: 16)
            }
        }
        .frame(height: 180)
        // Soft fade into the page background
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [.clear, Color(UIColor.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)
        }
    }

    // MARK: - Tagline Section

    private var taglineSection: some View {
        HStack(spacing: 10) {
            Text("❤️")
                .font(.title2)
            Text("Made with ")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            + Text("love")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.dinkrCoral)
            + Text(" for the pickleball community")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Legal Links Section

    private var legalLinksSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Legal")

            VStack(spacing: 0) {
                NavigationLink {
                    LegalDocumentView(
                        title: "Privacy Policy",
                        icon: "lock.shield.fill",
                        accentColor: Color.dinkrSky,
                        content: LegalContent.privacyPolicy
                    )
                } label: {
                    AboutRow(icon: "lock.shield.fill", iconColor: Color.dinkrSky, title: "Privacy Policy")
                }

                Divider().padding(.leading, 52)

                NavigationLink {
                    LegalDocumentView(
                        title: "Terms of Service",
                        icon: "doc.text.fill",
                        accentColor: Color.dinkrNavy,
                        content: LegalContent.termsOfService
                    )
                } label: {
                    AboutRow(icon: "doc.text.fill", iconColor: Color.dinkrNavy, title: "Terms of Service")
                }

                Divider().padding(.leading, 52)

                NavigationLink {
                    LegalDocumentView(
                        title: "Open Source Licenses",
                        icon: "scroll.fill",
                        accentColor: Color.dinkrGreen,
                        content: LegalContent.openSourceLicenses
                    )
                } label: {
                    AboutRow(icon: "scroll.fill", iconColor: Color.dinkrGreen, title: "Open Source Licenses")
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Acknowledgments Section

    private var acknowledgmentsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Special Thanks")

            VStack(spacing: 0) {
                ForEach(Array(acknowledgments.enumerated()), id: \.element.name) { idx, person in
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(person.color.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Text(person.emoji)
                                .font(.system(size: 18))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(person.name)
                                .font(.subheadline.weight(.semibold))
                            Text(person.role)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    if idx < acknowledgments.count - 1 {
                        Divider().padding(.leading, 66)
                    }
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private struct Acknowledgment {
        let name: String
        let role: String
        let emoji: String
        let color: Color
    }

    private let acknowledgments: [Acknowledgment] = [
        .init(name: "Jordan \"Dink King\" Mercer",
              role: "Community advisor & beta tester extraordinaire",
              emoji: "🏓",
              color: Color.dinkrGreen),
        .init(name: "Sofia Palencia",
              role: "UX research — courts, players, and chaos",
              emoji: "🎨",
              color: Color.dinkrSky),
        .init(name: "Theo Abramowitz",
              role: "Data science & DUPR algorithm guidance",
              emoji: "📊",
              color: Color.dinkrAmber),
    ]

    // MARK: - Social Links Section

    private var socialLinksSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Find Us Online")

            HStack(spacing: 12) {
                socialButton(icon: "text.bubble.fill", label: "X / Twitter", color: Color.primary) {
                    socialAlertTitle = "Twitter / X"
                    showSocialComingSoon = true
                }
                socialButton(icon: "camera.fill", label: "Instagram", color: Color(red: 0.83, green: 0.19, blue: 0.55)) {
                    socialAlertTitle = "Instagram"
                    showSocialComingSoon = true
                }
                socialButton(icon: "globe", label: "Website", color: Color.dinkrSky) {
                    socialAlertTitle = "dinkr.app"
                    showSocialComingSoon = true
                }
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    @ViewBuilder
    private func socialButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(color)
                }
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - App Store Section

    private var appStoreSection: some View {
        Button {
            if let url = URL(string: "https://apps.apple.com/app/id000000000") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.dinkrAmber.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "star.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.dinkrAmber)
                }
                Text("Rate Dinkr on the App Store")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Feedback Section

    private var feedbackSection: some View {
        Button {
            showFeedbackAlert = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.dinkrGreen.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.dinkrGreen)
                }
                Text("Send Feedback")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Version Footer

    private var versionFooter: some View {
        VStack(spacing: 4) {
            Text("Dinkr · Version 1.0.0 (Build 1)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("© 2025 Dinkr, Inc. All rights reserved.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.leading, 4)
            .padding(.bottom, 8)
    }
}

// MARK: - About Row

private struct AboutRow: View {
    let icon: String
    let iconColor: Color
    let title: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.primary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}

// MARK: - Legal Document View

struct LegalDocumentView: View {
    let title: String
    let icon: String
    let accentColor: Color
    let content: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Icon + title block
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 52, height: 52)
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(accentColor)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.title3.weight(.bold))
                        Text("Last updated: January 2025")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 8)

                Divider()

                Text(content)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Legal Content

private enum LegalContent {
    static let privacyPolicy = """
Dinkr Privacy Policy

Effective Date: January 1, 2025

1. Information We Collect
We collect information you provide when creating an account, including your name, email address, location, and skill level. When you use Dinkr, we also collect usage data such as games played, courts visited, and in-app interactions.

2. How We Use Your Information
Your data helps us match you with nearby players, surface relevant courts and events, and improve the Dinkr experience. We do not sell your personal information to third parties.

3. Location Data
With your permission, Dinkr uses your device location to show nearby games, courts, and players. You may revoke this permission at any time in iOS Settings.

4. Data Sharing
We share only the minimum necessary information with service partners (such as Firebase) to operate the app. All partners are bound by strict data processing agreements.

5. Your Rights
You may request a copy of your data, ask for corrections, or request deletion at any time by contacting privacy@dinkr.app or using the Export Data feature in Settings.

6. Cookies & Analytics
We use anonymized analytics to understand how players use the app. No personally identifiable information is shared with analytics providers.

7. Children
Dinkr is not intended for users under 13 years of age.

8. Changes to This Policy
We may update this policy periodically. We will notify you of significant changes via in-app notice or email.

9. Contact
Questions? Reach us at privacy@dinkr.app
"""

    static let termsOfService = """
Dinkr Terms of Service

Effective Date: January 1, 2025

1. Acceptance
By downloading or using Dinkr, you agree to these Terms of Service. If you do not agree, please do not use the app.

2. Eligibility
You must be at least 13 years old to use Dinkr. By using the app, you confirm you meet this requirement.

3. Your Account
You are responsible for maintaining the security of your account and for all activity under it. Provide accurate information and keep your credentials confidential.

4. Acceptable Use
You agree not to: harass other players, post false information, attempt to access systems without authorization, or use Dinkr for any unlawful purpose.

5. User Content
By posting content on Dinkr, you grant us a non-exclusive, worldwide license to display and distribute that content within the app. You retain ownership of your content.

6. Game & Match Data
Match results and statistics you submit may be displayed publicly on your profile and in leaderboards. Ensure all submitted data is accurate.

7. Marketplace
Transactions in the Dinkr Marketplace are between users. Dinkr is not responsible for disputes arising from user-to-user exchanges.

8. Disclaimers
Dinkr is provided "as is." We make no warranties about uptime, accuracy of court information, or match quality.

9. Limitation of Liability
To the fullest extent permitted by law, Dinkr's liability for any claim is limited to the amount you paid us in the 12 months preceding the claim.

10. Termination
We may suspend or terminate accounts that violate these Terms.

11. Governing Law
These Terms are governed by the laws of the State of California.

12. Contact
Legal questions? Email legal@dinkr.app
"""

    static let openSourceLicenses = """
Open Source Licenses

Dinkr is built with the help of the following open source projects:

─────────────────────────────────

Firebase iOS SDK
Copyright © 2016-2025 Google LLC
Licensed under the Apache License, Version 2.0

You may obtain a copy of the License at:
http://www.apache.org/licenses/LICENSE-2.0

─────────────────────────────────

GoogleSignIn-iOS
Copyright © 2015-2025 Google LLC
Licensed under the Apache License, Version 2.0

─────────────────────────────────

Swift (Apple Open Source)
Copyright © 2014-2025 Apple Inc.
Licensed under the Apache License, Version 2.0

─────────────────────────────────

SwiftUI (Apple)
Part of the Apple platform SDK.
All rights reserved by Apple Inc.

─────────────────────────────────

Apple's full open source projects are available at:
https://opensource.apple.com

Thank you to the open source community for making Dinkr possible.
"""
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AboutView()
    }
}

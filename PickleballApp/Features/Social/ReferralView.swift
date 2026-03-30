import SwiftUI

// MARK: - Referral Step Model

private struct ReferralStep: Identifiable {
    let id: Int
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
}

private let referralSteps: [ReferralStep] = [
    ReferralStep(
        id: 1,
        icon: "link.badge.plus",
        iconColor: Color.dinkrGreen,
        title: "Share Your Code",
        description: "Send your unique referral code or link to friends who love pickleball."
    ),
    ReferralStep(
        id: 2,
        icon: "person.badge.plus",
        iconColor: Color.dinkrSky,
        title: "Friend Joins Dinkr",
        description: "They sign up using your code and complete their player profile."
    ),
    ReferralStep(
        id: 3,
        icon: "star.circle.fill",
        iconColor: Color.dinkrAmber,
        title: "Both Get 1 Month Premium",
        description: "You and your friend each unlock one month of Dinkr Premium — free."
    ),
]

// MARK: - ReferralView

struct ReferralView: View {
    let user: User

    @State private var showShareSheet = false
    @State private var showContactsAlert = false
    @State private var codeCopied = false

    private var referralCode: String {
        // Derive a stable code from username — in production this would come from backend
        let base = user.username.uppercased().replacingOccurrences(of: "_", with: "")
        let suffix = abs(user.id.hashValue) % 100
        return "DINKR-\(String(base.prefix(6)))\(suffix)"
    }

    private var referralURL: URL {
        URL(string: "https://dinkr.app/join?ref=\(referralCode.lowercased())")
            ?? URL(string: "https://dinkr.app")!
    }

    // Mock: friends who have joined via this referral
    private let joinedCount: Int = 2
    private let targetCount: Int = 5

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: Header
                    headerSection

                    // MARK: Referral Code Card
                    referralCodeCard

                    // MARK: Share Link Button
                    shareButton

                    // MARK: How It Works
                    howItWorksSection

                    // MARK: Progress
                    progressSection

                    // MARK: Invite from Contacts
                    contactsButton

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Invite Friends")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showShareSheet) {
                ActivityShareSheet(items: [
                    "Join me on Dinkr! Use my referral code \(referralCode) or tap the link to get started:",
                    referralURL
                ])
                .presentationDetents([.medium, .large])
            }
            .alert("Contacts Access Coming Soon", isPresented: $showContactsAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Direct contacts invite is coming in a future update. For now, share your link or code manually!")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            DinkrLogoView(size: 44, showWordmark: true, tintColor: Color.dinkrGreen)

            Text("Invite Friends to Dinkr 🏓")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)

            Text("Grow the community. Earn rewards together.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Referral Code Card

    private var referralCodeCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundStyle(Color.dinkrGreen)
                Text("Your Referral Code")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(spacing: 12) {
                Text(referralCode)
                    .font(.system(.title2, design: .monospaced, weight: .bold))
                    .foregroundStyle(Color.dinkrNavy)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Spacer()

                Button {
                    UIPasteboard.general.string = referralCode
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        codeCopied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { codeCopied = false }
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(codeCopied ? Color.dinkrGreen : Color.dinkrGreen.opacity(0.12))
                            .frame(width: 80, height: 38)

                        Label(
                            codeCopied ? "Copied!" : "Copy",
                            systemImage: codeCopied ? "checkmark" : "doc.on.doc"
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(codeCopied ? .white : Color.dinkrGreen)
                        .labelStyle(.titleAndIcon)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: codeCopied)
            }
            .padding(16)
            .background(Color.dinkrGreen.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.dinkrGreen.opacity(0.25), lineWidth: 1)
            )
        }
        .padding(20)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    // MARK: - Share Button

    private var shareButton: some View {
        Button {
            showShareSheet = true
        } label: {
            Label("Share Your Link", systemImage: "square.and.arrow.up")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - How It Works

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How It Works")
                .font(.headline)
                .padding(.bottom, 2)

            VStack(spacing: 0) {
                ForEach(referralSteps) { step in
                    HStack(alignment: .top, spacing: 16) {
                        // Step number + icon
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(step.iconColor.opacity(0.12))
                                    .frame(width: 48, height: 48)
                                Image(systemName: step.icon)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(step.iconColor)
                            }

                            if step.id < referralSteps.count {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 2, height: 28)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("\(step.id).")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.secondary)
                                Text(step.title)
                                    .font(.subheadline.weight(.bold))
                            }
                            Text(step.description)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 12)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Your Referrals")
                    .font(.headline)
                Spacer()
                Text("\(joinedCount) of \(targetCount) joined")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dinkrGreen)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.dinkrGreen.opacity(0.12))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.dinkrGreen, Color.dinkrSky],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * CGFloat(joinedCount) / CGFloat(targetCount),
                            height: 12
                        )
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: joinedCount)
                }
            }
            .frame(height: 12)

            // Reward unlock indicator
            HStack(spacing: 8) {
                Image(systemName: joinedCount >= targetCount ? "gift.fill" : "gift")
                    .foregroundStyle(joinedCount >= targetCount ? Color.dinkrAmber : .secondary)
                    .font(.subheadline)

                if joinedCount >= targetCount {
                    Text("Reward unlocked! Claim your free Premium month.")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.dinkrAmber)
                } else {
                    Text("Invite \(targetCount - joinedCount) more friend\(targetCount - joinedCount == 1 ? "" : "s") to unlock 1 month free Premium.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            // Friend slots
            HStack(spacing: 8) {
                ForEach(0..<targetCount, id: \.self) { i in
                    ZStack {
                        Circle()
                            .fill(i < joinedCount ? Color.dinkrGreen.opacity(0.15) : Color.secondary.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: i < joinedCount ? "person.fill.checkmark" : "person.fill.questionmark")
                            .font(.system(size: 14))
                            .foregroundStyle(i < joinedCount ? Color.dinkrGreen : Color.secondary.opacity(0.4))
                    }
                }
                Spacer()
            }
        }
        .padding(20)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    // MARK: - Contacts Button

    private var contactsButton: some View {
        Button {
            showContactsAlert = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Invite from Contacts")
                    .font(.headline)
            }
            .foregroundStyle(Color.dinkrNavy)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.dinkrAmber.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.dinkrAmber.opacity(0.4), lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    ReferralView(user: .mockCurrentUser)
}

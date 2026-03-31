import SwiftUI

// MARK: - CompanyModeToggleView
// Inline settings card used inside SettingsView.

struct CompanyModeToggleView: View {
    @Binding var companyModeEnabled: Bool

    // In a real app these would come from the authenticated user's profile.
    private let companyName = "Acme Corp"
    private let department = "Engineering"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header row
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.dinkrSky.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.dinkrSky)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Company Mode")
                        .font(.subheadline.weight(.semibold))
                    HStack(spacing: 4) {
                        Image(systemName: "briefcase.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("\(department) · \(companyName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Toggle("", isOn: $companyModeEnabled)
                    .tint(Color.dinkrGreen)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if companyModeEnabled {
                Divider()
                    .padding(.horizontal, 16)

                // Status description
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.dinkrGreen)
                    Text("You appear on the \(companyName) leaderboard and earn wellness points")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider()
                    .padding(.horizontal, 16)

                // Navigation link to the leaderboard
                NavigationLink(destination: OrgLeaderboardView()) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundStyle(Color.dinkrGreen)
                        Text("Company Leaderboard")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.horizontal, 16)

                // Navigation link to enterprise settings
                NavigationLink(destination: EnterpriseSettingsView()) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption)
                            .foregroundStyle(Color.dinkrSky)
                        Text("Enterprise Settings")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.dinkrSky.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - EnterpriseSettingsView
// Full enterprise/company settings screen.

struct EnterpriseSettingsView: View {
    @State private var companyModeEnabled = true
    @State private var emailDomain = "acmecorp.com"
    @State private var domainVerified = true
    @State private var isVerifying = false
    @State private var showBadgeOnProfile = true
    @State private var weeklyChallenge = true
    @State private var selectedDepartment = "Engineering"
    @State private var showVerifiedAlert = false
    @State private var showTeamChallengeView = false

    private let departments = ["Engineering", "Sales", "Marketing", "HR", "Executive", "Design", "Finance", "Operations"]
    private let companyName = "Acme Corp"

    var body: some View {
        List {
            companyStatusSection
            domainVerificationSection
            featuresSection
            profileSection
            challengeSection
            teamChallengeSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Enterprise Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert("Domain Verified", isPresented: $showVerifiedAlert) {
            Button("OK") {}
        } message: {
            Text("Your work email domain @\(emailDomain) has been confirmed. You now have access to \(companyName) company features.")
        }
        .navigationDestination(isPresented: $showTeamChallengeView) {
            TeamChallengeView()
        }
    }

    // MARK: - Company Status Section

    private var companyStatusSection: some View {
        Section {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.dinkrNavy.opacity(0.15), Color.dinkrGreen.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    Text("AC")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(Color.dinkrNavy)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(companyName)
                            .font(.headline.weight(.bold))
                        if domainVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Color.dinkrGreen)
                                .font(.footnote)
                        }
                    }
                    Text("47 employees playing · \(selectedDepartment)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: $companyModeEnabled)
                    .tint(Color.dinkrGreen)
                    .labelsHidden()
            }
            .padding(.vertical, 4)
        } header: {
            Text("Company Mode")
        } footer: {
            Text("When enabled, your activity appears on the \(companyName) internal leaderboard and you earn wellness points.")
        }
    }

    // MARK: - Domain Verification Section

    private var domainVerificationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: domainVerified ? "checkmark.circle.fill" : "envelope.badge.shield.half.filled")
                        .foregroundStyle(domainVerified ? Color.dinkrGreen : Color.dinkrAmber)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(domainVerified ? "Email Domain Verified" : "Verify Your Work Email")
                            .font(.subheadline.weight(.semibold))
                        Text(domainVerified ? "@\(emailDomain)" : "Enter your company email domain to unlock company features")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !domainVerified {
                    HStack(spacing: 8) {
                        Text("@")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextField("yourcompany.com", text: $emailDomain)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        Spacer()
                        Button {
                            verifyDomain()
                        } label: {
                            ZStack {
                                if isVerifying {
                                    ProgressView()
                                        .tint(Color.dinkrGreen)
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Verify")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(Color.dinkrGreen)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(emailDomain.count < 4 || isVerifying)
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Domain Verification")
        } footer: {
            Text("We verify your work email to ensure only \(companyName) employees can join the company leaderboard.")
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        Section("Company Features") {
            ForEach(enterpriseFeatures, id: \.title) { feature in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(feature.color.opacity(0.12))
                            .frame(width: 34, height: 34)
                        Image(systemName: feature.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(feature.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.subheadline.weight(.medium))
                        Text(feature.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(domainVerified ? Color.dinkrGreen : Color.secondary.opacity(0.4))
                        .font(.footnote)
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var enterpriseFeatures: [(icon: String, color: Color, title: String, description: String)] {
        [
            ("trophy.fill",         Color.dinkrAmber,  "Org Leaderboard",          "See how you rank against \(companyName) colleagues"),
            ("person.3.fill",       Color.dinkrSky,    "Team Challenges",           "Department vs department pickleball battles"),
            ("lock.shield.fill",    Color.dinkrNavy,   "Private Company DinkrGroup",     "A members-only group for \(companyName) players"),
            ("heart.fill",          Color.dinkrCoral,  "Wellness Points",           "Earn points toward company wellness rewards"),
        ]
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        Section {
            Toggle(isOn: $showBadgeOnProfile) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.dinkrNavy.opacity(0.12))
                            .frame(width: 30, height: 30)
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.dinkrNavy)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show Company Badge")
                            .font(.subheadline)
                        Text("Display the \(companyName) badge on your public profile")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .tint(Color.dinkrGreen)

            Picker(selection: $selectedDepartment) {
                ForEach(departments, id: \.self) { dept in
                    Text(dept).tag(dept)
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.dinkrSky.opacity(0.12))
                            .frame(width: 30, height: 30)
                        Image(systemName: "briefcase.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.dinkrSky)
                    }
                    Text("Your Department")
                        .font(.subheadline)
                }
            }
        } header: {
            Text("Profile")
        }
    }

    // MARK: - Challenge Section

    private var challengeSection: some View {
        Section {
            Toggle(isOn: $weeklyChallenge) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.dinkrAmber.opacity(0.12))
                            .frame(width: 30, height: 30)
                        Text("🍕")
                            .font(.system(size: 14))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weekly Challenges")
                            .font(.subheadline)
                        Text("Opt in to company-wide pickleball challenges with prizes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .tint(Color.dinkrGreen)

            if weeklyChallenge {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.dinkrCoral.opacity(0.12))
                            .frame(width: 30, height: 30)
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.dinkrCoral)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Challenge")
                            .font(.subheadline)
                        Text("Most games played wins lunch — 4 days left")
                            .font(.caption)
                            .foregroundStyle(Color.dinkrAmber)
                    }
                    Spacer()
                    Text("Active")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.dinkrGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.dinkrGreen.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        } header: {
            Text("Challenges")
        } footer: {
            Text("Challenge notifications will be sent at the start of each week. You can opt out any time.")
        }
    }

    // MARK: - Team Challenge Section

    private var teamChallengeSection: some View {
        Section("Team Challenges") {
            Button {
                showTeamChallengeView = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.dinkrGreen.opacity(0.12))
                            .frame(width: 30, height: 30)
                        Image(systemName: "person.2.badge.gearshape.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("View Active Team Challenge")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Text("Engineering vs Sales · Best of 5")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Domain Verification Logic

    private func verifyDomain() {
        guard !emailDomain.isEmpty else { return }
        isVerifying = true
        HapticManager.selection()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isVerifying = false
            domainVerified = true
            showVerifiedAlert = true
            HapticManager.success()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        VStack(spacing: 20) {
            CompanyModeToggleView(companyModeEnabled: .constant(true))
            CompanyModeToggleView(companyModeEnabled: .constant(false))
        }
        .padding()
    }
    .background(Color.appBackground)
}

#Preview("Enterprise Settings") {
    NavigationStack {
        EnterpriseSettingsView()
    }
}

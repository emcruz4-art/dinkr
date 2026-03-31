import SwiftUI
import StoreKit

// MARK: - Settings View

struct SettingsView: View {
    @Environment(AuthService.self) private var authService

    // MARK: - Account
    @State private var showChangePassword = false
    @State private var showChangeEmail = false
    @State private var showChangePhone = false

    // MARK: - Notifications
    @State private var emailNotificationsEnabled = true
    @State private var smsAlertsEnabled = false

    // MARK: - Privacy & Security
    @State private var twoFactorEnabled = false
    @State private var showTwoFactorSetupAlert = false
    @State private var whoCanMessage: MessageAudience = .everyone
    @State private var whoCanSeeStats: StatsAudience = .everyone
    @State private var locationSharing = false
    @State private var blockedCount = 3

    // MARK: - Appearance
    @AppStorage("textSizeMultiplier") private var textSizeMultiplier: Double = 1.0

    // MARK: - Gameplay
    @State private var defaultGameFormat: GameFormat = .doubles
    @State private var skillDisplayPreference: SkillDisplayPreference = .duprAndSelf
    @State private var autoRSVPReminder = true
    @State private var courtNotificationRadius: Double = 15

    // MARK: - App Preferences (existing)
    @State private var defaultSkillFilter: SkillLevel = .intermediate35
    @State private var distanceRadius = 15
    @State private var courtSurface: SettingsCourtSurface = .any

    // MARK: - Company
    @State private var companyModeEnabled = true

    // MARK: - Danger Zone
    @State private var showSignOutAlert = false
    @State private var showAccountDeletion = false

    var body: some View {
        NavigationStack {
            List {
                accountSection
                notificationsSection
                privacyAndSecuritySection
                appearanceSection
                gameplaySection
                aboutSection
                supportSection
                companySection
                dangerZoneSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            // Sign Out alert
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) { authService.signOut() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
            // Two-Factor setup alert
            .alert("Set Up Two-Factor Authentication", isPresented: $showTwoFactorSetupAlert) {
                Button("Continue") { twoFactorEnabled = true }
                Button("Cancel", role: .cancel) { twoFactorEnabled = false }
            } message: {
                Text("Two-factor authentication adds an extra layer of security to your account. You'll be asked to verify your identity when signing in on a new device.")
            }
            // Sheet presentations
            .sheet(isPresented: $showChangePassword) { ChangePasswordView() }
            .sheet(isPresented: $showChangeEmail) { ChangeEmailView(currentEmail: authService.currentUser.flatMap { _ in nil } ?? "—") }
            .sheet(isPresented: $showChangePhone) { ChangePhoneView() }
            // Account Deletion
            .fullScreenCover(isPresented: $showAccountDeletion) { AccountDeletionView() }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section("Account") {
            NavigationLink {
                EditProfileView(user: User.mockCurrentUser)
            } label: {
                SettingsRow(icon: "person.crop.circle", iconColor: Color.dinkrGreen, title: "Edit Profile")
            }

            Button {
                showChangePassword = true
            } label: {
                SettingsRow(icon: "lock.rotation", iconColor: Color.dinkrNavy, title: "Change Password")
            }
            .buttonStyle(.plain)

            Button {
                showChangeEmail = true
            } label: {
                HStack {
                    SettingsRow(icon: "envelope", iconColor: Color.dinkrSky, title: "Email Address")
                    Spacer()
                    if let email = authService.currentUser.map({ _ in "••••@gmail.com" }) {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)

            Button {
                showChangePhone = true
            } label: {
                HStack {
                    SettingsRow(icon: "phone", iconColor: Color.dinkrGreen, title: "Phone Number")
                    Spacer()
                    Text("Add")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
            .buttonStyle(.plain)

            NavigationLink {
                LinkedAccountsView()
            } label: {
                HStack {
                    SettingsRow(icon: "link", iconColor: Color.dinkrNavy, title: "Linked Accounts")
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "applelogo")
                            .font(.caption)
                            .foregroundStyle(.primary)
                        Image(systemName: "globe")
                            .font(.caption)
                            .foregroundStyle(Color.dinkrSky)
                    }
                }
            }
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section("Notifications") {
            NavigationLink {
                NotificationPreferencesView()
            } label: {
                SettingsRow(icon: "bell.badge", iconColor: Color.dinkrGreen, title: "Push Notifications")
            }

            Toggle(isOn: $emailNotificationsEnabled) {
                SettingsRow(icon: "envelope.badge", iconColor: Color.dinkrSky, title: "Email Notifications")
            }
            .tint(Color.dinkrGreen)

            Toggle(isOn: $smsAlertsEnabled) {
                SettingsRow(icon: "message.badge", iconColor: Color.dinkrAmber, title: "SMS Alerts")
            }
            .tint(Color.dinkrGreen)
        }
    }

    // MARK: - Privacy & Security Section

    private var privacyAndSecuritySection: some View {
        Section("Privacy & Security") {
            NavigationLink {
                PrivacySettingsView()
            } label: {
                SettingsRow(icon: "hand.raised.fill", iconColor: Color.dinkrGreen, title: "Privacy Settings")
            }

            NavigationLink {
                LinkedAccountsView()
            } label: {
                SettingsRow(icon: "externaldrive.connected.to.line.below", iconColor: Color.dinkrSky, title: "Linked Accounts")
            }

            Toggle(isOn: Binding(
                get: { twoFactorEnabled },
                set: { newValue in
                    if newValue {
                        showTwoFactorSetupAlert = true
                    } else {
                        twoFactorEnabled = false
                    }
                }
            )) {
                SettingsRow(icon: "shield.lefthalf.filled", iconColor: Color.dinkrNavy, title: "Two-Factor Authentication")
            }
            .tint(Color.dinkrGreen)

            NavigationLink {
                BlockedUsersView()
            } label: {
                HStack {
                    SettingsRow(icon: "nosign", iconColor: Color.dinkrCoral, title: "Block List")
                    Spacer()
                    Text("\(blockedCount)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.dinkrCoral, in: Capsule())
                }
            }

            Picker(selection: $whoCanMessage) {
                ForEach(MessageAudience.allCases) { audience in
                    Text(audience.label).tag(audience)
                }
            } label: {
                SettingsRow(icon: "message", iconColor: Color.dinkrSky, title: "Who Can Message Me")
            }

            Picker(selection: $whoCanSeeStats) {
                ForEach(StatsAudience.allCases) { audience in
                    Text(audience.label).tag(audience)
                }
            } label: {
                SettingsRow(icon: "chart.bar", iconColor: Color.dinkrSky, title: "Who Can See My Stats")
            }

            Toggle(isOn: $locationSharing) {
                SettingsRow(icon: "location", iconColor: Color.dinkrGreen, title: "Location Sharing")
            }
            .tint(Color.dinkrGreen)
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section("Appearance") {
            NavigationLink {
                AppearanceSettingsView()
            } label: {
                SettingsRow(icon: "paintbrush.fill", iconColor: Color.dinkrNavy, title: "Theme")
            }

            NavigationLink {
                AppIconSettingsView()
            } label: {
                SettingsRow(icon: "app.badge", iconColor: Color.dinkrGreen, title: "App Icon")
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.dinkrSky.opacity(0.15))
                            .frame(width: 30, height: 30)
                        Image(systemName: "textformat.size")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.dinkrSky)
                    }
                    Text("Text Size")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(textSizeLabel)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.dinkrGreen)
                }

                Slider(value: $textSizeMultiplier, in: 0.8...1.4, step: 0.1)
                    .tint(Color.dinkrGreen)

                HStack {
                    Text("A")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("A")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var textSizeLabel: String {
        switch textSizeMultiplier {
        case ..<0.85:  return "XS"
        case ..<0.95:  return "Small"
        case ..<1.05:  return "Default"
        case ..<1.15:  return "Large"
        case ..<1.25:  return "XL"
        default:       return "XXL"
        }
    }

    // MARK: - Gameplay Section

    private var gameplaySection: some View {
        Section("Gameplay") {
            Picker(selection: $defaultGameFormat) {
                ForEach(GameFormat.allCases, id: \.self) { format in
                    Text(format.label).tag(format)
                }
            } label: {
                SettingsRow(icon: "sportscourt", iconColor: Color.dinkrGreen, title: "Default Game Format")
            }

            Picker(selection: $skillDisplayPreference) {
                ForEach(SkillDisplayPreference.allCases) { pref in
                    Text(pref.label).tag(pref)
                }
            } label: {
                SettingsRow(icon: "chart.line.uptrend.xyaxis", iconColor: Color.dinkrAmber, title: "Skill Level Display")
            }

            Toggle(isOn: $autoRSVPReminder) {
                SettingsRow(icon: "calendar.badge.clock", iconColor: Color.dinkrSky, title: "Auto-RSVP Reminder")
            }
            .tint(Color.dinkrGreen)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.dinkrGreen.opacity(0.15))
                            .frame(width: 30, height: 30)
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                    Text("Court Notification Radius")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(Int(courtNotificationRadius)) mi")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                        .frame(minWidth: 44, alignment: .trailing)
                }

                Slider(value: $courtNotificationRadius, in: 1...50, step: 1)
                    .tint(Color.dinkrGreen)

                HStack {
                    Text("1 mi")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("50 mi")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)

            Picker(selection: $courtSurface) {
                ForEach(SettingsCourtSurface.allCases) { surface in
                    Text(surface.label).tag(surface)
                }
            } label: {
                SettingsRow(icon: "square.grid.3x3", iconColor: Color.dinkrAmber, title: "Preferred Court Surface")
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section("About") {
            NavigationLink {
                ReferAFriendView()
            } label: {
                HStack {
                    SettingsRow(icon: "person.2.wave.2.fill", iconColor: Color.dinkrGreen, title: "Invite Friends")
                    Spacer()
                    Text("Earn rewards")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.dinkrAmber)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.dinkrAmber.opacity(0.12), in: Capsule())
                }
            }

            NavigationLink {
                AboutView()
            } label: {
                SettingsRow(icon: "info.circle.fill", iconColor: Color.dinkrNavy, title: "About Dinkr")
            }

            NavigationLink {
                ExportDataView()
            } label: {
                SettingsRow(icon: "square.and.arrow.up.fill", iconColor: Color.dinkrSky, title: "Export My Data")
            }

            NavigationLink {
                SettingsCommunityRulesView()
            } label: {
                SettingsRow(icon: "text.badge.checkmark", iconColor: Color.dinkrGreen, title: "Community Guidelines")
            }

            Button {
                if let scene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first {
                    SKStoreReviewController.requestReview(in: scene)
                }
            } label: {
                HStack {
                    SettingsRow(icon: "star.fill", iconColor: Color.dinkrAmber, title: "Rate Dinkr")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            ShareLink(
                item: URL(string: "https://dinkr.app")!,
                subject: Text("Play Pickleball with Dinkr"),
                message: Text("I've been using Dinkr to find pickleball games, courts, and players near me!")
            ) {
                HStack {
                    SettingsRow(icon: "square.and.arrow.up", iconColor: Color.dinkrGreen, title: "Share Dinkr")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            HStack {
                SettingsRow(icon: "info.circle", iconColor: .secondary, title: "Version")
                Spacer()
                Text(appVersionString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Support Section

    private var supportSection: some View {
        Section("Support") {
            NavigationLink {
                FAQView()
            } label: {
                SettingsRow(icon: "questionmark.circle", iconColor: Color.dinkrSky, title: "FAQ")
            }

            NavigationLink {
                FeedbackView()
            } label: {
                SettingsRow(icon: "envelope", iconColor: Color.dinkrGreen, title: "Send Feedback")
            }

            Button {
                if let url = URL(string: "mailto:support@dinkr.app") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    SettingsRow(icon: "headphones", iconColor: Color.dinkrNavy, title: "Contact Support")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Company Section

    private var companySection: some View {
        Section("Enterprise") {
            CompanyModeToggleView(companyModeEnabled: $companyModeEnabled)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
    }

    // MARK: - Danger Zone Section

    private var dangerZoneSection: some View {
        Section {
            Button {
                showSignOutAlert = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.dinkrCoral.opacity(0.12))
                            .frame(width: 30, height: 30)
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.dinkrCoral)
                    }
                    Text("Sign Out")
                        .foregroundStyle(Color.dinkrCoral)
                    Spacer()
                }
            }

            Button(role: .destructive) {
                showAccountDeletion = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.dinkrCoral.opacity(0.12))
                            .frame(width: 30, height: 30)
                        Image(systemName: "trash.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.dinkrCoral)
                    }
                    Text("Delete Account")
                        .foregroundStyle(Color.dinkrCoral)
                    Spacer()
                }
            }
        } header: {
            Text("Danger Zone")
                .foregroundStyle(Color.dinkrCoral)
        } footer: {
            Text("Deleting your account is permanent and cannot be undone. All your games, stats, and connections will be removed.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Supporting Row Component

private struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            Text(title)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Change Password Sheet

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    private var passwordsMatch: Bool { newPassword == confirmPassword }
    private var isValid: Bool { !currentPassword.isEmpty && newPassword.count >= 8 && passwordsMatch }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                        .textContentType(.password)
                } header: {
                    Text("Current")
                }

                Section {
                    SecureField("New Password", text: $newPassword)
                        .textContentType(.newPassword)
                    SecureField("Confirm New Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                } header: {
                    Text("New Password")
                } footer: {
                    if !confirmPassword.isEmpty && !passwordsMatch {
                        Text("Passwords do not match.")
                            .foregroundStyle(Color.dinkrCoral)
                    } else {
                        Text("Minimum 8 characters.")
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(Color.dinkrCoral)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update") {
                        updatePassword()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid || isLoading)
                }
            }
            .alert("Password Updated", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your password has been changed successfully.")
            }
        }
    }

    private func updatePassword() {
        isLoading = true
        errorMessage = nil
        // Wire to FirebaseAuth reauthentication + updatePassword in production
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            showSuccess = true
        }
    }
}

// MARK: - Change Email Sheet

struct ChangeEmailView: View {
    @Environment(\.dismiss) private var dismiss
    let currentEmail: String
    @State private var newEmail = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showSuccess = false

    private var isValid: Bool {
        newEmail.contains("@") && newEmail.contains(".") && !password.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Current Email") {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundStyle(Color.dinkrSky)
                        Text(currentEmail.isEmpty ? "Not set" : currentEmail)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    TextField("New Email Address", text: $newEmail)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Confirm Password", text: $password)
                        .textContentType(.password)
                } header: {
                    Text("New Email")
                } footer: {
                    Text("We'll send a verification link to your new address.")
                }
            }
            .navigationTitle("Change Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEmail() }
                        .fontWeight(.semibold)
                        .disabled(!isValid || isLoading)
                }
            }
            .alert("Verification Sent", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Check \(newEmail) to verify your new address.")
            }
        }
    }

    private func saveEmail() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            showSuccess = true
        }
    }
}

// MARK: - Change Phone Sheet

struct ChangePhoneView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var codeSent = false
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                if !codeSent {
                    Section {
                        HStack {
                            Text("+1")
                                .foregroundStyle(.secondary)
                                .padding(.trailing, 4)
                            TextField("Phone Number", text: $phoneNumber)
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                        }
                    } header: {
                        Text("Mobile Number")
                    } footer: {
                        Text("Standard messaging rates may apply.")
                    }
                } else {
                    Section {
                        TextField("6-digit code", text: $verificationCode)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                    } header: {
                        Text("Verification Code")
                    } footer: {
                        Text("Sent to +1 \(phoneNumber). This code expires in 10 minutes.")
                    }
                }
            }
            .navigationTitle(codeSent ? "Verify Phone" : "Phone Number")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(codeSent ? "Verify" : "Send Code") {
                        if codeSent {
                            dismiss()
                        } else {
                            withAnimation { codeSent = true }
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(codeSent ? verificationCode.count != 6 : phoneNumber.count < 10)
                }
            }
        }
    }
}

// MARK: - Community Rules View

struct SettingsCommunityRulesView: View {
    private let rules: [(icon: String, color: Color, title: String, body: String)] = [
        ("heart.fill",          Color.dinkrCoral,  "Be Respectful",        "Treat every player with courtesy on and off the court. Unsportsmanlike behavior, harassment, or hate speech will not be tolerated."),
        ("checkmark.seal.fill", Color.dinkrGreen,  "Play Fair",            "Honor the score, call lines honestly, and respect your opponents. Dinkr relies on a culture of integrity."),
        ("person.2.fill",       Color.dinkrSky,    "Show Up",              "When you RSVP to a game, show up. Ghosting hurts the community. Cancel at least 2 hours in advance if something comes up."),
        ("star.fill",           Color.dinkrAmber,  "Rate Honestly",        "Leave fair, constructive reviews. Ratings help the community find great players and courts."),
        ("lock.shield.fill",    Color.dinkrNavy,   "Protect Privacy",      "Don't share personal information about other players without their consent. Respect private profiles."),
        ("megaphone.fill",      Color.dinkrGreen,  "No Spam",              "Don't abuse the messaging or posting features to promote products, services, or external platforms."),
        ("flag.fill",           Color.dinkrCoral,  "Report Problems",      "If you see something that violates these guidelines, report it. We rely on the community to keep Dinkr safe and fun."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero header
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.dinkrGreen, Color.dinkrNavy],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    VStack(spacing: 10) {
                        Image(systemName: "text.badge.checkmark")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Community Guidelines")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        Text("Keep Dinkr a great place to play")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.vertical, 28)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)

                // Rules list
                VStack(spacing: 12) {
                    ForEach(rules, id: \.title) { rule in
                        CommunityRuleCard(
                            icon: rule.icon,
                            color: rule.color,
                            title: rule.title,
                            description: rule.body
                        )
                    }
                }
                .padding(.horizontal, 20)

                // Footer
                VStack(spacing: 8) {
                    Text("Last updated March 2025")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Link("Full Terms of Service →", destination: URL(string: "https://dinkr.app/terms")!)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.dinkrGreen)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Community Guidelines")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Community Rule Card

private struct CommunityRuleCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Local Enums

enum MessageAudience: String, CaseIterable, Identifiable {
    case everyone  = "Everyone"
    case followers = "Followers"
    case nobody    = "Nobody"

    var id: String { rawValue }
    var label: String { rawValue }
}

enum StatsAudience: String, CaseIterable, Identifiable {
    case everyone  = "Everyone"
    case followers = "Followers"
    case onlyMe    = "Only Me"

    var id: String { rawValue }
    var label: String { rawValue }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light  = "Light"
    case dark   = "Dark"

    var id: String { rawValue }
    var label: String { rawValue }
}

enum SettingsCourtSurface: String, CaseIterable, Identifiable {
    case any       = "Any"
    case concrete  = "Concrete"
    case asphalt   = "Asphalt"
    case sportCourt = "Sport Court"

    var id: String { rawValue }
    var label: String { rawValue }
}

enum SkillDisplayPreference: String, CaseIterable, Identifiable {
    case selfRated   = "Self-Rated Only"
    case duprOnly    = "DUPR Only"
    case duprAndSelf = "DUPR + Self-Rated"

    var id: String { rawValue }
    var label: String { rawValue }
}

extension GameFormat {
    var label: String {
        switch self {
        case .singles:      return "Singles"
        case .doubles:      return "Doubles"
        case .mixed:        return "Mixed Doubles"
        case .openPlay:     return "Open Play"
        case .round_robin:  return "Round Robin"
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(AuthService())
}

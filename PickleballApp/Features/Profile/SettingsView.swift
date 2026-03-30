import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @Environment(AuthService.self) private var authService

    // MARK: Account
    @State private var showChangeUsername = false
    @State private var showLinkedAccounts = false

    // MARK: Notifications
    @State private var notifyGameInvites = true
    @State private var notifyMatchRequests = true
    @State private var notifyGroupActivity = true
    @State private var notifyTournamentUpdates = false
    @State private var notifyMarketing = false

    // MARK: Privacy
    @State private var whoCanMessage: MessageAudience = .everyone
    @State private var whoCanSeeStats: StatsAudience = .everyone
    @State private var blockedCount = 3
    @State private var locationSharing = false

    // MARK: App Preferences
    @State private var defaultSkillFilter: SkillLevel = .intermediate35
    @State private var distanceRadius = 15
    @State private var appTheme: AppTheme = .system
    @State private var courtSurface: SettingsCourtSurface = .any

    // MARK: Danger Zone
    @State private var showLogOutAlert = false
    @State private var showDeleteAlert = false
    @State private var showShareSheet = false

    // MARK: Company Mode
    @State private var companyModeEnabled = true   // true by default for demo

    var body: some View {
        NavigationStack {
            List {
                accountSection
                notificationsSection
                privacySection
                preferencesSection
                aboutSection
                supportSection
                companySection
                dangerZoneSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Log Out", isPresented: $showLogOutAlert) {
                Button("Log Out", role: .destructive) { authService.signOut() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to log out?")
            }
            .alert("Delete Account", isPresented: $showDeleteAlert) {
                Button("Delete My Account", role: .destructive) { authService.signOut() /* full delete requires server-side Firebase call */ }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action is permanent. All your data, matches, and posts will be deleted and cannot be recovered.")
            }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section("Account") {
            NavigationLink {
                Text("Edit Profile").navigationTitle("Edit Profile")
            } label: {
                SettingsRow(icon: "person.crop.circle", iconColor: Color.dinkrGreen, title: "Edit Profile")
            }

            SettingsRow(icon: "at", iconColor: Color.dinkrSky, title: "Change Username")

            NavigationLink {
                Text("Linked Accounts").navigationTitle("Linked Accounts")
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
            Toggle(isOn: $notifyGameInvites) {
                SettingsRow(icon: "bell.badge", iconColor: Color.dinkrGreen, title: "Game Invites")
            }
            Toggle(isOn: $notifyMatchRequests) {
                SettingsRow(icon: "figure.pickleball", iconColor: Color.dinkrGreen, title: "Match Requests")
            }
            Toggle(isOn: $notifyGroupActivity) {
                SettingsRow(icon: "person.3", iconColor: Color.dinkrSky, title: "Group Activity")
            }
            Toggle(isOn: $notifyTournamentUpdates) {
                SettingsRow(icon: "trophy", iconColor: Color.dinkrAmber, title: "Tournament Updates")
            }
            Toggle(isOn: $notifyMarketing) {
                SettingsRow(icon: "megaphone", iconColor: .secondary, title: "Marketing & Tips")
            }
        }
    }

    // MARK: - Privacy & Safety Section

    private var privacySection: some View {
        Section("Privacy & Safety") {
            Picker(selection: $whoCanMessage) {
                ForEach(MessageAudience.allCases) { audience in
                    Text(audience.label).tag(audience)
                }
            } label: {
                SettingsRow(icon: "message", iconColor: Color.dinkrSky, title: "Who can message me")
            }

            Picker(selection: $whoCanSeeStats) {
                ForEach(StatsAudience.allCases) { audience in
                    Text(audience.label).tag(audience)
                }
            } label: {
                SettingsRow(icon: "chart.bar", iconColor: Color.dinkrSky, title: "Who can see my stats")
            }

            NavigationLink {
                Text("Blocked Players").navigationTitle("Blocked Players")
            } label: {
                HStack {
                    SettingsRow(icon: "nosign", iconColor: Color.dinkrCoral, title: "Blocked Players")
                    Spacer()
                    Text("\(blockedCount)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.dinkrCoral, in: Capsule())
                }
            }

            Toggle(isOn: $locationSharing) {
                SettingsRow(icon: "location", iconColor: Color.dinkrGreen, title: "Location Sharing")
            }
        }
    }

    // MARK: - App Preferences Section

    private var preferencesSection: some View {
        Section("App Preferences") {
            Picker(selection: $defaultSkillFilter) {
                ForEach(SkillLevel.allCases, id: \.self) { level in
                    Text(level.label).tag(level)
                }
            } label: {
                SettingsRow(icon: "slider.horizontal.3", iconColor: Color.dinkrGreen, title: "Default Skill Filter")
            }

            HStack {
                SettingsRow(icon: "location.circle", iconColor: Color.dinkrSky, title: "Distance Radius")
                Spacer()
                Stepper("\(distanceRadius) mi", value: $distanceRadius, in: 5...50, step: 5)
                    .labelsHidden()
                Text("\(distanceRadius) mi")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 44, alignment: .trailing)
            }

            Picker(selection: $appTheme) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.label).tag(theme)
                }
            } label: {
                SettingsRow(icon: "circle.lefthalf.filled", iconColor: Color.dinkrNavy, title: "App Theme")
            }

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
            Button {
                if let url = URL(string: "https://apps.apple.com/app/id000000000") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    SettingsRow(icon: "star", iconColor: Color.dinkrAmber, title: "Rate Dinkr")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            Button {
                showShareSheet = true
            } label: {
                HStack {
                    SettingsRow(icon: "square.and.arrow.up", iconColor: Color.dinkrGreen, title: "Share Dinkr")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showShareSheet) {
                ShareLink(
                    item: URL(string: "https://dinkr.app")!,
                    subject: Text("Play Pickleball with Dinkr"),
                    message: Text("I've been using Dinkr to find pickleball games, courts, and players near me!")
                )
                .presentationDetents([.medium])
            }

            NavigationLink {
                Text("Privacy Policy").navigationTitle("Privacy Policy")
            } label: {
                SettingsRow(icon: "lock.shield", iconColor: Color.dinkrSky, title: "Privacy Policy")
            }

            NavigationLink {
                Text("Terms of Service").navigationTitle("Terms of Service")
            } label: {
                SettingsRow(icon: "doc.text", iconColor: Color.dinkrSky, title: "Terms of Service")
            }

            HStack {
                SettingsRow(icon: "info.circle", iconColor: .secondary, title: "Version")
                Spacer()
                Text("Dinkr v1.0.0 (build 42)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
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
        Section("Danger Zone") {
            Button {
                showLogOutAlert = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .frame(width: 28)
                    Text("Log Out")
                }
                .foregroundStyle(Color.dinkrCoral)
            }

            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                        .frame(width: 28)
                    Text("Delete Account")
                }
                .foregroundStyle(Color.dinkrCoral)
            }
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

// MARK: - Local Enums

enum MessageAudience: String, CaseIterable, Identifiable {
    case everyone = "Everyone"
    case followers = "Followers"
    case nobody = "Nobody"

    var id: String { rawValue }
    var label: String { rawValue }
}

enum StatsAudience: String, CaseIterable, Identifiable {
    case everyone = "Everyone"
    case followers = "Followers"
    case onlyMe = "Only Me"

    var id: String { rawValue }
    var label: String { rawValue }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }
    var label: String { rawValue }
}

enum SettingsCourtSurface: String, CaseIterable, Identifiable {
    case any = "Any"
    case concrete = "Concrete"
    case asphalt = "Asphalt"
    case sportCourt = "Sport Court"

    var id: String { rawValue }
    var label: String { rawValue }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(AuthService())
}

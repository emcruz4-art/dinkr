import SwiftUI

// MARK: - Privacy Settings View

struct PrivacySettingsView: View {

    // MARK: Profile Visibility
    @AppStorage("privacy.profileVisibility") private var profileVisibility: String = ProfileVisibility.public_.rawValue

    // MARK: Location & Activity
    @AppStorage("privacy.locationSharing")   private var locationSharing: Bool   = false
    @AppStorage("privacy.activityStatus")    private var activityStatus: Bool    = true

    // MARK: Game History
    @AppStorage("privacy.gameHistoryVisibility") private var gameHistoryVisibility: String = GameHistoryAudience.everyone.rawValue

    // MARK: Discoverability
    @AppStorage("privacy.searchDiscoverability") private var searchDiscoverability: Bool = true

    // MARK: Data Safety
    @AppStorage("privacy.whoCanSeeStats")    private var whoCanSeeStats: String   = DataAudience.everyone.rawValue
    @AppStorage("privacy.whoCanMessage")     private var whoCanMessage: String    = MessagingAudience.everyone.rawValue

    // MARK: Local State
    @State private var showDataToast = false

    // MARK: Computed Helpers

    private var selectedVisibility: ProfileVisibility {
        ProfileVisibility(rawValue: profileVisibility) ?? .public_
    }
    private var selectedGameHistory: GameHistoryAudience {
        GameHistoryAudience(rawValue: gameHistoryVisibility) ?? .everyone
    }
    private var selectedStatsAudience: DataAudience {
        DataAudience(rawValue: whoCanSeeStats) ?? .everyone
    }
    private var selectedMessaging: MessagingAudience {
        MessagingAudience(rawValue: whoCanMessage) ?? .everyone
    }

    // MARK: Body

    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                profileVisibilitySection
                locationActivitySection
                gameHistorySection
                dataSafetySection
                exportSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.large)

            if showDataToast {
                toastBanner
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showDataToast)
    }

    // MARK: - Profile Visibility Section

    private var profileVisibilitySection: some View {
        Section {
            Picker(selection: Binding(
                get: { selectedVisibility },
                set: { profileVisibility = $0.rawValue }
            )) {
                ForEach(ProfileVisibility.allCases) { option in
                    Text(option.label).tag(option)
                }
            } label: {
                PrivacyRow(
                    icon: "person.crop.circle.badge.checkmark",
                    iconColor: Color.dinkrGreen,
                    title: "Profile Visibility"
                )
            }
        } header: {
            Text("Profile Visibility")
        } footer: {
            Text(selectedVisibility.footerNote)
        }
    }

    // MARK: - Location & Activity Section

    private var locationActivitySection: some View {
        Section("Location & Activity") {
            Toggle(isOn: $locationSharing) {
                PrivacyRow(
                    icon: "location.fill",
                    iconColor: Color.dinkrGreen,
                    title: "Location Sharing"
                )
            }
            .tint(Color.dinkrGreen)

            Toggle(isOn: $activityStatus) {
                PrivacyRow(
                    icon: "circle.fill",
                    iconColor: Color.dinkrSky,
                    title: "Activity Status"
                )
            }
            .tint(Color.dinkrGreen)

            Toggle(isOn: $searchDiscoverability) {
                PrivacyRow(
                    icon: "magnifyingglass",
                    iconColor: Color.dinkrNavy,
                    title: "Search Discoverability"
                )
            }
            .tint(Color.dinkrGreen)
        }
    }

    // MARK: - Game History Visibility Section

    private var gameHistorySection: some View {
        Section {
            Picker(selection: Binding(
                get: { selectedGameHistory },
                set: { gameHistoryVisibility = $0.rawValue }
            )) {
                ForEach(GameHistoryAudience.allCases) { option in
                    Text(option.label).tag(option)
                }
            } label: {
                PrivacyRow(
                    icon: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                    iconColor: Color.dinkrAmber,
                    title: "Game History"
                )
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        } header: {
            Text("Game History Visibility")
        } footer: {
            Text("Controls who can see the games you've played and your match results.")
        }
    }

    // MARK: - Data Safety Section

    private var dataSafetySection: some View {
        Section("Data Safety") {
            Picker(selection: Binding(
                get: { selectedStatsAudience },
                set: { whoCanSeeStats = $0.rawValue }
            )) {
                ForEach(DataAudience.allCases) { option in
                    Text(option.label).tag(option)
                }
            } label: {
                PrivacyRow(
                    icon: "chart.bar.fill",
                    iconColor: Color.dinkrSky,
                    title: "Who can see my stats"
                )
            }

            Picker(selection: Binding(
                get: { selectedMessaging },
                set: { whoCanMessage = $0.rawValue }
            )) {
                ForEach(MessagingAudience.allCases) { option in
                    Text(option.label).tag(option)
                }
            } label: {
                PrivacyRow(
                    icon: "message.fill",
                    iconColor: Color.dinkrSky,
                    title: "Who can message me"
                )
            }
        }
    }

    // MARK: - Export Section

    private var exportSection: some View {
        Section {
            Button {
                triggerDataExport()
            } label: {
                HStack {
                    PrivacyRow(
                        icon: "square.and.arrow.down",
                        iconColor: Color.dinkrNavy,
                        title: "Download My Data"
                    )
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        } footer: {
            Text("Request a copy of all your Dinkr data including profile info, game history, and messages.")
        }
    }

    // MARK: - Toast Banner

    private var toastBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.dinkrGreen)
            Text("Your data export is being prepared")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }

    // MARK: - Actions

    private func triggerDataExport() {
        withAnimation {
            showDataToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showDataToast = false
            }
        }
    }
}

// MARK: - PrivacyRow Component

private struct PrivacyRow: View {
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

// MARK: - Supporting Enums

enum ProfileVisibility: String, CaseIterable, Identifiable {
    case public_ = "Public"
    case friendsOnly = "Friends Only"
    case private_ = "Private"

    var id: String { rawValue }
    var label: String { rawValue }

    var footerNote: String {
        switch self {
        case .public_:
            return "Anyone on Dinkr can view your profile, stats, and activity."
        case .friendsOnly:
            return "Only people you follow back can view your full profile."
        case .private_:
            return "Your profile is hidden from search. Only you can see your full profile."
        }
    }
}

enum GameHistoryAudience: String, CaseIterable, Identifiable {
    case everyone = "Everyone"
    case friends = "Friends"
    case onlyMe = "Only Me"

    var id: String { rawValue }
    var label: String { rawValue }
}

enum DataAudience: String, CaseIterable, Identifiable {
    case everyone = "Everyone"
    case friends = "Friends"
    case onlyMe = "Only Me"

    var id: String { rawValue }
    var label: String { rawValue }
}

enum MessagingAudience: String, CaseIterable, Identifiable {
    case everyone = "Everyone"
    case friends = "Friends"
    case nobody = "Nobody"

    var id: String { rawValue }
    var label: String { rawValue }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
}

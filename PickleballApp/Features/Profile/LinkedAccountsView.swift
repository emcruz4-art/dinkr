import SwiftUI

// MARK: - Linked Accounts View

struct LinkedAccountsView: View {

    // MARK: Health / Wearable Toggles
    @AppStorage("linkedAppleHealth") private var appleHealthEnabled: Bool = false
    @AppStorage("linkedAppleWatch")  private var appleWatchEnabled: Bool  = false

    // MARK: Alert State
    @State private var showComingSoonAlert   = false
    @State private var comingSoonPlatform    = ""
    @State private var showDisconnectAlert   = false
    @State private var disconnectPlatform    = ""
    @State private var showUnlinkAlert       = false
    @State private var unlinkPlatform        = ""

    var body: some View {
        List {
            socialAccountsSection
            sportsPlatformsSection
            wearablesSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Linked Accounts")
        .navigationBarTitleDisplayMode(.large)
        // Coming Soon alert
        .alert("Coming Soon", isPresented: $showComingSoonAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Connecting \(comingSoonPlatform) is not yet available. Stay tuned for a future update!")
        }
        // Disconnect confirmation
        .alert("Disconnect \(disconnectPlatform)?", isPresented: $showDisconnectAlert) {
            Button("Disconnect", role: .destructive) {}
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll need to reconnect to use \(disconnectPlatform) features in Dinkr.")
        }
        // Unlink confirmation
        .alert("Unlink \(unlinkPlatform)?", isPresented: $showUnlinkAlert) {
            Button("Unlink", role: .destructive) {}
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your \(unlinkPlatform) data will no longer sync with Dinkr. You can re-link at any time.")
        }
    }

    // MARK: - Social Accounts Section

    private var socialAccountsSection: some View {
        Section {
            // Google — connected
            LinkedAccountRow(
                icon: "globe",
                iconColor: Color.dinkrSky,
                title: "Google",
                status: .connected("evan@gmail.com"),
                actionLabel: "Disconnect"
            ) {
                disconnectPlatform = "Google"
                showDisconnectAlert = true
            }

            // Apple — connected
            LinkedAccountRow(
                icon: "applelogo",
                iconColor: .primary,
                title: "Apple",
                status: .connected(nil),
                actionLabel: "Disconnect"
            ) {
                disconnectPlatform = "Apple"
                showDisconnectAlert = true
            }

            // Facebook — not connected
            LinkedAccountRow(
                icon: "person.crop.circle.badge.plus",
                iconColor: Color(red: 0.23, green: 0.35, blue: 0.60),
                title: "Facebook",
                status: .notConnected,
                actionLabel: "Connect"
            ) {
                comingSoonPlatform = "Facebook"
                showComingSoonAlert = true
            }

            // Instagram — not connected
            LinkedAccountRow(
                icon: "camera.fill",
                iconColor: Color(red: 0.83, green: 0.19, blue: 0.55),
                title: "Instagram",
                status: .notConnected,
                actionLabel: "Connect"
            ) {
                comingSoonPlatform = "Instagram"
                showComingSoonAlert = true
            }
        } header: {
            Text("Social Accounts")
        } footer: {
            Text("Connecting social accounts lets you find friends already on Dinkr.")
        }
    }

    // MARK: - Sports Platforms Section

    private var sportsPlatformsSection: some View {
        Section {
            // DUPR — linked with rating
            DUPRLinkedRow(
                onViewProfile: {
                    comingSoonPlatform = "DUPR Profile"
                    showComingSoonAlert = true
                },
                onUnlink: {
                    unlinkPlatform = "DUPR"
                    showUnlinkAlert = true
                }
            )

            // UTR — not linked
            LinkedPlatformRow(
                icon: "tennisball.fill",
                iconColor: Color.dinkrAmber,
                title: "UTR",
                subtitle: "Universal Tennis Rating",
                isLinked: false,
                actionLabel: "Link Account"
            ) {
                comingSoonPlatform = "UTR"
                showComingSoonAlert = true
            }

            // Pickleheads — not linked
            LinkedPlatformRow(
                icon: "figure.pickleball",
                iconColor: Color.dinkrGreen,
                title: "Pickleheads",
                subtitle: "Court finder & event platform",
                isLinked: false,
                actionLabel: "Link Account"
            ) {
                comingSoonPlatform = "Pickleheads"
                showComingSoonAlert = true
            }
        } header: {
            Text("Sports Platforms")
        } footer: {
            Text("Link your ratings and profiles to display verified stats on your Dinkr profile.")
        }
    }

    // MARK: - Wearables Section

    private var wearablesSection: some View {
        Section {
            Toggle(isOn: $appleHealthEnabled) {
                HStack(spacing: 12) {
                    PlatformIconBox(
                        icon: "heart.fill",
                        iconColor: Color.dinkrCoral,
                        bgColor: Color.dinkrCoral.opacity(0.12)
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Health")
                            .font(.body)
                        Text("Syncs games as workouts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .tint(Color.dinkrGreen)

            Toggle(isOn: $appleWatchEnabled) {
                HStack(spacing: 12) {
                    PlatformIconBox(
                        icon: "applewatch",
                        iconColor: Color.dinkrNavy,
                        bgColor: Color.dinkrNavy.opacity(0.12)
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Watch")
                            .font(.body)
                        Text("Live match tracking on wrist")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .tint(Color.dinkrGreen)
        } header: {
            Text("Wearables")
        } footer: {
            Text("Apple Health and Apple Watch integrations require iOS 17 and watchOS 10 or later.")
        }
    }
}

// MARK: - Connection Status

private enum ConnectionStatus {
    case connected(String?)   // associated value: optional detail string (e.g. email)
    case notConnected
}

// MARK: - Linked Account Row (Social)

private struct LinkedAccountRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let status: ConnectionStatus
    let actionLabel: String
    let action: () -> Void

    private var isConnected: Bool {
        if case .connected = status { return true }
        return false
    }

    private var detailText: String? {
        if case .connected(let detail) = status { return detail }
        return nil
    }

    var body: some View {
        HStack(spacing: 12) {
            PlatformIconBox(
                icon: icon,
                iconColor: iconColor,
                bgColor: iconColor.opacity(0.12)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)

                HStack(spacing: 5) {
                    Circle()
                        .fill(isConnected ? Color.dinkrGreen : Color(.systemGray3))
                        .frame(width: 7, height: 7)

                    if let detail = detailText {
                        Text("Connected as \(detail)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if isConnected {
                        Text("Connected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Not connected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Button(action: action) {
                Text(actionLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isConnected ? Color.dinkrCoral : Color.dinkrGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        (isConnected ? Color.dinkrCoral : Color.dinkrGreen).opacity(0.1),
                        in: Capsule()
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - DUPR Linked Row (special — has badge + two actions)

private struct DUPRLinkedRow: View {
    let onViewProfile: () -> Void
    let onUnlink: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                PlatformIconBox(
                    icon: "chart.bar.fill",
                    iconColor: Color.dinkrSky,
                    bgColor: Color.dinkrSky.opacity(0.12)
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text("DUPR")
                        .font(.body)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.dinkrGreen)
                            .frame(width: 7, height: 7)

                        Text("Linked")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        // Rating badge
                        Text("Rating 3.8")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.dinkrSky)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.dinkrSky.opacity(0.15), in: Capsule())
                            .overlay(Capsule().stroke(Color.dinkrSky.opacity(0.4), lineWidth: 1))
                    }
                }

                Spacer()
            }

            // Action buttons row
            HStack(spacing: 10) {
                Button(action: onViewProfile) {
                    Label("View Profile", systemImage: "arrow.up.right.square")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrSky)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .background(Color.dinkrSky.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.dinkrSky.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button(action: onUnlink) {
                    Label("Unlink", systemImage: "link.badge.minus")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrCoral)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .background(Color.dinkrCoral.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.dinkrCoral.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Generic Platform Row (not linked)

private struct LinkedPlatformRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isLinked: Bool
    let actionLabel: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            PlatformIconBox(
                icon: icon,
                iconColor: iconColor,
                bgColor: iconColor.opacity(0.12)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: action) {
                Text(actionLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isLinked ? Color.dinkrCoral : Color.dinkrGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        (isLinked ? Color.dinkrCoral : Color.dinkrGreen).opacity(0.1),
                        in: Capsule()
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Platform Icon Box (shared helper)

private struct PlatformIconBox: View {
    let icon: String
    let iconColor: Color
    let bgColor: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(bgColor)
                .frame(width: 38, height: 38)
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(iconColor)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LinkedAccountsView()
    }
}

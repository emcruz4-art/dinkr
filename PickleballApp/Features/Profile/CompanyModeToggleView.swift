import SwiftUI

// MARK: - CompanyModeToggleView

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

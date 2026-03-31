import SwiftUI

// MARK: - VerifiedBadgeType

enum VerifiedBadgeType: String, CaseIterable, Identifiable {
    case duprVerified
    case identityVerified
    case topPlayer
    case proPlayer

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .duprVerified:     return "chart.bar.fill"
        case .identityVerified: return "checkmark.seal.fill"
        case .topPlayer:        return "star.fill"
        case .proPlayer:        return "crown.fill"
        }
    }

    var color: Color {
        switch self {
        case .duprVerified:     return Color.dinkrAmber
        case .identityVerified: return Color.dinkrGreen
        case .topPlayer:        return Color.dinkrSky
        case .proPlayer:        return Color.dinkrCoral
        }
    }

    var title: String {
        switch self {
        case .duprVerified:     return "DUPR Verified"
        case .identityVerified: return "Identity Verified"
        case .topPlayer:        return "Top Player"
        case .proPlayer:        return "Pro Player"
        }
    }

    var description: String {
        switch self {
        case .duprVerified:
            return "This player's DUPR rating has been linked and verified directly from their DUPR account."
        case .identityVerified:
            return "This player's identity has been confirmed via a government-issued ID or phone number."
        case .topPlayer:
            return "Ranked in the top 10% of players in their region based on win rate and activity."
        case .proPlayer:
            return "A sponsored or tournament-circuit professional player recognized by Dinkr."
        }
    }
}

// MARK: - Small Inline Badge

struct VerifiedBadgeSmall: View {
    let type: VerifiedBadgeType
    @State private var showTooltip = false

    var body: some View {
        Image(systemName: "checkmark.seal.fill")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(type.color)
            .popover(isPresented: $showTooltip) {
                BadgeTooltipContent(type: type)
                    .padding(16)
                    .presentationCompactAdaptation(.popover)
            }
            .onLongPressGesture(minimumDuration: 0.4) {
                HapticManager.selection()
                showTooltip = true
            }
    }
}

// MARK: - Large Badge Card

struct VerifiedBadgeLarge: View {
    let type: VerifiedBadgeType
    var onViewDetails: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [type.color.opacity(0.22), type.color.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                RoundedRectangle(cornerRadius: 14)
                    .stroke(type.color.opacity(0.35), lineWidth: 1)
                    .frame(width: 56, height: 56)
                Image(systemName: type.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(type.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(type.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Text(type.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if onViewDetails != nil {
                Button("Details") {
                    onViewDetails?()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(type.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(type.color.opacity(0.12), in: Capsule())
                .overlay(Capsule().stroke(type.color.opacity(0.3), lineWidth: 1))
            }
        }
        .padding(14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(type.color.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Tooltip Content

private struct BadgeTooltipContent: View {
    let type: VerifiedBadgeType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(type.color)
                Text(type.title)
                    .font(.subheadline.weight(.bold))
            }
            Text(type.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 240, alignment: .leading)
    }
}

// MARK: - VerifiedBadgeRow

struct VerifiedBadgeRow: View {
    let types: [VerifiedBadgeType]
    @State private var activeBadge: VerifiedBadgeType? = nil

    var body: some View {
        HStack(spacing: 8) {
            ForEach(types) { type in
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(type.color)
                    Text(type.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(type.color)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(type.color.opacity(0.12), in: Capsule())
                .overlay(Capsule().stroke(type.color.opacity(0.3), lineWidth: 1))
                .popover(isPresented: Binding(
                    get: { activeBadge == type },
                    set: { if !$0 { activeBadge = nil } }
                )) {
                    BadgeTooltipContent(type: type)
                        .padding(16)
                        .presentationCompactAdaptation(.popover)
                }
                .onLongPressGesture(minimumDuration: 0.4) {
                    HapticManager.selection()
                    activeBadge = type
                }
            }
        }
    }
}

// MARK: - PlayerNameWithBadges

struct PlayerNameWithBadges: View {
    let name: String
    let verifiedTypes: [VerifiedBadgeType]
    var nameFont: Font = .headline.weight(.semibold)
    var nameColor: Color = Color.primary

    var body: some View {
        HStack(spacing: 5) {
            Text(name)
                .font(nameFont)
                .foregroundStyle(nameColor)
            ForEach(verifiedTypes) { type in
                VerifiedBadgeSmall(type: type)
            }
        }
    }
}

// MARK: - Preview

#Preview("Badge Types") {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            Text("Small Inline Badges")
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: 12) {
                ForEach(VerifiedBadgeType.allCases) { type in
                    VerifiedBadgeSmall(type: type)
                }
            }
            .padding(.horizontal)

            Text("Player Name With Badges")
                .font(.headline)
                .padding(.horizontal)

            PlayerNameWithBadges(
                name: "Alex Rivera",
                verifiedTypes: [.duprVerified, .identityVerified]
            )
            .padding(.horizontal)

            Text("Badge Row")
                .font(.headline)
                .padding(.horizontal)

            VerifiedBadgeRow(types: [.duprVerified, .identityVerified, .topPlayer])
                .padding(.horizontal)

            Text("Large Badge Cards")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(VerifiedBadgeType.allCases) { type in
                    VerifiedBadgeLarge(type: type, onViewDetails: {})
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

import SwiftUI

// MARK: -----------------------------------------------------------------------
// SharedComponents.swift
// Brand-consistent, reusable building blocks for the Dinkr design system.
//
// Inventory of what lives elsewhere (do NOT duplicate):
//   - AvatarView          → AvatarView.swift
//   - SkillBadge          → SkillBadge.swift
//   - EmptyStateView      → PickleballCard.swift
//   - PickleballCard      → PickleballCard.swift  (generic card primitive)
//   - FilterChipRow       → UIComponents.swift
//   - AnimatedCounterView → UIComponents.swift
// MARK: -----------------------------------------------------------------------


// MARK: - DinkrButton
// Three semantic styles: primary (green gradient fill), secondary (outlined),
// destructive (coral fill). Supports a leading SF Symbol icon.

struct DinkrButton: View {
    enum Style {
        case primary
        case secondary
        case destructive
    }

    let title: String
    var icon: String? = nil
    var style: Style = .primary
    var isLoading: Bool = false
    var isFullWidth: Bool = true
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(foregroundColor)
                        .scaleEffect(0.85)
                        .accessibilityLabel("Loading")
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.subheadline.weight(.semibold))
                            .accessibilityHidden(true) // label comes from Text
                    }
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                }
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            // Minimum 44 pt height per Apple HIG tap-target guidelines
            .frame(minHeight: 44)
            .padding(.horizontal, 20)
            .padding(.vertical, 13)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(border)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(isLoading ? "\(title), loading" : title)
        .accessibilityAddTraits(.isButton)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    // MARK: Private styling

    private var foregroundColor: Color {
        switch style {
        case .primary:      return .white
        case .secondary:    return Color.dinkrGreen
        case .destructive:  return .white
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            LinearGradient.dinkrPrimaryGradient
        case .secondary:
            Color.clear
        case .destructive:
            Color.dinkrCoral
        }
    }

    @ViewBuilder
    private var border: some View {
        switch style {
        case .secondary:
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.dinkrGreen, lineWidth: 1.5)
        default:
            EmptyView()
        }
    }
}


// MARK: - DinkrCard
// Semantic card container that wraps any content with consistent elevation,
// corner radius, and subtle border. Builds on the same spec as PickleballCard
// but is named for the design system rather than the legacy sport name.

struct DinkrCard<Content: View>: View {
    var cornerRadius: CGFloat = 16
    var padding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    let content: Content

    init(
        cornerRadius: CGFloat = 16,
        padding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16),
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 4)
            // Card children are individually focusable by default; callers
            // that want a single combined VoiceOver element should apply
            // .accessibilityElement(children: .combine) or one of the
            // .gameCardAccessibility / .playerCardAccessibility modifiers.
    }
}


// MARK: - DinkrSection
// Standardized section header: bold title on the left, optional "See All"
// navigation trigger on the right. Matches the bento-grid Home tab cadence.

struct DinkrSection<Content: View>: View {
    let title: String
    var seeAllLabel: String = "See All"
    var onSeeAll: (() -> Void)? = nil
    let content: Content

    init(
        _ title: String,
        seeAllLabel: String = "See All",
        onSeeAll: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.seeAllLabel = seeAllLabel
        self.onSeeAll = onSeeAll
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.primaryText)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                if let onSeeAll {
                    Button(seeAllLabel, action: onSeeAll)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.dinkrGreen)
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityLabel("\(seeAllLabel) \(title)")
                        .accessibilityAddTraits(.isButton)
                }
            }
            .padding(.horizontal, 16)

            content
        }
    }
}


// MARK: - StatBox
// Compact stat tile: large animated number on top, small label underneath.
// Used in profile summaries, match recaps, and leaderboard headers.

struct StatBox: View {
    let value: String
    let label: String
    var valueColor: Color = Color.dinkrNavy
    var accent: Color = Color.dinkrGreen

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(accent.opacity(0.18), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        // Combine value + label into a single VoiceOver element, e.g. "142 Games Played"
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}


// MARK: - Previews

#Preview("DinkrButton") {
    VStack(spacing: 16) {
        DinkrButton(title: "Find a Game", icon: "figure.pickleball", style: .primary) {}
        DinkrButton(title: "Join DinkrGroup", icon: "person.2", style: .secondary) {}
        DinkrButton(title: "Leave Game", icon: "xmark", style: .destructive) {}
        DinkrButton(title: "Loading…", style: .primary, isLoading: true) {}
        HStack {
            DinkrButton(title: "Cancel", style: .secondary, isFullWidth: false) {}
            DinkrButton(title: "Confirm", style: .primary, isFullWidth: false) {}
        }
    }
    .padding()
}

#Preview("DinkrCard") {
    ScrollView {
        VStack(spacing: 16) {
            DinkrCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Match Result")
                        .font(.headline)
                    Text("You won 11–7, 11–5 against Jordan Kim")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            DinkrCard(cornerRadius: 20, padding: .init(top: 0, leading: 0, bottom: 0, trailing: 0)) {
                LinearGradient.dinkrPrimaryGradient
                    .frame(height: 80)
                    .overlay(
                        Text("Hero Card")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                    )
            }
        }
        .padding()
    }
}

#Preview("DinkrSection") {
    DinkrSection("Nearby Courts", onSeeAll: {}) {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(["Balboa Park", "Mission Bay", "Morley Field"], id: \.self) { court in
                    DinkrCard(padding: .init(top: 12, leading: 14, bottom: 12, trailing: 14)) {
                        Text(court)
                            .font(.subheadline.weight(.medium))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    .padding(.vertical)
}

#Preview("StatBox") {
    HStack(spacing: 10) {
        StatBox(value: "142", label: "Games Played")
        StatBox(value: "3.67", label: "DUPR Rating", accent: Color.dinkrAmber)
        StatBox(value: "68%", label: "Win Rate", valueColor: Color.dinkrGreen, accent: Color.dinkrGreen)
    }
    .padding()
}

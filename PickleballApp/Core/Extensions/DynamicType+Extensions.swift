import SwiftUI

// MARK: -----------------------------------------------------------------------
// DynamicType+Extensions.swift
// Dynamic Type support for the Dinkr design system.
//
// Provides:
//   - scaledValue(_:)          proportional scaling relative to the current
//                               DynamicType size category
//   - isCompactText            true when an accessibility size is active
//   - Named font styles        dinkrTitle, dinkrBody, dinkrCaption, dinkrLabel
//                               that scale with the user's type size preference
// MARK: -----------------------------------------------------------------------


// MARK: - DynamicTypeSize convenience

extension DynamicTypeSize {
    /// Returns `true` for the four largest accessibility sizes (AX3–AX5 and
    /// the extraExtraExtraLarge step that crosses into accessibility territory).
    var isAccessibilitySize: Bool {
        switch self {
        case .accessibility1, .accessibility2, .accessibility3,
             .accessibility4, .accessibility5:
            return true
        default:
            return false
        }
    }

    /// A numeric scale factor relative to the default (.large) size.
    /// Values < 1 shrink at small sizes; values > 1 grow at large/AX sizes.
    var scaleFactor: CGFloat {
        switch self {
        case .xSmall:         return 0.80
        case .small:          return 0.88
        case .medium:         return 0.94
        case .large:          return 1.00   // system default
        case .xLarge:         return 1.06
        case .xxLarge:        return 1.13
        case .xxxLarge:       return 1.22
        case .accessibility1: return 1.35
        case .accessibility2: return 1.50
        case .accessibility3: return 1.70
        case .accessibility4: return 1.90
        case .accessibility5: return 2.10
        @unknown default:     return 1.00
        }
    }
}


// MARK: - Environment-aware scaling helper

extension View {
    /// Scales `base` proportionally to the user's current DynamicType size.
    ///
    /// Inject using `@Environment(\.dynamicTypeSize)` at the call site, or
    /// use the `scaledValue(_:dynamicTypeSize:)` free function.
    ///
    /// Usage inside a view:
    /// ```swift
    /// @Environment(\.dynamicTypeSize) private var typeSize
    /// var body: some View {
    ///     Circle().frame(width: typeSize.scaledValue(48))
    /// }
    /// ```
}

extension DynamicTypeSize {
    /// Returns `base` scaled to this DynamicType size category.
    func scaledValue(_ base: CGFloat) -> CGFloat {
        base * scaleFactor
    }
}

/// Convenience free function — usable anywhere without an environment lookup.
func scaledValue(_ base: CGFloat, dynamicTypeSize: DynamicTypeSize) -> CGFloat {
    dynamicTypeSize.scaledValue(base)
}


// MARK: - isCompactText environment helper
// A ViewModifier that surfaces a Bool preference for adaptive layouts.
// Use `@Environment(\.isCompactText)` after applying `.dynamicTypeAware()`.

private struct IsCompactTextKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// `true` when the active DynamicType size is an accessibility category.
    /// Propagated automatically by `DynamicTypeAwareModifier`.
    var isCompactText: Bool {
        get { self[IsCompactTextKey.self] }
        set { self[IsCompactTextKey.self] = newValue }
    }
}

private struct DynamicTypeAwareModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) private var typeSize

    func body(content: Content) -> some View {
        content
            .environment(\.isCompactText, typeSize.isAccessibilitySize)
    }
}

extension View {
    /// Propagates `isCompactText` into the environment so child views can
    /// branch their layout for accessibility type sizes.
    ///
    /// Apply once near the root of a screen or scroll view:
    /// ```swift
    /// MyContentView()
    ///     .dynamicTypeAware()
    /// ```
    func dynamicTypeAware() -> some View {
        modifier(DynamicTypeAwareModifier())
    }
}


// MARK: - Named font styles (Dinkr design system)
// All styles use `.body`-relative scaling via the system's built-in
// `Font.TextStyle` engine, so they respect the user's preferred text size
// automatically. Custom weight and design attributes are layered on top.

extension Font {
    // MARK: Display

    /// Hero numbers, court names on full-bleed cards — bold, large.
    static var dinkrDisplay: Font {
        .system(.largeTitle, design: .rounded, weight: .black)
    }

    // MARK: Titles

    /// Screen/section title — equivalent to `.title2`, rounded, bold.
    static var dinkrTitle: Font {
        .system(.title2, design: .rounded, weight: .bold)
    }

    /// Sub-section heading — equivalent to `.title3`, semibold.
    static var dinkrSubtitle: Font {
        .system(.title3, design: .rounded, weight: .semibold)
    }

    // MARK: Body

    /// Default reading size — `.body`, regular weight.
    static var dinkrBody: Font {
        .system(.body, design: .default, weight: .regular)
    }

    /// Emphasised body — `.body`, medium weight. Use for usernames, stat values.
    static var dinkrBodyMedium: Font {
        .system(.body, design: .default, weight: .medium)
    }

    // MARK: Labels

    /// Card and form labels — `.subheadline`, semibold.
    static var dinkrLabel: Font {
        .system(.subheadline, design: .default, weight: .semibold)
    }

    /// Secondary label — `.footnote`, medium weight. Use for metadata rows.
    static var dinkrLabelSecondary: Font {
        .system(.footnote, design: .default, weight: .medium)
    }

    // MARK: Captions

    /// Timestamps, status chips — `.caption`, regular weight.
    static var dinkrCaption: Font {
        .system(.caption, design: .default, weight: .regular)
    }

    /// Emphasised caption — `.caption`, semibold. Use for badge text, tags.
    static var dinkrCaptionBold: Font {
        .system(.caption, design: .default, weight: .semibold)
    }

    // MARK: Numeric / Monospaced

    /// Scores, ratings, counters — monospaced digits, rounded design.
    static var dinkrNumeric: Font {
        .system(.title2, design: .rounded, weight: .bold)
            .monospacedDigit()
    }

    /// Small numeric values in stat boxes.
    static var dinkrNumericSmall: Font {
        .system(.subheadline, design: .rounded, weight: .semibold)
            .monospacedDigit()
    }
}


// MARK: - Adaptive layout helpers (ViewModifier)

/// Switches between a single-column (stacked) and multi-column layout
/// based on whether an accessibility DynamicType size is active.
struct AdaptiveStack<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    var spacing: CGFloat = 8
    var alignment: HorizontalAlignment = .leading
    let content: Content

    init(
        spacing: CGFloat = 8,
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.alignment = alignment
        self.content = content()
    }

    var body: some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: alignment, spacing: spacing) {
                content
            }
        } else {
            HStack(spacing: spacing) {
                content
            }
        }
    }
}


// MARK: - Minimum tap target enforcer

extension View {
    /// Ensures the view has at least a 44×44 pt tap target as required by
    /// Apple's Human Interface Guidelines, without affecting visual size.
    func minimumTapTarget() -> some View {
        self.frame(minWidth: 44, minHeight: 44)
    }
}

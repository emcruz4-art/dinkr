import SwiftUI

// MARK: -----------------------------------------------------------------------
// Accessibility+Extensions.swift
// App-wide accessibility helpers: VoiceOver labels, semantic traits, and
// WCAG contrast utilities for the Dinkr design system.
// MARK: -----------------------------------------------------------------------


// MARK: - DinkrAccessibleModifier
// ViewModifier that sets .accessibilityLabel and an optional .accessibilityHint
// on any view. Use `.dinkrAccessible(label:hint:)` on call sites.

private struct DinkrAccessibleModifier: ViewModifier {
    let label: String
    let hint: String?

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .if(hint != nil) { view in
                view.accessibilityHint(hint!)
            }
    }
}

extension View {
    /// Attaches a VoiceOver label and optional hint to any view.
    ///
    /// Usage:
    /// ```swift
    /// Image(systemName: "star.fill")
    ///     .dinkrAccessible(label: "Favorite", hint: "Double-tap to toggle")
    /// ```
    func dinkrAccessible(label: String, hint: String? = nil) -> some View {
        modifier(DinkrAccessibleModifier(label: label, hint: hint))
    }
}


// MARK: - Game Card Accessibility
// Produces a rich, single VoiceOver utterance describing a GameSession card.
// Applied to the container view so `children: .combine` is not needed on
// inner elements — this modifier handles the combined description itself.

extension View {
    /// Attaches a comprehensive VoiceOver description to a game session card.
    ///
    /// Example output:
    /// "Doubles game at Westside Pickleball Complex, hosted by Maria Chen.
    ///  Skill range 3.0 to 3.5. 2 of 4 spots filled. Starts in 2 hours.
    ///  Free. Public game."
    func gameCardAccessibility(session: GameSession) -> some View {
        let dateFormatter = RelativeDateTimeFormatter()
        dateFormatter.unitsStyle = .full
        let relativeDate = dateFormatter.localizedString(
            for: session.dateTime, relativeTo: Date()
        )

        let spotsLabel: String
        if session.isFull {
            spotsLabel = "Full — \(session.totalSpots) of \(session.totalSpots) spots filled"
        } else {
            spotsLabel = "\(session.rsvps.count) of \(session.totalSpots) spots filled, \(session.spotsRemaining) remaining"
        }

        let feeLabel: String
        if let fee = session.fee, fee > 0 {
            feeLabel = String(format: "$%.0f fee", fee)
        } else {
            feeLabel = "Free"
        }

        let visibilityLabel = session.isPublic ? "Public game" : "Private game"

        let liveLabel: String
        if let live = session.liveScore, !live.isComplete {
            liveLabel = "Live score: \(live.teamAName) \(live.scoreA), \(live.teamBName) \(live.scoreB)."
        } else if let live = session.liveScore, live.isComplete {
            liveLabel = "Completed. Final score: \(live.teamAName) \(live.scoreA), \(live.teamBName) \(live.scoreB)."
        } else {
            liveLabel = ""
        }

        let combinedLabel = [
            "\(session.format.displayLabel) game at \(session.courtName)",
            "hosted by \(session.hostName)",
            "Skill range \(session.skillRange.lowerBound.label) to \(session.skillRange.upperBound.label)",
            spotsLabel,
            "Starts \(relativeDate)",
            feeLabel,
            visibilityLabel,
            liveLabel
        ]
        .filter { !$0.isEmpty }
        .joined(separator: ". ")

        let hint = session.isFull
            ? "Join waitlist — double-tap to view details"
            : "Double-tap to RSVP or view details"

        return self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(combinedLabel)
            .accessibilityHint(hint)
            .accessibilityAddTraits(.isButton)
    }
}


// MARK: - Player Card Accessibility
// Produces a single VoiceOver utterance describing a User player card.

extension View {
    /// Attaches a comprehensive VoiceOver description to a player card.
    ///
    /// Example output:
    /// "Maria Chen, username maria_plays. Skill level 3.5. Austin, TX.
    ///  142 games played, 68% win rate. DUPR 4.69. Reliability 4.8 out of 5."
    func playerCardAccessibility(user: User) -> some View {
        let winRatePercent = Int(user.winRate * 100)

        var parts: [String] = [
            "\(user.displayName), username \(user.username)",
            "Skill level \(user.skillLevel.label)",
            user.city
        ]

        if user.gamesPlayed > 0 {
            parts.append("\(user.gamesPlayed) games played, \(winRatePercent)% win rate")
        }

        if let dupr = user.duprRating {
            parts.append(String(format: "DUPR rating %.2f", dupr))
        }

        parts.append(String(format: "Reliability score %.1f out of 5", user.reliabilityScore))

        if user.isPrivate {
            parts.append("Private profile")
        }

        if user.isWomenOnly {
            parts.append("Women's game preference")
        }

        if let style = user.playStyle {
            parts.append("\(style.rawValue) play style")
        }

        let combinedLabel = parts.joined(separator: ". ")

        return self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(combinedLabel)
            .accessibilityHint("Double-tap to view \(user.displayName)'s profile")
            .accessibilityAddTraits(.isButton)
    }
}


// MARK: - Color Contrast Utilities
// WCAG 2.1 AA requires a 4.5:1 contrast ratio for normal text.
// This extension picks white or a dark navy foreground depending on which
// achieves the required ratio against the supplied background color.

extension Color {
    /// Returns either white or `Color.dinkrNavy` — whichever achieves at
    /// least a 4.5:1 WCAG AA contrast ratio against `background`.
    ///
    /// The calculation converts both colors to their relative luminance
    /// values (sRGB linearised) then applies the WCAG contrast formula.
    ///
    /// Usage:
    /// ```swift
    /// Text("Label")
    ///     .foregroundStyle(Color.dinkrGreen.accessibleForeground(on: .dinkrGreen))
    /// ```
    func accessibleForeground(on background: Color) -> Color {
        // Resolve the background to sRGB components.
        let bgComponents = background.resolvedRGBComponents()
        let fgWhiteComponents = Color.white.resolvedRGBComponents()
        let fgNavyComponents = Color.dinkrNavy.resolvedRGBComponents()

        let bgLuminance = relativeLuminance(r: bgComponents.r, g: bgComponents.g, b: bgComponents.b)
        let whiteLuminance = relativeLuminance(r: fgWhiteComponents.r, g: fgWhiteComponents.g, b: fgWhiteComponents.b)
        let navyLuminance = relativeLuminance(r: fgNavyComponents.r, g: fgNavyComponents.g, b: fgNavyComponents.b)

        let whiteContrast = contrastRatio(l1: whiteLuminance, l2: bgLuminance)
        let navyContrast = contrastRatio(l1: navyLuminance, l2: bgLuminance)

        // Prefer white; fall back to navy if navy achieves better contrast.
        // Either way, always return the option that clears the 4.5:1 threshold
        // when possible.
        if whiteContrast >= 4.5 {
            return .white
        } else if navyContrast >= 4.5 {
            return Color.dinkrNavy
        } else {
            // Neither clears 4.5:1 — return whichever is higher contrast.
            return whiteContrast >= navyContrast ? .white : Color.dinkrNavy
        }
    }

    // MARK: Private helpers

    /// Decomposes the color into (r, g, b) components in [0, 1].
    /// Falls back to opaque black on platforms where UIColor resolution fails.
    fileprivate func resolvedRGBComponents() -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b)
    }

    /// WCAG relative luminance of a linearised sRGB triplet.
    private func relativeLuminance(r: CGFloat, g: CGFloat, b: CGFloat) -> CGFloat {
        func linearise(_ channel: CGFloat) -> CGFloat {
            channel <= 0.04045
                ? channel / 12.92
                : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearise(r)
             + 0.7152 * linearise(g)
             + 0.0722 * linearise(b)
    }

    /// WCAG contrast ratio between two relative luminance values.
    private func contrastRatio(l1: CGFloat, l2: CGFloat) -> CGFloat {
        let lighter = max(l1, l2)
        let darker  = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }
}


// MARK: - Accessibility Convenience Traits

extension View {
    /// Marks the view as a header for screen reader navigation.
    func accessibilityHeading() -> some View {
        self.accessibilityAddTraits(.isHeader)
    }

    /// Marks the view as a static image (decorative) — hidden from VoiceOver.
    func accessibilityDecorativeImage() -> some View {
        self.accessibilityHidden(true)
    }

    /// Ensures any icon-only button or image button is announced by VoiceOver.
    func iconButtonAccessibility(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .if(hint != nil) { v in v.accessibilityHint(hint!) }
            .accessibilityAddTraits(.isButton)
            .frame(minWidth: 44, minHeight: 44)
    }
}

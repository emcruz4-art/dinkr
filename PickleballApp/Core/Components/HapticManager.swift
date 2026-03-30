import UIKit

// MARK: - HapticManager
//
// Centralised haptic feedback. All methods are static so callers never
// need to retain an instance. Each call lazily allocates, triggers, and
// discards the appropriate UIKit feedback generator.

enum HapticManager {

    // MARK: Impact Feedbacks

    /// Soft, brief tap — ideal for toggles, minor selections.
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Mid-weight tap — general button presses, list row selections.
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Strong, solid thud — destructive actions, drag completions.
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Gentle, springy feel — sheet appearances, smooth transitions.
    static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Crisp, firm click — confirmations, snapping into place.
    static func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: Notification Feedbacks

    /// Three-pulse success pattern — RSVP confirmed, listing saved, challenge complete.
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// Two-pulse caution pattern — form validation warnings, near-full courts.
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    /// Sharp error pattern — failed action, network error, invalid input.
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }

    // MARK: Selection Feedback

    /// Subtle tick — picker wheels, segmented control changes, tab switches.
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

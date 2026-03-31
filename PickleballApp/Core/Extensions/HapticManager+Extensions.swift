import UIKit
import CoreHaptics

// MARK: -----------------------------------------------------------------------
// HapticManager+Extensions.swift
// Convenience API additions for HapticManager.
//
// HapticManager already provides:
//   light(), medium(), heavy(), soft(), rigid()
//   success(), warning(), error(), selection()
//
// This file adds:
//   - impact(_ style:)        unified impact entry point with UIImpactFeedbackGenerator.FeedbackStyle
//   - notification(_ type:)   unified notification entry point with UINotificationFeedbackGenerator.FeedbackType
//   - isHapticsAvailable      guard for devices/simulators without haptic hardware
// MARK: -----------------------------------------------------------------------

extension HapticManager {

    // MARK: - Hardware availability guard

    /// `true` when the device can produce haptic feedback.
    ///
    /// UIKit feedback generators silently no-op on hardware that doesn't
    /// support haptics (e.g. older iPads, the Simulator), so this flag is
    /// informational rather than a hard gate. Use it for UI decisions such
    /// as disabling a "Haptic Feedback" toggle in Settings.
    @available(iOS 13.0, *)
    static var isHapticsAvailable: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    // MARK: - Unified impact(_:) entry point

    /// Triggers an impact haptic with the given UIKit feedback style.
    ///
    /// Prefer the named helpers (`HapticManager.light()`, `.medium()`, etc.)
    /// when the style is known at compile time. Use this variant when the
    /// style is determined at runtime (e.g. from a user preference).
    ///
    /// ```swift
    /// HapticManager.impact(.light)
    /// HapticManager.impact(.medium)
    /// HapticManager.impact(.heavy)
    /// HapticManager.impact(.soft)
    /// HapticManager.impact(.rigid)
    /// ```
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        if #available(iOS 13.0, *) {
            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - Unified notification(_:) entry point

    /// Triggers a notification haptic with the given UIKit feedback type.
    ///
    /// Prefer the named helpers (`HapticManager.success()`, `.warning()`,
    /// `.error()`) when the type is known at compile time.
    ///
    /// ```swift
    /// HapticManager.notification(.success)
    /// HapticManager.notification(.warning)
    /// HapticManager.notification(.error)
    /// ```
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        if #available(iOS 13.0, *) {
            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

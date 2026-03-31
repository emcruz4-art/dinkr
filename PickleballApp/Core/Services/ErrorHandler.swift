import SwiftUI
import Observation

// MARK: - DinkrError

/// Typed error domain for Dinkr operations.
/// Each case maps to a user-facing title and a suggested SF Symbol.
enum DinkrError: LocalizedError {
    case networkError(String)
    case authError(String)
    case dataError(String)
    case permissionError(String)
    case unknown(String)

    // MARK: LocalizedError

    var errorDescription: String? {
        switch self {
        case .networkError(let msg):    return msg
        case .authError(let msg):       return msg
        case .dataError(let msg):       return msg
        case .permissionError(let msg): return msg
        case .unknown(let msg):         return msg
        }
    }

    // MARK: Derived metadata

    var title: String {
        switch self {
        case .networkError:    return "Connection Problem"
        case .authError:       return "Authentication Error"
        case .dataError:       return "Data Error"
        case .permissionError: return "Permission Denied"
        case .unknown:         return "Something Went Wrong"
        }
    }

    var symbolName: String {
        switch self {
        case .networkError:    return "wifi.slash"
        case .authError:       return "lock.shield"
        case .dataError:       return "exclamationmark.triangle"
        case .permissionError: return "hand.raised.slash"
        case .unknown:         return "exclamationmark.circle"
        }
    }

    var accentColor: Color {
        switch self {
        case .networkError:    return Color.dinkrSky
        case .authError:       return Color.dinkrAmber
        case .dataError:       return Color.dinkrCoral
        case .permissionError: return Color.dinkrCoral
        case .unknown:         return Color.dinkrCoral
        }
    }

    // MARK: - Convenience factory from any Error

    static func from(_ error: Error, context: String = "") -> DinkrError {
        if let dinkrError = error as? DinkrError {
            return dinkrError
        }
        let message = error.localizedDescription
        let lower = message.lowercased() + context.lowercased()

        if lower.contains("network") || lower.contains("internet") ||
           lower.contains("offline") || lower.contains("connection") ||
           lower.contains("timeout") {
            return .networkError(message)
        } else if lower.contains("auth") || lower.contains("credential") ||
                  lower.contains("sign in") || lower.contains("token") ||
                  lower.contains("unauthenticated") {
            return .authError(message)
        } else if lower.contains("permission") || lower.contains("denied") ||
                  lower.contains("forbidden") || lower.contains("unauthorized") {
            return .permissionError(message)
        } else if lower.contains("data") || lower.contains("decode") ||
                  lower.contains("parse") || lower.contains("firestore") {
            return .dataError(message)
        } else {
            return .unknown(message.isEmpty ? "An unexpected error occurred." : message)
        }
    }
}

// MARK: - AlertItem

/// Value type passed to SwiftUI's `.alert` via `ErrorHandler`.
struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let symbolName: String
    let accentColor: Color
    var dismissLabel: String = "OK"
    var dismissAction: (() -> Void)?
}

// MARK: - ErrorHandler (singleton, @Observable)

/// Central error handling service.
///
/// Usage — in a view model:
/// ```swift
/// do {
///     try await someService.fetch()
/// } catch {
///     ErrorHandler.shared.handleError(error, context: "loading games")
/// }
/// ```
///
/// Usage — in a view:
/// ```swift
/// .errorHandling()
/// ```
@Observable
final class ErrorHandler {

    // MARK: Singleton

    static let shared = ErrorHandler()
    private init() {}

    // MARK: State

    /// Set to a non-nil value whenever an alert should be presented.
    /// Automatically cleared when the user dismisses the alert via `.errorHandling()`.
    var currentAlert: AlertItem? = nil

    // MARK: - Public API

    /// Classifies `error` into a `DinkrError`, logs the context, and surfaces an alert.
    func handleError(_ error: Error, context: String = "") {
        let typed = DinkrError.from(error, context: context)
        logError(typed, context: context)
        showAlert(
            title: typed.title,
            message: typed.errorDescription ?? "An unexpected error occurred.",
            symbolName: typed.symbolName,
            accentColor: typed.accentColor
        )
    }

    /// Presents a fully custom alert without going through error classification.
    func presentAlert(
        title: String,
        message: String,
        symbolName: String = "exclamationmark.circle",
        accentColor: Color = Color.dinkrCoral,
        dismissLabel: String = "OK",
        dismissAction: (() -> Void)? = nil
    ) {
        currentAlert = AlertItem(
            title: title,
            message: message,
            symbolName: symbolName,
            accentColor: accentColor,
            dismissLabel: dismissLabel,
            dismissAction: dismissAction
        )
    }

    /// Clears the current alert without running its dismiss action.
    func clearAlert() {
        currentAlert = nil
    }

    // MARK: - Typed convenience helpers

    func handleNetworkError(_ message: String = "Check your internet connection and try again.") {
        let error = DinkrError.networkError(message)
        showAlert(
            title: error.title,
            message: message,
            symbolName: error.symbolName,
            accentColor: error.accentColor
        )
    }

    func handleAuthError(_ message: String = "Please sign in again to continue.") {
        let error = DinkrError.authError(message)
        showAlert(
            title: error.title,
            message: message,
            symbolName: error.symbolName,
            accentColor: error.accentColor
        )
    }

    func handleDataError(_ message: String = "There was a problem loading your data.") {
        let error = DinkrError.dataError(message)
        showAlert(
            title: error.title,
            message: message,
            symbolName: error.symbolName,
            accentColor: error.accentColor
        )
    }

    func handlePermissionError(_ message: String = "You don't have permission to do that.") {
        let error = DinkrError.permissionError(message)
        showAlert(
            title: error.title,
            message: message,
            symbolName: error.symbolName,
            accentColor: error.accentColor
        )
    }

    // MARK: - Private helpers

    private func showAlert(
        title: String,
        message: String,
        symbolName: String,
        accentColor: Color,
        dismissLabel: String = "OK",
        dismissAction: (() -> Void)? = nil
    ) {
        // Ensure UI updates happen on the main actor
        Task { @MainActor in
            self.currentAlert = AlertItem(
                title: title,
                message: message,
                symbolName: symbolName,
                accentColor: accentColor,
                dismissLabel: dismissLabel,
                dismissAction: dismissAction
            )
        }
    }

    private func logError(_ error: DinkrError, context: String) {
        #if DEBUG
        let ctx = context.isEmpty ? "unknown context" : context
        print("[ErrorHandler] \(error.title) in \(ctx): \(error.errorDescription ?? "-")")
        #endif
    }
}

// MARK: - ErrorHandlingModifier

/// Attaches an alert driven by `ErrorHandler.shared.currentAlert` to any view.
struct ErrorHandlingModifier: ViewModifier {
    // Observe the shared singleton so SwiftUI re-renders on changes.
    @State private var errorHandler = ErrorHandler.shared

    func body(content: Content) -> some View {
        content
            .alert(
                errorHandler.currentAlert?.title ?? "",
                isPresented: Binding(
                    get: { errorHandler.currentAlert != nil },
                    set: { if !$0 { errorHandler.clearAlert() } }
                ),
                presenting: errorHandler.currentAlert
            ) { item in
                Button(item.dismissLabel) {
                    item.dismissAction?()
                    errorHandler.clearAlert()
                }
            } message: { item in
                VStack {
                    Text(item.message)
                }
            }
    }
}

extension View {
    /// Wires `ErrorHandler.shared` alerts to this view.
    /// Attach once at the root (e.g. `RootTabView`) so all children can call
    /// `ErrorHandler.shared.handleError(_:context:)` without needing a local sheet.
    func errorHandling() -> some View {
        modifier(ErrorHandlingModifier())
    }
}

// MARK: - Preview

#Preview("ErrorHandler Alerts") {
    VStack(spacing: 16) {
        Button("Network Error") {
            ErrorHandler.shared.handleNetworkError()
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.dinkrSky)

        Button("Auth Error") {
            ErrorHandler.shared.handleAuthError()
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.dinkrAmber)

        Button("Data Error") {
            ErrorHandler.shared.handleDataError()
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.dinkrCoral)

        Button("Permission Error") {
            ErrorHandler.shared.handlePermissionError()
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.dinkrNavy)

        Button("Custom Alert") {
            ErrorHandler.shared.presentAlert(
                title: "Game Full",
                message: "This game has reached its player limit. Check back later or start your own.",
                symbolName: "person.crop.circle.badge.xmark",
                accentColor: Color.dinkrGreen,
                dismissLabel: "Got It"
            )
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.dinkrGreen)
    }
    .padding()
    .errorHandling()
}

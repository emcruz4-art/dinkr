import SwiftUI

// MARK: - LoadingButton

/// A button that swaps its label for an inline spinner while `isLoading` is true.
/// Becomes disabled and dims during loading to prevent double-taps.
struct LoadingButton<Label: View>: View {
    @Binding var isLoading: Bool
    let action: () -> Void
    let label: () -> Label

    init(
        isLoading: Binding<Bool>,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self._isLoading = isLoading
        self.action = action
        self.label = label
    }

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                // Keep layout stable while spinner is visible
                label().opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.85)
                }
            }
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.65 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

// MARK: - LoadingOverlay

/// A full-screen dimmed overlay with a centred card, spinner and message.
/// Apply via the `.loadingOverlay(isLoading:message:)` modifier.
struct LoadingOverlayView: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.dinkrGreen)
                    .scaleEffect(1.3)

                if !message.isEmpty {
                    Text(message)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.primaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.cardBackground)
                    .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 8)
            )
        }
    }
}

struct LoadingOverlayModifier: ViewModifier {
    @Binding var isLoading: Bool
    var message: String

    func body(content: Content) -> some View {
        ZStack {
            content
            if isLoading {
                LoadingOverlayView(message: message)
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

extension View {
    /// Overlays a dimmed spinner card while `isLoading` is true.
    func loadingOverlay(isLoading: Binding<Bool>, message: String = "") -> some View {
        modifier(LoadingOverlayModifier(isLoading: isLoading, message: message))
    }
}

// MARK: - NetworkErrorView

/// Categorised error states each mapped to an appropriate SF Symbol.
enum NetworkErrorType {
    case network       // no connectivity
    case server        // backend / HTTP error
    case generic       // unknown / catchall
    case permission    // auth / permission denied

    var symbolName: String {
        switch self {
        case .network:    return "wifi.slash"
        case .server:     return "server.rack"
        case .generic:    return "exclamationmark.triangle"
        case .permission: return "lock.shield"
        }
    }

    var defaultTitle: String {
        switch self {
        case .network:    return "No Connection"
        case .server:     return "Server Error"
        case .generic:    return "Something Went Wrong"
        case .permission: return "Access Denied"
        }
    }
}

/// A standalone error-state card with icon, message and retry button.
struct NetworkErrorView: View {
    var errorType: NetworkErrorType = .generic
    var message: String
    var onRetry: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: errorType.symbolName)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Color.dinkrCoral)

            VStack(spacing: 6) {
                Text(errorType.defaultTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.primaryText)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let onRetry {
                Button {
                    onRetry()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 11)
                    .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.dinkrCoral.opacity(0.25), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - NetworkErrorView + ViewModifier

struct NetworkErrorModifier: ViewModifier {
    var error: Error?
    var errorType: NetworkErrorType
    var onRetry: () -> Void

    func body(content: Content) -> some View {
        ZStack {
            content
            if let error {
                NetworkErrorView(
                    errorType: errorType,
                    message: error.localizedDescription,
                    onRetry: onRetry
                )
                .padding(.horizontal, 24)
                .transition(.opacity.combined(with: .scale(scale: 0.96))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: error != nil)
    }
}

extension View {
    /// Overlays a `NetworkErrorView` card whenever `error` is non-nil.
    /// - Parameters:
    ///   - error: The current error to display. Pass `nil` to hide the overlay.
    ///   - errorType: Determines the SF Symbol and title. Defaults to `.generic`.
    ///   - onRetry: Called when the user taps "Try Again".
    func networkError(
        _ error: Error?,
        errorType: NetworkErrorType = .generic,
        onRetry: @escaping () -> Void
    ) -> some View {
        modifier(NetworkErrorModifier(error: error, errorType: errorType, onRetry: onRetry))
    }
}

// MARK: - SkeletonLoadingModifier

/// Dims the view and applies the shimmer from `SkeletonViews.swift` while loading.
struct SkeletonLoadingModifier: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        content
            .redacted(reason: isLoading ? .placeholder : [])
            .overlay {
                if isLoading {
                    // Reuse the shimmer animation defined in SkeletonViews.swift
                    Color(UIColor.systemGray5)
                        .opacity(0.6)
                        .shimmer()
                }
            }
            .allowsHitTesting(!isLoading)
            .animation(.easeInOut(duration: 0.25), value: isLoading)
    }
}

extension View {
    /// Applies a shimmer placeholder while `isLoading` is true.
    /// Relies on `shimmer()` defined in `SkeletonViews.swift`.
    func skeletonLoading(isLoading: Bool) -> some View {
        modifier(SkeletonLoadingModifier(isLoading: isLoading))
    }
}

// MARK: - RefreshableScrollView

/// A `ScrollView` wrapper with:
/// - Standard `refreshable` pull-to-refresh wired to a `dinkrGreen` tint
/// - An optional "Last updated X min ago" subtitle below the content
struct RefreshableScrollView<Content: View>: View {
    var lastUpdated: Date?
    let onRefresh: () async -> Void
    let content: () -> Content

    @State private var currentTime = Date.now
    // Drives the clock subtitle — ticks every 30 s so the relative label stays fresh.
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    init(
        lastUpdated: Date? = nil,
        onRefresh: @escaping () async -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.lastUpdated = lastUpdated
        self.onRefresh = onRefresh
        self.content = content
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // "Last updated" subtitle
                if let lastUpdated {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption2)
                        Text(relativeLabel(for: lastUpdated))
                            .font(.caption)
                    }
                    .foregroundStyle(Color.dinkrGreen.opacity(0.8))
                    .padding(.top, 8)
                    .padding(.bottom, 2)
                    .onReceive(timer) { _ in currentTime = .now }
                }

                content()
            }
        }
        .tint(Color.dinkrGreen)         // colours the default PTR spinner
        .refreshable {
            await onRefresh()
        }
    }

    private func relativeLabel(for date: Date) -> String {
        let minutes = Int(currentTime.timeIntervalSince(date) / 60)
        switch minutes {
        case 0:       return "Updated just now"
        case 1:       return "Updated 1 min ago"
        case 2...59:  return "Updated \(minutes) min ago"
        default:
            let hours = minutes / 60
            return hours == 1 ? "Updated 1 hr ago" : "Updated \(hours) hrs ago"
        }
    }
}

// MARK: - Preview

#Preview("LoadingButton") {
    @Previewable @State var loading = false
    VStack(spacing: 20) {
        LoadingButton(isLoading: $loading) {
            loading = true
            Task {
                try? await Task.sleep(for: .seconds(2))
                loading = false
            }
        } label: {
            Text("Find a Game")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 12))
        }

        LoadingButton(isLoading: .constant(true)) {} label: {
            Text("Joining...")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.dinkrNavy, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    .padding()
}

#Preview("LoadingOverlay") {
    @Previewable @State var isLoading = true
    ZStack {
        Color(UIColor.systemGroupedBackground).ignoresSafeArea()
        VStack { Text("Content beneath") }
    }
    .loadingOverlay(isLoading: $isLoading, message: "Finding games...")
}

#Preview("NetworkErrorView") {
    ScrollView {
        VStack(spacing: 20) {
            NetworkErrorView(
                errorType: .network,
                message: "Please check your internet connection and try again.",
                onRetry: {}
            )
            NetworkErrorView(
                errorType: .server,
                message: "Our servers are taking a breather. Hold tight.",
                onRetry: {}
            )
            NetworkErrorView(
                errorType: .permission,
                message: "You don't have permission to view this content."
            )
        }
        .padding()
    }
    .background(Color(UIColor.systemGroupedBackground))
}

#Preview("SkeletonLoading") {
    VStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.cardBackground)
            .frame(height: 80)
            .skeletonLoading(isLoading: true)

        RoundedRectangle(cornerRadius: 8)
            .fill(Color.cardBackground)
            .frame(height: 40)
            .skeletonLoading(isLoading: false)
    }
    .padding()
}

#Preview("RefreshableScrollView") {
    RefreshableScrollView(lastUpdated: Date(timeIntervalSinceNow: -125)) {
        try? await Task.sleep(for: .seconds(1))
    } content: {
        VStack(spacing: 12) {
            ForEach(0..<8, id: \.self) { i in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
                    .frame(height: 70)
                    .overlay(Text("Row \(i + 1)").foregroundStyle(.secondary))
            }
        }
        .padding()
    }
}

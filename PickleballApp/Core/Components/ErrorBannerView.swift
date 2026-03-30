import SwiftUI

// MARK: - ErrorBanner Model

struct ErrorBanner: Equatable {
    var message: String
    var type: BannerType
    var duration: Double = 3.0

    enum BannerType {
        case error
        case warning
        case success
        case info

        var backgroundColor: Color {
            switch self {
            case .error:   return Color.dinkrCoral
            case .warning: return Color.dinkrAmber
            case .success: return Color.dinkrGreen
            case .info:    return Color.dinkrSky
            }
        }

        var foregroundColor: Color {
            switch self {
            case .error:   return .white
            case .warning: return .black.opacity(0.85)
            case .success: return .white
            case .info:    return .white
            }
        }

        var iconName: String {
            switch self {
            case .error:   return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .success: return "checkmark.circle.fill"
            case .info:    return "info.circle.fill"
            }
        }
    }
}

// MARK: - ErrorBannerView

struct ErrorBannerView: View {
    @Binding var banner: ErrorBanner?
    @State private var hideTask: Task<Void, Never>? = nil

    var body: some View {
        VStack {
            if let current = banner {
                pill(for: current)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onTapGesture {
                        dismiss()
                    }
                    .onAppear {
                        scheduleAutoDismiss(after: current.duration)
                    }
                    .onChange(of: current) { _, newBanner in
                        scheduleAutoDismiss(after: newBanner.duration)
                    }
            }
            Spacer()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: banner)
        .padding(.top, 8)
    }

    private func pill(for current: ErrorBanner) -> some View {
        HStack(spacing: 8) {
            Image(systemName: current.type.iconName)
                .font(.system(size: 14, weight: .semibold))
            Text(current.message)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .foregroundStyle(current.type.foregroundColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(current.type.backgroundColor)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }

    private func dismiss() {
        hideTask?.cancel()
        withAnimation {
            banner = nil
        }
    }

    private func scheduleAutoDismiss(after duration: Double) {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            if !Task.isCancelled {
                withAnimation {
                    banner = nil
                }
            }
        }
    }
}

// MARK: - BannerManager

@Observable
final class BannerManager {
    static let shared = BannerManager()
    var currentBanner: ErrorBanner? = nil

    private init() {}

    func show(
        _ message: String,
        type: ErrorBanner.BannerType = .error,
        duration: Double = 3.0
    ) {
        withAnimation {
            currentBanner = ErrorBanner(message: message, type: type, duration: duration)
        }
    }

    func showSuccess(_ message: String) {
        show(message, type: .success)
    }

    func showError(_ message: String) {
        show(message, type: .error)
    }

    func showWarning(_ message: String) {
        show(message, type: .warning)
    }

    func showInfo(_ message: String) {
        show(message, type: .info)
    }
}

// MARK: - BannerManagerModifier

struct BannerManagerModifier: ViewModifier {
    @State private var bannerManager = BannerManager.shared

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                ErrorBannerView(banner: Binding(
                    get: { bannerManager.currentBanner },
                    set: { bannerManager.currentBanner = $0 }
                ))
            }
    }
}

// MARK: - View Extension

extension View {
    func bannerManager() -> some View {
        modifier(BannerManagerModifier())
    }
}

import SwiftUI

// MARK: - InAppBannerType

enum InAppBannerType {
    case gameReminder
    case message
    case achievement
    case alert

    var color: Color {
        switch self {
        case .gameReminder: return Color.dinkrGreen
        case .message:      return Color.dinkrSky
        case .achievement:  return Color.dinkrAmber
        case .alert:        return Color.dinkrCoral
        }
    }

    var defaultIcon: String {
        switch self {
        case .gameReminder: return "figure.pickleball"
        case .message:      return "bubble.left.fill"
        case .achievement:  return "trophy.fill"
        case .alert:        return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - InAppBannerItem

struct InAppBannerItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String?
    let icon: String
    let type: InAppBannerType
    /// Stub deep link destination — consumed by tap handler
    var deepLink: String?

    static func == (lhs: InAppBannerItem, rhs: InAppBannerItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - InAppBanner (Singleton Observable)

@Observable
final class InAppBanner {
    static let shared = InAppBanner()

    var current: InAppBannerItem? = nil

    private var dismissTask: Task<Void, Never>? = nil
    private let autoDismissSeconds: Double = 4.0

    private init() {}

    // MARK: Show

    func show(
        title: String,
        subtitle: String? = nil,
        icon: String,
        type: InAppBannerType,
        deepLink: String? = nil
    ) {
        dismissTask?.cancel()

        let item = InAppBannerItem(
            id: UUID(),
            title: title,
            subtitle: subtitle,
            icon: icon,
            type: type,
            deepLink: deepLink
        )

        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
            current = item
        }

        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(autoDismissSeconds))
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }

    // MARK: Dismiss

    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            current = nil
        }
    }

    // MARK: Convenience

    func gameReminder(_ title: String, subtitle: String? = nil) {
        show(title: title, subtitle: subtitle, icon: InAppBannerType.gameReminder.defaultIcon, type: .gameReminder)
    }

    func message(_ title: String, subtitle: String? = nil) {
        show(title: title, subtitle: subtitle, icon: InAppBannerType.message.defaultIcon, type: .message)
    }

    func achievement(_ title: String, subtitle: String? = nil) {
        show(title: title, subtitle: subtitle, icon: InAppBannerType.achievement.defaultIcon, type: .achievement)
    }

    func alert(_ title: String, subtitle: String? = nil) {
        show(title: title, subtitle: subtitle, icon: InAppBannerType.alert.defaultIcon, type: .alert)
    }
}

// MARK: - InAppNotificationBanner View

struct InAppNotificationBanner: View {
    let item: InAppBannerItem
    let onDismiss: () -> Void
    let onTap: (InAppBannerItem) -> Void

    @State private var dragOffset: CGFloat = 0
    private let dismissThreshold: CGFloat = -40

    var body: some View {
        HStack(spacing: 14) {
            // Left icon badge
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(item.type.color.opacity(0.18))
                    .frame(width: 44, height: 44)

                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(item.type.color)
            }

            // Title + subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.dinkrNavy)
                    .lineLimit(1)

                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Chevron hint (indicates tappable)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.secondary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: item.type.color.opacity(0.18), radius: 12, x: 0, y: 4)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
        )
        // Left accent strip
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(item.type.color)
                .frame(width: 4)
                .padding(.vertical, 10)
                .padding(.leading, 4)
        }
        .padding(.horizontal, 16)
        .offset(y: dragOffset)
        .onTapGesture {
            onTap(item)
        }
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    // Only allow upward drag
                    let translation = value.translation.height
                    if translation < 0 {
                        dragOffset = translation * 0.6 // rubber-band resistance
                    }
                }
                .onEnded { value in
                    if value.translation.height < dismissThreshold {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            dragOffset = -200
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            onDismiss()
                        }
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .accessibilityLabel("\(item.title)\(item.subtitle.map { ", \($0)" } ?? "")")
        .accessibilityHint("Tap to open. Swipe up to dismiss.")
    }
}

// MARK: - InAppBannerContainerModifier

struct InAppBannerContainerModifier: ViewModifier {
    @State private var banner = InAppBanner.shared

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .top, spacing: 0) {
                ZStack {
                    if let current = banner.current {
                        InAppNotificationBanner(
                            item: current,
                            onDismiss: {
                                banner.dismiss()
                            },
                            onTap: { item in
                                handleDeepLink(item.deepLink)
                                banner.dismiss()
                            }
                        )
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            )
                        )
                        .id(current.id)
                        .zIndex(999)
                    }
                }
                .animation(.spring(response: 0.45, dampingFraction: 0.72), value: banner.current)
                .padding(.top, 8)
                .padding(.bottom, banner.current != nil ? 4 : 0)
            }
    }

    // MARK: Deep Link Handler (stub)

    private func handleDeepLink(_ link: String?) {
        guard let link else { return }
        // TODO: Route to the appropriate screen via TabRouter / NavigationPath
        // Example: TabRouter.shared.navigate(to: link)
        print("[InAppBanner] Deep link triggered: \(link)")
    }
}

// MARK: - View Extension

extension View {
    /// Wraps a view to support the in-app notification banner system.
    /// Apply once at the NavigationStack or root level.
    func inAppBannerSupport() -> some View {
        modifier(InAppBannerContainerModifier())
    }
}

// MARK: - Preview

#Preview("Banner Types") {
    @Previewable @State var banner = InAppBanner.shared

    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()

        VStack(spacing: 14) {
            Button("Game Reminder") {
                banner.gameReminder("Court booked!", subtitle: "Westside Courts · Today 6:00 PM")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.dinkrGreen)

            Button("New Message") {
                banner.message("Alex Rivera", subtitle: "Nice game yesterday! Rematch?")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.dinkrSky)

            Button("Achievement") {
                banner.achievement("New Badge Unlocked!", subtitle: "5-Game Win Streak 🏆")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.dinkrAmber)

            Button("Alert") {
                banner.alert("Game starting soon", subtitle: "Your 7:00 PM game begins in 15 min")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.dinkrCoral)
        }
        .padding()
    }
    .inAppBannerSupport()
}

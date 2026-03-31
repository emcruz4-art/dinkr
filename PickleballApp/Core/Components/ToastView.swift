import SwiftUI

// MARK: - ToastType

enum ToastType {
    case success
    case error
    case info
    case warning

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error:   return "xmark.circle.fill"
        case .info:    return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return Color.dinkrGreen
        case .error:   return Color.dinkrCoral
        case .info:    return Color.dinkrSky
        case .warning: return Color.dinkrAmber
        }
    }
}

// MARK: - ToastMessage

struct ToastMessage: Identifiable {
    let id: UUID
    let type: ToastType
    let title: String
    let subtitle: String?
    let duration: Double

    init(
        id: UUID = UUID(),
        type: ToastType,
        title: String,
        subtitle: String? = nil,
        duration: Double = 3.0
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.duration = duration
    }
}

// MARK: - ToastView

struct ToastView: View {
    let message: ToastMessage
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Left: colored circle icon
            Circle()
                .fill(message.type.color.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: message.type.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(message.type.color)
                )

            // Center: title + optional subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(message.title)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let subtitle = message.subtitle {
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right: X dismiss button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(Color(.tertiarySystemFill), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
        .padding(.horizontal, 16)
    }
}

// MARK: - ToastManager

@Observable
final class ToastManager {
    static let shared = ToastManager()

    var current: ToastMessage? = nil

    private init() {}

    func show(_ message: ToastMessage) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            current = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + message.duration) { [weak self] in
            guard let self, self.current?.id == message.id else { return }
            self.dismiss()
        }
    }

    func dismiss() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            current = nil
        }
    }

    func success(_ title: String, subtitle: String? = nil, duration: Double = 3.0) {
        show(ToastMessage(type: .success, title: title, subtitle: subtitle, duration: duration))
    }

    func error(_ title: String, subtitle: String? = nil, duration: Double = 3.0) {
        show(ToastMessage(type: .error, title: title, subtitle: subtitle, duration: duration))
    }

    func info(_ title: String, subtitle: String? = nil, duration: Double = 3.0) {
        show(ToastMessage(type: .info, title: title, subtitle: subtitle, duration: duration))
    }

    func warning(_ title: String, subtitle: String? = nil, duration: Double = 3.0) {
        show(ToastMessage(type: .warning, title: title, subtitle: subtitle, duration: duration))
    }
}

// MARK: - ToastContainerModifier

struct ToastContainerModifier: ViewModifier {
    @State private var toastManager = ToastManager.shared

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                ZStack {
                    if let current = toastManager.current {
                        ToastView(message: current) {
                            toastManager.dismiss()
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .id(current.id)
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: toastManager.current?.id)
                .padding(.top, 8)
            }
    }
}

// MARK: - View Extension

extension View {
    func toastContainer() -> some View {
        modifier(ToastContainerModifier())
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var manager = ToastManager.shared

    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        VStack(spacing: 16) {
            Button("Show Success") {
                manager.success("Game joined!", subtitle: "Westside Courts · 4.0+")
            }
            Button("Show Error") {
                manager.error("Couldn't join", subtitle: "Session is full")
            }
            Button("Show Info") {
                manager.info("Court booked for 2 hrs")
            }
            Button("Show Warning") {
                manager.warning("Low skill match", subtitle: "This game is rated 5.0+")
            }
        }
    }
    .toastContainer()
}

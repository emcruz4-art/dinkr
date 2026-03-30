import SwiftUI

/// Duolingo/Headspace-style toast that slides down from the top of the screen
/// when a player joins a session.
///
/// Usage:
/// ```swift
/// .overlay(alignment: .top) { JoinToastView(message: $vm.joinToast) }
/// ```
struct JoinToastView: View {
    @Binding var message: String?

    /// Controls the slide-in / slide-out translation.
    @State private var offset: CGFloat = -120
    /// Keeps a local copy so the view can finish its exit animation before
    /// the binding is cleared.
    @State private var displayedMessage: String = ""

    private let toastHeight: CGFloat = 52
    private let autoDismissDelay: Double = 3.0

    var body: some View {
        ZStack {
            if !displayedMessage.isEmpty {
                toastPill
                    .offset(y: offset)
                    .animation(.spring(response: 0.45, dampingFraction: 0.72), value: offset)
                    .transition(.identity)   // animation is manual; no implicit transition needed
            }
        }
        .onChange(of: message) { _, newValue in
            if let text = newValue, !text.isEmpty {
                displayedMessage = text
                show()
            }
        }
    }

    // MARK: - Pill

    private var toastPill: some View {
        HStack(spacing: 10) {
            // Avatar initial circle
            Circle()
                .fill(Color.dinkrGreen.opacity(0.25))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(avatarInitial)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.dinkrGreen)
                )

            Text(displayedMessage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .frame(height: toastHeight)
        .background(
            Capsule()
                .fill(Color.dinkrGreen)
                .shadow(color: Color.dinkrGreen.opacity(0.40), radius: 12, x: 0, y: 4)
        )
        .padding(.top, 12)   // small gap from the safe-area top edge
    }

    // MARK: - Helpers

    private var avatarInitial: String {
        displayedMessage.first.map { String($0).uppercased() } ?? "?"
    }

    private func show() {
        // Slide down into view
        offset = 0
        // Schedule auto-dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
            dismiss()
        }
    }

    private func dismiss() {
        offset = -120
        // Clear binding and local copy after exit animation completes (~0.45 s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            message = nil
            displayedMessage = ""
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var msg: String? = "Alex just joined · Westside 4.0"
    return ZStack(alignment: .top) {
        Color(.systemGroupedBackground).ignoresSafeArea()
        VStack {
            Button("Show Toast") { msg = "Alex just joined · Westside 4.0" }
                .padding(.top, 120)
        }
    }
    .overlay(alignment: .top) {
        JoinToastView(message: $msg)
    }
}

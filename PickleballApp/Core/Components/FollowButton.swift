import SwiftUI

// MARK: - Follow Button Size

enum FollowButtonSize {
    case compact
    case regular
}

// MARK: - Follow Button

struct FollowButton: View {
    let currentUserId: String
    let targetUserId: String
    var isPrivateAccount: Bool = false
    var size: FollowButtonSize = .regular

    @State private var isFollowing: Bool = false
    @State private var isLoading: Bool = true
    @State private var isPressed: Bool = false

    private var followService: FollowService { FollowService.shared }

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(Color.dinkrGreen)
                        .scaleEffect(size == .compact ? 0.75 : 1.0)
                        .frame(width: buttonWidth, height: buttonHeight)
                        .background(Color.secondary.opacity(0.08), in: Capsule())
                } else if isFollowing {
                    followingLabel
                } else {
                    followLabel
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.93 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: isPressed)
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: isFollowing)
        .disabled(isLoading || currentUserId.isEmpty)
        .task { await checkFollowStatus() }
    }

    // MARK: - Labels

    private var followLabel: some View {
        HStack(spacing: size == .compact ? 4 : 5) {
            Image(systemName: isPrivateAccount ? "person.badge.plus" : "plus")
                .font(.system(size: size == .compact ? 10 : 12, weight: .bold))
            Text(isPrivateAccount ? "Request" : "Follow")
                .font(size == .compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
        }
        .foregroundStyle(Color.dinkrGreen)
        .padding(.horizontal, size == .compact ? 10 : 16)
        .padding(.vertical, size == .compact ? 5 : 8)
        .background(
            Capsule()
                .stroke(Color.dinkrGreen, lineWidth: 1.5)
        )
    }

    private var followingLabel: some View {
        HStack(spacing: size == .compact ? 4 : 5) {
            Image(systemName: "checkmark")
                .font(.system(size: size == .compact ? 10 : 12, weight: .bold))
            Text("Following")
                .font(size == .compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, size == .compact ? 10 : 16)
        .padding(.vertical, size == .compact ? 5 : 8)
        .background(Color.dinkrNavy, in: Capsule())
    }

    // MARK: - Helpers

    private var buttonWidth: CGFloat { size == .compact ? 80 : 100 }
    private var buttonHeight: CGFloat { size == .compact ? 28 : 36 }

    private func checkFollowStatus() async {
        isLoading = true
        isFollowing = await followService.isFollowing(
            currentUserId: currentUserId,
            targetUserId: targetUserId
        )
        isLoading = false
    }

    private func handleTap() {
        guard !isLoading else { return }

        // Haptic
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        // Spring press
        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
            isPressed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                isPressed = false
            }
        }

        // Optimistic toggle
        let newState = !isFollowing
        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
            isFollowing = newState
        }

        Task {
            do {
                if newState {
                    try await followService.follow(
                        currentUserId: currentUserId,
                        targetUserId: targetUserId
                    )
                } else {
                    try await followService.unfollow(
                        currentUserId: currentUserId,
                        targetUserId: targetUserId
                    )
                }
            } catch {
                // Revert on failure
                withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                    isFollowing = !newState
                }
                print("[FollowButton] error: \(error)")
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        FollowButton(currentUserId: "user1", targetUserId: "user2", size: .regular)
        FollowButton(currentUserId: "user1", targetUserId: "user3", size: .compact)
    }
    .padding()
}

import SwiftUI

// MARK: - AvatarView

struct AvatarView: View {
    let urlString: String?
    let displayName: String
    let size: CGFloat
    var isOnline: Bool = false
    var isPremium: Bool = false

    init(
        urlString: String? = nil,
        displayName: String,
        size: CGFloat = 40,
        isOnline: Bool = false,
        isPremium: Bool = false
    ) {
        self.urlString = urlString
        self.displayName = displayName
        self.size = size
        self.isOnline = isOnline
        self.isPremium = isPremium
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarContent
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(premiumRing)

            if isOnline {
                OnlineIndicator(size: size)
            }
        }
    }

    // MARK: - Avatar Content

    @ViewBuilder
    private var avatarContent: some View {
        if let urlString, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    initialsView
                case .empty:
                    ShimmerAvatar(size: size)
                @unknown default:
                    initialsView
                }
            }
        } else {
            initialsView
        }
    }

    // MARK: - Premium Ring

    @ViewBuilder
    private var premiumRing: some View {
        if isPremium {
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.dinkrAmber, Color.dinkrCoral, Color.dinkrAmber],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: size * 0.055
                )
        } else {
            Circle()
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        }
    }

    // MARK: - Initials View

    private var initials: String {
        let parts = displayName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.dropFirst().first?.prefix(1) ?? ""
        return (first + last).uppercased()
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.dinkrGreen, Color.dinkrSky],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(initials)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - OnlineIndicator

private struct OnlineIndicator: View {
    let size: CGFloat

    private var dotSize: CGFloat { max(size * 0.22, 8) }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: dotSize + 2, height: dotSize + 2)
            Circle()
                .fill(Color.dinkrGreen)
                .frame(width: dotSize, height: dotSize)
        }
        .offset(x: 1, y: 1)
    }
}

// MARK: - ShimmerAvatar

private struct ShimmerAvatar: View {
    let size: CGFloat
    @State private var phase: CGFloat = 0

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color.secondary.opacity(0.12), location: phase - 0.3),
                        .init(color: Color.secondary.opacity(0.28), location: phase),
                        .init(color: Color.secondary.opacity(0.12), location: phase + 0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.4).repeatForever(autoreverses: false)
                ) {
                    phase = 1.6
                }
            }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        HStack(spacing: 20) {
            AvatarView(displayName: "Alex Rivera", size: 36)
            AvatarView(displayName: "Maria Chen", size: 48, isOnline: true)
            AvatarView(displayName: "Jordan Kim", size: 56, isPremium: true)
            AvatarView(displayName: "Sam Lee", size: 64, isOnline: true, isPremium: true)
        }

        HStack(spacing: 20) {
            AvatarView(urlString: nil, displayName: "Loading State", size: 48)
            AvatarView(
                urlString: "https://i.pravatar.cc/150?img=3",
                displayName: "With Photo",
                size: 48,
                isOnline: true
            )
        }
    }
    .padding()
}

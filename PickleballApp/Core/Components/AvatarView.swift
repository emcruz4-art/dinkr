import SwiftUI

struct AvatarView: View {
    let urlString: String?
    let displayName: String
    let size: CGFloat

    init(urlString: String? = nil, displayName: String, size: CGFloat = 40) {
        self.urlString = urlString
        self.displayName = displayName
        self.size = size
    }

    var body: some View {
        ZStack {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    initialsView
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var initials: String {
        let parts = displayName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.dropFirst().first?.prefix(1) ?? ""
        return (first + last).uppercased()
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [Color.pickleballGreen, Color.courtBlue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            Text(initials)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        AvatarView(displayName: "Alex Rivera", size: 32)
        AvatarView(displayName: "Maria Chen", size: 48)
        AvatarView(displayName: "Jordan", size: 64)
    }
    .padding()
}

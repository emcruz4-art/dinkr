import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    func sectionHeader() -> some View {
        self
            .font(.title3.weight(.bold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
    }

    func primaryButton() -> some View {
        self
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.pickleballGreen, in: RoundedRectangle(cornerRadius: 12))
    }

    func secondaryButton() -> some View {
        self
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.pickleballGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.pickleballGreen, lineWidth: 1.5)
            )
    }
}

struct PillTag: View {
    let text: String
    var color: Color = Color.pickleballGreen.opacity(0.15)
    var textColor: Color = Color.pickleballGreen

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color, in: Capsule())
    }
}

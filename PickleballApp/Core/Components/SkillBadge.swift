import SwiftUI

struct SkillBadge: View {
    let level: SkillLevel
    let compact: Bool

    init(level: SkillLevel, compact: Bool = false) {
        self.level = level
        self.compact = compact
    }

    var body: some View {
        Text(level.label)
            .font(compact ? .caption2.weight(.bold) : .caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, compact ? 6 : 8)
            .padding(.vertical, compact ? 2 : 4)
            .background(badgeColor, in: Capsule())
    }

    private var badgeColor: Color {
        switch level {
        case .beginner20, .beginner25: return .green
        case .intermediate30, .intermediate35: return .courtBlue
        case .advanced40, .advanced45: return .courtOrange
        case .pro50: return .red
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        ForEach(SkillLevel.allCases, id: \.self) { level in
            SkillBadge(level: level)
        }
    }
    .padding()
}

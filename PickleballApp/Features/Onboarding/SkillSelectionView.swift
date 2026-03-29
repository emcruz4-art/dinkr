import SwiftUI

struct SkillSelectionView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("What's Your Skill Level?")
                    .font(.title2.weight(.bold))
                Text("We'll match you with games and players at your level")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(SkillLevel.allCases, id: \.self) { level in
                        SkillLevelRow(level: level, isSelected: viewModel.selectedSkill == level) {
                            viewModel.selectedSkill = level
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            Button("Continue") {
                viewModel.advance()
            }
            .primaryButton()
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .navigationBarBackButtonHidden()
    }
}

struct SkillLevelRow: View {
    let level: SkillLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                SkillBadge(level: level)
                VStack(alignment: .leading, spacing: 2) {
                    Text(levelTitle)
                        .font(.subheadline.weight(.semibold))
                    Text(levelDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.pickleballGreen)
                }
            }
            .padding(16)
            .background(isSelected ? Color.pickleballGreen.opacity(0.08) : Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.pickleballGreen : .clear, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
    }

    var levelTitle: String {
        switch level {
        case .beginner20: return "2.0 — Complete Beginner"
        case .beginner25: return "2.5 — Learning the Basics"
        case .intermediate30: return "3.0 — Developing Player"
        case .intermediate35: return "3.5 — Intermediate"
        case .advanced40: return "4.0 — Advanced"
        case .advanced45: return "4.5 — Expert"
        case .pro50: return "5.0+ — Pro / Semi-Pro"
        }
    }

    var levelDescription: String {
        switch level {
        case .beginner20: return "New to pickleball, still learning rules"
        case .beginner25: return "Knows the basics, working on consistency"
        case .intermediate30: return "Reliable groundstrokes, learning strategy"
        case .intermediate35: return "Consistent play, knows third-shot drop"
        case .advanced40: return "Strong all-around game, plays tournaments"
        case .advanced45: return "Tournament competitor, advanced strategies"
        case .pro50: return "National/regional tournament player"
        }
    }
}

#Preview {
    SkillSelectionView(viewModel: OnboardingViewModel())
}

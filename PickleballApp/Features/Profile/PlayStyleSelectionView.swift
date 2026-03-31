import SwiftUI

// MARK: - StyleInfo (file-private data model)

private struct StyleInfo: Identifiable {
    let style: PlayStyle
    let description: String
    let scenario: String

    var id: PlayStyle { style }
}

private let allStyleData: [StyleInfo] = [
    StyleInfo(
        style: .competitive,
        description: "You play to win. Every point counts, you study opponents, and you grind until the last ball.",
        scenario: "\"I was down 9-2 and clawed back 11-9 because I spotted their backhand weakness.\""
    ),
    StyleInfo(
        style: .recreational,
        description: "You're in it for the fun, the community, and the laughs after the game. Results are secondary.",
        scenario: "\"I lost 11-3 but we laughed the whole time — best Sunday morning ever.\""
    ),
    StyleInfo(
        style: .drillFocused,
        description: "Progress through repetition. You'd rather spend 30 min drilling thirds than playing a full game.",
        scenario: "\"Let's run the ATP drill from both sides ten times each before we play.\""
    ),
    StyleInfo(
        style: .dinkCulture,
        description: "The kitchen is your home. Patient, precise, and deadly at the NVZ. You live for the dink battle.",
        scenario: "\"We had a 40-ball dink rally and I was in my element — every reset, every angle.\""
    ),
    StyleInfo(
        style: .allAround,
        description: "Balanced and adaptable. You shift game plans mid-match and enjoy all aspects of the sport.",
        scenario: "\"I can bang with bangers or dink with dinkers — I just read what the game needs.\""
    ),
]

// MARK: - PlayStyleSelectionView

/// Full-sheet multi-select play style picker (up to 2 styles).
/// Shows each style as a large card with icon, name, description, and an example scenario.
struct PlayStyleSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: [PlayStyle]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    explanationBanner
                    styleList
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .background(Color.appBackground)
            .navigationTitle("Play Style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
    }

    // MARK: - Explanation Banner

    private var explanationBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.dinkrGreen)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Your style helps us find better match-ups")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Select up to 2 styles that best describe how you approach the game.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !selection.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(selection, id: \.self) { style in
                            selectedChip(style)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func selectedChip(_ style: PlayStyle) -> some View {
        let color = styleColor(style)
        HStack(spacing: 4) {
            Image(systemName: style.icon)
                .font(.caption2)
            Text(style.rawValue)
                .font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }

    // MARK: - Style List

    private var styleList: some View {
        VStack(spacing: 14) {
            ForEach(allStyleData) { info in
                StyleCard(
                    info: info,
                    isSelected: selection.contains(info.style),
                    isDisabled: !selection.contains(info.style) && selection.count >= 2
                ) {
                    toggleStyle(info.style)
                }
            }
        }
    }

    // MARK: - Toggle Logic

    private func toggleStyle(_ style: PlayStyle) {
        HapticManager.selection()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.62)) {
            if let idx = selection.firstIndex(of: style) {
                selection.remove(at: idx)
            } else if selection.count < 2 {
                selection.append(style)
            }
        }
    }

    private func styleColor(_ style: PlayStyle) -> Color {
        switch style.color {
        case "dinkrCoral":  return Color.dinkrCoral
        case "dinkrGreen":  return Color.dinkrGreen
        case "dinkrSky":    return Color.dinkrSky
        case "dinkrAmber":  return Color.dinkrAmber
        case "dinkrNavy":   return Color.dinkrNavy
        default:            return Color.dinkrGreen
        }
    }
}

// MARK: - StyleCard

private struct StyleCard: View {
    let info: StyleInfo
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    private var accentColor: Color {
        switch info.style.color {
        case "dinkrCoral":  return Color.dinkrCoral
        case "dinkrGreen":  return Color.dinkrGreen
        case "dinkrSky":    return Color.dinkrSky
        case "dinkrAmber":  return Color.dinkrAmber
        case "dinkrNavy":   return Color.dinkrNavy
        default:            return Color.dinkrGreen
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                // Animated icon circle
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(isSelected ? 0.25 : 0.10))
                        .frame(width: 52, height: 52)
                    Image(systemName: info.style.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(accentColor.opacity(isDisabled && !isSelected ? 0.4 : 1.0))
                }
                .scaleEffect(isSelected ? 1.08 : 1.0)
                .animation(.spring(response: 0.28, dampingFraction: 0.55), value: isSelected)

                // Text block
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(info.style.rawValue)
                            .font(.headline)
                            .foregroundStyle(isDisabled && !isSelected ? .secondary : .primary)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(accentColor)
                                .transition(
                                    .asymmetric(
                                        insertion: .scale(scale: 0.5).combined(with: .opacity),
                                        removal: .scale(scale: 0.5).combined(with: .opacity)
                                    )
                                )
                        }
                    }

                    Text(info.description)
                        .font(.subheadline)
                        .foregroundStyle(isDisabled && !isSelected ? .tertiary : .secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Scenario quote
                    Text(info.scenario)
                        .font(.caption)
                        .italic()
                        .foregroundStyle(isSelected ? accentColor.opacity(0.85) : Color(UIColor.tertiaryLabel))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? accentColor.opacity(0.07) : Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.015 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled && !isSelected)
        .opacity(isDisabled && !isSelected ? 0.55 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isDisabled)
    }
}

// MARK: - Preview

#Preview("Play Style Selection") {
    PlayStyleSelectionView(selection: .constant([.dinkCulture]))
}

#Preview("Max selected") {
    PlayStyleSelectionView(selection: .constant([.competitive, .drillFocused]))
}

import SwiftUI

// MARK: - App Icon Settings View

struct AppIconSettingsView: View {

    @AppStorage("selectedAppIcon") private var selectedAppIcon: String = DinkrAppIcon.default_.rawValue
    @State private var showConfirmation = false
    @State private var confirmationMessage = ""

    private var selectedOption: DinkrAppIcon {
        DinkrAppIcon(rawValue: selectedAppIcon) ?? .default_
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Section header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Choose your app icon")
                        .font(.headline)
                    Text("The icon will update on your home screen immediately.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Icon grid
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(DinkrAppIcon.allCases) { option in
                        AppIconCell(
                            option: option,
                            isSelected: selectedOption == option
                        ) {
                            applyIcon(option)
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Footnote
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Alternate icons are available to all Dinkr users. More icons coming soon.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.large)
        .overlay(alignment: .bottom) {
            if showConfirmation {
                ConfirmationToast(message: confirmationMessage)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showConfirmation)
    }

    // MARK: - Apply Icon

    private func applyIcon(_ option: DinkrAppIcon) {
        guard option != selectedOption else { return }
        selectedAppIcon = option.rawValue
        HapticManager.selection()

        let iconName: String? = option == .default_ ? nil : option.rawValue
        UIApplication.shared.setAlternateIconName(iconName) { error in
            DispatchQueue.main.async {
                if let error {
                    // Surface a graceful message — alternate icons must be declared in Info.plist
                    confirmationMessage = "Icon preference saved. (\(error.localizedDescription))"
                } else {
                    confirmationMessage = "App icon updated!"
                }
                showConfirmation = true
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    showConfirmation = false
                }
            }
        }
    }
}

// MARK: - App Icon Cell

private struct AppIconCell: View {
    let option: DinkrAppIcon
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                ZStack {
                    // Icon preview background
                    RoundedRectangle(cornerRadius: 22)
                        .fill(option.backgroundGradient)
                        .frame(width: 84, height: 84)
                        .shadow(
                            color: option.shadowColor.opacity(isSelected ? 0.35 : 0.12),
                            radius: isSelected ? 10 : 4,
                            x: 0,
                            y: isSelected ? 4 : 2
                        )

                    // Selection border
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(
                            isSelected ? Color.dinkrGreen : Color.clear,
                            lineWidth: 3
                        )
                        .frame(width: 84, height: 84)

                    // Paddle / icon symbol
                    Image(systemName: option.symbolName)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(option.symbolStyle)

                    // Selected checkmark badge
                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(Color.dinkrGreen)
                                .frame(width: 22, height: 22)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(6)
                    }
                }
                .frame(width: 84, height: 84)

                Text(option.label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? Color.dinkrGreen : .secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }
}

// MARK: - Confirmation Toast

private struct ConfirmationToast: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.dinkrGreen)
            Text(message)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Dinkr App Icon Model

enum DinkrAppIcon: String, CaseIterable, Identifiable {
    case default_ = "AppIcon-Default"
    case dark     = "AppIcon-Dark"
    case coral    = "AppIcon-Coral"
    case gold     = "AppIcon-Gold"
    case minimal  = "AppIcon-Minimal"
    case pride    = "AppIcon-Pride"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .default_: return "Default"
        case .dark:     return "Dark Mode"
        case .coral:    return "Coral"
        case .gold:     return "Gold"
        case .minimal:  return "Minimal"
        case .pride:    return "Pride"
        }
    }

    var symbolName: String { "figure.pickleball" }

    // MARK: Visual properties

    var backgroundGradient: AnyShapeStyle {
        switch self {
        case .default_:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.65)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .dark:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.dinkrNavy, Color.dinkrNavy.opacity(0.80)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .coral:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.dinkrCoral, Color.dinkrCoral.opacity(0.70)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .gold:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.dinkrAmber, Color.dinkrAmber.opacity(0.65)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .minimal:
            return AnyShapeStyle(Color(UIColor.systemBackground))
        case .pride:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.27, blue: 0.27),
                        Color(red: 0.99, green: 0.60, blue: 0.15),
                        Color(red: 0.99, green: 0.88, blue: 0.10),
                        Color(red: 0.20, green: 0.78, blue: 0.35),
                        Color(red: 0.20, green: 0.48, blue: 0.99),
                        Color(red: 0.60, green: 0.20, blue: 0.90)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    var symbolStyle: AnyShapeStyle {
        switch self {
        case .dark:    return AnyShapeStyle(Color.dinkrGreen)
        case .minimal: return AnyShapeStyle(
                            LinearGradient(
                                colors: [Color.dinkrGreen, Color.dinkrNavy],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
        default:       return AnyShapeStyle(Color.white)
        }
    }

    var shadowColor: Color {
        switch self {
        case .default_: return Color.dinkrGreen
        case .dark:     return Color.dinkrNavy
        case .coral:    return Color.dinkrCoral
        case .gold:     return Color.dinkrAmber
        case .minimal:  return Color(.systemGray3)
        case .pride:    return Color(red: 0.60, green: 0.20, blue: 0.90)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AppIconSettingsView()
    }
}

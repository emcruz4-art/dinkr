import SwiftUI

// MARK: - Appearance Settings View

struct AppearanceSettingsView: View {

    // MARK: Persistence
    @AppStorage("appTheme")    private var appTheme: String    = AppearanceTheme.system.rawValue
    @AppStorage("accentColor") private var accentColor: String = AccentColorOption.dinkrGreen.rawValue
    @AppStorage("appIcon")     private var appIcon: String     = AppIconOption.defaultIcon.rawValue
    @AppStorage("textSize")    private var textSize: Double    = TextSizeOption.default_.rawValue
    @AppStorage("reduceMotion")       private var reduceMotion: Bool       = false
    @AppStorage("reduceTransparency") private var reduceTransparency: Bool = false

    // MARK: Computed helpers
    private var selectedTheme: AppearanceTheme {
        AppearanceTheme(rawValue: appTheme) ?? .system
    }
    private var selectedAccent: AccentColorOption {
        AccentColorOption(rawValue: accentColor) ?? .dinkrGreen
    }
    private var selectedIcon: AppIconOption {
        AppIconOption(rawValue: appIcon) ?? .defaultIcon
    }
    private var selectedTextSize: TextSizeOption {
        TextSizeOption(rawValue: textSize) ?? .default_
    }

    // MARK: Body

    var body: some View {
        List {
            themeSection
            accentColorSection
            appIconSection
            textSizeSection
            accessibilitySection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(selectedTheme.colorScheme)
    }

    // MARK: - Theme Section

    private var themeSection: some View {
        Section {
            HStack(spacing: 12) {
                ForEach(AppearanceTheme.allCases) { theme in
                    ThemeCard(
                        theme: theme,
                        isSelected: selectedTheme == theme
                    ) {
                        appTheme = theme.rawValue
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("App Theme")
        }
    }

    // MARK: - Accent Color Section

    private var accentColorSection: some View {
        Section {
            HStack(spacing: 16) {
                ForEach(AccentColorOption.allCases) { option in
                    AccentCircle(
                        option: option,
                        isSelected: selectedAccent == option
                    ) {
                        accentColor = option.rawValue
                    }
                }
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
        } header: {
            Text("Accent Color")
        }
    }

    // MARK: - App Icon Section

    private var appIconSection: some View {
        Section {
            HStack(spacing: 16) {
                ForEach(AppIconOption.allCases) { option in
                    AppIconCard(
                        option: option,
                        isSelected: selectedIcon == option
                    ) {
                        appIcon = option.rawValue
                    }
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Alternate icons require app restart")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .listRowSeparator(.hidden)
        } header: {
            Text("App Icon")
        }
    }

    // MARK: - Text Size Section

    private var textSizeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                // Live preview
                Text("The quick brown fox")
                    .font(.system(size: selectedTextSize.fontSize))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                    .animation(.easeInOut(duration: 0.2), value: textSize)

                // Slider
                VStack(spacing: 6) {
                    Slider(
                        value: $textSize,
                        in: TextSizeOption.small.rawValue...TextSizeOption.xl.rawValue,
                        step: 1
                    )
                    .tint(Color.dinkrGreen)

                    HStack {
                        ForEach(TextSizeOption.allCases) { option in
                            Text(option.label)
                                .font(.caption2)
                                .foregroundStyle(selectedTextSize == option ? Color.dinkrGreen : .secondary)
                                .fontWeight(selectedTextSize == option ? .semibold : .regular)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Text Size")
        }
    }

    // MARK: - Accessibility Section

    private var accessibilitySection: some View {
        Section("Accessibility") {
            Toggle(isOn: $reduceMotion) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.dinkrSky.opacity(0.15))
                            .frame(width: 30, height: 30)
                        Image(systemName: "figure.walk")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.dinkrSky)
                    }
                    Text("Reduce Motion")
                        .foregroundStyle(.primary)
                }
            }
            .tint(Color.dinkrGreen)

            Toggle(isOn: $reduceTransparency) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.dinkrAmber.opacity(0.15))
                            .frame(width: 30, height: 30)
                        Image(systemName: "square.on.square.dashed")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.dinkrAmber)
                    }
                    Text("Reduce Transparency")
                        .foregroundStyle(.primary)
                }
            }
            .tint(Color.dinkrGreen)
        }
    }
}

// MARK: - Theme Card

private struct ThemeCard: View {
    let theme: AppearanceTheme
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Phone mockup
                ZStack(alignment: .top) {
                    // Phone shell
                    RoundedRectangle(cornerRadius: 10)
                        .fill(theme.mockupBackground)
                        .frame(width: 72, height: 110)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    isSelected ? Color.dinkrGreen : Color(.systemGray4),
                                    lineWidth: isSelected ? 2.5 : 1
                                )
                        )

                    VStack(spacing: 0) {
                        // Nav bar strip
                        RoundedRectangle(cornerRadius: 0)
                            .fill(theme.mockupNavBar)
                            .frame(height: 22)
                            .clipShape(
                                .rect(
                                    topLeadingRadius: 10,
                                    topTrailingRadius: 10
                                )
                            )

                        // Content rows
                        VStack(spacing: 5) {
                            ForEach(0..<3, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(theme.mockupRow)
                                    .frame(height: 8)
                                    .padding(.horizontal, 8)
                                    .opacity(1.0 - Double(i) * 0.2)
                            }
                        }
                        .padding(.top, 8)
                    }

                    // Selected checkmark
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.dinkrGreen)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            .padding(6)
                    }
                }
                .frame(width: 72, height: 110)

                Text(theme.label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? Color.dinkrGreen : .secondary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Accent Circle

private struct AccentCircle: View {
    let option: AccentColorOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(option.color)
                    .frame(width: 36, height: 36)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - App Icon Card

private struct AppIconCard: View {
    let option: AppIconOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    // Rounded square background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(option.backgroundColor)
                        .frame(width: 64, height: 64)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    isSelected ? Color.dinkrGreen : Color(.systemGray4),
                                    lineWidth: isSelected ? 2.5 : 1
                                )
                        )

                    // Icon symbol
                    Image(systemName: option.symbolName)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(option.symbolColor)

                    // Selected checkmark badge
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.dinkrGreen)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            .padding(4)
                    }
                }
                .frame(width: 64, height: 64)

                Text(option.label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? Color.dinkrGreen : .secondary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Supporting Enums

enum AppearanceTheme: String, CaseIterable, Identifiable {
    case light  = "light"
    case dark   = "dark"
    case system = "system"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light:  return "Light"
        case .dark:   return "Dark"
        case .system: return "Auto"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }

    var mockupBackground: Color {
        switch self {
        case .light:  return Color(UIColor.systemBackground)
        case .dark:   return Color(red: 0.11, green: 0.11, blue: 0.12)
        case .system: return Color(UIColor.systemBackground)
        }
    }

    var mockupNavBar: Color {
        switch self {
        case .light:  return Color.dinkrGreen
        case .dark:   return Color.dinkrNavy
        case .system: return Color.dinkrGreen.opacity(0.8)
        }
    }

    var mockupRow: Color {
        switch self {
        case .light:  return Color(UIColor.systemGray5)
        case .dark:   return Color(red: 0.22, green: 0.22, blue: 0.23)
        case .system: return Color(UIColor.systemGray4)
        }
    }
}

enum AccentColorOption: String, CaseIterable, Identifiable {
    case dinkrGreen = "dinkrGreen"
    case dinkrCoral = "dinkrCoral"
    case dinkrSky   = "dinkrSky"
    case dinkrAmber = "dinkrAmber"
    case purple     = "purple"
    case pink       = "pink"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .dinkrGreen: return Color.dinkrGreen
        case .dinkrCoral: return Color.dinkrCoral
        case .dinkrSky:   return Color.dinkrSky
        case .dinkrAmber: return Color.dinkrAmber
        case .purple:     return Color(red: 0.55, green: 0.25, blue: 0.90)
        case .pink:       return Color(red: 0.96, green: 0.25, blue: 0.55)
        }
    }
}

enum AppIconOption: String, CaseIterable, Identifiable {
    case defaultIcon = "default"
    case dark        = "dark"
    case minimal     = "minimal"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .defaultIcon: return "Default"
        case .dark:        return "Dark"
        case .minimal:     return "Minimal"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .defaultIcon: return Color.dinkrGreen
        case .dark:        return Color.dinkrNavy
        case .minimal:     return Color(UIColor.systemBackground)
        }
    }

    var symbolName: String { "figure.pickleball" }

    var symbolColor: Color {
        switch self {
        case .defaultIcon: return .white
        case .dark:        return Color.dinkrGreen
        case .minimal:     return Color.dinkrNavy
        }
    }
}

enum TextSizeOption: Double, CaseIterable, Identifiable {
    case small   = 13
    case default_ = 15
    case large   = 18
    case xl      = 22

    var id: Double { rawValue }

    var label: String {
        switch self {
        case .small:    return "Small"
        case .default_: return "Default"
        case .large:    return "Large"
        case .xl:       return "XL"
        }
    }

    var fontSize: CGFloat { rawValue }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}

import SwiftUI

// MARK: - Date + Friendly

extension Date {

    /// "2 hours ago", "3 days ago", etc. using the system relative formatter.
    var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Returns `true` when the date falls in the current calendar week (Sun–Sat).
    var isSameWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
}

// MARK: - String + Validation

extension String {

    /// Returns `true` for strings that match a basic RFC-5322-ish email pattern.
    var isValidEmail: Bool {
        let regex = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return range(of: regex, options: .regularExpression) != nil
    }

    /// Returns `true` when the string is 3–20 characters, alphanumeric + underscores only.
    var isValidUsername: Bool {
        let regex = #"^[A-Za-z0-9_]{3,20}$"#
        return range(of: regex, options: .regularExpression) != nil
    }

    /// Whitespace-trimmed copy of the string.
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Double + DUPR

extension Double {

    /// DUPR rating formatted to two decimal places, e.g. `"3.67"`.
    var duprFormatted: String {
        String(format: "%.2f", self)
    }

    /// DUPR delta formatted with an explicit sign, e.g. `"+0.08"` or `"-0.12"`.
    var duprChangeFormatted: String {
        let prefix = self >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", self))"
    }
}

// MARK: - View + ConditionalModifier

extension View {

    /// Applies `transform` to the view only when `condition` is `true`.
    ///
    /// Usage:
    /// ```swift
    /// Text("Hello")
    ///     .if(isHighlighted) { $0.foregroundStyle(Color.dinkrGreen) }
    /// ```
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool,
                              transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Applies `ifTransform` when `condition` is `true`, otherwise `elseTransform`.
    @ViewBuilder
    func `if`<IfContent: View, ElseContent: View>(
        _ condition: Bool,
        transform ifTransform: (Self) -> IfContent,
        else elseTransform: (Self) -> ElseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
}

// MARK: - Color + Hex

extension Color {

    /// Initialises a `Color` from a hex string.
    ///
    /// Supports the following formats (with or without `#`):
    /// - 6-digit RGB:   `"#1ABC62"` or `"1ABC62"`
    /// - 8-digit ARGB:  `"#FF1ABC62"` or `"FF1ABC62"`
    ///
    /// Returns `Color.clear` for malformed inputs.
    init(hex: String) {
        var raw = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        raw = raw.hasPrefix("#") ? String(raw.dropFirst()) : raw

        var value: UInt64 = 0
        guard Scanner(string: raw).scanHexInt64(&value) else {
            self = .clear
            return
        }

        switch raw.count {
        case 6: // RGB
            self = Color(
                red:   Double((value >> 16) & 0xFF) / 255,
                green: Double((value >>  8) & 0xFF) / 255,
                blue:  Double( value        & 0xFF) / 255
            )
        case 8: // ARGB
            self = Color(
                red:     Double((value >> 16) & 0xFF) / 255,
                green:   Double((value >>  8) & 0xFF) / 255,
                blue:    Double( value        & 0xFF) / 255,
                opacity: Double((value >> 24) & 0xFF) / 255
            )
        default:
            self = .clear
        }
    }
}

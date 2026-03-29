import SwiftUI

struct GameFilterBar: View {
    @Binding var selectedFormat: GameFormat?
    @Binding var todayOnly: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Today toggle
                Button {
                    todayOnly.toggle()
                } label: {
                    Label("Today", systemImage: "sun.max.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(todayOnly ? .white : Color.dinkrAmber)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(todayOnly ? Color.dinkrAmber : Color.dinkrAmber.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Divider().frame(height: 20)

                // Format chips
                FormatChip(label: "All", format: nil, selectedFormat: $selectedFormat)
                FormatChip(label: "Doubles", format: .doubles, selectedFormat: $selectedFormat)
                FormatChip(label: "Singles", format: .singles, selectedFormat: $selectedFormat)
                FormatChip(label: "Open Play", format: .openPlay, selectedFormat: $selectedFormat)
                FormatChip(label: "Round Robin", format: .round_robin, selectedFormat: $selectedFormat)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

private struct FormatChip: View {
    let label: String
    let format: GameFormat?
    @Binding var selectedFormat: GameFormat?

    var isSelected: Bool { selectedFormat == format }

    var body: some View {
        Button {
            selectedFormat = isSelected ? nil : format
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(isSelected ? .white : Color.dinkrGreen)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? Color.dinkrGreen : Color.dinkrGreen.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

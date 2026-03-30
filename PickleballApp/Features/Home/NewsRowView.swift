import SwiftUI

struct NewsRowView: View {
    let title: String
    let source: String
    let date: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
            HStack(spacing: 4) {
                Text(source)
                    .font(.caption)
                    .foregroundStyle(Color.dinkrGreen)
                Text("·")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NewsRowView(title: "PPA Tour Announces Expanded 2025 Schedule", source: "Pickleball Central", date: "Mar 26")
        .padding()
}

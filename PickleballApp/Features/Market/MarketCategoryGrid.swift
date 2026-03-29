import SwiftUI

struct MarketCategoryGrid: View {
    @Binding var selectedCategory: MarketCategory?

    let categories: [(category: MarketCategory?, icon: String, label: String, color: Color)] = [
        (nil, "square.grid.2x2", "All", Color.dinkrGreen),
        (.paddles, "figure.pickleball", "Paddles", Color.dinkrCoral),
        (.balls, "circle.fill", "Balls", Color.dinkrAmber),
        (.bags, "bag.fill", "Bags", Color.dinkrSky),
        (.apparel, "tshirt.fill", "Apparel", .purple),
        (.shoes, "shoeprints.fill", "Shoes", .teal),
        (.accessories, "sparkles", "Accessories", .pink),
        (.other, "ellipsis.circle", "Other", .secondary),
    ]

    let columns = Array(repeating: GridItem(.flexible()), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(categories, id: \.label) { item in
                Button {
                    selectedCategory = item.category
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selectedCategory == item.category
                                      ? item.color
                                      : item.color.opacity(0.12))
                                .frame(width: 52, height: 52)
                            Image(systemName: item.icon)
                                .font(.title3)
                                .foregroundStyle(selectedCategory == item.category ? .white : item.color)
                        }
                        Text(item.label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }
}

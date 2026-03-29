import SwiftUI

struct ListingCardView: View {
    let listing: MarketListing
    @State private var isSaved = false

    var isHot: Bool { listing.viewCount > 40 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Photo area
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.cardBackground)
                    .frame(height: 130)
                    .overlay {
                        Image(systemName: categoryIcon)
                            .font(.system(size: 36))
                            .foregroundStyle(Color.dinkrCoral.opacity(0.35))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                // Top-right overlay: heart button (and hot badge stacked below)
                VStack(alignment: .trailing, spacing: 4) {
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                            isSaved.toggle()
                        }
                    } label: {
                        Image(systemName: isSaved ? "heart.fill" : "heart")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isSaved ? Color.dinkrCoral : Color.secondary)
                            .padding(7)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .scaleEffect(isSaved ? 1.2 : 1.0)
                    }
                    .buttonStyle(.plain)

                    // Hot badge
                    if isHot {
                        Text("🔥 Hot")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.dinkrCoral)
                            .clipShape(Capsule())
                    }
                }
                .padding(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Condition badge + view count
                HStack {
                    Text(listing.condition.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(conditionColor)
                        .clipShape(Capsule())
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: "eye")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Text("\(listing.viewCount)")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }

                Text(listing.brand)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(listing.model)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text("$\(Int(listing.price))")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.dinkrCoral)
                Label(listing.location, systemImage: "mappin")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .background(Color.appBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    var categoryIcon: String {
        switch listing.category {
        case .paddles: return "figure.pickleball"
        case .balls: return "circle.fill"
        case .bags: return "bag.fill"
        case .apparel: return "tshirt.fill"
        case .shoes: return "shoeprints.fill"
        case .accessories: return "sparkles"
        case .courts: return "sportscourt"
        case .other: return "ellipsis.circle"
        }
    }

    var conditionColor: Color {
        switch listing.condition {
        case .brandNew: return Color.dinkrGreen
        case .likeNew: return Color.dinkrSky
        case .good: return Color.dinkrAmber
        case .fair: return Color.dinkrCoral
        case .forParts: return .secondary
        }
    }
}

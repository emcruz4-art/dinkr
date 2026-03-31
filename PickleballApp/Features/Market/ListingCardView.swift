import SwiftUI

struct ListingCardView: View {
    let listing: MarketListing
    var showSoldBanner: Bool = false
    var isNewThisWeek: Bool = false

    @State private var isSaved = false
    @State private var isPressed = false

    var isHot: Bool { listing.viewCount > 40 }

    var categoryTintColor: Color {
        switch listing.category {
        case .paddles:     return Color.dinkrCoral
        case .balls:       return Color.dinkrAmber
        case .bags:        return Color.dinkrSky
        case .apparel:     return .purple
        case .shoes:       return .teal
        case .accessories: return .pink
        case .courts:      return Color.dinkrGreen
        case .other:       return Color.dinkrNavy
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Photo area ──────────────────────────────────────────────
            ZStack(alignment: .bottom) {
                // Image / gradient placeholder
                CachedAsyncImage(urlString: listing.photos.first) {
                    ZStack {
                        LinearGradient(
                            colors: [
                                categoryTintColor.opacity(0.18),
                                categoryTintColor.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: categoryIcon)
                            .font(.system(size: 44))
                            .foregroundStyle(categoryTintColor.opacity(0.45))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .clipped()

                // Vignette overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.30)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 140)
                .allowsHitTesting(false)
            }
            .frame(height: 140)
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 18, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: 18
            ))
            // ── SOLD diagonal banner ──────────────────────────────────
            .overlay {
                if showSoldBanner {
                    SoldDiagonalBanner()
                        .clipShape(UnevenRoundedRectangle(
                            topLeadingRadius: 18, bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0, topTrailingRadius: 18
                        ))
                }
            }
            .overlay(alignment: .topLeading) {
                // Condition badge — top left
                Text(listing.condition.rawValue)
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(conditionColor)
                    .clipShape(Capsule())
                    .padding(8)
            }
            .overlay(alignment: .topTrailing) {
                // Hot badge + save button — top right
                VStack(alignment: .trailing, spacing: 4) {
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                            isSaved.toggle()
                        }
                    } label: {
                        Image(systemName: isSaved ? "heart.fill" : "heart")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(isSaved ? Color.dinkrCoral : .white)
                            .padding(7)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .scaleEffect(isSaved ? 1.2 : 1.0)
                    }
                    .buttonStyle(.plain)

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

            // ── Info area ────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {

                // Brand + model
                Text(listing.brand)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: 5) {
                    Text(listing.model)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .foregroundStyle(.primary)

                    // "New This Week" green chip
                    if isNewThisWeek {
                        Text("New")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.dinkrGreen)
                            .clipShape(Capsule())
                    }
                }

                // Price — big and bold
                // Strike-through style when sold, normal green otherwise
                Text("$\(Int(listing.price))")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(listing.status == .sold ? Color.dinkrCoral : Color.dinkrGreen)
                    .strikethrough(listing.status == .sold, color: Color.dinkrCoral)

                Divider()
                    .padding(.vertical, 2)

                // Bottom row: seller + view count
                HStack(spacing: 6) {
                    AvatarView(displayName: listing.sellerName, size: 20)
                    Text(listing.sellerName)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
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

                // Location
                Label(listing.location, systemImage: "mappin")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .background(Color.appBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(
            color: categoryTintColor.opacity(0.18),
            radius: 10, x: 0, y: 4
        )
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 1)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    var categoryIcon: String {
        switch listing.category {
        case .paddles:     return "figure.pickleball"
        case .balls:       return "circle.fill"
        case .bags:        return "bag.fill"
        case .apparel:     return "tshirt.fill"
        case .shoes:       return "shoeprints.fill"
        case .accessories: return "sparkles"
        case .courts:      return "sportscourt"
        case .other:       return "ellipsis.circle"
        }
    }

    var conditionColor: Color {
        switch listing.condition {
        case .brandNew:  return Color.dinkrGreen
        case .likeNew:   return Color.dinkrSky
        case .good:      return Color.dinkrAmber
        case .fair:      return Color.dinkrCoral
        case .forParts:  return .secondary
        }
    }
}

// MARK: - Sold Diagonal Banner

private struct SoldDiagonalBanner: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Dark scrim over the image
                Color.black.opacity(0.38)

                // Diagonal ribbon
                Text("SOLD")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)
                    .tracking(3)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 6)
                    .background(Color.dinkrCoral)
                    .rotationEffect(.degrees(-35))
                    .offset(y: 10)
            }
        }
        .allowsHitTesting(false)
    }
}

import SwiftUI

struct MyOffersView: View {
    let userId: String
    @State private var offers: [MarketOffer] = []
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(Color.dinkrGreen)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if offers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tag.slash")
                            .font(.system(size: 48, weight: .thin))
                            .foregroundStyle(Color.dinkrNavy.opacity(0.3))
                        Text("No Offers Yet")
                            .font(.headline)
                            .foregroundStyle(Color.dinkrNavy.opacity(0.6))
                        Text("Offers you make on listings will appear here")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List(offers) { offer in
                        OfferRowView(offer: offer)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Offers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
            .task {
                offers = await OfferService.shared.loadOffersByBuyer(userId)
                isLoading = false
            }
        }
    }
}

struct OfferRowView: View {
    let offer: MarketOffer

    private var statusColor: Color {
        switch offer.status {
        case .pending:   return Color.dinkrAmber
        case .accepted:  return Color.dinkrGreen
        case .declined:  return Color.dinkrCoral
        case .withdrawn: return Color.secondary
        }
    }

    private var statusIcon: String {
        switch offer.status {
        case .pending:   return "clock"
        case .accepted:  return "checkmark.circle.fill"
        case .declined:  return "xmark.circle.fill"
        case .withdrawn: return "arrow.uturn.left.circle"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(offer.listingTitle)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("Offered to \(offer.sellerName)")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                Text(offer.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(Int(offer.amount))")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.dinkrNavy)
                Text(offer.status.rawValue.capitalized)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

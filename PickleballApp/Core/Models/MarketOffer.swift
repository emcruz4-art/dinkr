import Foundation

enum OfferStatus: String, Codable {
    case pending
    case accepted
    case declined
    case withdrawn
}

struct MarketOffer: Identifiable, Codable {
    var id: String
    var listingId: String
    var listingTitle: String   // "Brand Model" for display
    var buyerId: String
    var buyerName: String
    var sellerId: String
    var sellerName: String
    var amount: Double
    var message: String
    var status: OfferStatus
    var createdAt: Date
    var respondedAt: Date?
}

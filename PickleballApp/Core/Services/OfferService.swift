import Foundation
import FirebaseFirestore
import Observation

@Observable
final class OfferService {
    static let shared = OfferService()
    private let db = Firestore.firestore()
    private init() {}

    // Submit an offer — buyer calls this
    func submitOffer(_ offer: MarketOffer) async throws {
        try await FirestoreService.shared.setDocument(
            offer,
            collection: FirestoreCollections.offers,
            documentId: offer.id
        )
    }

    // Load offers received by seller for a specific listing
    func loadOffersForListing(_ listingId: String) async -> [MarketOffer] {
        (try? await FirestoreService.shared.queryCollection(
            collection: FirestoreCollections.offers,
            field: "listingId",
            isEqualTo: listingId
        )) ?? []
    }

    // Load all offers made by a buyer
    func loadOffersByBuyer(_ buyerId: String) async -> [MarketOffer] {
        (try? await FirestoreService.shared.queryCollection(
            collection: FirestoreCollections.offers,
            field: "buyerId",
            isEqualTo: buyerId
        )) ?? []
    }

    // Load all offers received by a seller
    func loadOffersBySeller(_ sellerId: String) async -> [MarketOffer] {
        (try? await FirestoreService.shared.queryCollection(
            collection: FirestoreCollections.offers,
            field: "sellerId",
            isEqualTo: sellerId
        )) ?? []
    }

    // Seller responds to offer
    func respondToOffer(offerId: String, accept: Bool) async {
        let status = accept ? OfferStatus.accepted : OfferStatus.declined
        try? await FirestoreService.shared.updateDocument(
            collection: FirestoreCollections.offers,
            documentId: offerId,
            data: [
                "status": status.rawValue,
                "respondedAt": Timestamp(date: Date())
            ]
        )
    }
}

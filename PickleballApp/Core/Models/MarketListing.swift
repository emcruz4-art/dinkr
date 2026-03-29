import Foundation

struct MarketListing: Identifiable, Codable, Hashable {
    var id: String
    var sellerId: String
    var sellerName: String
    var category: MarketCategory
    var brand: String
    var model: String
    var condition: ListingCondition
    var price: Double
    var description: String
    var photos: [String]
    var status: ListingStatus
    var location: String
    var createdAt: Date
    var isFeatured: Bool
    var viewCount: Int
}

extension MarketListing {
    static let mockListings: [MarketListing] = [
        MarketListing(id: "ml_001", sellerId: "user_005", sellerName: "Chris Park",
                      category: .paddles, brand: "Selkirk", model: "Vanguard Power Air",
                      condition: .likeNew, price: 185.00,
                      description: "Used for 3 months. Small scuff on edge guard but plays perfectly. Original grip still on. Comes with cover.",
                      photos: [], status: .active, location: "Austin, TX",
                      createdAt: Date().addingTimeInterval(-86400), isFeatured: true, viewCount: 47),
        MarketListing(id: "ml_002", sellerId: "user_006", sellerName: "Taylor Kim",
                      category: .paddles, brand: "JOOLA", model: "Ben Johns Hyperion CAS 16",
                      condition: .good, price: 120.00,
                      description: "Great paddle, upgrading to a newer model. Light scratches but fully functional. Grip has been replaced.",
                      photos: [], status: .active, location: "Round Rock, TX",
                      createdAt: Date().addingTimeInterval(-172800), isFeatured: false, viewCount: 31),
        MarketListing(id: "ml_003", sellerId: "user_007", sellerName: "Jamie Lee",
                      category: .bags, brand: "HEAD", model: "Tour Team Backpack",
                      condition: .brandNew, price: 65.00,
                      description: "Never used. Gift I received that doesn't fit my style. Tags still on.",
                      photos: [], status: .active, location: "Cedar Park, TX",
                      createdAt: Date().addingTimeInterval(-43200), isFeatured: false, viewCount: 18),
        MarketListing(id: "ml_004", sellerId: "user_008", sellerName: "Morgan Davis",
                      category: .shoes, brand: "K-Swiss", model: "Hypercourt Express 2 HB",
                      condition: .good, price: 55.00,
                      description: "Size 10.5. Great court shoes, only used one season. Normal wear on soles.",
                      photos: [], status: .active, location: "Austin, TX",
                      createdAt: Date().addingTimeInterval(-259200), isFeatured: false, viewCount: 22),
        MarketListing(id: "ml_005", sellerId: "user_002", sellerName: "Maria Chen",
                      category: .apparel, brand: "Prince", model: "Women's Court Tank",
                      condition: .likeNew, price: 28.00,
                      description: "Wore twice, perfect condition. Size M. Breathable fabric, great for outdoor play.",
                      photos: [], status: .active, location: "Austin, TX",
                      createdAt: Date().addingTimeInterval(-21600), isFeatured: false, viewCount: 15),
        MarketListing(id: "ml_006", sellerId: "user_007", sellerName: "Jamie Lee",
                      category: .paddles, brand: "Franklin", model: "Ben Johns Signature",
                      condition: .good, price: 95.00,
                      description: "Intermediate paddle, great for 3.0–3.5 players. Upgrading to pro-level. Has sticker on back.",
                      photos: [], status: .active, location: "Austin, TX",
                      createdAt: Date().addingTimeInterval(-108000), isFeatured: false, viewCount: 67),
        MarketListing(id: "ml_007", sellerId: "user_003", sellerName: "Jordan Smith",
                      category: .balls, brand: "ONIX", model: "Pure 2 Outdoor 6-Pack",
                      condition: .brandNew, price: 22.00,
                      description: "Never opened. Received as gift, already have plenty. USAPA approved.",
                      photos: [], status: .active, location: "Austin, TX",
                      createdAt: Date().addingTimeInterval(-32400), isFeatured: false, viewCount: 9),
        MarketListing(id: "ml_008", sellerId: "user_009", sellerName: "Riley Torres",
                      category: .accessories, brand: "Gamma", model: "Overgrip 30-Pack",
                      condition: .brandNew, price: 18.00,
                      description: "Unopened 30-pack of overgrips. Great deal — bought too many.",
                      photos: [], status: .active, location: "Austin, TX",
                      createdAt: Date().addingTimeInterval(-64800), isFeatured: false, viewCount: 24),
        MarketListing(id: "ml_009", sellerId: "user_005", sellerName: "Chris Park",
                      category: .paddles, brand: "Electrum", model: "Model E Pro",
                      condition: .likeNew, price: 210.00,
                      description: "Used for one month. Pro-level paddle, slight edge wear but surface pristine. Comes with original sleeve.",
                      photos: [], status: .active, location: "Round Rock, TX",
                      createdAt: Date().addingTimeInterval(-7200), isFeatured: true, viewCount: 89),
        MarketListing(id: "ml_010", sellerId: "user_008", sellerName: "Morgan Davis",
                      category: .shoes, brand: "New Balance", model: "MC806v1",
                      condition: .good, price: 48.00,
                      description: "Size 9 women's. Worn one season, still plenty of life left. Great lateral support.",
                      photos: [], status: .active, location: "Austin, TX",
                      createdAt: Date().addingTimeInterval(-129600), isFeatured: false, viewCount: 31),
    ]
}

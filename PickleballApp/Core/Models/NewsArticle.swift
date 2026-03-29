import Foundation

struct NewsArticle: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var source: String
    var summary: String
    var url: String
    var publishedAt: Date
    var category: NewsCategory
    var imageURL: String?

    enum NewsCategory: String, Codable, CaseIterable {
        case tour = "Tour"
        case tips = "Tips"
        case gear = "Gear"
        case community = "Community"
        case health = "Health"
    }
}

extension NewsArticle {
    static let mockArticles: [NewsArticle] = [
        NewsArticle(id: "n1", title: "PPA Tour Announces 2025 Austin Stop Details",
                    source: "PPA Tour", summary: "The Pro Pickleball Association confirms Austin as a premier stop in the 2025 circuit, featuring a $150K prize pool across all brackets.",
                    url: "https://ppatour.com", publishedAt: Date().addingTimeInterval(-3600),
                    category: .tour, imageURL: nil),
        NewsArticle(id: "n2", title: "5 Dink Drills That Will Transform Your Third-Shot Game",
                    source: "Pickleball Kitchen", summary: "Coach Maria Torres breaks down the five essential dink drills that separate 3.5 from 4.0 players. Includes video walkthroughs.",
                    url: "https://pickleballkitchen.com", publishedAt: Date().addingTimeInterval(-7200),
                    category: .tips, imageURL: nil),
        NewsArticle(id: "n3", title: "Selkirk Drops New Power Series — We Tested It",
                    source: "Gear Report", summary: "The new Selkirk Power Series promises 15% more pop without sacrificing control. Our testers put it through 40 hours of play.",
                    url: "https://gearreport.com", publishedAt: Date().addingTimeInterval(-14400),
                    category: .gear, imageURL: nil),
        NewsArticle(id: "n4", title: "Austin Pickleball Community Raises $28K for Local Courts",
                    source: "Austin Chronicle", summary: "A grassroots fundraising campaign by local players secured new lighting and resurfacing for four public courts at Zilker Park.",
                    url: "https://austinchronicle.com", publishedAt: Date().addingTimeInterval(-28800),
                    category: .community, imageURL: nil),
        NewsArticle(id: "n5", title: "The Right Warm-Up Routine to Prevent Common Pickleball Injuries",
                    source: "Sports Medicine Weekly", summary: "Physical therapists share a 10-minute warm-up protocol designed specifically for pickleball players to prevent elbow and knee injuries.",
                    url: "https://sportsmedicine.com", publishedAt: Date().addingTimeInterval(-86400),
                    category: .health, imageURL: nil),
        NewsArticle(id: "n6", title: "Ben Johns Wins His 50th Professional Title",
                    source: "PPA Tour", summary: "In a dominant performance at the Nashville Open, Ben Johns clinched his 50th professional singles title, cementing his GOAT status.",
                    url: "https://ppatour.com", publishedAt: Date().addingTimeInterval(-172800),
                    category: .tour, imageURL: nil),
    ]
}

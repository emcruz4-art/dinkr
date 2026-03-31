import Foundation

// MARK: - DUPRDataPoint

struct DUPRDataPoint: Identifiable, Codable {
    var id: String
    var date: Date
    var rating: Double
    var change: Double       // +/- from previous data point
    var gameId: String?      // which game caused the change
    var opponentName: String?
    var isWin: Bool
}

// MARK: - Mock Data

extension DUPRDataPoint {
    /// 12 data points spanning ~6 months, realistic progression from 3.42 → 3.67.
    static let mockHistory: [DUPRDataPoint] = {
        let cal = Calendar.current
        let now = Date()

        // Helper: date N days before today
        func daysAgo(_ n: Int) -> Date {
            cal.date(byAdding: .day, value: -n, to: now) ?? now
        }

        return [
            DUPRDataPoint(
                id: "dp_01",
                date: daysAgo(175),
                rating: 3.42,
                change: 0.00,
                gameId: "game_001",
                opponentName: "Jordan Smith",
                isWin: false
            ),
            DUPRDataPoint(
                id: "dp_02",
                date: daysAgo(155),
                rating: 3.46,
                change: +0.04,
                gameId: "game_014",
                opponentName: "Morgan Davis",
                isWin: true
            ),
            DUPRDataPoint(
                id: "dp_03",
                date: daysAgo(138),
                rating: 3.50,
                change: +0.04,
                gameId: "game_027",
                opponentName: "Taylor Kim",
                isWin: true
            ),
            DUPRDataPoint(
                id: "dp_04",
                date: daysAgo(120),
                rating: 3.48,
                change: -0.02,
                gameId: "game_041",
                opponentName: "Jamie Lee",
                isWin: false
            ),
            DUPRDataPoint(
                id: "dp_05",
                date: daysAgo(104),
                rating: 3.52,
                change: +0.04,
                gameId: "game_056",
                opponentName: "Riley Torres",
                isWin: true
            ),
            DUPRDataPoint(
                id: "dp_06",
                date: daysAgo(88),
                rating: 3.55,
                change: +0.03,
                gameId: "game_068",
                opponentName: "Chris Park",
                isWin: true
            ),
            DUPRDataPoint(
                id: "dp_07",
                date: daysAgo(74),
                rating: 3.53,
                change: -0.02,
                gameId: "game_079",
                opponentName: "Jordan Smith",
                isWin: false
            ),
            DUPRDataPoint(
                id: "dp_08",
                date: daysAgo(58),
                rating: 3.57,
                change: +0.04,
                gameId: "game_092",
                opponentName: "Maria Chen",
                isWin: true
            ),
            DUPRDataPoint(
                id: "dp_09",
                date: daysAgo(44),
                rating: 3.60,
                change: +0.03,
                gameId: "game_103",
                opponentName: "Sarah Johnson",
                isWin: true
            ),
            DUPRDataPoint(
                id: "dp_10",
                date: daysAgo(30),
                rating: 3.62,
                change: +0.02,
                gameId: "game_115",
                opponentName: "Taylor Kim",
                isWin: true
            ),
            DUPRDataPoint(
                id: "dp_11",
                date: daysAgo(16),
                rating: 3.60,
                change: -0.02,
                gameId: "game_128",
                opponentName: "Jamie Lee",
                isWin: false
            ),
            DUPRDataPoint(
                id: "dp_12",
                date: daysAgo(4),
                rating: 3.67,
                change: +0.07,
                gameId: "game_141",
                opponentName: "Jordan Smith",
                isWin: true
            ),
        ]
    }()
}

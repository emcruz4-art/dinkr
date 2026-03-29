import XCTest
@testable import PickleballApp

final class PickleballAppTests: XCTestCase {

    func testMockUserCreation() {
        let user = User.mockCurrentUser
        XCTAssertEqual(user.id, "user_001")
        XCTAssertFalse(user.displayName.isEmpty)
        XCTAssertGreaterThan(user.reliabilityScore, 0)
    }

    func testWinRateCalculation() {
        let user = User.mockCurrentUser
        let expected = Double(user.wins) / Double(user.gamesPlayed)
        XCTAssertEqual(user.winRate, expected, accuracy: 0.001)
    }

    func testMockGameSessions() {
        let sessions = GameSession.mockSessions
        XCTAssertFalse(sessions.isEmpty)
        for session in sessions {
            XCTAssertLessThanOrEqual(session.skillRange.lowerBound, session.skillRange.upperBound)
        }
    }

    func testGameSessionSpots() {
        let session = GameSession.mockSessions[0]
        XCTAssertEqual(session.spotsRemaining, session.totalSpots - session.rsvps.count)
    }

    func testMockEventsNotEmpty() {
        XCTAssertFalse(Event.mockEvents.isEmpty)
    }

    func testMockListingsNotEmpty() {
        XCTAssertFalse(MarketListing.mockListings.isEmpty)
    }

    func testDateHelpers() {
        let now = Date()
        XCTAssertTrue(now.isToday)
        XCTAssertFalse(now.isTomorrow)
        XCTAssertFalse(now.relativeString.isEmpty)
    }

    @MainActor
    func testAuthServiceInitialState() {
        let auth = AuthService()
        XCTAssertFalse(auth.isAuthenticated)
        XCTAssertNil(auth.currentUser)
    }
}

import Foundation
import CoreLocation

// MARK: - AppConfiguration

enum AppConfiguration {

    // MARK: App Info

    static let appVersion: String =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    static let buildNumber: String =
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    static var fullVersionString: String { "\(appVersion) (\(buildNumber))" }

    // MARK: Feature Flags

    /// Live scoring during active matches.
    static let enableLiveScoring = true

    /// Court reservation / booking flow.
    static let enableCourtBooking = true

    /// Tournament registration module.
    static let enableTournamentReg = true

    /// Organisation-wide leaderboard tab.
    static let enableOrgLeaderboard = true

    /// In-app marketplace (gear, lessons, etc.).
    static let enableMarketplace = true

    // MARK: Defaults & Constants

    /// Fallback city shown when location is unavailable.
    static let defaultCity = "Austin, TX"

    /// Fallback coordinates (Austin, TX).
    static let defaultCoordinates: (lat: Double, lon: Double) = (lat: 30.2672, lon: -97.7431)

    static var defaultLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: defaultCoordinates.lat,
                               longitude: defaultCoordinates.lon)
    }

    /// Maximum number of members in a group.
    static let maxGroupSize = 50

    /// Maximum character count for chat / feed messages.
    static let maxMessageLength = 280

    /// DUPR API base URL (stub — replace when key is issued).
    static let duprApiBaseURL = "https://api.dupr.gg"

    // MARK: Pagination

    static let defaultPageSize = 20
    static let feedPageSize = 30

    // MARK: Timeouts

    /// Network request timeout in seconds.
    static let networkTimeout: TimeInterval = 15

    // MARK: Environment

    enum Environment {
        case debug, staging, production

        static var current: Environment {
            #if DEBUG
            return .debug
            #else
            return .production
            #endif
        }
    }

    static var isDebug: Bool { Environment.current == .debug }
}

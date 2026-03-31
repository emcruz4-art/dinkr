import SwiftUI

// MARK: - DeepLink

enum DeepLink: Equatable {
    case game(id: String)
    case player(id: String)
    case event(id: String)
    case court(id: String)
    case group(id: String)
    case challenge
    case notifications

    // MARK: URL Parsing

    /// Parses a `dinkr://` URL into a DeepLink case.
    ///
    /// Supported schemes:
    ///   dinkr://game/<id>
    ///   dinkr://player/<id>
    ///   dinkr://event/<id>
    ///   dinkr://court/<id>
    ///   dinkr://group/<id>
    ///   dinkr://challenge
    ///   dinkr://notifications
    static func from(url: URL) -> DeepLink? {
        guard url.scheme?.lowercased() == "dinkr" else { return nil }

        let host = url.host?.lowercased() ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "game":
            guard let id = pathComponents.first, !id.isEmpty else { return nil }
            return .game(id: id)

        case "player":
            guard let id = pathComponents.first, !id.isEmpty else { return nil }
            return .player(id: id)

        case "event":
            guard let id = pathComponents.first, !id.isEmpty else { return nil }
            return .event(id: id)

        case "court":
            guard let id = pathComponents.first, !id.isEmpty else { return nil }
            return .court(id: id)

        case "group":
            guard let id = pathComponents.first, !id.isEmpty else { return nil }
            return .group(id: id)

        case "challenge":
            return .challenge

        case "notifications":
            return .notifications

        default:
            return nil
        }
    }
}

// MARK: - DeepLinkHandler

@Observable
final class DeepLinkHandler {

    static let shared = DeepLinkHandler()

    /// Set when a deep link arrives. Consuming views should read and clear this.
    var pendingDeepLink: DeepLink?

    private init() {}

    // MARK: URL Handling

    /// Handle a raw URL (e.g. from `onOpenURL` or `application(_:open:options:)`).
    func handle(_ url: URL) {
        guard let deepLink = DeepLink.from(url: url) else {
            #if DEBUG
            print("[DeepLinkHandler] Unrecognised URL: \(url)")
            #endif
            return
        }
        pendingDeepLink = deepLink
    }

    // MARK: NSUserActivity Handling

    /// Handle a Handoff / Universal Link activity.
    /// Expects `activityType == NSUserActivityTypeBrowsingWeb` with a `webpageURL`
    /// that redirects to a `dinkr://` deep link.
    func handle(_ userActivity: NSUserActivity) {
        guard
            userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let webURL = userActivity.webpageURL
        else { return }

        // Attempt direct parse first (in case the universal link IS the deep link)
        if let deepLink = DeepLink.from(url: webURL) {
            pendingDeepLink = deepLink
            return
        }

        // Map https://dinkr.app/<host>/<id> → dinkr://<host>/<id>
        var components = URLComponents(url: webURL, resolvingAgainstBaseURL: false)
        components?.scheme = "dinkr"
        if let mapped = components?.url, let deepLink = DeepLink.from(url: mapped) {
            pendingDeepLink = deepLink
        } else {
            #if DEBUG
            print("[DeepLinkHandler] Could not map universal link: \(webURL)")
            #endif
        }
    }

    // MARK: Convenience

    /// Clears the pending deep link after it has been consumed.
    func consume() {
        pendingDeepLink = nil
    }
}

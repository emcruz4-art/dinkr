import FirebaseAnalytics

enum AnalyticsService {

    // MARK: - Screen Tracking

    /// Call from `.onAppear` in each top-level view.
    /// Example: `.onAppear { AnalyticsService.logScreen("Home") }`
    static func logScreen(_ name: String, class screenClass: String = "") {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: name,
            AnalyticsParameterScreenClass: screenClass.isEmpty ? name : screenClass,
        ])
    }

    // MARK: - Auth Events

    /// Call after a successful sign-in. Pass "apple", "google", or "email".
    static func logSignIn(method: String) {
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method,
        ])
    }

    /// Call after a successful account creation. Pass "apple", "google", or "email".
    static func logSignUp(method: String) {
        Analytics.logEvent(AnalyticsEventSignUp, parameters: [
            AnalyticsParameterMethod: method,
        ])
    }

    // MARK: - Game Events

    static func logGameJoined(sessionId: String, format: String, courtName: String) {
        Analytics.logEvent("game_joined", parameters: [
            "session_id": sessionId,
            "format": format,
            "court_name": courtName,
        ])
    }

    static func logGameHosted(sessionId: String, format: String) {
        Analytics.logEvent("game_hosted", parameters: [
            "session_id": sessionId,
            "format": format,
        ])
    }

    static func logRSVPCancelled(sessionId: String) {
        Analytics.logEvent("rsvp_cancelled", parameters: [
            "session_id": sessionId,
        ])
    }

    // MARK: - Social Events

    /// `type` examples: "text", "image", "video"
    static func logPostCreated(type: String, hasMedia: Bool) {
        Analytics.logEvent("post_created", parameters: [
            "post_type": type,
            "has_media": hasMedia,
        ])
    }

    static func logPostLiked(postId: String) {
        Analytics.logEvent("post_liked", parameters: [
            AnalyticsParameterItemID: postId,
        ])
    }

    static func logPlayerFollowed(targetUserId: String) {
        Analytics.logEvent("player_followed", parameters: [
            "target_user_id": targetUserId,
        ])
    }

    /// Call when a match-swipe connection is accepted.
    static func logPlayerConnected() {
        Analytics.logEvent("player_connected", parameters: nil)
    }

    // MARK: - Content Events

    static func logEventViewed(eventId: String, eventName: String) {
        Analytics.logEvent(AnalyticsEventViewItem, parameters: [
            AnalyticsParameterItemID: eventId,
            AnalyticsParameterItemName: eventName,
            AnalyticsParameterItemCategory: "event",
        ])
    }

    static func logListingViewed(listingId: String, category: String) {
        Analytics.logEvent(AnalyticsEventViewItem, parameters: [
            AnalyticsParameterItemID: listingId,
            AnalyticsParameterItemCategory: category,
        ])
    }

    static func logListingCreated(category: String, price: Double) {
        Analytics.logEvent("listing_created", parameters: [
            AnalyticsParameterItemCategory: category,
            AnalyticsParameterPrice: price,
        ])
    }

    static func logSearchPerformed(query: String, resultsCount: Int) {
        Analytics.logEvent(AnalyticsEventSearch, parameters: [
            AnalyticsParameterSearchTerm: query,
            "results_count": resultsCount,
        ])
    }

    // MARK: - Training Events

    static func logDrillCompleted(drillId: String, category: String) {
        Analytics.logEvent("drill_completed", parameters: [
            AnalyticsParameterItemID: drillId,
            AnalyticsParameterItemCategory: category,
        ])
    }

    static func logTrainingPlanStarted(planId: String, level: String) {
        Analytics.logEvent("training_plan_started", parameters: [
            AnalyticsParameterItemID: planId,
            "level": level,
        ])
    }

    static func logStreakUpdated(streakDays: Int) {
        Analytics.logEvent("streak_updated", parameters: [
            "streak_days": streakDays,
        ])
    }

    // MARK: - Engagement Events

    static func logTabSwitched(tabName: String) {
        Analytics.logEvent("tab_switched", parameters: [
            "tab_name": tabName,
        ])
    }

    static func logNotificationTapped(type: String) {
        Analytics.logEvent("notification_tapped", parameters: [
            "notification_type": type,
        ])
    }

    static func logShareTapped(contentType: String) {
        Analytics.logEvent(AnalyticsEventShare, parameters: [
            AnalyticsParameterContentType: contentType,
        ])
    }

    // MARK: - Pro / Monetization Events

    static func logPaywallShown(source: String) {
        Analytics.logEvent("paywall_shown", parameters: [
            "source": source,
        ])
    }

    static func logProPurchaseStarted(productId: String) {
        Analytics.logEvent(AnalyticsEventBeginCheckout, parameters: [
            AnalyticsParameterItemID: productId,
        ])
    }

    static func logProPurchaseCompleted(productId: String, price: Double) {
        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterItemID: productId,
            AnalyticsParameterPrice: price,
            AnalyticsParameterCurrency: "USD",
        ])
    }
}

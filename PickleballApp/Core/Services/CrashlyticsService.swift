import FirebaseCrashlytics

enum CrashlyticsService {

    // MARK: - User Identity

    /// Call after sign-in so crash reports are tied to the user.
    static func setUser(id: String, email: String?) {
        Crashlytics.crashlytics().setUserID(id)
        if let email {
            Crashlytics.crashlytics().setCustomValue(email, forKey: "user_email")
        }
    }

    // MARK: - Error Recording

    /// Record a non-fatal error with an optional plain-English context string.
    static func record(error: Error, context: String) {
        Crashlytics.crashlytics().log(context)
        Crashlytics.crashlytics().record(error: error)
    }

    /// Append a message to the Crashlytics log visible in the crash report.
    static func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }

    // MARK: - Custom Keys

    /// Attach a string key/value pair to every subsequent crash report.
    static func setContext(key: String, value: String) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
}

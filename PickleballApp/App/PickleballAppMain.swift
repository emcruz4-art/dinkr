import SwiftUI
import FirebaseCore
import FirebaseCrashlytics
import FirebaseMessaging
import GoogleSignIn

@main
struct PickleballAppMain: App {
    @State private var authService = AuthService()
    @State private var locationService = LocationService()
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var storeService = StoreService.shared

    init() {
        FirebaseApp.configure()
        MessagingService.shared.setup()

        #if !DEBUG
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        #endif

        configureAppearance()
    }

    // MARK: - Global UIKit Appearance

    private func configureAppearance() {
        // ── Navigation Bar ──────────────────────────────────────────────────
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor.systemBackground
        navAppearance.shadowColor = UIColor.separator.withAlphaComponent(0.3)

        // Rounded-bold large title
        let largeTitleDescriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .largeTitle)
            .withSymbolicTraits(.traitBold)?
            .withDesign(.rounded) ?? UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
        navAppearance.largeTitleTextAttributes = [
            .font: UIFont(descriptor: largeTitleDescriptor, size: 0),
            .foregroundColor: UIColor(red: 0.10, green: 0.18, blue: 0.29, alpha: 1), // dinkrNavy
        ]

        // Rounded-semibold inline title
        let inlineTitleDescriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .headline)
            .withSymbolicTraits(.traitBold)?
            .withDesign(.rounded) ?? UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
        navAppearance.titleTextAttributes = [
            .font: UIFont(descriptor: inlineTitleDescriptor, size: 0),
            .foregroundColor: UIColor(red: 0.10, green: 0.18, blue: 0.29, alpha: 1), // dinkrNavy
        ]

        // Back button tint → dinkrGreen
        let backButtonAppearance = UIBarButtonItemAppearance()
        backButtonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(red: 0.18, green: 0.74, blue: 0.38, alpha: 1),
        ]
        navAppearance.backButtonAppearance = backButtonAppearance

        UINavigationBar.appearance().tintColor = UIColor(red: 0.18, green: 0.74, blue: 0.38, alpha: 1)
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        // ── Tab Bar ─────────────────────────────────────────────────────────
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        tabAppearance.backgroundColor = UIColor.systemBackground

        // Selected item tint → dinkrGreen
        let selectedColor = UIColor(red: 0.18, green: 0.74, blue: 0.38, alpha: 1)
        let unselectedColor = UIColor.tertiaryLabel

        let selectedAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: selectedColor,
        ]
        let unselectedAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: unselectedColor,
        ]

        // Apply to both inline and stacked item layouts
        for itemAppearance in [
            tabAppearance.stackedLayoutAppearance,
            tabAppearance.inlineLayoutAppearance,
            tabAppearance.compactInlineLayoutAppearance,
        ] {
            itemAppearance.selected.titleTextAttributes = selectedAttrs
            itemAppearance.selected.iconColor = selectedColor
            itemAppearance.normal.titleTextAttributes = unselectedAttrs
            itemAppearance.normal.iconColor = unselectedColor
        }

        UITabBar.appearance().tintColor = selectedColor
        UITabBar.appearance().unselectedItemTintColor = unselectedColor
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(authService)
                .environment(locationService)
                .environment(networkMonitor)
                .environment(storeService)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

struct AppRootView: View {
    @Environment(AuthService.self) private var authService
    @Environment(StoreService.self) private var storeService

    var body: some View {
        ZStack {
            if authService.isRestoringSession {
                LaunchSplashView()
            } else if authService.isAuthenticated {
                RootTabView()
            } else {
                OnboardingView()
            }
        }
        .offlineBanner()
        .bannerManager()
        .task {
            await authService.restoreSession()
            await SeedService.shared.seedIfNeeded()
            await storeService.loadProducts()
            await MessagingService.shared.requestPermission()
            if let userId = authService.currentUser?.id {
                await MessagingService.shared.saveTokenToFirestore(userId: userId)
            }
        }
        // Analytics screen tracking — add .onAppear to individual views, e.g.:
        // .onAppear { AnalyticsService.logScreen("Home") }
    }
}

// MARK: - Launch Splash View

private struct LaunchSplashView: View {
    var body: some View {
        ZStack {
            Color.dinkrNavy
                .ignoresSafeArea()
            VStack(spacing: 20) {
                DinkrLogoView()
                ProgressView()
                    .tint(.white.opacity(0.6))
            }
        }
    }
}

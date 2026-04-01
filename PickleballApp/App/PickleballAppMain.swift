import SwiftUI
import FirebaseCore
import FirebaseCrashlytics
import FirebaseMessaging
import GoogleSignIn

@main
struct PickleballAppMain: App {
    @State private var authService    = AuthService()
    @State private var locationService = LocationService()
    @State private var networkMonitor  = NetworkMonitor.shared
    @State private var storeService    = StoreService.shared
    @State private var deepLinkHandler = DeepLinkHandler.shared

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
        UINavigationBar.appearance().standardAppearance    = navAppearance
        UINavigationBar.appearance().compactAppearance     = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance  = navAppearance

        // ── Tab Bar ─────────────────────────────────────────────────────────
        // Blurred appearance — RootTabView also applies this at runtime, but
        // we set a reasonable default here so the system tab bar (hidden under
        // the custom floating bar) is consistent on first frame.
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        tabAppearance.shadowColor = .clear

        let selectedColor   = UIColor(red: 0.18, green: 0.74, blue: 0.38, alpha: 1)
        let unselectedColor = UIColor.tertiaryLabel

        for itemAppearance in [
            tabAppearance.stackedLayoutAppearance,
            tabAppearance.inlineLayoutAppearance,
            tabAppearance.compactInlineLayoutAppearance,
        ] {
            itemAppearance.selected.titleTextAttributes   = [.foregroundColor: selectedColor]
            itemAppearance.selected.iconColor             = selectedColor
            itemAppearance.normal.titleTextAttributes     = [.foregroundColor: unselectedColor]
            itemAppearance.normal.iconColor               = unselectedColor
        }

        UITabBar.appearance().tintColor              = selectedColor
        UITabBar.appearance().unselectedItemTintColor = unselectedColor
        UITabBar.appearance().standardAppearance      = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance    = tabAppearance
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(authService)
                .environment(locationService)
                .environment(networkMonitor)
                .environment(storeService)
                .environment(deepLinkHandler)
                .onOpenURL { url in
                    // 1. Let Google Sign-In handle its own callback first.
                    if GIDSignIn.sharedInstance.handle(url) { return }
                    // 2. Route everything else through DeepLinkHandler.
                    deepLinkHandler.handle(url)
                }
        }
    }
}

// MARK: - AppRootView

struct AppRootView: View {
    @Environment(AuthService.self)     private var authService
    @Environment(StoreService.self)    private var storeService
    @Environment(DeepLinkHandler.self) private var deepLinkHandler

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            if authService.isRestoringSession {
                LaunchSplashView()
            } else if authService.isAuthenticated {
                RootTabView()
                    // Consume pending deep links and route to the correct tab.
                    .onChange(of: deepLinkHandler.pendingDeepLink) { _, link in
                        guard let link else { return }
                        routeDeepLink(link)
                        deepLinkHandler.consume()
                    }
            } else if hasCompletedOnboarding {
                AuthLandingView()
                    .environment(authService)
            } else {
                OnboardingView()
            }
        }
        // Post-auth onboarding gate: show the carousel as a fullScreenCover when the
        // user is authenticated but has not yet completed the onboarding flow.
        .fullScreenCover(
            isPresented: Binding(
                get: { authService.isAuthenticated && !hasCompletedOnboarding },
                set: { _ in }
            )
        ) {
            OnboardingView()
                .environment(authService)
        }
        .offlineBanner()
        .bannerManager()
        .inAppBannerSupport()
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

    // MARK: Deep-link routing

    private func routeDeepLink(_ link: DeepLink) {
        let router = TabRouter.shared
        switch link {
        case .game:          router.selectedTab = .play
        case .player:        router.selectedTab = .profile
        case .event:         router.selectedTab = .events
        case .court:         router.selectedTab = .play
        case .group:         router.selectedTab = .groups
        case .challenge:     router.selectedTab = .play
        case .notifications: router.selectedTab = .home
        }
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

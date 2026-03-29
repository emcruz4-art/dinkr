import SwiftUI
import FirebaseCore

@main
struct PickleballAppMain: App {
    @State private var authService = AuthService()
    @State private var locationService = LocationService()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(authService)
                .environment(locationService)
        }
    }
}

struct AppRootView: View {
    @Environment(AuthService.self) private var authService

    var body: some View {
        ZStack {
            if authService.isAuthenticated {
                RootTabView()
            } else {
                OnboardingView()
            }
        }
        .task {
            await authService.restoreSession()
        }
    }
}

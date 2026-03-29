import SwiftUI

struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(AuthService.self) private var authService

    var body: some View {
        NavigationStack {
            switch viewModel.step {
            case .welcome:
                WelcomeView(viewModel: viewModel)
            case .skillSelection:
                SkillSelectionView(viewModel: viewModel)
            case .locationPermission:
                LocationPermissionView(viewModel: viewModel)
            }
        }
        .task {
            viewModel.authService = authService
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AuthService())
        .environment(LocationService())
}

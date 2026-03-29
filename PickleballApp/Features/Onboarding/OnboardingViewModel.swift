import Foundation
import Observation

enum OnboardingStep {
    case welcome, skillSelection, locationPermission
}

@Observable
final class OnboardingViewModel {
    var step: OnboardingStep = .welcome
    var selectedSkill: SkillLevel = .intermediate30
    var isLoading = false
    var error: String? = nil

    var authService: AuthService? = nil

    func advance() {
        switch step {
        case .welcome: step = .skillSelection
        case .skillSelection: step = .locationPermission
        case .locationPermission: completeOnboarding()
        }
    }

    func signInWithApple() {
        Task { @MainActor in
            isLoading = true
            defer { isLoading = false }
            do {
                try await authService?.signInWithApple()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func signInWithGoogle() {
        Task { @MainActor in
            isLoading = true
            defer { isLoading = false }
            do {
                try await authService?.signInWithGoogle()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func completeOnboarding() {
        Task { @MainActor in
            isLoading = true
            defer { isLoading = false }
            // Persist skill selection to user profile, then mark onboarding complete
            // For mock: just sign in
            try? await authService?.signIn(email: "demo@pickleballapp.com", password: "demo")
        }
    }
}

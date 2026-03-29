import SwiftUI

struct WelcomeView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "figure.pickleball")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.pickleballGreen)
                Text("Pickleball")
                    .font(.system(size: 42, weight: .black))
                Text("Your community. Your courts.\nYour game.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    viewModel.signInWithApple()
                } label: {
                    Label("Continue with Apple", systemImage: "apple.logo")
                        .primaryButton()
                        .overlay {
                            RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.2))
                        }
                }
                .tint(.black)

                Button {
                    viewModel.signInWithGoogle()
                } label: {
                    Label("Continue with Google", systemImage: "globe")
                        .secondaryButton()
                }

                Button("Get Started with Email") {
                    viewModel.advance()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView().scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black.opacity(0.2))
            }
        }
    }
}

#Preview {
    WelcomeView(viewModel: OnboardingViewModel())
        .environment(AuthService())
}

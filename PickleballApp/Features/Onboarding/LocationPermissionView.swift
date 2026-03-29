import SwiftUI
import CoreLocation

struct LocationPermissionView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(LocationService.self) private var locationService

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.courtBlue)
                Text("Find Games Near You")
                    .font(.title2.weight(.bold))
                Text("We use your location to show nearby courts, open games, and players in your area. Your exact location is never shared publicly.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()

            VStack(spacing: 12) {
                Button("Allow Location Access") {
                    locationService.requestPermission()
                    viewModel.advance()
                }
                .primaryButton()

                Button("Skip for Now") {
                    viewModel.advance()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    LocationPermissionView(viewModel: OnboardingViewModel())
        .environment(LocationService())
}

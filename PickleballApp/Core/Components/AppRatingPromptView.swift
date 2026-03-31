import SwiftUI
import StoreKit

// MARK: - AppRatingPromptView
// Custom in-app rating pre-prompt shown after 5 games played.
// Collects star sentiment first; routes high-raters to StoreKit review,
// low-raters to an inline feedback field.

struct AppRatingPromptView: View {

    // MARK: Stored state
    @AppStorage("hasRated") private var hasRated: Bool = false
    @AppStorage("gamesPlayedCount") private var gamesPlayedCount: Int = 0

    // MARK: Environment
    @Environment(\.requestReview) private var requestReview
    @Environment(\.dismiss) private var dismiss

    // MARK: Local state
    @State private var selectedStars: Int = 0
    @State private var feedbackText: String = ""
    @State private var feedbackSubmitted: Bool = false
    @State private var starScale: [CGFloat] = Array(repeating: 1.0, count: 5)

    // MARK: Computed helpers
    private var isHighRating: Bool { selectedStars >= 4 }
    private var isLowRating: Bool  { selectedStars >= 1 && selectedStars <= 3 }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 40, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 18)

            // Paddle emoji
            Text("🏓")
                .font(.system(size: 52))
                .padding(.bottom, 10)

            // Title
            Text("Enjoying Dinkr? 🏓")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.dinkrNavy)
                .multilineTextAlignment(.center)

            Text("Tap to rate your experience")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
                .padding(.bottom, 20)

            // Star row
            starRow
                .padding(.bottom, 20)

            // Context-sensitive follow-up
            if isHighRating {
                highRatingSection
            } else if isLowRating {
                lowRatingSection
            }

            Spacer(minLength: 0)

            // Not Now
            Button {
                dismiss()
            } label: {
                Text("Not Now")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.hidden) // we draw our own
        .presentationCornerRadius(24)
    }

    // MARK: - Subviews

    private var starRow: some View {
        HStack(spacing: 10) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= selectedStars ? "star.fill" : "star")
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(index <= selectedStars ? Color.dinkrAmber : Color.secondary.opacity(0.4))
                    .scaleEffect(starScale[index - 1])
                    .onTapGesture {
                        tapStar(index)
                    }
            }
        }
    }

    @ViewBuilder
    private var highRatingSection: some View {
        VStack(spacing: 12) {
            Text("Amazing! Leave us a review?")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.dinkrNavy)
                .multilineTextAlignment(.center)

            Button {
                hasRated = true
                requestReview()
                dismiss()
            } label: {
                Label("Rate on the App Store", systemImage: "star.bubble.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.dinkrGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    @ViewBuilder
    private var lowRatingSection: some View {
        VStack(spacing: 12) {
            if feedbackSubmitted {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.dinkrGreen)
                    Text("Thanks for the feedback!")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                Text("We're sorry! Tell us what's wrong?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dinkrCoral)
                    .multilineTextAlignment(.center)

                TextField("What can we improve?", text: $feedbackText, axis: .vertical)
                    .font(.subheadline)
                    .padding(12)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .lineLimit(2...3)

                Button {
                    submitFeedback()
                } label: {
                    Text("Send Feedback")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(feedbackText.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? Color.dinkrCoral.opacity(0.4)
                                    : Color.dinkrCoral)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(feedbackText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Actions

    private func tapStar(_ index: Int) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
            selectedStars = index
            // Pop the tapped star
            starScale[index - 1] = 1.35
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                starScale[index - 1] = 1.0
            }
        }
    }

    private func submitFeedback() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            feedbackSubmitted = true
            hasRated = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            dismiss()
        }
    }
}

// MARK: - Smart trigger helper

extension AppRatingPromptView {
    /// Returns true when the rating prompt should be shown:
    /// 5+ games played and the user hasn't already rated.
    static func shouldPrompt(gamesPlayed: Int, hasRated: Bool) -> Bool {
        !hasRated && gamesPlayed >= 5
    }
}

// MARK: - Preview

#Preview("AppRatingPromptView — sheet") {
    struct Wrapper: View {
        @State private var show = true
        var body: some View {
            Color.dinkrNavy.opacity(0.1).ignoresSafeArea()
                .sheet(isPresented: $show) {
                    AppRatingPromptView()
                }
        }
    }
    return Wrapper()
}

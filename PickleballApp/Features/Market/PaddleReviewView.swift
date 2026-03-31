import SwiftUI

// MARK: - Paddle Review View

struct PaddleReviewView: View {
    let itemName: String
    let verifiedPurchase: Bool

    @Environment(\.dismiss) private var dismiss

    // Overall star rating
    @State private var overallRating: Int = 0

    // Category sliders
    @State private var powerRating: Double = 3
    @State private var controlRating: Double = 3
    @State private var spinRating: Double = 3
    @State private var durabilityRating: Double = 3
    @State private var valueRating: Double = 3

    // Text review
    @State private var reviewText: String = ""

    // Skill level
    @State private var selectedSkillLevel: SkillLevel = .intermediate30

    // Ownership duration chip
    @State private var ownershipDuration: OwnershipDuration = .oneToSix

    // Verified purchase toggle
    @State private var isVerifiedPurchase: Bool

    // Photo attachment placeholder
    @State private var showPhotoPlaceholder = false

    // Submission state
    @State private var submitted = false

    enum OwnershipDuration: String, CaseIterable, Identifiable {
        case lessThanOne = "< 1 month"
        case oneToSix = "1–6 months"
        case sixToTwelve = "6–12 months"
        case overYear = "1+ year"
        var id: String { rawValue }
    }

    init(itemName: String, verifiedPurchase: Bool = false) {
        self.itemName = itemName
        self.verifiedPurchase = verifiedPurchase
        _isVerifiedPurchase = State(initialValue: verifiedPurchase)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if submitted {
                    submittedView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            headerCard
                            overallStarCard
                            categoryRatingsCard
                            impressionCard
                            playingLevelCard
                            ownershipCard
                            verifiedCard
                            photoCard
                            submitButton
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Write a Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .tint(Color.dinkrNavy)
                }
            }
        }
    }

    // MARK: - Submitted

    private var submittedView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.dinkrGreen)
            }
            Text("Review submitted! Thank you 🙌")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            Text("Your review helps the Dinkr community make better gear decisions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.dinkrGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)
            .padding(.top, 8)
            Spacer()
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.dinkrCoral.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: "figure.pickleball")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.dinkrCoral)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Reviewing")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(itemName)
                    .font(.headline.weight(.bold))
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Overall Star Rating

    private var overallStarCard: some View {
        VStack(spacing: 12) {
            sectionLabel("Overall Rating")
            HStack(spacing: 14) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            overallRating = star
                        }
                    } label: {
                        Image(systemName: star <= overallRating ? "star.fill" : "star")
                            .font(.system(size: 38, weight: .medium))
                            .foregroundStyle(star <= overallRating ? Color.dinkrAmber : Color.secondary.opacity(0.35))
                            .scaleEffect(star <= overallRating ? 1.1 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)

            if overallRating > 0 {
                Text(overallRatingLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dinkrAmber)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private var overallRatingLabel: String {
        switch overallRating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Great"
        case 5: return "Outstanding!"
        default: return ""
        }
    }

    // MARK: - Category Ratings

    private var categoryRatingsCard: some View {
        VStack(spacing: 14) {
            sectionLabel("Category Ratings")
            categorySlider(label: "Power", icon: "bolt.fill", color: Color.dinkrCoral, value: $powerRating)
            categorySlider(label: "Control", icon: "scope", color: Color.dinkrGreen, value: $controlRating)
            categorySlider(label: "Spin", icon: "arrow.trianglehead.2.clockwise.rotate.90", color: Color.dinkrSky, value: $spinRating)
            categorySlider(label: "Durability", icon: "shield.fill", color: Color.dinkrNavy, value: $durabilityRating)
            categorySlider(label: "Value", icon: "dollarsign.circle.fill", color: Color.dinkrAmber, value: $valueRating)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private func categorySlider(label: String, icon: String, color: Color, value: Binding<Double>) -> some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 20)
                Text(label)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(String(format: "%.1f", value.wrappedValue))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(color)
                    .frame(width: 32, alignment: .trailing)
            }
            Slider(value: value, in: 1...5, step: 0.5)
                .tint(color)
        }
    }

    // MARK: - Overall Impression

    private var impressionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Your Impression")
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGroupedBackground))
                    .frame(minHeight: 110)
                if reviewText.isEmpty {
                    Text("Tell others what you think…")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $reviewText)
                    .font(.subheadline)
                    .frame(minHeight: 110)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            }
            HStack {
                Spacer()
                Text("\(reviewText.count)/500")
                    .font(.caption2)
                    .foregroundStyle(reviewText.count > 500 ? Color.dinkrCoral : .secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Playing Level

    private var playingLevelCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Your Playing Level")
            Text("This helps readers understand your perspective.")
                .font(.caption)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SkillLevel.allCases, id: \.self) { level in
                        let isSelected = selectedSkillLevel == level
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedSkillLevel = level
                            }
                        } label: {
                            Text(level.rawValue)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(isSelected ? .white : Color.dinkrNavy)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    isSelected
                                    ? Color.dinkrNavy
                                    : Color.dinkrNavy.opacity(0.08)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Ownership Duration

    private var ownershipCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("How Long Owned?")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(OwnershipDuration.allCases) { duration in
                    let isSelected = ownershipDuration == duration
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            ownershipDuration = duration
                        }
                    } label: {
                        Text(duration.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isSelected ? .white : Color.dinkrGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                isSelected
                                ? Color.dinkrGreen
                                : Color.dinkrGreen.opacity(0.08)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected ? Color.clear : Color.dinkrGreen.opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Verified Purchase Toggle

    private var verifiedCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.dinkrAmber.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.dinkrAmber)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Verified Purchase")
                    .font(.subheadline.weight(.semibold))
                Text("Indicates this was bought through Dinkr Market")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isVerifiedPurchase)
                .tint(Color.dinkrAmber)
                .labelsHidden()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Photo Attachment

    private var photoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Add Photos")
            Button {
                showPhotoPlaceholder = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.dinkrSky.opacity(0.10))
                            .frame(width: 56, height: 56)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.dinkrSky)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Attach Photos")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("Show your paddle, wear patterns, etc.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        .alert("Photo Upload", isPresented: $showPhotoPlaceholder) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Photo attachment will be available in a future update.")
        }
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                submitted = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "paperplane.fill")
                Text("Submit Review")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                overallRating > 0
                ? Color.dinkrGreen
                : Color.secondary.opacity(0.3)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(overallRating == 0)
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Color.dinkrNavy)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    PaddleReviewView(itemName: "Selkirk Vanguard Power Air", verifiedPurchase: true)
}

import SwiftUI

// MARK: - CourtReviewsView

struct CourtReviewsView: View {
    let court: CourtVenue

    @State private var reviews: [CourtReview] = []
    @State private var activeTagFilter: String? = nil
    @State private var showWriteSheet = false

    private var filteredReviews: [CourtReview] {
        let courtReviews = reviews
            .filter { $0.courtId == court.id }
            .sorted { $0.createdAt > $1.createdAt }
        guard let tag = activeTagFilter else { return courtReviews }
        return courtReviews.filter { $0.tags.contains(tag) }
    }

    private var averageRating: Double {
        let courtReviews = reviews.filter { $0.courtId == court.id }
        guard !courtReviews.isEmpty else { return 0 }
        return Double(courtReviews.map(\.rating).reduce(0, +)) / Double(courtReviews.count)
    }

    private var ratingCounts: [Int: Int] {
        let courtReviews = reviews.filter { $0.courtId == court.id }
        return Dictionary(
            grouping: courtReviews, by: { $0.rating }
        ).mapValues(\.count)
    }

    private var popularTags: [String] {
        let courtReviews = reviews.filter { $0.courtId == court.id }
        var counts: [String: Int] = [:]
        for review in courtReviews {
            for tag in review.tags {
                counts[tag, default: 0] += 1
            }
        }
        return counts
            .sorted { $0.value > $1.value }
            .map(\.key)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                reviewsHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                Divider().padding(.vertical, 16)

                ratingBreakdown
                    .padding(.horizontal, 16)

                if !popularTags.isEmpty {
                    tagFilterRow
                        .padding(.top, 16)
                }

                Divider().padding(.vertical, 16)

                reviewsList
                    .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showWriteSheet) {
            WriteReviewSheet(courtId: court.id) { newReview in
                reviews.insert(newReview, at: 0)
            }
        }
        .onAppear {
            reviews = CourtReview.mockReviews
        }
    }

    // MARK: Header

    private var reviewsHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(court.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.dinkrNavy)

            HStack(spacing: 10) {
                StarRatingDisplay(rating: averageRating, size: 22)

                Text(String(format: "%.1f", averageRating))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.dinkrNavy)

                Text("(\(reviews.filter { $0.courtId == court.id }.count) reviews)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    showWriteSheet = true
                } label: {
                    Label("Write a Review", systemImage: "square.and.pencil")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.dinkrGreen)
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: Rating Breakdown

    private var ratingBreakdown: some View {
        VStack(spacing: 6) {
            ForEach([5, 4, 3, 2, 1], id: \.self) { star in
                HStack(spacing: 10) {
                    Text("\(star)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(width: 10, alignment: .trailing)

                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(Color.dinkrAmber)

                    RatingBar(
                        filled: ratingBarFraction(for: star),
                        color: Color.dinkrGreen
                    )

                    Text("\(ratingCounts[star, default: 0])")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 22, alignment: .trailing)
                }
            }
        }
    }

    private func ratingBarFraction(for star: Int) -> Double {
        let total = reviews.filter { $0.courtId == court.id }.count
        guard total > 0 else { return 0 }
        return Double(ratingCounts[star, default: 0]) / Double(total)
    }

    // MARK: Tag Filter Row

    private var tagFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                TagChip(label: "All", isSelected: activeTagFilter == nil) {
                    activeTagFilter = nil
                }
                ForEach(popularTags, id: \.self) { tag in
                    TagChip(label: tag, isSelected: activeTagFilter == tag) {
                        activeTagFilter = (activeTagFilter == tag) ? nil : tag
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: Reviews List

    private var reviewsList: some View {
        LazyVStack(spacing: 16) {
            if filteredReviews.isEmpty {
                Text("No reviews match this filter.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 24)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(filteredReviews) { review in
                    CourtReviewRow(review: review)
                    if review.id != filteredReviews.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(.bottom, 32)
    }
}

// MARK: - CourtReviewRow

struct CourtReviewRow: View {
    let review: CourtReview
    @State private var helpfulCount: Int

    init(review: CourtReview) {
        self.review = review
        self._helpfulCount = State(initialValue: review.helpfulCount)
    }

    @State private var markedHelpful = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Author row
            HStack(spacing: 10) {
                AuthorInitialCircle(name: review.authorName)

                VStack(alignment: .leading, spacing: 2) {
                    Text(review.authorName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.dinkrNavy)

                    Text(review.createdAt.formatted(.dateTime.month(.abbreviated).day().year()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                StarRatingDisplay(rating: Double(review.rating), size: 14)
            }

            // Title
            Text(review.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.dinkrNavy)

            // Body (3-line clamp)
            Text(review.body)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(3)

            // Tag pills
            if !review.tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(review.tags, id: \.self) { tag in
                        ReviewTagPill(label: tag)
                    }
                }
            }

            // Helpful button
            Button {
                if !markedHelpful {
                    helpfulCount += 1
                    markedHelpful = true
                }
            } label: {
                Label("Helpful (\(helpfulCount))", systemImage: markedHelpful ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(markedHelpful ? Color.dinkrGreen : .secondary)
            }
        }
    }
}

// MARK: - WriteReviewSheet

struct WriteReviewSheet: View {
    let courtId: String
    var onSubmit: (CourtReview) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedRating: Int = 0
    @State private var title: String = ""
    @State private var reviewBody: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var bodyEditorFocused = false

    private var isValid: Bool {
        selectedRating > 0 && !reviewBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Star tap-to-rate
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your Rating")
                            .font(.headline)
                            .foregroundColor(Color.dinkrNavy)

                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    selectedRating = star
                                } label: {
                                    Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                        .font(.system(size: 40))
                                        .foregroundColor(
                                            star <= selectedRating ? Color.dinkrAmber : Color(UIColor.systemGray4)
                                        )
                                }
                                .buttonStyle(.plain)
                                .animation(.easeInOut(duration: 0.15), value: selectedRating)
                            }
                        }
                    }

                    // Title field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Title")
                            .font(.headline)
                            .foregroundColor(Color.dinkrNavy)

                        TextField("Summarize your experience", text: $title)
                            .padding(12)
                            .background(Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Body TextEditor
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Review")
                            .font(.headline)
                            .foregroundColor(Color.dinkrNavy)

                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $reviewBody)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(Color.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            if reviewBody.isEmpty {
                                Text("Tell other players about the courts, conditions, and atmosphere…")
                                    .font(.subheadline)
                                    .foregroundColor(Color(UIColor.placeholderText))
                                    .padding(.top, 16)
                                    .padding(.leading, 14)
                                    .allowsHitTesting(false)
                            }
                        }
                    }

                    // Multi-select tag chips
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tags")
                            .font(.headline)
                            .foregroundColor(Color.dinkrNavy)

                        FlowLayout(spacing: 8) {
                            ForEach(CourtReview.allTags, id: \.self) { tag in
                                ToggleTagChip(
                                    label: tag,
                                    isSelected: selectedTags.contains(tag)
                                ) {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                }
                            }
                        }
                    }

                    // Submit
                    Button {
                        submitReview()
                    } label: {
                        Text("Submit Review")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isValid ? Color.dinkrGreen : Color(UIColor.systemGray4))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!isValid)
                    .animation(.easeInOut(duration: 0.2), value: isValid)
                }
                .padding(20)
            }
            .navigationTitle("Write a Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.dinkrGreen)
                }
            }
        }
    }

    private func submitReview() {
        let review = CourtReview(
            id: UUID().uuidString,
            courtId: courtId,
            authorId: "current_user",
            authorName: "You",
            rating: selectedRating,
            title: title.isEmpty ? "Untitled Review" : title,
            body: reviewBody.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: Array(selectedTags),
            createdAt: Date(),
            helpfulCount: 0
        )
        onSubmit(review)
        dismiss()
    }
}

// MARK: - CourtConditionsWidget

struct CourtConditionsWidget: View {
    let court: CourtVenue

    // In a real app these would be fetched from an API or derived from recent activity.
    // For now they are computed from the court model with deterministic logic.
    private var weatherEmoji: String { court.isIndoor ? "🏢" : "☀️" }
    private var surfaceQuality: SurfaceQuality { court.rating >= 4.5 ? .good : court.rating >= 3.5 ? .moderate : .poor }
    private var crowdLevel: CrowdLevel { court.reviewCount > 200 ? .high : court.reviewCount > 100 ? .moderate : .low }
    private var netStatus: String { "Good" }
    private var bestTime: String { court.isIndoor ? "Any time" : "Weekday mornings" }
    private var lastUpdated: String { "Updated today" }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Court Conditions")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.6)

            HStack(spacing: 0) {
                conditionCell(
                    label: "Weather",
                    value: weatherEmoji,
                    valueIsEmoji: true
                )
                Divider().frame(height: 36)
                conditionCell(
                    label: "Surface",
                    valueView: AnyView(qualityDot(surfaceQuality)),
                    subLabel: surfaceQuality.label
                )
                Divider().frame(height: 36)
                conditionCell(
                    label: "Nets",
                    value: netStatus
                )
            }

            Divider()

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Crowd")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    HStack(spacing: 5) {
                        Circle()
                            .fill(crowdLevel.color)
                            .frame(width: 8, height: 8)
                        Text(crowdLevel.label)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.dinkrNavy)
                    }
                }

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Best time")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(bestTime)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.dinkrNavy)
                }

                Spacer()

                Text(lastUpdated)
                    .font(.caption2)
                    .foregroundColor(Color(UIColor.systemGray3))
            }
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // Overloads for text vs custom view

    private func conditionCell(label: String, value: String, valueIsEmoji: Bool = false) -> some View {
        VStack(spacing: 4) {
            if valueIsEmoji {
                Text(value)
                    .font(.title3)
            } else {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.dinkrNavy)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func conditionCell(label: String, valueView: AnyView, subLabel: String) -> some View {
        VStack(spacing: 4) {
            valueView
            Text(subLabel)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.dinkrNavy)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func qualityDot(_ quality: SurfaceQuality) -> some View {
        Circle()
            .fill(quality.color)
            .frame(width: 12, height: 12)
    }

    // MARK: Supporting enums

    enum SurfaceQuality {
        case good, moderate, poor
        var label: String {
            switch self {
            case .good: return "Excellent"
            case .moderate: return "Good"
            case .poor: return "Fair"
            }
        }
        var color: Color {
            switch self {
            case .good: return Color.dinkrGreen
            case .moderate: return Color.dinkrAmber
            case .poor: return Color.dinkrCoral
            }
        }
    }

    enum CrowdLevel {
        case low, moderate, high
        var label: String {
            switch self {
            case .low: return "Light"
            case .moderate: return "Moderate"
            case .high: return "Busy"
            }
        }
        var color: Color {
            switch self {
            case .low: return Color.dinkrGreen
            case .moderate: return Color.dinkrAmber
            case .high: return Color.dinkrCoral
            }
        }
    }
}

// MARK: - Supporting Components

// Star display (read-only)
struct StarRatingDisplay: View {
    let rating: Double
    let size: CGFloat

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: starImageName(for: star))
                    .font(.system(size: size))
                    .foregroundColor(Color.dinkrAmber)
            }
        }
    }

    private func starImageName(for star: Int) -> String {
        let threshold = Double(star)
        if rating >= threshold {
            return "star.fill"
        } else if rating >= threshold - 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

// Author initial avatar
struct AuthorInitialCircle: View {
    let name: String

    private var initial: String {
        String(name.prefix(1)).uppercased()
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.dinkrGreen)
                .frame(width: 36, height: 36)
            Text(initial)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
}

// Rating progress bar
struct RatingBar: View {
    let filled: Double  // 0.0 – 1.0
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(UIColor.systemGray5))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: geo.size.width * CGFloat(filled), height: 8)
            }
        }
        .frame(height: 8)
    }
}

// Filter chip (read-only selection)
struct TagChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.dinkrGreen : Color(UIColor.systemGray6))
                .foregroundColor(isSelected ? .white : Color.dinkrNavy)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// Toggle chip for write sheet
struct ToggleTagChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? Color.dinkrGreen.opacity(0.15) : Color(UIColor.systemGray6))
            .foregroundColor(isSelected ? Color.dinkrGreen : Color.dinkrNavy)
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.dinkrGreen : Color.clear, lineWidth: 1.5)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.12), value: isSelected)
    }
}

// Small pill for review tags
struct ReviewTagPill: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Color.dinkrSky.opacity(0.15))
            .foregroundColor(Color.dinkrSky)
            .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("Court Reviews") {
    NavigationStack {
        CourtReviewsView(court: CourtVenue.mockVenues[0])
    }
}

#Preview("Conditions Widget") {
    CourtConditionsWidget(court: CourtVenue.mockVenues[1])
        .padding()
}

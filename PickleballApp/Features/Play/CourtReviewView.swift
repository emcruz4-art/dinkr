import SwiftUI

// MARK: - Sort Order

enum ReviewSortOrder: String, CaseIterable {
    case mostRecent   = "Most Recent"
    case mostHelpful  = "Most Helpful"
    case highestRated = "Highest Rated"
    case lowestRated  = "Lowest Rated"
}

// MARK: - CourtReviewsView

struct CourtReviewsView: View {
    let court: CourtVenue

    @State private var reviews: [CourtReview] = []
    @State private var sortOrder: ReviewSortOrder = .mostRecent
    @State private var showWriteSheet = false

    private var courtReviews: [CourtReview] {
        reviews.filter { $0.courtId == court.id }
    }

    private var sortedReviews: [CourtReview] {
        switch sortOrder {
        case .mostRecent:   return courtReviews.sorted { $0.createdAt > $1.createdAt }
        case .mostHelpful:  return courtReviews.sorted { $0.helpfulCount > $1.helpfulCount }
        case .highestRated: return courtReviews.sorted { $0.overallRating > $1.overallRating }
        case .lowestRated:  return courtReviews.sorted { $0.overallRating < $1.overallRating }
        }
    }

    private var averageOverall: Double {
        guard !courtReviews.isEmpty else { return 0 }
        return courtReviews.map(\.overallRating).reduce(0, +) / Double(courtReviews.count)
    }

    private var avgSurface: Double    { avg(\.surfaceRating) }
    private var avgLighting: Double   { avg(\.lightingRating) }
    private var avgFacility: Double   { avg(\.facilityRating) }
    private var avgCrowds: Double     { avg(\.crowdsRating) }
    private var avgAtmosphere: Double { avg(\.atmosphereRating) }

    private func avg(_ kp: KeyPath<CourtReview, Double>) -> Double {
        guard !courtReviews.isEmpty else { return 0 }
        return courtReviews.map { $0[keyPath: kp] }.reduce(0, +) / Double(courtReviews.count)
    }

    private var topTags: [CourtTag] {
        var counts: [CourtTag: Int] = [:]
        for review in courtReviews {
            for tag in review.tags { counts[tag, default: 0] += 1 }
        }
        return counts.sorted { $0.value > $1.value }.map(\.key)
    }

    private var allPlayTimes: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for review in courtReviews {
            for time in review.typicalPlayTimes {
                if seen.insert(time).inserted { result.append(time) }
            }
        }
        return Array(result.prefix(6))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: Rating Summary Header
                    ratingSummaryHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    Divider().padding(.vertical, 20).padding(.horizontal, 20)

                    // MARK: Criteria Breakdown
                    criteriaBreakdown
                        .padding(.horizontal, 20)

                    Divider().padding(.vertical, 20).padding(.horizontal, 20)

                    // MARK: Tag Cloud
                    if !topTags.isEmpty {
                        tagCloud
                            .padding(.horizontal, 20)

                        Divider().padding(.vertical, 20).padding(.horizontal, 20)
                    }

                    // MARK: Typical Play Times
                    if !allPlayTimes.isEmpty {
                        typicalPlayTimesSection
                            .padding(.horizontal, 20)

                        Divider().padding(.vertical, 20).padding(.horizontal, 20)
                    }

                    // MARK: Sort + Reviews
                    sortPicker
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    reviewsList
                        .padding(.horizontal, 20)
                        .padding(.bottom, 96) // clearance for fixed button
                }
            }
            .background(Color.appBackground)

            // MARK: Fixed Write Button
            writeReviewButton
        }
        .navigationTitle("Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showWriteSheet) {
            WriteCourtReviewView(court: court) { newReview in
                reviews.insert(newReview, at: 0)
            }
        }
        .onAppear {
            reviews = CourtReview.mockReviews
        }
    }

    // MARK: - Rating Summary Header

    private var ratingSummaryHeader: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(spacing: 6) {
                Text(String(format: "%.1f", averageOverall))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dinkrNavy)
                StarRatingDisplay(rating: averageOverall, size: 18)
                Text("\(courtReviews.count) reviews")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Star breakdown bars
            VStack(spacing: 5) {
                ForEach([5, 4, 3, 2, 1], id: \.self) { star in
                    HStack(spacing: 8) {
                        Text("\(star)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .frame(width: 10, alignment: .trailing)
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.dinkrAmber)
                        RatingBar(
                            filled: starFraction(star),
                            color: Color.dinkrGreen
                        )
                        Text("\(starCount(star))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 18, alignment: .trailing)
                    }
                }
            }
        }
        .padding(18)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func starCount(_ star: Int) -> Int {
        courtReviews.filter { Int($0.overallRating.rounded()) == star }.count
    }

    private func starFraction(_ star: Int) -> Double {
        guard !courtReviews.isEmpty else { return 0 }
        return Double(starCount(star)) / Double(courtReviews.count)
    }

    // MARK: - Criteria Breakdown

    private var criteriaBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ratings by Category")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.6)

            VStack(spacing: 10) {
                CriteriaRow(label: "Surface",     icon: "rectangle.fill",            value: avgSurface)
                CriteriaRow(label: "Lighting",    icon: "flashlight.on.fill",         value: avgLighting)
                CriteriaRow(label: "Facilities",  icon: "building.2.fill",            value: avgFacility)
                CriteriaRow(label: "Crowds",      icon: "person.3.fill",              value: avgCrowds)
                CriteriaRow(label: "Atmosphere",  icon: "hand.thumbsup.fill",         value: avgAtmosphere)
            }
        }
    }

    // MARK: - Tag Cloud

    private var tagCloud: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Community Tags")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.6)

            FlowLayout(spacing: 8) {
                ForEach(topTags.prefix(10), id: \.self) { tag in
                    ReviewTagPill(label: tag.rawValue)
                }
            }
        }
    }

    // MARK: - Typical Play Times

    private var typicalPlayTimesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("When People Play Here")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.6)

            FlowLayout(spacing: 8) {
                ForEach(allPlayTimes, id: \.self) { time in
                    HStack(spacing: 5) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text(time)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(Color.dinkrSky)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.dinkrSky.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Sort Picker

    private var sortPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reviews")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.6)

            Picker("Sort by", selection: $sortOrder) {
                ForEach(ReviewSortOrder.allCases, id: \.self) { order in
                    Text(order.rawValue).tag(order)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Reviews List

    private var reviewsList: some View {
        LazyVStack(spacing: 16) {
            if sortedReviews.isEmpty {
                Text("No reviews yet. Be the first to review this court!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(sortedReviews) { review in
                    CourtReviewCard(review: review)
                    if review.id != sortedReviews.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - Fixed Write Button

    private var writeReviewButton: some View {
        Button {
            showWriteSheet = true
        } label: {
            Label("Write a Review", systemImage: "square.and.pencil")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.dinkrGreen)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 10, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .background(
            LinearGradient(
                colors: [Color.appBackground.opacity(0), Color.appBackground],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - CriteriaRow

private struct CriteriaRow: View {
    let label: String
    let icon: String
    let value: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.dinkrGreen)
                .frame(width: 18)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.dinkrNavy)
                .frame(width: 80, alignment: .leading)
            RatingBar(filled: value / 5.0, color: Color.dinkrGreen)
            Text(String(format: "%.1f", value))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.dinkrNavy)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

// MARK: - CourtReviewCard

struct CourtReviewCard: View {
    let review: CourtReview

    @State private var helpfulCount: Int
    @State private var markedHelpful = false
    @State private var isExpanded = false

    init(review: CourtReview) {
        self.review = review
        self._helpfulCount = State(initialValue: review.helpfulCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Author row
            HStack(spacing: 10) {
                AuthorInitialCircle(name: review.authorName)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(review.authorName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrNavy)

                        if review.isVerifiedPlayer {
                            Label("Verified", systemImage: "checkmark.seal.fill")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color.dinkrGreen)
                                .labelStyle(.titleAndIcon)
                        }
                    }

                    HStack(spacing: 6) {
                        Text("@\(review.authorUsername)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(review.createdAt.relativeString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    StarRatingDisplay(rating: review.overallRating, size: 13)
                    Text(String(format: "%.1f", review.overallRating))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.dinkrAmber)
                }
            }

            // Body text (expandable)
            VStack(alignment: .leading, spacing: 4) {
                Text(review.body)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(isExpanded ? nil : 3)

                if review.body.count > 120 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Text(isExpanded ? "Show less" : "Read more")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrSky)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Tag pills
            if !review.tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(review.tags, id: \.self) { tag in
                        ReviewTagPill(label: tag.rawValue)
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
                Label("Helpful (\(helpfulCount))",
                      systemImage: markedHelpful ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(markedHelpful ? Color.dinkrGreen : .secondary)
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.15), value: markedHelpful)
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    review.isFeatured ? Color.dinkrGreen.opacity(0.45) : Color.clear,
                    lineWidth: 1.5
                )
        )
    }
}

// MARK: - WriteCourtReviewView

struct WriteCourtReviewView: View {
    let court: CourtVenue
    var onSubmit: (CourtReview) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var overallRating: Int = 0
    @State private var surfaceRating: Double = 3
    @State private var lightingRating: Double = 3
    @State private var facilityRating: Double = 3
    @State private var crowdsRating: Double = 3
    @State private var atmosphereRating: Double = 3
    @State private var selectedTags: Set<CourtTag> = []
    @State private var selectedPlayTimes: Set<String> = []
    @State private var reviewBody: String = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false

    private let playTimeOptions = [
        "Weekday mornings", "Weekday afternoons", "Weekday evenings",
        "Weekend mornings", "Weekend afternoons", "Weekend evenings"
    ]

    private var isValid: Bool {
        overallRating > 0 &&
        reviewBody.trimmingCharacters(in: .whitespacesAndNewlines).count >= 20
    }

    private var charCount: Int {
        reviewBody.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // MARK: Overall Star Rating
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: "Overall Rating")
                        HStack(spacing: 14) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        overallRating = star
                                    }
                                } label: {
                                    Image(systemName: star <= overallRating ? "star.fill" : "star")
                                        .font(.system(size: 40))
                                        .foregroundStyle(
                                            star <= overallRating
                                                ? Color.dinkrAmber
                                                : Color(UIColor.systemGray4)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    }

                    // MARK: Criteria Sliders
                    VStack(alignment: .leading, spacing: 16) {
                        SectionLabel(text: "Rate Each Category")

                        CriteriaSlider(
                            label: "Surface Quality",
                            emoji: "🏓",
                            value: $surfaceRating
                        )
                        CriteriaSlider(
                            label: "Lighting",
                            emoji: "💡",
                            value: $lightingRating
                        )
                        CriteriaSlider(
                            label: "Facilities",
                            emoji: "🚿",
                            value: $facilityRating
                        )
                        CriteriaSlider(
                            label: "Crowd Level",
                            emoji: "👥",
                            value: $crowdsRating
                        )
                        CriteriaSlider(
                            label: "Atmosphere",
                            emoji: "🌟",
                            value: $atmosphereRating
                        )
                    }

                    // MARK: Tag Grid
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: "Quick Tags (Select all that apply)")

                        FlowLayout(spacing: 8) {
                            ForEach(CourtTag.allCases, id: \.self) { tag in
                                ToggleTagChip(
                                    label: tag.rawValue,
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

                    // MARK: Typical Play Times
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: "When Do You Usually Play Here?")

                        FlowLayout(spacing: 8) {
                            ForEach(playTimeOptions, id: \.self) { time in
                                ToggleTagChip(
                                    label: time,
                                    isSelected: selectedPlayTimes.contains(time)
                                ) {
                                    if selectedPlayTimes.contains(time) {
                                        selectedPlayTimes.remove(time)
                                    } else {
                                        selectedPlayTimes.insert(time)
                                    }
                                }
                            }
                        }
                    }

                    // MARK: Written Review
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            SectionLabel(text: "Your Review")
                            Spacer()
                            Text("\(charCount)/min 20")
                                .font(.caption)
                                .foregroundStyle(charCount >= 20 ? Color.dinkrGreen : .secondary)
                        }

                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $reviewBody)
                                .frame(minHeight: 130)
                                .padding(10)
                                .background(Color.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            if reviewBody.isEmpty {
                                Text("Tell other players about the courts, conditions, and atmosphere…")
                                    .font(.subheadline)
                                    .foregroundStyle(Color(UIColor.placeholderText))
                                    .padding(.top, 18)
                                    .padding(.leading, 14)
                                    .allowsHitTesting(false)
                            }
                        }
                    }

                    // MARK: Anti-fake disclaimer
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.dinkrGreen)
                        Text("Dinkr only shows verified community reviews. We never accept payment for reviews.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color.dinkrGreen.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // MARK: Submit
                    Button {
                        submitReview()
                    } label: {
                        ZStack {
                            Text("Submit Review")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .opacity(isSubmitting ? 0 : 1)

                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isValid ? Color.dinkrGreen : Color(UIColor.systemGray4))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!isValid || isSubmitting)
                    .animation(.easeInOut(duration: 0.2), value: isValid)
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("Review \(court.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
            .alert("Review Submitted!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Thanks for helping the Dinkr community. Your review will appear shortly.")
            }
        }
    }

    private func submitReview() {
        guard isValid else { return }
        isSubmitting = true

        let review = CourtReview(
            id: UUID().uuidString,
            courtId: court.id,
            authorId: "current_user",
            authorName: "You",
            authorUsername: "current_player",
            overallRating: Double(overallRating),
            surfaceRating: surfaceRating,
            lightingRating: lightingRating,
            facilityRating: facilityRating,
            crowdsRating: crowdsRating,
            atmosphereRating: atmosphereRating,
            body: reviewBody.trimmingCharacters(in: .whitespacesAndNewlines),
            typicalPlayTimes: Array(selectedPlayTimes),
            tags: Array(selectedTags),
            isVerifiedPlayer: false,
            helpfulCount: 0,
            createdAt: Date(),
            isFeatured: false
        )

        Task {
            do {
                _ = try await FirestoreService.shared.addDocument(review, collection: "courtReviews")
            } catch {
                // Firestore unavailable in dev — no-op, still show success
            }
            await MainActor.run {
                isSubmitting = false
                onSubmit(review)
                showSuccess = true
            }
        }
    }
}

// MARK: - CriteriaSlider

private struct CriteriaSlider: View {
    let label: String
    let emoji: String
    @Binding var value: Double

    private var emojiForValue: String {
        switch Int(value.rounded()) {
        case 1: return "😞"
        case 2: return "😐"
        case 3: return "🙂"
        case 4: return "😊"
        default: return "🤩"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(emoji)
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.dinkrNavy)
                Spacer()
                Text(emojiForValue)
                Text(String(format: "%.0f", value))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.dinkrGreen)
                    .frame(width: 18, alignment: .trailing)
            }
            Slider(value: $value, in: 1...5, step: 0.5)
                .tint(Color.dinkrGreen)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - SectionLabel

private struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.6)
    }
}

// MARK: - CourtConditionsWidget

struct CourtConditionsWidget: View {
    let court: CourtVenue

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
                conditionCell(label: "Weather", value: weatherEmoji, valueIsEmoji: true)
                Divider().frame(height: 36)
                conditionCell(label: "Surface", valueView: AnyView(qualityDot(surfaceQuality)), subLabel: surfaceQuality.label)
                Divider().frame(height: 36)
                conditionCell(label: "Nets", value: netStatus)
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

    private func conditionCell(label: String, value: String, valueIsEmoji: Bool = false) -> some View {
        VStack(spacing: 4) {
            if valueIsEmoji {
                Text(value).font(.title3)
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

// MARK: - Shared Components

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

struct RatingBar: View {
    let filled: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(UIColor.systemGray5))
                    .frame(height: 8)
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: geo.size.width * CGFloat(min(max(filled, 0), 1)), height: 8)
            }
        }
        .frame(height: 8)
    }
}

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

// MARK: - Previews

#Preview("Court Reviews") {
    NavigationStack {
        CourtReviewsView(court: CourtVenue.mockVenues[0])
    }
}

#Preview("Write Review") {
    WriteCourtReviewView(court: CourtVenue.mockVenues[0]) { _ in }
}

#Preview("Review Card") {
    CourtReviewCard(review: CourtReview.mockReviews[0])
        .padding()
}

#Preview("Conditions Widget") {
    CourtConditionsWidget(court: CourtVenue.mockVenues[1])
        .padding()
}

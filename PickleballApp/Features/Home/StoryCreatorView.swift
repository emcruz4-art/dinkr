import SwiftUI

// MARK: - Data models

struct RecentCourt: Identifiable {
    let id: String
    let name: String
    let address: String
}

struct MomentType: Identifiable {
    let id: String
    let label: String
    let emoji: String
}

// MARK: - StoryCreatorView

struct StoryCreatorView: View {
    @Environment(\.dismiss) private var dismiss

    // Step tracking (0-based: 0=location, 1=moment, 2=details)
    @State private var step: Int = 0

    // Step 1 – Location
    @State private var courtSearch: String = ""
    @State private var selectedCourt: RecentCourt? = nil

    // Step 2 – Moment
    @State private var selectedMoment: MomentType? = nil

    // Step 3 – Details
    @State private var taggedPlayers: [String] = []
    @State private var playerSearchText: String = ""
    @State private var caption: String = ""
    @State private var sessionStars: Int = 0
    @State private var selectedMood: String = ""

    // Post completion
    @State private var isPosting: Bool = false
    @State private var showSuccess: Bool = false

    // MARK: - Static data

    let recentCourts: [RecentCourt] = [
        RecentCourt(id: "rc1", name: "Westside Pickleball", address: "2200 William Cannon Dr"),
        RecentCourt(id: "rc2", name: "Mueller Rec Center", address: "4400 Mueller Blvd"),
        RecentCourt(id: "rc3", name: "Barton Springs Courts", address: "2201 Barton Springs Rd"),
        RecentCourt(id: "rc4", name: "Zilker Park", address: "2100 Barton Springs Rd"),
    ]

    let momentTypes: [MomentType] = [
        MomentType(id: "m1", label: "Just Arrived", emoji: "🏃"),
        MomentType(id: "m2", label: "Mid Game",     emoji: "🏓"),
        MomentType(id: "m3", label: "Winning",      emoji: "🏆"),
        MomentType(id: "m4", label: "Training",     emoji: "💪"),
        MomentType(id: "m5", label: "Social Vibes", emoji: "🎉"),
        MomentType(id: "m6", label: "Game Complete",emoji: "✅"),
    ]

    let moodEmojis: [String] = ["😄", "💪", "🎯", "🔥", "😤"]

    let suggestedPlayers: [String] = ["Maria S.", "Jordan K.", "Jamie L.", "Sarah T.", "Riley P."]

    // MARK: - Filtered courts

    private var filteredCourts: [RecentCourt] {
        if courtSearch.isEmpty { return recentCourts }
        return recentCourts.filter {
            $0.name.localizedCaseInsensitiveContains(courtSearch) ||
            $0.address.localizedCaseInsensitiveContains(courtSearch)
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color.dinkrNavy.opacity(0.06),
                    Color.appBackground,
                    Color.dinkrGreen.opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                creatorTopBar

                // Step progress dots
                stepProgressIndicator
                    .padding(.top, 4)
                    .padding(.bottom, 20)

                // Step content
                ScrollView {
                    VStack(spacing: 0) {
                        switch step {
                        case 0:  stepLocationView
                        case 1:  stepMomentView
                        default: stepDetailsView
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }

                // Bottom CTA
                bottomCTA
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
            }

            // Success overlay
            if showSuccess {
                successOverlay
            }
        }
    }

    // MARK: - Top bar

    private var creatorTopBar: some View {
        HStack {
            Button {
                HapticManager.selection()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(Color.cardBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Create Check-in")
                .font(.headline)

            Spacer()

            // Balance spacer
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Step progress indicator

    private var stepProgressIndicator: some View {
        HStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? Color.dinkrGreen : Color.dinkrGreen.opacity(0.18))
                    .frame(width: index == step ? 28 : 10, height: 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: step)
            }
        }
    }

    // MARK: - Step 1: Location

    private var stepLocationView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Where are you playing?")
                    .font(.title2.weight(.bold))
                Text("Pick a court to start your check-in")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                TextField("Search court name…", text: $courtSearch)
                    .font(.subheadline)
                if !courtSearch.isEmpty {
                    Button {
                        courtSearch = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.dinkrGreen.opacity(0.25), lineWidth: 1)
            )

            // Recent courts
            VStack(alignment: .leading, spacing: 10) {
                Text("Recent Courts")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                StoryFlowLayout(spacing: 8) {
                    ForEach(filteredCourts) { court in
                        Button {
                            HapticManager.selection()
                            selectedCourt = court
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.fill")
                                    .font(.caption2)
                                    .foregroundStyle(selectedCourt?.id == court.id ? .white : Color.dinkrCoral)
                                Text(court.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(selectedCourt?.id == court.id ? .white : .primary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                selectedCourt?.id == court.id
                                    ? Color.dinkrGreen
                                    : Color.cardBackground
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(
                                        selectedCourt?.id == court.id
                                            ? Color.clear
                                            : Color.dinkrGreen.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.15), value: selectedCourt?.id)
                    }
                }
            }

            // Map thumbnail placeholder
            mapThumbnail
        }
    }

    private var mapThumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.dinkrSky.opacity(0.12))
                .frame(height: 140)

            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.dinkrSky.opacity(0.3), lineWidth: 1)
                .frame(height: 140)

            VStack(spacing: 8) {
                // Simulated map grid lines
                ZStack {
                    // Horizontal "road" lines
                    ForEach([0.35, 0.55, 0.75], id: \.self) { ratio in
                        Rectangle()
                            .fill(Color.dinkrSky.opacity(0.25))
                            .frame(height: 2)
                            .offset(y: 140 * (ratio - 0.5))
                    }
                    // Vertical "road" lines
                    ForEach([0.25, 0.5, 0.75], id: \.self) { ratio in
                        Rectangle()
                            .fill(Color.dinkrSky.opacity(0.2))
                            .frame(width: 2)
                            .offset(x: UIScreen.main.bounds.width * (ratio - 0.5))
                    }

                    // Court pin
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(Color.dinkrCoral)
                                .frame(width: 32, height: 32)
                                .shadow(color: Color.dinkrCoral.opacity(0.4), radius: 6, y: 2)
                            Image(systemName: "mappin.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        StoryTriangle()
                            .fill(Color.dinkrCoral)
                            .frame(width: 12, height: 6)
                    }
                    .offset(y: -8)

                    // "Austin, TX" label
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("Austin, TX")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color.dinkrNavy.opacity(0.6))
                                .padding(6)
                        }
                    }
                }
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Step 2: Moment type

    private var stepMomentView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("What's your moment?")
                    .font(.title2.weight(.bold))
                if let court = selectedCourt {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.fill")
                            .font(.caption)
                            .foregroundStyle(Color.dinkrCoral)
                        Text(court.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                }
                Text("Let your friends know what you're up to")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Card grid – 2 columns
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(momentTypes) { moment in
                    MomentCard(
                        moment: moment,
                        isSelected: selectedMoment?.id == moment.id,
                        onTap: {
                            HapticManager.selection()
                            selectedMoment = moment
                        }
                    )
                }
            }
        }
    }

    // MARK: - Step 3: Details

    private var stepDetailsView: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                if let court = selectedCourt, let moment = selectedMoment {
                    HStack(spacing: 6) {
                        Text(moment.emoji)
                        Text(moment.label)
                            .font(.title2.weight(.bold))
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.fill")
                            .font(.caption)
                            .foregroundStyle(Color.dinkrCoral)
                        Text(court.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                }
                Text("Add the finishing touches")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Who I'm with
            VStack(alignment: .leading, spacing: 10) {
                Label("Who I'm with", systemImage: "person.2.fill")
                    .font(.subheadline.weight(.semibold))

                // Tagged player pills
                if !taggedPlayers.isEmpty {
                    StoryFlowLayout(spacing: 8) {
                        ForEach(taggedPlayers, id: \.self) { player in
                            HStack(spacing: 4) {
                                Text(player)
                                    .font(.caption.weight(.semibold))
                                Button {
                                    taggedPlayers.removeAll { $0 == player }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9, weight: .bold))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.dinkrGreen.opacity(0.12))
                            .foregroundStyle(Color.dinkrGreen)
                            .clipShape(Capsule())
                        }
                    }
                }

                // Suggested players
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestedPlayers.filter { !taggedPlayers.contains($0) }, id: \.self) { player in
                            Button {
                                HapticManager.selection()
                                taggedPlayers.append(player)
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.dinkrSky)
                                    Text(player)
                                        .font(.caption.weight(.medium))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color.cardBackground)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.dinkrSky.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Caption
            VStack(alignment: .leading, spacing: 8) {
                Label("Caption", systemImage: "text.bubble")
                    .font(.subheadline.weight(.semibold))
                TextField("What's on your mind? (optional)", text: $caption, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(3...5)
                    .padding(12)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.dinkrGreen.opacity(0.2), lineWidth: 1)
                    )
            }

            // Skill rating
            VStack(alignment: .leading, spacing: 10) {
                Label("Session Rating", systemImage: "star.fill")
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 10) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            HapticManager.selection()
                            sessionStars = star
                        } label: {
                            Image(systemName: star <= sessionStars ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundStyle(star <= sessionStars ? Color.dinkrAmber : Color.dinkrAmber.opacity(0.3))
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: sessionStars)
                    }
                    Spacer()
                    if sessionStars > 0 {
                        Text(ratingLabel(for: sessionStars))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrAmber)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                .animation(.easeInOut(duration: 0.15), value: sessionStars)
            }

            // Mood
            VStack(alignment: .leading, spacing: 10) {
                Label("Mood", systemImage: "face.smiling")
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 12) {
                    ForEach(moodEmojis, id: \.self) { emoji in
                        Button {
                            HapticManager.selection()
                            selectedMood = selectedMood == emoji ? "" : emoji
                        } label: {
                            Text(emoji)
                                .font(.title2)
                                .frame(width: 48, height: 48)
                                .background(
                                    selectedMood == emoji
                                        ? Color.dinkrGreen.opacity(0.15)
                                        : Color.cardBackground
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            selectedMood == emoji ? Color.dinkrGreen : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: selectedMood)
                    }
                }
            }
        }
    }

    // MARK: - Bottom CTA

    private var bottomCTA: some View {
        VStack(spacing: 12) {
            if step < 2 {
                Button {
                    HapticManager.medium()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        step += 1
                    }
                } label: {
                    HStack {
                        Text(step == 0 ? "Choose Moment" : "Add Details")
                            .font(.headline)
                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        canAdvance
                            ? Color.dinkrGreen
                            : Color.dinkrGreen.opacity(0.35)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .disabled(!canAdvance)
            } else {
                // Post button — green gradient
                Button {
                    postCheckIn()
                } label: {
                    HStack(spacing: 8) {
                        if isPosting {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.subheadline.weight(.semibold))
                        }
                        Text(isPosting ? "Posting…" : "Share Check-in")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.78)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 10, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(isPosting)
            }

            // Back button for steps 1+
            if step > 0 {
                Button {
                    HapticManager.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        step -= 1
                    }
                } label: {
                    Text("Back")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Success overlay

    private var successOverlay: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ConfettiView()
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Text("🏓")
                        .font(.system(size: 52))
                }

                VStack(spacing: 8) {
                    Text("Check-in posted!")
                        .font(.title.weight(.bold))
                    Text("Your friends can see you're playing 🏓")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .zIndex(10)
    }

    // MARK: - Helpers

    private var canAdvance: Bool {
        switch step {
        case 0: return selectedCourt != nil
        case 1: return selectedMoment != nil
        default: return true
        }
    }

    private func ratingLabel(for stars: Int) -> String {
        switch stars {
        case 1: return "Rough"
        case 2: return "Okay"
        case 3: return "Good"
        case 4: return "Great"
        case 5: return "Epic"
        default: return ""
        }
    }

    private func postCheckIn() {
        HapticManager.medium()
        isPosting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isPosting = false
            HapticManager.success()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                showSuccess = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                dismiss()
            }
        }
    }
}

// MARK: - MomentCard

private struct MomentCard: View {
    let moment: MomentType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Text(moment.emoji)
                    .font(.system(size: 36))
                Text(moment.label)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                isSelected
                    ? Color.dinkrGreen
                    : Color.cardBackground
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.clear : Color.dinkrGreen.opacity(0.15),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: isSelected ? Color.dinkrGreen.opacity(0.3) : Color.clear,
                radius: 8, y: 3
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FlowLayout (wrapping chip rows)

private struct StoryFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { row in
            row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
        }.reduce(0) { $0 + $1 + spacing } - spacing
        return CGSize(width: proposal.width ?? 0, height: max(height, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: ProposedViewSize(width: bounds.width, height: nil), subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubview]] = [[]]
        var rowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([])
                rowWidth = 0
            }
            rows[rows.count - 1].append(subview)
            rowWidth += size.width + spacing
        }
        return rows
    }
}

// MARK: - Triangle shape (used in map pin)

private struct StoryTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
        }
    }
}

// MARK: - Preview

#Preview {
    StoryCreatorView()
}

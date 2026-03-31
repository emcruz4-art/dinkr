import SwiftUI

// MARK: - FeedFilterOptions

struct FeedFilterOptions: Equatable {
    var selectedPostTypes: Set<PostType> = []       // empty = "All"
    var skillMin: SkillLevel = .beginner20
    var skillMax: SkillLevel = .pro50
    var location: FeedLocationFilter = .all
    var timeRange: FeedTimeRange = .allTime
    var sortBy: FeedSortOption = .mostRecent

    /// Number of non-default filter dimensions that are active.
    var activeCount: Int {
        var count = 0
        if !selectedPostTypes.isEmpty { count += 1 }
        if skillMin != .beginner20 || skillMax != .pro50 { count += 1 }
        if location != .all { count += 1 }
        if timeRange != .allTime { count += 1 }
        if sortBy != .mostRecent { count += 1 }
        return count
    }

    static let `default` = FeedFilterOptions()
}

// MARK: - Supporting enums

enum FeedLocationFilter: String, CaseIterable {
    case nearMe     = "Near Me"
    case myGroups   = "My Groups"
    case following  = "Following"
    case all        = "All"

    var icon: String {
        switch self {
        case .nearMe:    return "location.fill"
        case .myGroups:  return "person.3.fill"
        case .following: return "person.2.fill"
        case .all:       return "globe"
        }
    }
}

enum FeedTimeRange: String, CaseIterable {
    case allTime   = "All Time"
    case today     = "Today"
    case thisWeek  = "This Week"
    case thisMonth = "This Month"
}

enum FeedSortOption: String, CaseIterable {
    case mostRecent    = "Most Recent"
    case mostLiked     = "Most Liked"
    case mostCommented = "Most Commented"
    case trending      = "Trending"

    var icon: String {
        switch self {
        case .mostRecent:    return "clock.fill"
        case .mostLiked:     return "heart.fill"
        case .mostCommented: return "bubble.left.fill"
        case .trending:      return "flame.fill"
        }
    }
}

// MARK: - FeedFilterSheet

struct FeedFilterSheet: View {
    @Binding var options: FeedFilterOptions
    @Environment(\.dismiss) private var dismiss

    /// Local draft — only committed on Apply
    @State private var draft: FeedFilterOptions

    init(options: Binding<FeedFilterOptions>) {
        self._options = options
        self._draft = State(initialValue: options.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    dragHandle
                    filterContent
                    applyBar
                }
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)    // we draw our own
        .presentationBackground(Color.appBackground)
    }

    // MARK: - Drag handle

    private var dragHandle: some View {
        VStack(spacing: 8) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            HStack {
                Text("Filter Feed")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.dinkrNavy)
                Spacer()
                Button("Clear All") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        draft = .default
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(draft == .default ? Color.secondary : Color.dinkrCoral)
                .disabled(draft == .default)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 4)
        }
    }

    // MARK: - Scrollable filter content

    private var filterContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                postTypesSection
                skillLevelSection
                locationSection
                timeRangeSection
                sortBySection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Post Types

    private var postTypesSection: some View {
        FilterSection(title: "Post Type", icon: "tag.fill", color: Color.dinkrSky) {
            postTypeChips
        }
    }

    private var postTypeChips: some View {
        FeedFlowLayout(spacing: 8) {
            // "All" chip
            let isAllActive = draft.selectedPostTypes.isEmpty
            FeedFilterChip(
                label: "All",
                icon: "square.grid.2x2.fill",
                isSelected: isAllActive,
                color: Color.dinkrNavy
            ) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    draft.selectedPostTypes = []
                }
            }

            ForEach(PostType.allCases, id: \.self) { type in
                let isSelected = draft.selectedPostTypes.contains(type)
                FeedFilterChip(
                    label: type.filterLabel,
                    icon: type.filterIcon,
                    isSelected: isSelected,
                    color: type.filterColor
                ) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        if isSelected {
                            draft.selectedPostTypes.remove(type)
                        } else {
                            draft.selectedPostTypes.insert(type)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Skill Level Range

    private var skillLevelSection: some View {
        FilterSection(title: "Skill Level Range", icon: "chart.bar.fill", color: Color.dinkrGreen) {
            VStack(spacing: 12) {
                HStack {
                    Text("Min")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, alignment: .leading)
                    skillLevelPicker(selection: $draft.skillMin, label: "Minimum")
                }
                HStack {
                    Text("Max")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, alignment: .leading)
                    skillLevelPicker(selection: $draft.skillMax, label: "Maximum")
                }
                if draft.skillMin > draft.skillMax {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.dinkrAmber)
                        Text("Min level must be ≤ max level")
                            .font(.caption2)
                            .foregroundStyle(Color.dinkrAmber)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private func skillLevelPicker(selection: Binding<SkillLevel>, label: String) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(SkillLevel.allCases, id: \.self) { level in
                    let isSelected = selection.wrappedValue == level
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selection.wrappedValue = level
                        }
                        HapticManager.selection()
                    } label: {
                        Text(level.label)
                            .font(.caption.weight(isSelected ? .bold : .regular))
                            .foregroundStyle(isSelected ? .white : Color.dinkrNavy)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                isSelected
                                    ? Color.dinkrGreen
                                    : Color.dinkrGreen.opacity(0.08),
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        isSelected ? Color.clear : Color.dinkrGreen.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
                }
            }
        }
    }

    // MARK: - Location

    private var locationSection: some View {
        FilterSection(title: "Location", icon: "location.fill", color: Color.dinkrCoral) {
            HStack(spacing: 8) {
                ForEach(FeedLocationFilter.allCases, id: \.self) { loc in
                    let isSelected = draft.location == loc
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            draft.location = loc
                        }
                        HapticManager.selection()
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: loc.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(isSelected ? .white : Color.dinkrCoral)
                            Text(loc.rawValue)
                                .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                                .foregroundStyle(isSelected ? .white : Color.dinkrNavy)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            isSelected
                                ? Color.dinkrCoral
                                : Color.dinkrCoral.opacity(0.07),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    isSelected ? Color.clear : Color.dinkrCoral.opacity(0.18),
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(isSelected ? 1.03 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
                }
            }
        }
    }

    // MARK: - Time Range

    private var timeRangeSection: some View {
        FilterSection(title: "Time Range", icon: "clock.fill", color: Color.dinkrAmber) {
            HStack(spacing: 6) {
                ForEach(FeedTimeRange.allCases, id: \.self) { range in
                    let isSelected = draft.timeRange == range
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            draft.timeRange = range
                        }
                        HapticManager.selection()
                    } label: {
                        Text(range.rawValue)
                            .font(.caption.weight(isSelected ? .bold : .regular))
                            .foregroundStyle(isSelected ? .white : Color.dinkrNavy)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                isSelected
                                    ? Color.dinkrAmber
                                    : Color.dinkrAmber.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .stroke(
                                        isSelected ? Color.clear : Color.dinkrAmber.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(isSelected ? 1.03 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
                }
            }
        }
    }

    // MARK: - Sort By

    private var sortBySection: some View {
        FilterSection(title: "Sort By", icon: "arrow.up.arrow.down", color: Color.dinkrNavy) {
            VStack(spacing: 6) {
                ForEach(FeedSortOption.allCases, id: \.self) { option in
                    let isSelected = draft.sortBy == option
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            draft.sortBy = option
                        }
                        HapticManager.selection()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: option.icon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(isSelected ? Color.dinkrGreen : .secondary)
                                .frame(width: 22)
                            Text(option.rawValue)
                                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                                .foregroundStyle(isSelected ? Color.dinkrNavy : .primary)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color.dinkrGreen)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(
                            isSelected
                                ? Color.dinkrGreen.opacity(0.08)
                                : Color.secondary.opacity(0.05),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    isSelected ? Color.dinkrGreen.opacity(0.25) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Apply bar

    private var applyBar: some View {
        VStack(spacing: 0) {
            Divider()
            VStack(spacing: 10) {
                Button {
                    options = draft
                    HapticManager.medium()
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text(draft.activeCount > 0
                             ? "Apply Filters (\(draft.activeCount))"
                             : "Apply Filters")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 8, x: 0, y: 3)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.appBackground)
        }
    }
}

// MARK: - FilterSection

private struct FilterSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(color)
                    .frame(width: 20, height: 20)
                    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.dinkrNavy)
            }
            content()
        }
    }
}

// MARK: - FilterChip

private struct FeedFilterChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            HapticManager.selection()
        }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(label)
                    .font(.caption.weight(isSelected ? .bold : .regular))
            }
            .foregroundStyle(isSelected ? .white : color)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(
                isSelected ? color : color.opacity(0.08),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - FeedFlowLayout (wrapping chip container)

private struct FeedFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: ProposedViewSize(width: bounds.width, height: nil), subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalHeight = y + rowHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), frames)
    }
}

// MARK: - PostType filter helpers (shared with FeedView)

extension PostType {
    var filterLabel: String {
        switch self {
        case .general:       return "General"
        case .highlight:     return "Highlights"
        case .question:      return "Questions"
        case .winCelebration: return "Wins"
        case .courtReview:   return "Courts"
        case .lookingForGame: return "LFG"
        }
    }

    var filterIcon: String {
        switch self {
        case .general:       return "text.bubble.fill"
        case .highlight:     return "star.fill"
        case .question:      return "questionmark.bubble.fill"
        case .winCelebration: return "trophy.fill"
        case .courtReview:   return "mappin.circle.fill"
        case .lookingForGame: return "person.badge.plus.fill"
        }
    }

    var filterColor: Color {
        switch self {
        case .general:       return Color.dinkrNavy
        case .highlight:     return Color.dinkrCoral
        case .question:      return Color.dinkrSky
        case .winCelebration: return Color.dinkrGreen
        case .courtReview:   return .purple
        case .lookingForGame: return Color.dinkrAmber
        }
    }
}

// MARK: - Preview

#Preview("FeedFilterSheet") {
    @Previewable @State var options = FeedFilterOptions()
    Color.appBackground
        .sheet(isPresented: .constant(true)) {
            FeedFilterSheet(options: $options)
        }
}

import SwiftUI

// MARK: - Badge Showcase View

struct BadgeShowcaseView: View {
    let user: User

    @State private var displayMode: DisplayMode = .grid
    @State private var selectedFilter: BadgeFilter = .all
    @State private var renderedShowcaseImage: UIImage? = nil
    @State private var isRenderingShowcase = false
    @State private var spotlightPulse = false
    @Namespace private var filterNamespace

    private let achievements = Achievement.all

    enum DisplayMode: String, CaseIterable {
        case grid = "Grid"
        case list = "List"

        var icon: String {
            switch self {
            case .grid: return "square.grid.3x3.fill"
            case .list: return "list.bullet"
            }
        }
    }

    enum BadgeFilter: String, CaseIterable, Identifiable {
        case all      = "All"
        case unlocked = "Unlocked"
        case locked   = "Locked"
        case recent   = "Recent"

        var id: String { rawValue }
    }

    // MARK: Derived data

    private var unlockedAchievements: [Achievement] {
        achievements.filter { $0.isUnlocked }
    }

    private var recentAchievements: [Achievement] {
        unlockedAchievements
            .compactMap { a -> (Achievement, Date)? in
                guard let d = a.unlockedDate else { return nil }
                return (a, d)
            }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }

    private var featuredAchievement: Achievement? {
        recentAchievements.first
    }

    private var filteredAchievements: [Achievement] {
        switch selectedFilter {
        case .all:      return achievements
        case .unlocked: return unlockedAchievements
        case .locked:   return achievements.filter { !$0.isUnlocked }
        case .recent:   return recentAchievements
        }
    }

    // MARK: Badge category grouping (for list mode section headers)

    private func category(for achievement: Achievement) -> String {
        switch achievement.badgeType {
        case .firstGame, .centennial:             return "Games"
        case .communityChampion, .womensPioneer:  return "Social"
        case .tournamentWinner:                    return "Events"
        case .reliablePro, .courtBuilder:         return "Special"
        }
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // ── Counter header ──────────────────────────────────────
                    BadgeCountHeader(
                        unlocked: unlockedAchievements.count,
                        total: achievements.count
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // ── Featured badge spotlight ────────────────────────────
                    if let featured = featuredAchievement {
                        FeaturedBadgeSpotlight(
                            achievement: featured,
                            pulse: spotlightPulse
                        )
                        .padding(.horizontal, 20)
                    }

                    // ── Display mode + filter strip ─────────────────────────
                    VStack(spacing: 12) {
                        // Mode toggle
                        HStack(spacing: 0) {
                            ForEach(DisplayMode.allCases, id: \.self) { mode in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        displayMode = mode
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: mode.icon)
                                            .font(.caption.weight(.semibold))
                                        Text(mode.rawValue)
                                            .font(.subheadline.weight(.semibold))
                                    }
                                    .foregroundStyle(displayMode == mode ? .white : .secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background(
                                        Group {
                                            if displayMode == mode {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color.dinkrNavy)
                                            } else {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color.clear)
                                            }
                                        }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(4)
                        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 20)

                        // Filter chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(BadgeFilter.allCases) { filter in
                                    BadgeFilterChip(
                                        label: filter.rawValue,
                                        count: countFor(filter),
                                        isSelected: selectedFilter == filter,
                                        namespace: filterNamespace
                                    ) {
                                        withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                                            selectedFilter = filter
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // ── Content ─────────────────────────────────────────────
                    if displayMode == .grid {
                        BadgeGrid(achievements: filteredAchievements)
                            .padding(.horizontal, 20)
                    } else {
                        BadgeList(achievements: filteredAchievements, category: category(for:))
                            .padding(.horizontal, 20)
                    }

                    // ── Share showcase button ───────────────────────────────
                    VStack(spacing: 10) {
                        if let image = renderedShowcaseImage {
                            ShareLink(
                                item: Image(uiImage: image),
                                preview: SharePreview(
                                    "Check out my Dinkr badge showcase! 🏅 #Dinkr #Pickleball",
                                    image: Image(uiImage: image)
                                )
                            ) {
                                ShareBadgesButton(isRendering: false)
                            }
                        } else {
                            Button {
                                renderShowcaseCard()
                            } label: {
                                ShareBadgesButton(isRendering: isRenderingShowcase)
                            }
                            .disabled(isRenderingShowcase)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("My Badges")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        }
        .onAppear {
            // Kick off spotlight pulse loop
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                spotlightPulse = true
            }
        }
    }

    // MARK: Helpers

    private func countFor(_ filter: BadgeFilter) -> Int? {
        switch filter {
        case .all:      return nil
        case .unlocked: return unlockedAchievements.count
        case .locked:   return achievements.count - unlockedAchievements.count
        case .recent:   return recentAchievements.prefix(5).count
        }
    }

    private func renderShowcaseCard() {
        isRenderingShowcase = true
        let card = BadgeShowcaseCard(
            achievements: unlockedAchievements,
            user: user,
            total: achievements.count
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        if let image = renderer.uiImage {
            renderedShowcaseImage = image
        }
        isRenderingShowcase = false
    }
}

// MARK: - Badge Count Header

private struct BadgeCountHeader: View {
    let unlocked: Int
    let total: Int

    private var fraction: Double { Double(unlocked) / Double(max(total, 1)) }
    @State private var barAnimated = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(unlocked) / \(total) badges earned")
                        .font(.headline.weight(.bold))
                    Text("\(Int(fraction * 100))% of your collection unlocked")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("🏅")
                    .font(.title)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.dinkrAmber.opacity(0.18))
                        .frame(height: 9)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color.dinkrAmber, Color.dinkrCoral.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * (barAnimated ? fraction : 0),
                            height: 9
                        )
                        .animation(.spring(response: 0.9, dampingFraction: 0.72).delay(0.2), value: barAnimated)
                }
            }
            .frame(height: 9)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .onAppear { barAnimated = true }
    }
}

// MARK: - Featured Badge Spotlight

private struct FeaturedBadgeSpotlight: View {
    let achievement: Achievement
    let pulse: Bool

    private var badgeColor: Color {
        switch achievement.color {
        case "dinkrGreen":  return Color.dinkrGreen
        case "dinkrNavy":   return Color.dinkrNavy
        case "dinkrCoral":  return Color.dinkrCoral
        case "dinkrSky":    return Color.dinkrSky
        default:            return Color.dinkrAmber
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                // Pulsing glow ring
                Circle()
                    .fill(badgeColor.opacity(pulse ? 0.22 : 0.08))
                    .frame(width: 72, height: 72)
                    .blur(radius: 6)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulse)

                Circle()
                    .fill(badgeColor.opacity(0.14))
                    .frame(width: 62, height: 62)
                Circle()
                    .stroke(badgeColor.opacity(0.6), lineWidth: 2)
                    .frame(width: 62, height: 62)

                Image(systemName: achievement.icon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(badgeColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Most Recent")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(badgeColor)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Image(systemName: "sparkles")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(badgeColor)
                }
                Text(achievement.title)
                    .font(.headline.weight(.bold))
                if let date = achievement.unlockedDate {
                    Text("Unlocked \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [badgeColor.opacity(0.12), badgeColor.opacity(0.04)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(badgeColor.opacity(0.30), lineWidth: 1.5)
                )
        )
    }
}

// MARK: - Filter Chip

private struct BadgeFilterChip: View {
    let label: String
    let count: Int?
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(label)
                    .font(.subheadline.weight(isSelected ? .bold : .regular))
                if let count {
                    Text("\(count)")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? .white.opacity(0.25) : Color.secondary.opacity(0.14))
                        )
                }
            }
            .foregroundStyle(isSelected ? .white : Color.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.dinkrNavy)
                        .matchedGeometryEffect(id: "filterBg", in: namespace)
                } else {
                    Capsule()
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Badge Grid (3-column)

private struct BadgeGrid: View {
    let achievements: [Achievement]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(achievements) { achievement in
                BadgeGridCell(achievement: achievement)
            }
        }
    }
}

private struct BadgeGridCell: View {
    let achievement: Achievement

    private var badgeColor: Color {
        switch achievement.color {
        case "dinkrGreen":  return Color.dinkrGreen
        case "dinkrNavy":   return Color.dinkrNavy
        case "dinkrCoral":  return Color.dinkrCoral
        case "dinkrSky":    return Color.dinkrSky
        default:            return Color.dinkrAmber
        }
    }

    private var unlockLabel: String {
        if achievement.isUnlocked, let date = achievement.unlockedDate {
            return date.formatted(.dateTime.month(.abbreviated).day())
        } else if achievement.isUnlocked {
            return "Unlocked"
        } else {
            return "Locked"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        achievement.isUnlocked
                            ? badgeColor.opacity(0.14)
                            : Color.secondary.opacity(0.08)
                    )
                    .frame(width: 58, height: 58)

                Image(systemName: achievement.icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(
                        achievement.isUnlocked
                            ? badgeColor
                            : Color.secondary.opacity(0.28)
                    )
                    .saturation(achievement.isUnlocked ? 1 : 0)

                if !achievement.isUnlocked {
                    Circle()
                        .fill(Color.black.opacity(0.25))
                        .frame(width: 58, height: 58)
                    Image(systemName: "lock.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.65))
                }
            }

            Text(achievement.title)
                .font(.system(size: 10, weight: .semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(achievement.isUnlocked ? Color.primary : Color.secondary)

            Text(unlockLabel)
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(
                    achievement.isUnlocked
                        ? Color.dinkrGreen.opacity(0.85)
                        : Color.secondary.opacity(0.55)
                )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    achievement.isUnlocked ? badgeColor.opacity(0.25) : Color.clear,
                    lineWidth: 1.5
                )
        )
    }
}

// MARK: - Badge List

private struct BadgeList: View {
    let achievements: [Achievement]
    let category: (Achievement) -> String

    var body: some View {
        LazyVStack(spacing: 10) {
            ForEach(achievements) { achievement in
                BadgeListRow(achievement: achievement, category: category(achievement))
            }
        }
    }
}

private struct BadgeListRow: View {
    let achievement: Achievement
    let category: String

    private var badgeColor: Color {
        switch achievement.color {
        case "dinkrGreen":  return Color.dinkrGreen
        case "dinkrNavy":   return Color.dinkrNavy
        case "dinkrCoral":  return Color.dinkrCoral
        case "dinkrSky":    return Color.dinkrSky
        default:            return Color.dinkrAmber
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        achievement.isUnlocked
                            ? badgeColor.opacity(0.14)
                            : Color.secondary.opacity(0.08)
                    )
                    .frame(width: 52, height: 52)

                Image(systemName: achievement.icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(
                        achievement.isUnlocked
                            ? badgeColor
                            : Color.secondary.opacity(0.28)
                    )
                    .saturation(achievement.isUnlocked ? 1 : 0)

                if !achievement.isUnlocked {
                    Circle()
                        .fill(Color.black.opacity(0.25))
                        .frame(width: 52, height: 52)
                    Image(systemName: "lock.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.65))
                }
            }

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(achievement.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(achievement.isUnlocked ? Color.primary : Color.secondary)

                    // Category tag
                    Text(category)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(badgeColor.opacity(0.8))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(badgeColor.opacity(0.10), in: Capsule())
                }

                Text(achievement.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if achievement.isUnlocked {
                    if let date = achievement.unlockedDate {
                        Text("Unlocked \(date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundStyle(Color.dinkrGreen.opacity(0.9))
                    }
                } else {
                    // Progress for locked
                    HStack(spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.14))
                                    .frame(height: 5)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.4))
                                    .frame(width: geo.size.width * achievement.progressFraction, height: 5)
                            }
                        }
                        .frame(height: 5)

                        Text("\(achievement.progress)/\(achievement.goal)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fixedSize()
                    }
                }
            }

            Spacer()
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    achievement.isUnlocked ? badgeColor.opacity(0.20) : Color.clear,
                    lineWidth: 1.5
                )
        )
    }
}

// MARK: - Share Badges Button

private struct ShareBadgesButton: View {
    let isRendering: Bool

    var body: some View {
        HStack(spacing: 10) {
            if isRendering {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(0.9)
            } else {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline.weight(.bold))
            }
            Text(isRendering ? "Preparing…" : "Share My Badges")
                .font(.subheadline.weight(.bold))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [Color.dinkrNavy, Color.dinkrNavy.opacity(0.85)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Badge Showcase Card (ImageRenderer source)

struct BadgeShowcaseCard: View {
    let achievements: [Achievement]
    let user: User
    let total: Int

    private var displayBadges: [Achievement] {
        Array(achievements.prefix(9))
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.dinkrNavy, Color(red: 0.07, green: 0.10, blue: 0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                        Text("\(achievements.count) / \(total) badges earned")
                            .font(.caption)
                            .foregroundStyle(Color.dinkrGreen.opacity(0.9))
                    }
                    Spacer()
                    Text("dinkr")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(Color.dinkrGreen)
                        .tracking(1.5)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Badge grid
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(displayBadges) { achievement in
                        ShowcaseCardBadge(achievement: achievement)
                    }
                }
                .padding(.horizontal, 20)

                // Footer
                HStack {
                    Text("🥒 DINKR · Play. Connect. Dink.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.38))
                    Spacer()
                    Text("dinkr.app")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.38))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 18)
            }
        }
        .frame(width: 360)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

private struct ShowcaseCardBadge: View {
    let achievement: Achievement

    private var badgeColor: Color {
        switch achievement.color {
        case "dinkrGreen":  return Color.dinkrGreen
        case "dinkrNavy":   return Color.dinkrGreen  // use green on dark bg
        case "dinkrCoral":  return Color.dinkrCoral
        case "dinkrSky":    return Color.dinkrSky
        default:            return Color.dinkrAmber
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(badgeColor.opacity(0.16))
                    .frame(width: 52, height: 52)
                Circle()
                    .stroke(badgeColor.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 52, height: 52)
                Image(systemName: achievement.icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(badgeColor)
            }
            Text(achievement.title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
}

// MARK: - Preview

#Preview {
    BadgeShowcaseView(user: User.mockCurrentUser)
}

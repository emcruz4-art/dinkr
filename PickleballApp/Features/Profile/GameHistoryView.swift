import SwiftUI

// MARK: - Filter

enum GameHistoryFilter: String, CaseIterable {
    case all       = "All"
    case wins      = "Wins"
    case losses    = "Losses"
    case doubles   = "Doubles"
    case singles   = "Singles"
    case openPlay  = "Open Play"
}

// MARK: - GameHistoryView

struct GameHistoryView: View {
    var userId: String = User.mockCurrentUser.id

    @State private var results: [GameResult] = []
    @State private var isLoading = true
    @State private var activeFilter: GameHistoryFilter = .all
    @State private var searchText: String = ""

    // MARK: Computed

    var filteredResults: [GameResult] {
        var base: [GameResult]
        switch activeFilter {
        case .all:      base = results
        case .wins:     base = results.filter { $0.isWin }
        case .losses:   base = results.filter { !$0.isWin }
        case .doubles:  base = results.filter { $0.format == .doubles }
        case .singles:  base = results.filter { $0.format == .singles }
        case .openPlay: base = results.filter { $0.format == .openPlay }
        }
        // Search filter: match opponent name (case-insensitive)
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            base = base.filter { $0.opponentName.lowercased().contains(q) }
        }
        return base
    }

    private var wins: Int   { results.filter { $0.isWin }.count }
    private var losses: Int { results.filter { !$0.isWin }.count }

    private var winRate: Int {
        guard !results.isEmpty else { return 0 }
        return Int(Double(wins) / Double(results.count) * 100)
    }

    private var avgMyScore: Double {
        guard !results.isEmpty else { return 0 }
        return Double(results.map { $0.myScore }.reduce(0, +)) / Double(results.count)
    }

    private var avgOppScore: Double {
        guard !results.isEmpty else { return 0 }
        return Double(results.map { $0.opponentScore }.reduce(0, +)) / Double(results.count)
    }

    /// Current win streak (most-recent games first)
    private var winStreak: Int {
        var streak = 0
        for r in results {
            if r.isWin { streak += 1 } else { break }
        }
        return streak
    }

    // Grouped by calendar month, most-recent first
    private var groupedResults: [(key: String, date: Date, results: [GameResult])] {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        var dict: [String: (date: Date, results: [GameResult])] = [:]
        for r in filteredResults {
            let key = formatter.string(from: r.playedAt)
            if dict[key] == nil {
                // anchor date = start of that month
                let comps = cal.dateComponents([.year, .month], from: r.playedAt)
                let anchor = cal.date(from: comps) ?? r.playedAt
                dict[key] = (date: anchor, results: [])
            }
            dict[key]?.results.append(r)
        }
        return dict
            .map { (key: $0.key, date: $0.value.date, results: $0.value.results) }
            .sorted { $0.date > $1.date }
    }

    // MARK: Body

    var body: some View {
        ZStack {
            if isLoading {
                skeletonView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                        // Search + filter bar
                        searchBar
                            .padding(.top, 12)
                        filterBar
                            .padding(.top, 6)
                            .padding(.bottom, 4)

                        // Summary strip
                        summaryStrip
                            .padding(.bottom, 12)

                        if filteredResults.isEmpty {
                            emptyState
                        } else {
                            ForEach(groupedResults, id: \.key) { group in
                                Section {
                                    LazyVStack(spacing: 8) {
                                        ForEach(group.results) { result in
                                            GameResultRow(result: result)
                                                .padding(.horizontal)
                                        }
                                    }
                                    .padding(.bottom, 12)
                                } header: {
                                    monthSectionHeader(label: group.key, results: group.results)
                                }
                            }
                        }
                    }
                }
            }
        }
        .task {
            results = await GameResultService.shared.loadResults(for: userId)
            isLoading = false
        }
    }

    // MARK: Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("Search opponent…", text: $searchText)
                .font(.subheadline)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GameHistoryFilter.allCases, id: \.self) { filter in
                    filterChip(filter)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func filterChip(_ filter: GameHistoryFilter) -> some View {
        let isActive = activeFilter == filter
        Button {
            HapticManager.selection()
            withAnimation(.easeInOut(duration: 0.18)) {
                activeFilter = filter
            }
        } label: {
            Text(filter.rawValue)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isActive ? .white : Color.dinkrGreen)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background {
                    if isActive {
                        Capsule().fill(Color.dinkrGreen)
                    } else {
                        Capsule().strokeBorder(Color.dinkrGreen, lineWidth: 1.5)
                    }
                }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: activeFilter)
    }

    // MARK: Summary Strip

    private var summaryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                SummaryChip(icon: "🔥", label: "Streak", value: "\(winStreak)")
                SummaryChip(icon: "🏓", label: "Total", value: "\(results.count)")
                SummaryChip(
                    icon: "🏆",
                    label: "W / L",
                    value: "\(wins) – \(losses)"
                )
                SummaryChip(icon: "📈", label: "Win Rate", value: "\(winRate)%")
                SummaryChip(
                    icon: "⚡️",
                    label: "Avg Score",
                    value: "\(Int(avgMyScore.rounded()))–\(Int(avgOppScore.rounded()))"
                )
            }
            .padding(.horizontal)
        }
    }

    // MARK: Section Header

    private func monthSectionHeader(label: String, results: [GameResult]) -> some View {
        let w = results.filter { $0.isWin }.count
        let l = results.filter { !$0.isWin }.count
        return HStack(spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
            Text("·")
                .foregroundStyle(.secondary)
            Text("\(w)W  \(l)L")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(w >= l ? Color.dinkrGreen : Color.dinkrCoral)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "trophy.slash")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(Color.dinkrNavy.opacity(0.3))
            Text("No \(activeFilter == .all ? "" : activeFilter.rawValue + " ")Games")
                .font(.headline)
                .foregroundStyle(Color.dinkrNavy.opacity(0.6))
            Text(searchText.isEmpty
                 ? "Try a different filter or log your first game."
                 : "No results for \"\(searchText)\".")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
        .padding(.horizontal, 32)
    }

    // MARK: Skeleton

    private var skeletonView: some View {
        VStack(spacing: 16) {
            ForEach(0..<5, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.cardBackground)
                    .frame(height: 80)
                    .redacted(reason: .placeholder)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
}

// MARK: - Summary Chip

private struct SummaryChip: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 3) {
            Text(icon)
                .font(.title3)
            Text(value)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 70)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - GameResultRow

struct GameResultRow: View {
    let result: GameResult
    var player: User = User.mockCurrentUser

    @State private var showDetail = false
    @State private var showRematch = false

    // Mock DUPR delta derived deterministically from score differential
    private var duprDelta: Double {
        let diff = result.myScore - result.opponentScore
        return Double(diff) * 0.008
    }
    private var duprText: String {
        let val = duprDelta
        return val >= 0 ? String(format: "+%.2f", val) : String(format: "%.2f", val)
    }
    private var duprColor: Color {
        duprDelta >= 0 ? Color.dinkrGreen : Color.dinkrCoral
    }

    var body: some View {
        Button {
            HapticManager.selection()
            showDetail = true
        } label: {
            rowContent
        }
        .buttonStyle(.plain)
        // Swipe-right action: Rematch
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                HapticManager.medium()
                showRematch = true
            } label: {
                Label("Rematch", systemImage: "arrow.trianglehead.counterclockwise")
            }
            .tint(Color.dinkrGreen)
        }
        .sheet(isPresented: $showDetail) {
            GameResultDetailView(result: result, player: player)
        }
        .alert("Challenge to Rematch?", isPresented: $showRematch) {
            Button("Send Challenge") { HapticManager.medium() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Send \(result.opponentName) a rematch request.")
        }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            // W/L pill
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(result.isWin ? Color.dinkrGreen : Color.dinkrCoral)
                    .frame(width: 38, height: 38)
                Text(result.isWin ? "W" : "L")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(.white)
            }

            // Opponent avatar
            AvatarView(urlString: nil, displayName: result.opponentName, size: 36)
                .overlay(
                    Circle().stroke(Color.dinkrNavy.opacity(0.12), lineWidth: 1)
                )

            // Center info
            VStack(alignment: .leading, spacing: 4) {
                // Opponent name + skill badge
                HStack(spacing: 6) {
                    Text(result.opponentName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    SkillBadge(level: result.opponentSkill, compact: true)
                }
                // Court + format chip
                HStack(spacing: 6) {
                    Text(result.courtName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    formatChip
                }
                // Score
                HStack(spacing: 4) {
                    Text("\(result.myScore)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(result.isWin ? Color.dinkrGreen : Color.dinkrCoral)
                    Text("–")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(result.opponentScore)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            // Right column
            VStack(alignment: .trailing, spacing: 4) {
                // DUPR change chip
                Text(duprText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(duprColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(duprColor.opacity(0.12), in: Capsule())

                // Date chip
                Text(result.playedAt, format: .dateTime.month(.abbreviated).day())
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.cardBackground, in: Capsule())
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var formatChip: some View {
        Text(result.format.displayLabel)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color.dinkrSky)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.dinkrSky.opacity(0.12), in: Capsule())
    }
}

// MARK: - GameResultDetailView

struct GameResultDetailView: View {
    let result: GameResult
    var player: User = User.mockCurrentUser

    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false

    private var accentColor: Color { result.isWin ? Color.dinkrGreen : Color.dinkrCoral }

    // Mock point-by-point highlights (5 events)
    private var highlights: [MatchHighlight] {
        [
            MatchHighlight(point: 1,  event: "Opening rally — \(player.displayName) winner"),
            MatchHighlight(point: 4,  event: "\(result.opponentName) kitchen error"),
            MatchHighlight(point: 7,  event: "Side-out after 3-dink sequence"),
            MatchHighlight(point: 9,  event: "\(player.displayName) overhead smash"),
            MatchHighlight(point: result.myScore, event: result.isWin ? "Match point — winning drive" : "Match point — opponent winner"),
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    scoreBanner
                    matchInfoGrid
                    timelineSection
                    actionButtons
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Match Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            MatchShareSheet(result: result, player: player)
        }
    }

    // MARK: Score Banner

    private var scoreBanner: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.dinkrNavy, result.isWin
                                 ? Color(red: 0.08, green: 0.35, blue: 0.20)
                                 : Color(red: 0.40, green: 0.12, blue: 0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            VStack(spacing: 8) {
                Text(result.isWin ? "WIN" : "LOSS")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.2), in: Capsule())

                HStack(alignment: .center, spacing: 24) {
                    VStack(spacing: 2) {
                        Text("\(result.myScore)")
                            .font(.system(size: 56, weight: .black, design: .rounded))
                            .foregroundStyle(accentColor)
                        Text("You")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Text("–")
                        .font(.system(size: 32, weight: .thin))
                        .foregroundStyle(.white.opacity(0.4))
                    VStack(spacing: 2) {
                        Text("\(result.opponentScore)")
                            .font(.system(size: 56, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(result.opponentName.components(separatedBy: " ").first ?? result.opponentName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.55))
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, 24)
        }
    }

    // MARK: Match Info Grid

    private var matchInfoGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            DetailInfoTile(icon: "mappin.circle.fill", label: "Court", value: result.courtName)
            DetailInfoTile(icon: "figure.pickleball", label: "Format", value: result.format.displayLabel)
            DetailInfoTile(icon: "person.fill", label: "Opponent", value: result.opponentName)
            DetailInfoTile(icon: "calendar", label: "Date",
                           value: result.playedAt.formatted(.dateTime.month(.wide).day().year()))
        }
    }

    // MARK: Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Match Highlights")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(highlights.enumerated()), id: \.offset) { idx, highlight in
                    HStack(spacing: 12) {
                        // Timeline dot + line
                        VStack(spacing: 0) {
                            if idx > 0 {
                                Rectangle()
                                    .fill(Color.dinkrGreen.opacity(0.25))
                                    .frame(width: 2, height: 16)
                            }
                            Circle()
                                .fill(idx == highlights.count - 1 ? accentColor : Color.dinkrGreen.opacity(0.6))
                                .frame(width: 10, height: 10)
                            if idx < highlights.count - 1 {
                                Rectangle()
                                    .fill(Color.dinkrGreen.opacity(0.25))
                                    .frame(width: 2, height: 16)
                            }
                        }
                        .frame(width: 20)

                        HStack {
                            Text("Pt \(highlight.point)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.dinkrGreen)
                                .frame(width: 36, alignment: .leading)
                            Text(highlight.event)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    // MARK: Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                HapticManager.medium()
            } label: {
                Label("Rematch", systemImage: "arrow.trianglehead.counterclockwise")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Button {
                HapticManager.selection()
                showShareSheet = true
            } label: {
                Label("Share Result", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dinkrGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.dinkrGreen.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Supporting types

private struct MatchHighlight {
    let point: Int
    let event: String
}

private struct DetailInfoTile: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrGreen)
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - StatPillCard (kept for callers that still reference it)

struct StatPillCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.heavy))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}



// MARK: - Previews

#Preview("Game History") {
    NavigationStack {
        GameHistoryView()
            .navigationTitle("Game History")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Result Detail") {
    GameResultDetailView(result: GameResult.mockResults[0])
}

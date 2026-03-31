// DinkrWidgetEntryView.swift
// DinkrWidget — SwiftUI views for all widget families
//
// Families covered:
//   Home Screen  — .systemSmall  (Next Game OR Streak)
//                — .systemMedium (Today's Games OR My Stats)
//                — .systemLarge  (Dinkr Dashboard)
//   Lock Screen  — .accessoryCircular   (streak fire count)
//                — .accessoryRectangular (next game countdown)
//                — .accessoryInline     (week summary)

import SwiftUI
import WidgetKit

// MARK: - Brand Colors
//
// Widget extension cannot access the main app target's Color+Brand extension,
// so we re-declare the exact same values as private constants. The rules still
// apply: always reference Color.dinkrGreen etc. inside the main app target.

private let dinkrGreen  = Color(red: 0.18, green: 0.74, blue: 0.38)
private let dinkrNavy   = Color(red: 0.10, green: 0.18, blue: 0.29)
private let dinkrAmber  = Color(red: 0.96, green: 0.65, blue: 0.14)
private let dinkrCoral  = Color(red: 0.95, green: 0.36, blue: 0.23)
private let dinkrSky    = Color(red: 0.29, green: 0.66, blue: 0.83)

private let gradientBG = LinearGradient(
    colors: [dinkrNavy, dinkrGreen.opacity(0.85)],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

private let warmGradientBG = LinearGradient(
    colors: [Color(red: 0.55, green: 0.08, blue: 0.00), dinkrAmber.opacity(0.90)],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

// MARK: - Root Entry View (dispatches to the right layout)

struct DinkrWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: DinkrWidgetEntry

    var body: some View {
        switch family {

        // ── Home Screen ───────────────────────────────────────────────────────
        case .systemSmall:
            smallView

        case .systemMedium:
            mediumView

        case .systemLarge:
            LargeDashboardView(entry: entry)

        // ── Lock Screen ───────────────────────────────────────────────────────
        case .accessoryCircular:
            LockCircularView(entry: entry)

        case .accessoryRectangular:
            LockRectangularView(entry: entry)

        case .accessoryInline:
            LockInlineView(entry: entry)

        default:
            smallView
        }
    }

    // Small: routing based on which widget kind / smallStat was selected
    @ViewBuilder
    private var smallView: some View {
        switch entry.smallStat {
        case .nextGame:
            SmallNextGameView(entry: entry)
        case .streak:
            SmallStreakView(entry: entry)
        }
    }

    // Medium: routing based on widgetURL / context — the two medium widget
    // kinds share the same entry view but differ in content panel shown.
    // We use an environment-accessible approach: the widget kind sets
    // widgetURL, but since we can't read kind from the view we use the
    // DinkrWidgetKind stored in widgetURL path to pick the right layout.
    // As a pragmatic alternative we expose both medium widgets from the
    // same view by reading the URL set by the widget declaration.
    @ViewBuilder
    private var mediumView: some View {
        // Both medium widgets share the same entry; differentiate via smallStat
        // which the DinkrMyStatsWidget overrides to .nextGame, and
        // DinkrTodayGamesWidget leaves as default. We use a dedicated flag
        // approach: if the entry has todayGames populated, prefer Today's Games,
        // but we need a clean split. The cleanest approach: render both views
        // and let each widget declaration pass its own entry. Since Swift
        // widgets share one provider and entry, we rely on widgetURL set on
        // the container to differentiate. For the entry view we render the
        // Today's Games layout by default for .systemMedium and the My Stats
        // layout when accessed from the DinkrMyStatsWidget.
        //
        // Practical solution: DinkrMyStatsWidget wraps entry in .smallStat = .streak
        // so we re-use that flag for medium routing too.
        if entry.smallStat == .streak {
            MediumMyStatsView(entry: entry)
        } else {
            MediumTodayGamesView(entry: entry)
        }
    }
}

// MARK: - Small: Next Game (2×2)

private struct SmallNextGameView: View {
    let entry: DinkrWidgetEntry

    var body: some View {
        ZStack {
            gradientBG
            VStack(alignment: .leading, spacing: 0) {

                HStack {
                    DinkrLogomark(size: 16)
                    Spacer()
                    if let game = entry.nextGame {
                        FormatBadge(text: game.format)
                    }
                }

                Spacer(minLength: 6)

                // Big countdown
                Text(entry.nextGameCountdown)
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text("until next game")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, -4)

                Spacer(minLength: 8)

                if let game = entry.nextGame {
                    HStack(spacing: 3) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(dinkrNavy)
                        Text(game.courtName)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(dinkrNavy)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(dinkrAmber)
                    .clipShape(Capsule())
                } else {
                    Text("No games scheduled")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(14)
        }
        .widgetBackground(gradient: gradientBG)
    }
}

// MARK: - Small: Streak (2×2)

private struct SmallStreakView: View {
    let entry: DinkrWidgetEntry

    var body: some View {
        ZStack {
            warmGradientBG
            VStack(alignment: .leading, spacing: 0) {

                HStack {
                    DinkrLogomark(size: 16)
                    Spacer()
                    Text("🔥")
                        .font(.system(size: 20))
                }

                Spacer(minLength: 4)

                // Big streak number
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(entry.currentStreak)")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }

                Text("day streak")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, -6)

                Spacer(minLength: 8)

                HStack(spacing: 3) {
                    Image(systemName: "calendar")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(dinkrNavy)
                    Text("Last: \(entry.lastPlayedFormatted)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(dinkrNavy)
                        .lineLimit(1)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(.white.opacity(0.9))
                .clipShape(Capsule())
            }
            .padding(14)
        }
        .widgetBackground(gradient: warmGradientBG)
    }
}

// MARK: - Medium: Today's Games (2×4)

private struct MediumTodayGamesView: View {
    let entry: DinkrWidgetEntry

    var body: some View {
        ZStack {
            gradientBG

            VStack(alignment: .leading, spacing: 8) {

                // Header
                HStack {
                    Label("Today's Games", systemImage: "figure.pickleball")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.55))
                    Spacer()
                    DinkrWordmark()
                }

                if entry.todayGames.isEmpty {
                    Spacer()
                    Text("No games today")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                } else {
                    // Up to 2 game rows
                    ForEach(Array(entry.todayGames.prefix(2).enumerated()), id: \.offset) { _, game in
                        TodayGameRow(game: game)
                    }
                }

                Spacer(minLength: 0)

                // Footer strip
                HStack(spacing: 6) {
                    Image(systemName: "sportscourt")
                        .font(.system(size: 9))
                        .foregroundColor(dinkrSky)
                    Text("\(entry.upcomingGameCount) games upcoming")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white.opacity(0.55))
                    Spacer()
                    Text("DUPR \(entry.duprRating, specifier: "%.2f")")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(dinkrNavy)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(dinkrAmber)
                        .clipShape(Capsule())
                }
            }
            .padding(14)
        }
        .widgetBackground(gradient: gradientBG)
    }
}

private struct TodayGameRow: View {
    let game: GameSummary

    var body: some View {
        HStack(spacing: 8) {
            // Time pill
            Text(game.timeString)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(dinkrNavy)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(dinkrAmber)
                .clipShape(Capsule())
                .fixedSize()

            // Court + format
            VStack(alignment: .leading, spacing: 1) {
                Text(game.courtName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    FormatBadge(text: game.format)
                    Text("\(game.spotsLeft) spots")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(dinkrGreen)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Medium: My Stats (2×4)

private struct MediumMyStatsView: View {
    let entry: DinkrWidgetEntry

    var body: some View {
        ZStack {
            gradientBG

            HStack(spacing: 0) {

                // LEFT: DUPR + W/L
                VStack(alignment: .leading, spacing: 6) {
                    Label("My Stats", systemImage: "chart.bar.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.55))

                    Spacer(minLength: 4)

                    // DUPR
                    Text(String(format: "%.2f", entry.duprRating))
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("DUPR Rating")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white.opacity(0.55))
                        .padding(.top, -4)

                    Spacer(minLength: 4)

                    // W/L this week
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 9))
                            .foregroundColor(dinkrSky)
                        Text(entry.weeklyRecord)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("this week")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))

                    Spacer(minLength: 0)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 1)
                    .padding(.vertical, 12)

                // RIGHT: Next game countdown + leaderboard
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label("Next Game", systemImage: "timer")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.55))
                        Spacer()
                        DinkrWordmark()
                    }

                    Spacer(minLength: 4)

                    // Countdown
                    Text(entry.nextGameCountdown)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)

                    if let game = entry.nextGame {
                        Text(game.courtName)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    // Leaderboard rank
                    if let rank = entry.leaderboardRank {
                        HStack(spacing: 4) {
                            Image(systemName: "list.number")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(dinkrNavy)
                            Text("#\(rank) on leaderboard")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(dinkrNavy)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(dinkrAmber)
                        .clipShape(Capsule())
                    }

                    Spacer(minLength: 0)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .widgetBackground(gradient: gradientBG)
    }
}

// MARK: - Large: Dinkr Dashboard (4×4)

private struct LargeDashboardView: View {
    let entry: DinkrWidgetEntry

    private var firstName: String {
        entry.playerName.components(separatedBy: " ").first ?? entry.playerName
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: entry.date)
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    var body: some View {
        ZStack {
            gradientBG

            VStack(alignment: .leading, spacing: 0) {

                // ── HEADER ─────────────────────────────────────────────────
                HStack(alignment: .center) {
                    DinkrLogomark(size: 22)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(greeting),")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Text(firstName)
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    // DUPR pill
                    Text("DUPR \(entry.duprRating, specifier: "%.2f")")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(dinkrNavy)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(dinkrAmber)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

                DividerLine()

                // ── NEXT GAME + STREAK ROW ──────────────────────────────────
                HStack(alignment: .top, spacing: 0) {

                    // Next game
                    VStack(alignment: .leading, spacing: 5) {
                        SectionLabel(icon: "timer", text: "NEXT GAME")

                        Text(entry.nextGameCountdown)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)

                        if let game = entry.nextGame {
                            HStack(spacing: 4) {
                                FormatBadge(text: game.format)
                                Text(game.timeString)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.65))
                                    .lineLimit(1)
                            }
                            Text(game.courtName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Vertical divider
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 1)
                        .padding(.vertical, 10)

                    // Streak
                    VStack(alignment: .leading, spacing: 5) {
                        SectionLabel(icon: "flame.fill", text: "STREAK")

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("🔥")
                                .font(.system(size: 22))
                            Text("\(entry.currentStreak)")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }

                        Text("Last: \(entry.lastPlayedFormatted)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DividerLine()

                // ── LEADERBOARD + W/L ROW ───────────────────────────────────
                HStack(spacing: 0) {

                    // Leaderboard rank
                    VStack(alignment: .leading, spacing: 4) {
                        SectionLabel(icon: "list.number", text: "LEADERBOARD")

                        if let rank = entry.leaderboardRank {
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("#")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(dinkrAmber)
                                Text("\(rank)")
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            Text("overall ranking")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.5))
                        } else {
                            Text("Unranked")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Vertical divider
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 1)
                        .padding(.vertical, 10)

                    // Weekly W/L
                    VStack(alignment: .leading, spacing: 4) {
                        SectionLabel(icon: "chart.bar.fill", text: "THIS WEEK")

                        Text(entry.weeklyRecord)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.7)

                        if let stats = entry.weeklyStats {
                            let total = stats.wins + stats.losses
                            if total > 0 {
                                let rate = Double(stats.wins) / Double(total)
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.white.opacity(0.15))
                                        Capsule().fill(dinkrGreen)
                                            .frame(width: geo.size.width * CGFloat(rate))
                                    }
                                }
                                .frame(height: 5)
                                Text("\(Int(stats.wins * 100 / max(total, 1)))% win rate")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DividerLine()

                // ── WEATHER STRIP ────────────────────────────────────────────
                if let wx = entry.weather {
                    HStack(spacing: 8) {
                        Text(wx.emoji)
                            .font(.system(size: 18))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(wx.temperatureF)°F · \(wx.label)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                            Text(wx.isGoodForPlay ? "Good pickleball weather" : "Check conditions before playing")
                                .font(.system(size: 9))
                                .foregroundColor(wx.isGoodForPlay ? dinkrGreen : dinkrCoral)
                        }
                        Spacer()
                        Text("⭐ \(entry.reliabilityScore, specifier: "%.1f")")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(dinkrSky)
                        Text("\(entry.openCourtsNearby) courts open near you")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                }

                Spacer(minLength: 0)

                // ── BOTTOM CTA PILLS ─────────────────────────────────────────
                HStack(spacing: 10) {
                    CTAPill(
                        icon: "figure.pickleball",
                        text: "Find Game",
                        url: URL(string: "dinkr://find-game"),
                        bg: dinkrGreen,
                        fg: .white
                    )
                    CTAPill(
                        icon: "person.2.fill",
                        text: "Host Game",
                        url: URL(string: "dinkr://host-game"),
                        bg: Color.white.opacity(0.15),
                        fg: .white
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
        .widgetBackground(gradient: gradientBG)
    }
}

// MARK: - Lock Screen: Circular (streak fire count)

private struct LockCircularView: View {
    let entry: DinkrWidgetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Text("🔥")
                    .font(.system(size: 16))
                Text("\(entry.currentStreak)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.6)
            }
        }
    }
}

// MARK: - Lock Screen: Rectangular ("Next game: 2h 30m · Westside")

private struct LockRectangularView: View {
    let entry: DinkrWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.system(size: 10, weight: .semibold))
                Text("Next Game")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(.white.opacity(0.7))

            HStack(spacing: 4) {
                Text(entry.nextGameCountdown)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                if let game = entry.nextGame {
                    Text("·")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                    Text(shortCourtName(game.courtName))
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                }
            }
            .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func shortCourtName(_ full: String) -> String {
        // Return just the first word/component before a space for brevity
        full.components(separatedBy: " ").first ?? full
    }
}

// MARK: - Lock Screen: Inline ("3 games this week · 🏓")

private struct LockInlineView: View {
    let entry: DinkrWidgetEntry

    var body: some View {
        Text("\(entry.upcomingGameCount) games this week  🏓")
            .font(.system(size: 12, weight: .semibold))
    }
}

// MARK: - Shared Sub-Components

private struct DinkrLogomark: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            Circle()
                .fill(dinkrGreen)
                .frame(width: size * 1.55, height: size * 1.55)
            Text("d")
                .font(.system(size: size, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .offset(y: -1)
        }
    }
}

private struct DinkrWordmark: View {
    var body: some View {
        Text("dinkr")
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundColor(.white.opacity(0.75))
            .tracking(0.5)
    }
}

private struct FormatBadge: View {
    let text: String

    private var color: Color {
        switch text.lowercased() {
        case "singles": return dinkrCoral
        case "mxd", "mixed": return dinkrSky
        default: return dinkrSky.opacity(0.8)  // Doubles
        }
    }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 7, weight: .black))
            .foregroundColor(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color)
            .clipShape(Capsule())
    }
}

private struct ProgressRow: View {
    let label: String
    let progress: Double
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 24, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.15))
                    Capsule().fill(color)
                        .frame(width: geo.size.width * CGFloat(progress))
                }
            }
            .frame(height: 5)
            Text("\(Int(progress * 100))%")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 26, alignment: .trailing)
        }
    }
}

private struct TagPill: View {
    let text: String
    let color: Color
    let textColor: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(textColor)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(Capsule())
    }
}

private struct SectionLabel: View {
    let icon: String
    let text: String
    var body: some View {
        Label(text, systemImage: icon)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white.opacity(0.45))
            .labelStyle(.titleAndIcon)
    }
}

private struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(height: 1)
            .padding(.horizontal, 16)
    }
}

private struct CTAPill: View {
    let icon: String
    let text: String
    let url: URL?
    let bg: Color
    let fg: Color

    var body: some View {
        Link(destination: url ?? URL(string: "dinkr://")!) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(text)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(fg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

// MARK: - Widget Background helper (iOS 17 containerBackground API)

private extension View {
    func widgetBackground(gradient: LinearGradient) -> some View {
        self.containerBackground(for: .widget) {
            gradient
        }
    }
}

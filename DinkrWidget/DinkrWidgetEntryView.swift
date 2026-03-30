// DinkrWidgetEntryView.swift
// DinkrWidget — SwiftUI views for all three widget sizes

import SwiftUI
import WidgetKit

// MARK: - Brand Colors

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

// MARK: - Root Entry View

struct DinkrWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: DinkrWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (2×2)

struct SmallWidgetView: View {
    let entry: DinkrWidgetEntry

    var body: some View {
        ZStack {
            gradientBG

            VStack(alignment: .leading, spacing: 0) {

                // Logo row
                HStack {
                    DinkrLogomark(size: 18)
                    Spacer()
                    Image(systemName: "sportscourt")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer(minLength: 6)

                // Big game count
                Text("\(entry.upcomingGameCount)")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text("games this week")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.65))
                    .padding(.top, -6)

                Spacer(minLength: 8)

                // Next game time pill
                if let game = entry.nextGame {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(dinkrNavy)
                        Text(game.timeString)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(dinkrNavy)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(dinkrAmber)
                    .clipShape(Capsule())

                    Text(game.courtName)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.top, 4)
                }
            }
            .padding(14)
        }
        .widgetBackground()
        .widgetURL(URL(string: "dinkr://games"))
    }
}

// MARK: - Medium Widget (4×2)

struct MediumWidgetView: View {
    let entry: DinkrWidgetEntry

    var body: some View {
        ZStack {
            gradientBG

            HStack(spacing: 0) {

                // LEFT: Next game card
                VStack(alignment: .leading, spacing: 5) {
                    Label("Next Game", systemImage: "figure.pickleball")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.55))
                        .labelStyle(.titleAndIcon)

                    if let game = entry.nextGame {
                        Text(game.courtName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)

                        HStack(spacing: 3) {
                            Text(game.timeString)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(dinkrNavy)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(dinkrAmber)
                                .clipShape(Capsule())
                        }

                        HStack(spacing: 3) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 9))
                                .foregroundColor(dinkrSky)
                            Text(game.format)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("\(game.spotsLeft) spots")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(dinkrGreen)
                        }
                    } else {
                        Text("No games scheduled")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    // DUPR strip
                    HStack(spacing: 6) {
                        Text("DUPR \(entry.duprRating, specifier: "%.2f")")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(dinkrNavy)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(dinkrAmber)
                            .clipShape(Capsule())

                        Text("⭐ \(entry.reliabilityScore, specifier: "%.1f")")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 1)
                    .padding(.vertical, 12)

                // RIGHT: Active challenge
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Label("Challenge", systemImage: "trophy.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.55))
                            .labelStyle(.titleAndIcon)
                        Spacer()
                        DinkrWordmark()
                    }

                    if let ch = entry.activeChallenge {
                        Text(ch.opponentName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(ch.type)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))

                        // Progress bars
                        VStack(alignment: .leading, spacing: 3) {
                            ProgressRow(label: "You", progress: ch.myProgress, color: dinkrGreen)
                            ProgressRow(label: ch.opponentName.components(separatedBy: " ").first ?? "Opp", progress: ch.theirProgress, color: dinkrCoral)
                        }

                        HStack(spacing: 3) {
                            Image(systemName: "timer")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.5))
                            Text("\(ch.daysLeft)d left")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    } else {
                        Text("No active challenge")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .widgetBackground()
        .widgetURL(URL(string: "dinkr://dashboard"))
    }
}

// MARK: - Large Widget (4×4)

struct LargeWidgetView: View {
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

                // HEADER
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

                // UPCOMING GAME
                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel(icon: "sportscourt", text: "UPCOMING GAME")

                    if let game = entry.nextGame {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(game.courtName)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                HStack(spacing: 6) {
                                    TagPill(text: game.format, color: dinkrSky.opacity(0.3), textColor: dinkrSky)
                                    TagPill(text: game.timeString, color: dinkrAmber, textColor: dinkrNavy)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(game.spotsLeft)")
                                    .font(.system(size: 20, weight: .black, design: .rounded))
                                    .foregroundColor(dinkrGreen)
                                Text("spots left")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    } else {
                        Text("No upcoming games")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                DividerLine()

                // ACTIVE CHALLENGE
                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel(icon: "trophy.fill", text: "ACTIVE CHALLENGE")

                    if let ch = entry.activeChallenge {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    TypeBadge(text: ch.type)
                                    Text("vs \(ch.opponentName)")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    LargeProgressRow(label: "You", progress: ch.myProgress, color: dinkrGreen)
                                    LargeProgressRow(label: ch.opponentName.components(separatedBy: " ").first ?? "Opp", progress: ch.theirProgress, color: dinkrCoral)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(ch.daysLeft)")
                                    .font(.system(size: 20, weight: .black, design: .rounded))
                                    .foregroundColor(dinkrAmber)
                                Text("days left")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    } else {
                        Text("No active challenge")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                DividerLine()

                // COURTS NEARBY
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(dinkrSky)
                    Text("\(entry.openCourtsNearby) courts open near you")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("⭐ \(entry.reliabilityScore, specifier: "%.1f") reliability")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Spacer(minLength: 0)

                // BOTTOM CTA PILLS
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
        .widgetBackground()
        .widgetURL(URL(string: "dinkr://dashboard"))
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

private struct LargeProgressRow: View {
    let label: String
    let progress: Double
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.65))
                .frame(width: 32, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.15))
                    Capsule().fill(color)
                        .frame(width: geo.size.width * CGFloat(progress))
                }
            }
            .frame(height: 6)
            Text("\(Int(progress * 100))%")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.75))
                .frame(width: 32, alignment: .trailing)
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

private struct TypeBadge: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 8, weight: .black))
            .foregroundColor(dinkrNavy)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(dinkrAmber)
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

// MARK: - Widget Background helper (iOS 17 API)

private extension View {
    func widgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            return self.containerBackground(for: .widget) {
                gradientBG
            }
        } else {
            return self
        }
    }
}

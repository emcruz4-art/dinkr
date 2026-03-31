import SwiftUI

// MARK: - PlayerSpotlightDetailView

struct PlayerSpotlightDetailView: View {
    let spotlight: PlayerSpotlightData

    @Environment(\.dismiss) private var dismiss
    @State private var isFollowing = false
    @State private var showShareSheet = false
    @State private var challengeSent = false
    @State private var followBounce = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                heroBanner
                contentStack
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showShareSheet = true
                    HapticManager.selection()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.dinkrGreen)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            SpotlightShareSheet(spotlight: spotlight)
        }
    }

    // MARK: - Hero Banner

    private var heroBanner: some View {
        ZStack(alignment: .bottom) {
            // Gradient background
            LinearGradient(
                colors: [Color.dinkrGreen, Color.dinkrNavy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 320)

            // Subtle pattern overlay
            GeometryReader { geo in
                ZStack {
                    ForEach(0..<6) { row in
                        ForEach(0..<5) { col in
                            Image(systemName: "circle.hexagongrid.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white.opacity(0.04))
                                .position(
                                    x: CGFloat(col) * (geo.size.width / 4) + 20,
                                    y: CGFloat(row) * 52 + 20
                                )
                        }
                    }
                }
            }
            .frame(height: 320)

            // Avatar + badge stack
            VStack(spacing: 0) {
                // Player of the Week badge at top of avatar area
                Text("🌟 \(spotlight.weekLabel)")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(Color.dinkrNavy)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.dinkrAmber)
                    .clipShape(Capsule())
                    .shadow(color: Color.dinkrAmber.opacity(0.5), radius: 8, y: 3)

                Spacer().frame(height: 16)

                // Large avatar with glowing amber ring
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(Color.dinkrAmber.opacity(0.3))
                        .frame(width: 108, height: 108)
                        .blur(radius: 12)

                    // Amber-coral ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.dinkrAmber, Color.dinkrCoral, Color.dinkrAmber],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3.5
                        )
                        .frame(width: 100, height: 100)

                    AvatarView(
                        urlString: nil,
                        displayName: spotlight.displayName,
                        size: 90,
                        isPremium: true
                    )
                }

                Spacer().frame(height: 14)

                // Name
                Text(spotlight.displayName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Spacer().frame(height: 4)

                // Username + skill + location row
                HStack(spacing: 10) {
                    Text("@\(spotlight.username)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))

                    Circle()
                        .fill(.white.opacity(0.4))
                        .frame(width: 4, height: 4)

                    Label(spotlight.skillLevel, systemImage: "star.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.dinkrAmber)

                    Circle()
                        .fill(.white.opacity(0.4))
                        .frame(width: 4, height: 4)

                    Label(spotlight.location, systemImage: "mappin.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))
                }

                Spacer().frame(height: 20)
            }
            .padding(.bottom, 8)
        }
        .frame(height: 320)
    }

    // MARK: - Content Stack

    private var contentStack: some View {
        VStack(spacing: 20) {
            // Achievement card
            achievementCard
                .padding(.top, 20)

            // Stats strip
            statsStrip

            // Action buttons
            actionButtons

            // Quote
            quoteSection

            // Recent games
            recentGamesSection

            // Previous spotlights
            previousSpotlightsSection

            Spacer().frame(height: 32)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Achievement Card

    private var achievementCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.dinkrAmber.opacity(0.15))
                    .frame(width: 48, height: 48)
                Text("🏆")
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Spotlight Achievement")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(spotlight.achievement)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                Text(spotlight.eventName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrAmber)
            }

            Spacer()
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.dinkrAmber.opacity(0.1), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.dinkrAmber.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Stats Strip

    private var statsStrip: some View {
        HStack(spacing: 0) {
            SpotlightStatPill(label: "Win Rate",     value: spotlight.winRate,                   accent: Color.dinkrGreen)
            statDivider
            SpotlightStatPill(label: "DUPR",         value: spotlight.dupr,                      accent: Color.dinkrSky)
            statDivider
            SpotlightStatPill(label: "This Month",   value: "\(spotlight.gamesThisMonth) games",  accent: Color.dinkrNavy)
            statDivider
            SpotlightStatPill(label: "Streak",       value: "\(spotlight.streak)🔥",              accent: Color.dinkrCoral)
        }
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.15))
            .frame(width: 1, height: 36)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Follow
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                    isFollowing.toggle()
                    followBounce = true
                }
                HapticManager.medium()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    followBounce = false
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isFollowing ? "checkmark" : "person.badge.plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text(isFollowing ? "Following" : "Follow")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(isFollowing ? Color.dinkrGreen : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    isFollowing
                        ? Color.dinkrGreen.opacity(0.12)
                        : Color.dinkrGreen
                )
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(Color.dinkrGreen, lineWidth: isFollowing ? 1.5 : 0)
                )
            }
            .scaleEffect(followBounce ? 0.94 : 1.0)

            // Challenge
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    challengeSent = true
                }
                HapticManager.selection()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { challengeSent = false }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: challengeSent ? "checkmark.circle.fill" : "bolt.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text(challengeSent ? "Sent!" : "Challenge")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(challengeSent ? Color.dinkrAmber : Color.dinkrNavy)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    challengeSent
                        ? Color.dinkrAmber.opacity(0.15)
                        : Color.dinkrNavy.opacity(0.08)
                )
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(
                            challengeSent ? Color.dinkrAmber : Color.dinkrNavy.opacity(0.2),
                            lineWidth: 1
                        )
                )
            }
        }
    }

    // MARK: - Quote Section

    private var quoteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "quote.bubble.fill")
                    .font(.caption)
                    .foregroundStyle(Color.dinkrSky)
                Text("In Their Words")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            HStack(alignment: .top, spacing: 12) {
                Text("\u{201C}")
                    .font(.system(size: 52, weight: .heavy))
                    .foregroundStyle(Color.dinkrGreen.opacity(0.3))
                    .offset(y: -8)
                    .frame(width: 24)

                Text(spotlight.quote)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Spacer()
                Text("— \(spotlight.displayName)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.dinkrGreen.opacity(0.07), Color.dinkrSky.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Recent Games Section

    private var recentGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.caption)
                    .foregroundStyle(Color.dinkrAmber)
                Text("Recent Results")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Text("Last 3 games")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                ForEach(spotlight.recentGames) { game in
                    SpotlightGameRow(game: game)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Previous Spotlights Section

    private var previousSpotlightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.dinkrAmber)
                Text("Previous Spotlights")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PlayerSpotlightData.previousSpotlights) { prev in
                        PreviousSpotlightChip(spotlight: prev)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - SpotlightStatPill

private struct SpotlightStatPill: View {
    let label: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(accent)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - SpotlightGameRow

private struct SpotlightGameRow: View {
    let game: SpotlightGameResult

    var isWin: Bool { game.result == .win }

    var body: some View {
        HStack(spacing: 12) {
            // Win/Loss badge
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isWin ? Color.dinkrGreen.opacity(0.12) : Color.dinkrCoral.opacity(0.12))
                    .frame(width: 34, height: 28)
                Text(isWin ? "W" : "L")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(isWin ? Color.dinkrGreen : Color.dinkrCoral)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("vs \(game.opponent)")
                    .font(.subheadline.weight(.semibold))
                Text(game.score)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(game.date)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.appBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - PreviousSpotlightChip

private struct PreviousSpotlightChip: View {
    let spotlight: PreviousSpotlight

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.dinkrAmber.opacity(0.6), Color.dinkrCoral.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 56, height: 56)
                AvatarView(urlString: nil, displayName: spotlight.displayName, size: 50)
            }

            VStack(spacing: 2) {
                Text(spotlight.displayName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text(spotlight.weekLabel)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 80)
    }
}

// MARK: - SpotlightShareSheet

private struct SpotlightShareSheet: View {
    let spotlight: PlayerSpotlightData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ShareLink(
            item: "Check out \(spotlight.displayName) — this week's Dinkr Player Spotlight! 🌟 \(spotlight.achievement) on @dinkr",
            subject: Text("Dinkr Player Spotlight"),
            message: Text(spotlight.achievement)
        ) {
            Label("Share Spotlight", systemImage: "square.and.arrow.up")
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PlayerSpotlightDetailView(spotlight: PlayerSpotlightData.mock)
    }
}

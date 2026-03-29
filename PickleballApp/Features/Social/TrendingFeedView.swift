import SwiftUI

// MARK: - Trending Shot Model

struct TrendingShot: Identifiable {
    var id: String
    var name: String
    var playCount: String
    var gradientColors: [Color]
    var emoji: String
}

extension TrendingShot {
    static let mockShots: [TrendingShot] = [
        TrendingShot(id: "1", name: "Erne",            playCount: "18.7K clips", gradientColors: [Color.dinkrCoral, Color.dinkrAmber],  emoji: "⚡️"),
        TrendingShot(id: "2", name: "ATP",             playCount: "12.4K clips", gradientColors: [Color.dinkrGreen, Color.dinkrNavy],   emoji: "🎾"),
        TrendingShot(id: "3", name: "Dink Rally",      playCount: "9.1K clips",  gradientColors: [Color.dinkrSky, Color.dinkrGreen],    emoji: "🏓"),
        TrendingShot(id: "4", name: "Speed-Up",        playCount: "7.6K clips",  gradientColors: [Color.dinkrAmber, Color.dinkrCoral],  emoji: "💥"),
        TrendingShot(id: "5", name: "Third Shot Drop", playCount: "6.3K clips",  gradientColors: [Color.dinkrNavy, Color.dinkrSky],     emoji: "🧊"),
        TrendingShot(id: "6", name: "Trick Shot",      playCount: "4.8K clips",  gradientColors: [Color(red: 0.55, green: 0.20, blue: 0.80), Color.dinkrCoral], emoji: "🎩")
    ]
}

// MARK: - Hashtag Model

enum TrendDirection {
    case up, down, new
}

struct TrendingHashtag: Identifiable {
    var id: String
    var rank: Int
    var tag: String
    var postCount: String
    var direction: TrendDirection
}

extension TrendingHashtag {
    static let mockHashtags: [TrendingHashtag] = [
        TrendingHashtag(id: "1", rank: 1, tag: "#erne",            postCount: "8.2K posts",  direction: .up),
        TrendingHashtag(id: "2", rank: 2, tag: "#atp",             postCount: "6.5K posts",  direction: .up),
        TrendingHashtag(id: "3", rank: 3, tag: "#pickleball",      postCount: "5.9K posts",  direction: .up),
        TrendingHashtag(id: "4", rank: 4, tag: "#dinkrally",       postCount: "4.1K posts",  direction: .down),
        TrendingHashtag(id: "5", rank: 5, tag: "#thirdshot",       postCount: "3.3K posts",  direction: .new),
        TrendingHashtag(id: "6", rank: 6, tag: "#kitchenlife",     postCount: "2.8K posts",  direction: .up),
        TrendingHashtag(id: "7", rank: 7, tag: "#openplay",        postCount: "2.4K posts",  direction: .new),
        TrendingHashtag(id: "8", rank: 8, tag: "#pickleballislife", postCount: "1.9K posts", direction: .down)
    ]
}

// MARK: - Player of the Week Model

struct FeaturedPlayer: Identifiable {
    var id: String
    var name: String
    var initial: String
    var skillLevel: String
    var winsThisWeek: Int
    var wins: Int
    var losses: Int
    var winPercent: Int
    var avatarGradient: [Color]
    var isFollowing: Bool
}

extension FeaturedPlayer {
    static let playerOfTheWeek = FeaturedPlayer(
        id: "potw-1",
        name: "Jordan Rivera",
        initial: "J",
        skillLevel: "4.5",
        winsThisWeek: 9,
        wins: 34,
        losses: 8,
        winPercent: 81,
        avatarGradient: [Color.dinkrGreen, Color.dinkrNavy],
        isFollowing: false
    )
}

// MARK: - Trending Feed View

struct TrendingFeedView: View {
    @State private var featuredPlayer = FeaturedPlayer.playerOfTheWeek
    @State private var hashtags = TrendingHashtag.mockHashtags
    @State private var shots = TrendingShot.mockShots

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // Header
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        Text("🔥")
                            .font(.title2)
                        Text("Trending in Pickleball")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.dinkrNavy)
                    }
                    Spacer()
                    Button("See all") {}
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.dinkrGreen)
                }
                .padding(.horizontal)
                .padding(.top, 4)

                // Section 1: Trending Shots
                trendingShotsSection

                // Section 2: Top Hashtags
                topHashtagsSection

                // Section 3: Player of the Week
                playerOfTheWeekSection

                Spacer(minLength: 40)
            }
            .padding(.top, 12)
        }
        .background(Color.appBackground)
    }

    // MARK: Trending Shots Section

    private var trendingShotsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Trending Shots")
                .sectionHeader()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(shots) { shot in
                        TrendingShotCard(shot: shot)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: Top Hashtags Section

    private var topHashtagsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Top Hashtags")
                .sectionHeader()

            VStack(spacing: 0) {
                ForEach(hashtags) { hashtag in
                    HashtagRow(hashtag: hashtag)

                    if hashtag.id != hashtags.last?.id {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding(.horizontal)
        }
    }

    // MARK: Player of the Week Section

    private var playerOfTheWeekSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Player of the Week")
                .sectionHeader()

            PlayerOfTheWeekCard(player: $featuredPlayer)
                .padding(.horizontal)
        }
    }
}

// MARK: - Trending Shot Card

struct TrendingShotCard: View {
    let shot: TrendingShot

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient background
            LinearGradient(
                colors: shot.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Frosted overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "play.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.80))
                    Text(shot.playCount)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.90))
                }

                HStack(spacing: 4) {
                    Text(shot.emoji)
                        .font(.subheadline)
                    Text(shot.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(12)

            // Trending arrow overlay (top-right)
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.white.opacity(0.20), in: Circle())
                        .padding(10)
                }
                Spacer()
            }
        }
        .frame(width: 150, height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Hashtag Row

struct HashtagRow: View {
    let hashtag: TrendingHashtag

    var body: some View {
        HStack(spacing: 14) {
            // Rank
            Text("\(hashtag.rank)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(rankColor(hashtag.rank))
                .frame(width: 28, alignment: .center)

            // Tag info
            VStack(alignment: .leading, spacing: 2) {
                Text(hashtag.tag)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dinkrNavy)
                Text(hashtag.postCount)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Direction
            directionView(hashtag.direction)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color.dinkrAmber
        case 2: return Color(red: 0.60, green: 0.60, blue: 0.65)
        case 3: return Color(red: 0.72, green: 0.45, blue: 0.20)
        default: return Color.dinkrNavy.opacity(0.45)
        }
    }

    @ViewBuilder
    private func directionView(_ direction: TrendDirection) -> some View {
        switch direction {
        case .up:
            HStack(spacing: 3) {
                Image(systemName: "arrow.up")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dinkrGreen)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.dinkrGreen.opacity(0.12), in: Capsule())

        case .down:
            HStack(spacing: 3) {
                Image(systemName: "arrow.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dinkrCoral)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.dinkrCoral.opacity(0.12), in: Capsule())

        case .new:
            Text("NEW")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.dinkrAmber, in: Capsule())
        }
    }
}

// MARK: - Player of the Week Card

struct PlayerOfTheWeekCard: View {
    @Binding var player: FeaturedPlayer

    var body: some View {
        VStack(spacing: 20) {
            // Top: avatar + name + skill badge
            HStack(spacing: 16) {
                // Large avatar
                ZStack {
                    LinearGradient(
                        colors: player.avatarGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(Circle())
                    .frame(width: 72, height: 72)

                    Text(player.initial)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                }
                .overlay(
                    Circle()
                        .strokeBorder(Color.dinkrAmber, lineWidth: 3)
                )
                .shadow(color: Color.dinkrGreen.opacity(0.30), radius: 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(player.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.dinkrNavy)

                    HStack(spacing: 6) {
                        // Skill badge
                        Text(player.skillLevel)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.dinkrGreen, in: Capsule())

                        Text("·")
                            .foregroundStyle(.secondary)

                        HStack(spacing: 3) {
                            Image(systemName: "trophy.fill")
                                .font(.caption)
                                .foregroundStyle(Color.dinkrAmber)
                            Text("\(player.winsThisWeek) wins this week")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()
            }

            // Stats row
            HStack(spacing: 0) {
                StatCell(label: "Wins", value: "\(player.wins)", color: Color.dinkrGreen)
                Divider().frame(height: 36)
                StatCell(label: "Losses", value: "\(player.losses)", color: Color.dinkrCoral)
                Divider().frame(height: 36)
                StatCell(label: "Win %", value: "\(player.winPercent)%", color: Color.dinkrAmber)
            }
            .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 10))

            // Follow button
            Button {
                player.isFollowing.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: player.isFollowing ? "checkmark" : "person.badge.plus")
                        .font(.subheadline)
                    Text(player.isFollowing ? "Following" : "Follow")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(player.isFollowing ? Color.dinkrGreen : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    player.isFollowing
                        ? Color.dinkrGreen.opacity(0.12)
                        : Color.dinkrGreen,
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            player.isFollowing ? Color.dinkrGreen : Color.clear,
                            lineWidth: 1.5
                        )
                )
            }
        }
        .padding(20)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Stat Cell

private struct StatCell: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

// MARK: - Preview

#Preview {
    TrendingFeedView()
}

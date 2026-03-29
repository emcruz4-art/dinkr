import SwiftUI

// MARK: - 1. DinkrHeaderView
struct DinkrHeaderView: View {
    let city: String

    var body: some View {
        HStack {
            DinkrLogoView(size: 32)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Color.dinkrCoral)
                    .font(.caption)
                Text(city)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.cardBackground)
            .clipShape(Capsule())

            AvatarView(urlString: nil, displayName: "Alex Rivera", size: 36)
        }
    }
}

// MARK: - 2. WelcomeHeroWidget
struct WelcomeHeroWidget: View {
    let greeting: String
    let gameCount: Int

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.dinkrNavy, Color.dinkrGreen.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(maxWidth: .infinity)
                .frame(height: 110)

            // Decorative circles
            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 120, height: 120)
                .offset(x: 260, y: -10)
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 80, height: 80)
                .offset(x: 300, y: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text("You have \(gameCount) game\(gameCount == 1 ? "" : "s") this week")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - 3. QuickActionsWidget
struct QuickActionsWidget: View {
    var body: some View {
        HStack(spacing: 10) {
            QuickActionPill(label: "Host Game", icon: "plus.circle.fill", color: Color.dinkrGreen)
            QuickActionPill(label: "Find Game", icon: "magnifyingglass.circle.fill", color: Color.dinkrSky)
            QuickActionPill(label: "Open Play", icon: "arrow.left.arrow.right.circle.fill", color: Color.dinkrCoral)
        }
    }
}

struct QuickActionPill: View {
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        Button {} label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                Text(label)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 4. FeaturedEventWidget
struct FeaturedEventWidget: View {
    let event: Event

    var registrationProgress: Double {
        guard let max = event.maxParticipants, max > 0 else { return 0 }
        return Double(event.currentParticipants) / Double(max)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Banner
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [Color.dinkrAmber.opacity(0.9), Color.dinkrCoral],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 72)
                VStack(alignment: .leading, spacing: 2) {
                    Text("🏆 FEATURED")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(event.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }
                .padding(10)
            }

            VStack(alignment: .leading, spacing: 6) {
                if let fee = event.entryFee {
                    Text(event.dateTime, style: .date) + Text(" · $\(Int(fee))")
                        .font(.caption2)
                } else {
                    Text(event.dateTime, style: .date)
                        .font(.caption2)
                }

                // Progress bar
                VStack(alignment: .leading, spacing: 2) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.dinkrAmber.opacity(0.2))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.dinkrAmber)
                                .frame(width: geo.size.width * registrationProgress)
                        }
                    }
                    .frame(height: 5)
                    Text("\(Int(registrationProgress * 100))% full")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(10)
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 5. NearbyGamesWidget
struct NearbyGamesWidget: View {
    let count: Int
    let distance: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Text("\(count)")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(Color.dinkrGreen)
                }
                Spacer()
                Image(systemName: "bolt.fill")
                    .foregroundStyle(Color.dinkrGreen)
                    .font(.caption)
            }
            Text("⚡ NEAR YOU")
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(.secondary)
            Text("games open")
                .font(.caption.weight(.semibold))
            Text(distance + " away")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            HStack {
                Text("Find →")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dinkrGreen)
                Spacer()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 6. CommunitySpotlightWidget
struct CommunitySpotlightWidget: View {
    let spotlight: PlayerSpotlightData

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.dinkrAmber)
                Text("COMMUNITY SPOTLIGHT")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(spacing: 12) {
                AvatarView(urlString: nil, displayName: spotlight.displayName, size: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text("@\(spotlight.username)")
                        .font(.subheadline.weight(.bold))
                    Text(spotlight.achievement)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
            }

            HStack(spacing: 6) {
                ForEach(spotlight.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.dinkrAmber)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.dinkrAmber.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 7. TopNewsWidget
struct TopNewsWidget: View {
    let articles: [NewsArticle]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "newspaper.fill")
                    .foregroundStyle(Color.dinkrSky)
                    .font(.caption)
                Text("TOP NEWS")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            ForEach(articles) { article in
                VStack(alignment: .leading, spacing: 2) {
                    Text(article.title)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(2)
                    Text(article.source + " · " + article.publishedAt.formatted(.relative(presentation: .named)))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                if article.id != articles.last?.id {
                    Divider().padding(.horizontal, 12)
                }
            }

            HStack {
                Spacer()
                Text("View all →")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrSky)
                Spacer()
            }
            .padding(10)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 8. FindPlayersNearbyWidget
struct FindPlayersNearbyWidget: View {
    let count: Int
    let newThisWeek: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(Color.dinkrSky)
                    .font(.caption)
                Text("PLAYERS")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.secondary)
            }

            Text("\(count)")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(Color.dinkrSky)
            Text("near you")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
                Text("\(newThisWeek) new this week")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {} label: {
                Text("Match →")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color.dinkrSky)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 9. MyGroupsWidget
struct MyGroupsWidget: View {
    let groups: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR GROUPS")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(groups, id: \.self) { group in
                        Text(group)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.dinkrGreen.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    Text("+ Discover")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.cardBackground)
                        .overlay(Capsule().stroke(Color.secondary.opacity(0.3)))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 10. WomensCornerWidget
struct WomensCornerWidget: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("🌸")
                Text("WOMEN'S")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            Text("Clinic Tomorrow")
                .font(.subheadline.weight(.bold))
            Text("Women's Beginner Clinic — 20 spots left")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Spacer()
            Text("Register →")
                .font(.caption.weight(.bold))
                .foregroundStyle(.pink)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color.pink.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 11. CourtVibesWidget
struct CourtVibesWidget: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("🌤")
                Text("COURT VIBES")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            Text("78°F")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(Color.dinkrAmber)
            Text("Perfect pickleball weather")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "sportscourt.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.dinkrSky)
                Text("8 courts open")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrSky)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color.dinkrSky.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 12. FeedPreviewWidget
struct FeedPreviewWidget: View {
    let posts: [Post]
    let onLike: (Post) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "rectangle.stack.fill")
                    .foregroundStyle(Color.dinkrGreen)
                    .font(.caption)
                Text("LATEST FROM YOUR FEED")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("See all →")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrGreen)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            ForEach(posts) { post in
                PostMiniRow(post: post, onLike: { onLike(post) })
                if post.id != posts.last?.id {
                    Divider().padding(.horizontal, 14)
                }
            }
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PostMiniRow: View {
    let post: Post
    let onLike: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            AvatarView(urlString: post.authorAvatarURL, displayName: post.authorName, size: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(post.authorName)
                    .font(.caption.weight(.semibold))
                Text(post.content)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button(action: onLike) {
                VStack(spacing: 2) {
                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(post.isLiked ? Color.dinkrCoral : .secondary)
                        .font(.caption)
                    Text("\(post.likes)")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

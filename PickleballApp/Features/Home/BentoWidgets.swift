import SwiftUI

// MARK: - 1. DinkrHeaderView
struct DinkrHeaderView: View {
    let city: String
    var onMessagesTap: (() -> Void)? = nil

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

            Button {
                onMessagesTap?()
            } label: {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.dinkrNavy)
            }
            .padding(.leading, 4)

            AvatarView(urlString: nil, displayName: "Alex Rivera", size: 36)
        }
    }
}

// MARK: - 2. WelcomeHeroWidget
struct WelcomeHeroWidget: View {
    let greeting: String
    let gameCount: Int

    // Compute time-of-day icon from the greeting string
    private var timeIcon: String {
        let lower = greeting.lowercased()
        if lower.contains("morning") { return "sun.max.fill" }
        if lower.contains("afternoon") { return "cloud.sun.fill" }
        if lower.contains("evening") { return "sunset.fill" }
        return "moon.stars.fill"
    }

    private var timeIconColor: Color {
        let lower = greeting.lowercased()
        if lower.contains("morning") { return Color.dinkrAmber }
        if lower.contains("afternoon") { return Color.dinkrSky }
        if lower.contains("evening") { return Color.dinkrCoral }
        return Color.dinkrSky.opacity(0.8)
    }

    // Strip the emoji from greeting for clean display
    private var cleanGreeting: String {
        greeting
            .replacingOccurrences(of: "☀️", with: "")
            .replacingOccurrences(of: "🌤️", with: "")
            .replacingOccurrences(of: "🌅", with: "")
            .replacingOccurrences(of: "🌙", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Base gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.dinkrNavy, Color.dinkrGreen.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(maxWidth: .infinity)
                .frame(height: 140)

            // Pickleball court line pattern
            Canvas { ctx, size in
                let lineColor = Color.white.opacity(0.06)
                // Kitchen line
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: 0, y: size.height * 0.45))
                    p.addLine(to: CGPoint(x: size.width, y: size.height * 0.45))
                }, with: .color(lineColor), lineWidth: 1.5)
                // Center line
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: size.width / 2, y: size.height * 0.45))
                    p.addLine(to: CGPoint(x: size.width / 2, y: size.height))
                }, with: .color(lineColor), lineWidth: 1.5)
                // Left sideline
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: size.width * 0.1, y: 0))
                    p.addLine(to: CGPoint(x: size.width * 0.1, y: size.height))
                }, with: .color(lineColor), lineWidth: 1)
                // Right sideline
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: size.width * 0.9, y: 0))
                    p.addLine(to: CGPoint(x: size.width * 0.9, y: size.height))
                }, with: .color(lineColor), lineWidth: 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Decorative circles
            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 120, height: 120)
                .offset(x: 260, y: -10)
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 80, height: 80)
                .offset(x: 300, y: 30)

            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    // Time-of-day icon with glow
                    Image(systemName: timeIcon)
                        .font(.title3)
                        .foregroundStyle(timeIconColor)
                        .shadow(color: timeIconColor.opacity(0.8), radius: 6, x: 0, y: 0)

                    // Greeting with shimmer phase animation
                    ShimmerGreetingText(text: cleanGreeting)
                }

                // Stats row
                HStack(spacing: 12) {
                    HeroStatBadge(icon: "flame.fill",
                                  label: "5 day streak",
                                  iconColor: Color.dinkrCoral)
                    HeroStatBadge(icon: "sportscourt.fill",
                                  label: "\(gameCount) games this week",
                                  iconColor: Color.dinkrGreen)
                }
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct ShimmerGreetingText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .phaseAnimator([false, true]) { content, isGlowing in
                content
                    .shadow(
                        color: Color.dinkrGreen.opacity(isGlowing ? 0.65 : 0.0),
                        radius: isGlowing ? 8 : 0,
                        x: 0, y: 0
                    )
            } animation: { _ in
                .easeInOut(duration: 2.2)
            }
    }
}

private struct HeroStatBadge: View {
    let icon: String
    let label: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(iconColor)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - 3. QuickActionsWidget
struct QuickActionsWidget: View {
    var body: some View {
        HStack(spacing: 10) {
            QuickActionPill(label: "Host Game",
                           icon: "plus.circle.fill",
                           gradientColors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.7)])
            QuickActionPill(label: "Find Game",
                           icon: "magnifyingglass.circle.fill",
                           gradientColors: [Color.dinkrSky, Color.dinkrSky.opacity(0.7)])
            QuickActionPill(label: "Open Play",
                           icon: "arrow.left.arrow.right.circle.fill",
                           gradientColors: [Color.dinkrCoral, Color.dinkrCoral.opacity(0.7)])
        }
    }
}

struct QuickActionPill: View {
    let label: String
    let icon: String
    let gradientColors: [Color]

    @State private var isPressed = false

    var body: some View {
        Button {
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(label)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: gradientColors[0].opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - 4. FeaturedEventWidget
struct FeaturedEventWidget: View {
    let event: Event

    var registrationProgress: Double {
        guard let max = event.maxParticipants, max > 0 else { return 0 }
        return Double(event.currentParticipants) / Double(max)
    }

    private var eventTypeBadge: (label: String, color: Color) {
        switch event.type {
        case .tournament:  return ("Tournament", Color.dinkrCoral)
        case .clinic:      return ("Clinic", Color.dinkrSky)
        case .social:      return ("Social", Color.dinkrGreen)
        case .openPlay:    return ("Open Play", Color.dinkrAmber)
        case .womenOnly:   return ("Women's", Color(red: 0.9, green: 0.3, blue: 0.6))
        case .fundraiser:  return ("Fundraiser", Color.dinkrAmber)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background gradient banner
            LinearGradient(
                colors: [Color.dinkrAmber.opacity(0.9), Color.dinkrCoral],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 160)

            // Dark overlay for readability
            LinearGradient(
                colors: [Color.clear, Color.dinkrNavy.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Top badges row
            HStack(alignment: .top) {
                // Event type badge
                Text(eventTypeBadge.label)
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(eventTypeBadge.color)
                    .clipShape(Capsule())

                Spacer()

                // FEATURED badge
                Text("FEATURED")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(Color.dinkrAmber)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.dinkrNavy.opacity(0.7))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.dinkrAmber.opacity(0.6), lineWidth: 0.8)
                    )
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .frame(maxHeight: .infinity, alignment: .top)

            // Bottom content
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                // Gradient progress bar
                VStack(alignment: .leading, spacing: 3) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.15))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.dinkrGreen, Color.dinkrSky],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * registrationProgress)
                        }
                    }
                    .frame(height: 5)

                    HStack {
                        Text("\(Int(registrationProgress * 100))% full · \(event.dateTime, style: .date)")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.75))
                        Spacer()
                        // Entry fee pill
                        if let fee = event.entryFee, fee > 0 {
                            Text("$\(Int(fee))")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.dinkrGreen)
                                .clipShape(Capsule())
                        } else {
                            Text("FREE")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.dinkrGreen)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - 5. NearbyGamesWidget
struct NearbyGamesWidget: View {
    let count: Int
    let distance: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Live indicator + label
            HStack(spacing: 6) {
                PulsingLiveDot()
                Text("LIVE")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(Color.dinkrGreen)
            }

            // Large game count
            Text("\(count)")
                .font(.system(size: 38, weight: .heavy))
                .foregroundStyle(Color.dinkrSky)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text("games\nnear you")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            // Distance badge
            HStack(spacing: 4) {
                Image(systemName: "mappin.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.dinkrCoral)
                Text(distance)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.dinkrCoral.opacity(0.1))
            .clipShape(Capsule())

            Spacer()

            Text("Find →")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.dinkrGreen)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(
            LinearGradient(
                colors: [Color.dinkrSky.opacity(0.15), Color.dinkrSky.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct PulsingLiveDot: View {
    var body: some View {
        Circle()
            .fill(Color.dinkrGreen)
            .frame(width: 8, height: 8)
            .phaseAnimator([1.0, 1.5, 1.0]) { content, scale in
                content
                    .scaleEffect(scale)
                    .opacity(scale > 1.2 ? 0.6 : 1.0)
            } animation: { _ in
                .easeInOut(duration: 1.0)
            }
    }
}

// MARK: - 6. CommunitySpotlightWidget
struct CommunitySpotlightWidget: View {
    let spotlight: PlayerSpotlightData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                TrophyShimmerView()
                Text("COMMUNITY SPOTLIGHT")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            // Player row
            HStack(spacing: 12) {
                // Avatar with amber ring for the winner
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.dinkrAmber, Color.dinkrCoral],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: 52, height: 52)
                    AvatarView(urlString: nil, displayName: spotlight.displayName, size: 46)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("@\(spotlight.username)")
                        .font(.subheadline.weight(.bold))
                    Text(spotlight.achievement)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Text(spotlight.eventName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.dinkrAmber)
                }
                Spacer()
            }

            // Achievement tag pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(spotlight.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.dinkrAmber)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.dinkrAmber.opacity(0.14))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.dinkrAmber.opacity(0.25), lineWidth: 0.8)
                            )
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.dinkrAmber.opacity(0.1), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct TrophyShimmerView: View {
    var body: some View {
        Text("🏆")
            .font(.title3)
            .phaseAnimator([false, true]) { content, isShimmering in
                content
                    .scaleEffect(isShimmering ? 1.15 : 1.0)
                    .brightness(isShimmering ? 0.25 : 0.0)
            } animation: { isShimmering in
                isShimmering
                    ? .spring(response: 0.5, dampingFraction: 0.5)
                    : .easeInOut(duration: 0.4).delay(2.5)
            }
    }
}

// MARK: - 7. TopNewsWidget
struct TopNewsWidget: View {
    let articles: [NewsArticle]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "newspaper.fill")
                    .foregroundStyle(Color.dinkrSky)
                    .font(.caption)
                Text("TOP NEWS")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            ForEach(Array(articles.enumerated()), id: \.element.id) { index, article in
                VStack(alignment: .leading, spacing: 3) {
                    Text(article.title)
                        .font(index == 0
                              ? .system(size: 13, weight: .bold)
                              : .system(size: 11, weight: .semibold))
                        .lineLimit(index == 0 ? 3 : 2)
                        .foregroundStyle(.primary)

                    HStack(spacing: 5) {
                        // Source indicator dot
                        Circle()
                            .fill(Color.dinkrGreen)
                            .frame(width: 5, height: 5)
                        Text(article.source)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color.dinkrGreen)
                        Text("·")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Text(article.publishedAt, style: .relative)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, index == 0 ? 8 : 6)

                if article.id != articles.last?.id {
                    Divider()
                        .padding(.horizontal, 14)
                }
            }

            // View all
            HStack {
                Spacer()
                Text("View all →")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrGreen)
                Spacer()
            }
            .padding(10)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.dinkrNavy.opacity(0.08), lineWidth: 1)
        )
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
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(Color.dinkrSky)
            Text("near you")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.dinkrGreen)
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
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color.dinkrSky, Color.dinkrSky.opacity(0.75)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color.dinkrSky.opacity(0.35), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - 9. MyGroupsWidget
struct MyGroupsWidget: View {
    let groups: [String]

    // Simple color pool for group initials circles
    private let groupColors: [Color] = [
        Color.dinkrGreen, Color.dinkrSky, Color.dinkrCoral,
        Color.dinkrAmber, Color.dinkrNavy
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR GROUPS")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(groups.enumerated()), id: \.element) { index, group in
                        GroupPill(name: group,
                                  accentColor: groupColors[index % groupColors.count])
                    }

                    // Discover chip with gradient fill
                    HStack(spacing: 5) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                        Text("Discover")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color.dinkrNavy, Color.dinkrNavy.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct GroupPill: View {
    let name: String
    let accentColor: Color

    private var initials: String {
        name.components(separatedBy: " ")
            .compactMap { $0.first.map(String.init) }
            .prefix(2)
            .joined()
            .uppercased()
    }

    var body: some View {
        HStack(spacing: 7) {
            // Colored initials circle acting as emoji avatar
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 22, height: 22)
                Text(initials)
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(accentColor)
            }

            Text(name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.dinkrGreen.opacity(0.08))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.dinkrGreen.opacity(0.4), lineWidth: 1.2)
        )
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
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color.pink.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - 11. CourtVibesWidget
struct CourtVibesWidget: View {
    @State private var courtCount = 8

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
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(Color.dinkrAmber)

            Text("Perfect pickleball weather")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "sportscourt.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.dinkrSky)
                // Animated court count
                Text("\(courtCount) courts open")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrSky)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4), value: courtCount)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            LinearGradient(
                colors: [Color.dinkrSky.opacity(0.14), Color.dinkrSky.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - 12. FeedPreviewWidget
struct FeedPreviewWidget: View {
    let posts: [Post]
    let onLike: (Post) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
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
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            ForEach(posts) { post in
                PostMiniRow(post: post, onLike: { onLike(post) })
                if post.id != posts.last?.id {
                    Divider()
                        .padding(.horizontal, 16)
                }
            }
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.dinkrNavy.opacity(0.07), lineWidth: 1)
        )
    }
}

struct PostMiniRow: View {
    let post: Post
    let onLike: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            AvatarView(urlString: post.authorAvatarURL, displayName: post.authorName, size: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(post.authorName)
                        .font(.caption.weight(.semibold))
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(post.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(post.content)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Reaction pills
                HStack(spacing: 6) {
                    ReactionPill(icon: post.isLiked ? "heart.fill" : "heart",
                                 count: post.likes,
                                 color: post.isLiked ? Color.dinkrCoral : .secondary,
                                 action: onLike)
                    ReactionPill(icon: "bubble.left",
                                 count: post.commentCount,
                                 color: Color.dinkrSky,
                                 action: {})
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }
}

private struct ReactionPill: View {
    let icon: String
    let count: Int
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(color)
                Text("\(count)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

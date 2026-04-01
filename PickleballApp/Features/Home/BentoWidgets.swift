import SwiftUI

// MARK: - 1. DinkrHeaderView
struct DinkrHeaderView: View {
    let city: String
    var unreadNotificationCount: Int = 0
    var liveGameCount: Int = 0
    var onMessagesTap: (() -> Void)? = nil
    var onBellTap: (() -> Void)? = nil
    var onLiveChipTap: (() -> Void)? = nil
    var onAvatarTap: (() -> Void)? = nil
    var onSearchTap: (() -> Void)? = nil

    @State private var showLocationSheet = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                DinkrLogoView(size: 32)

                Spacer()

                // Live games chip
                if liveGameCount > 0 {
                    Button {
                        HapticManager.selection()
                        onLiveChipTap?()
                    } label: {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 7, height: 7)
                            Text("Live \(liveGameCount) games")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.primary)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.cardBackground)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.dinkrCoral.opacity(0.35), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // City chip (tappable)
                Button {
                    HapticManager.selection()
                    showLocationSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(Color.dinkrCoral)
                            .font(.system(size: 10, weight: .semibold))
                        Text(city)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.cardBackground)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .confirmationDialog("Location", isPresented: $showLocationSheet, titleVisibility: .visible) {
                    Button("Change Location") { }
                    Button("Cancel", role: .cancel) { }
                }

                // Search button
                Button {
                    HapticManager.selection()
                    onSearchTap?()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.dinkrNavy)
                }

                // Messages button
                Button {
                    HapticManager.selection()
                    onMessagesTap?()
                } label: {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.dinkrNavy)
                }

                // Notification bell button
                Button {
                    HapticManager.selection()
                    onBellTap?()
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: unreadNotificationCount > 0 ? "bell.badge.fill" : "bell")
                            .font(.system(size: 20))
                            .foregroundStyle(unreadNotificationCount > 0 ? Color.dinkrAmber : Color.dinkrNavy)

                        if unreadNotificationCount > 0 {
                            Text(unreadNotificationCount > 99 ? "99+" : "\(unreadNotificationCount)")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 3)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .clipShape(Capsule())
                                .offset(x: 6, y: -6)
                        }
                    }
                }

                // Avatar linking to ProfileView
                Button {
                    HapticManager.selection()
                    onAvatarTap?()
                } label: {
                    AvatarView(urlString: nil, displayName: "Alex Rivera", size: 36)
                }
                .buttonStyle(.plain)
            }

            Divider()
                .padding(.top, 8)
        }
    }
}

// MARK: - 2. WelcomeHeroWidget
struct WelcomeHeroWidget: View {
    let greeting: String
    let gameCount: Int
    var weather: String? = nil   // e.g. "☀️ 78°F"

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
            // Clean static gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.dinkrNavy, Color.dinkrGreen.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(maxWidth: .infinity)
                .frame(height: 148)

            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: timeIcon)
                        .font(.title3)
                        .foregroundStyle(timeIconColor)

                    Text(cleanGreeting)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }

                // Weather line
                if let weather {
                    Text(weather)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
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
    var onHostGame: () -> Void = {}
    var onFindGame: () -> Void = {}
    var onOpenPlay: () -> Void = {}
    var onLogResult: () -> Void = {}
    var onLiveFeed: () -> Void = {}

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            QuickActionPill(
                label: "Host Game",
                subtitle: "Create a session",
                icon: "plus.circle.fill",
                gradientColors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.7)],
                action: onHostGame
            )
            QuickActionPill(
                label: "Find Game",
                subtitle: "Browse near you",
                icon: "magnifyingglass.circle.fill",
                gradientColors: [Color.dinkrSky, Color.dinkrSky.opacity(0.7)],
                action: onFindGame
            )
            QuickActionPill(
                label: "Log Result ✏️",
                subtitle: "Record a score",
                icon: "square.and.pencil",
                gradientColors: [Color.dinkrAmber, Color.dinkrAmber.opacity(0.7)],
                action: onLogResult
            )
            QuickActionPill(
                label: "Open Play",
                subtitle: "Drop-in sessions",
                icon: "arrow.left.arrow.right.circle.fill",
                gradientColors: [Color.dinkrCoral, Color.dinkrCoral.opacity(0.7)],
                action: onOpenPlay
            )
            QuickActionPill(
                label: "Live Scores",
                subtitle: "Watch in real time",
                icon: "dot.radiowaves.left.and.right",
                gradientColors: [Color.red.opacity(0.85), Color.dinkrCoral],
                action: onLiveFeed
            )
        }
    }
}

struct QuickActionPill: View {
    let label: String
    var subtitle: String? = nil
    let icon: String
    let gradientColors: [Color]
    var action: () -> Void = {}

    @State private var isPressed = false

    var body: some View {
        Button {
            HapticManager.medium()
            action()
        } label: {
            VStack(spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: icon)
                        .font(.subheadline)
                    Text(label)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .foregroundStyle(.white)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(gradientColors[0])
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
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
                                .fill(Color.dinkrGreen)
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
                Circle()
                    .fill(Color.dinkrGreen)
                    .frame(width: 7, height: 7)
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
        .background(Color.dinkrSky.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - 6. CommunitySpotlightWidget

struct CommunitySpotlightWidget: View {
    let spotlight: PlayerSpotlightData

    // Spotlight page indicator (3 recent spotlights)
    @State private var activeDot: Int = 0
    // Nominee voting
    @State private var votedNomineeId: UUID? = nil
    @State private var showVoteConfirmation = false
    @State private var voteScale: CGFloat = 1.0

    var body: some View {
        NavigationLink(destination: PlayerSpotlightDetailView(spotlight: spotlight)) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 8) {
                    TrophyShimmerView()
                    Text("COMMUNITY SPOTLIGHT")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.secondary)
                    Spacer()
                    // Spotlight indicator dots (3 recent spotlights)
                    HStack(spacing: 5) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(index == activeDot ? Color.dinkrAmber : Color.secondary.opacity(0.25))
                                .frame(
                                    width: index == activeDot ? 7 : 5,
                                    height: index == activeDot ? 7 : 5
                                )
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: activeDot)
                        }
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5).delay(2.0)) {
                            activeDot = 0
                        }
                    }
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
                        HStack(spacing: 6) {
                            Text("@\(spotlight.username)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.primary)
                            Text("🌟")
                                .font(.caption)
                        }
                        Text(spotlight.achievement)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        Text(spotlight.eventName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.dinkrAmber)
                    }
                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.secondary.opacity(0.4))
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

                Divider()
                    .opacity(0.5)

                // Nominee vote section
                nomineeVoteSection
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
        .buttonStyle(.plain)
    }

    // MARK: - Nominee Vote Section

    private var nomineeVoteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Who should be next?")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(.secondary)
                Spacer()
                if showVoteConfirmation {
                    Text("Vote recorded! 🗳️")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.dinkrGreen)
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                } else {
                    Text("Vote →")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.dinkrGreen)
                }
            }

            HStack(spacing: 10) {
                ForEach(PlayerSpotlightData.nominees) { nominee in
                    NomineeChip(
                        nominee: nominee,
                        isVoted: votedNomineeId == nominee.id
                    ) {
                        castVote(for: nominee)
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Vote Action

    private func castVote(for nominee: NomineeData) {
        guard votedNomineeId == nil else { return }
        HapticManager.medium()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
            votedNomineeId = nominee.id
            voteScale = 1.12
        }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7).delay(0.15)) {
            voteScale = 1.0
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            showVoteConfirmation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showVoteConfirmation = false
            }
        }
    }
}

// MARK: - NomineeChip

private struct NomineeChip: View {
    let nominee: NomineeData
    let isVoted: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(
                            isVoted ? Color.dinkrGreen : Color.secondary.opacity(0.2),
                            lineWidth: isVoted ? 2 : 1
                        )
                        .frame(width: 38, height: 38)
                    AvatarView(urlString: nil, displayName: nominee.displayName, size: 32)

                    if isVoted {
                        Circle()
                            .fill(Color.dinkrGreen)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 7, weight: .black))
                                    .foregroundStyle(.white)
                            )
                            .offset(x: 12, y: 12)
                    }
                }
                .scaleEffect(isVoted ? 1.08 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isVoted)

                Text(nominee.displayName.components(separatedBy: " ").first ?? nominee.displayName)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(isVoted ? Color.dinkrGreen : .secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .disabled(isVoted)
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
    var onMatch: () -> Void = {}

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

            Button {
                HapticManager.selection()
                onMatch()
            } label: {
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

/// Rich group metadata for the widget.
struct GroupInfo: Identifiable {
    let id: String
    let name: String
    var unreadCount: Int = 0
    var isRecentlyActive: Bool = false
    var nextGameLabel: String? = nil   // e.g. "Next game: Sun 9AM"
}

struct MyGroupsWidget: View {
    /// Accept either rich GroupInfo or plain group names (for backward compat)
    let groupInfos: [GroupInfo]

    init(groups: [String]) {
        self.groupInfos = groups.enumerated().map { idx, name in
            GroupInfo(id: "\(idx)-\(name)", name: name)
        }
    }

    init(groupInfos: [GroupInfo]) {
        self.groupInfos = groupInfos
    }

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
                    ForEach(Array(groupInfos.enumerated()), id: \.element.id) { index, group in
                        GroupPill(
                            info: group,
                            accentColor: groupColors[index % groupColors.count]
                        )
                    }

                    // Discover chip with vibrant gradient background
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
                            colors: [Color.dinkrNavy, Color.dinkrGreen.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.dinkrNavy.opacity(0.3), radius: 5, x: 0, y: 2)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct GroupPill: View {
    let info: GroupInfo
    let accentColor: Color

    private var initials: String {
        info.name.components(separatedBy: " ")
            .compactMap { $0.first.map(String.init) }
            .prefix(2)
            .joined()
            .uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 7) {
                // Colored initials circle with optional active green dot
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 24, height: 24)
                    Text(initials)
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(accentColor)

                    if info.isRecentlyActive {
                        Circle()
                            .fill(Color.dinkrGreen)
                            .frame(width: 7, height: 7)
                            .overlay(
                                Circle()
                                    .stroke(Color.cardBackground, lineWidth: 1.2)
                            )
                            .offset(x: 3, y: -3)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(info.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let nextGame = info.nextGameLabel {
                        Text(nextGame)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color.dinkrSky)
                            .lineLimit(1)
                    }
                }

                // Unread badge
                if info.unreadCount > 0 {
                    Text("\(info.unreadCount > 99 ? "99+" : "\(info.unreadCount)")")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.dinkrCoral)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.dinkrGreen.opacity(0.08))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    info.isRecentlyActive
                        ? Color.dinkrGreen.opacity(0.55)
                        : Color.dinkrGreen.opacity(0.4),
                    lineWidth: info.isRecentlyActive ? 1.5 : 1.2
                )
        )
    }
}

// MARK: - 10. WomensCornerWidget
struct WomensCornerWidget: View {
    var memberCount: Int = 847
    var onJoin: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 5) {
                Text("🌸")
                    .font(.system(size: 16))
                Text("Women's Corner")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(.white)
                Spacer()
            }

            // Upcoming event highlight
            VStack(alignment: .leading, spacing: 3) {
                Text("Beginner Clinic — Tomorrow")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text("Austin Tennis & Pickleball Center · 9 AM")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            // Member stat
            HStack(spacing: 4) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.85))
                Text("\(memberCount) members")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }

            // CTA button
            Button {
                HapticManager.selection()
                onJoin?()
            } label: {
                Text("Join the Community")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.dinkrCoral)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(.white.opacity(0.92))
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(
            LinearGradient(
                colors: [Color.dinkrCoral.opacity(0.85), Color(red: 1.0, green: 0.6, blue: 0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - 11. CourtVibesWidget
struct CourtVibesWidget: View {
    let weather: CurrentWeather?
    @State private var courtCount = 8

    private var tempDisplay: String {
        guard let w = weather else { return "—°F" }
        return "\(Int(w.temperatureF))°F"
    }

    private var windDisplay: String {
        guard let w = weather else { return "" }
        return "\(Int(w.windSpeedMph)) mph"
    }

    private var emoji: String {
        weather?.emoji ?? "🌤"
    }

    private var tempColor: Color {
        guard let w = weather else { return Color.dinkrAmber }
        if w.isRainy { return Color.dinkrSky }
        if w.temperatureF >= 65 && w.temperatureF <= 85 { return Color.dinkrGreen }
        if w.temperatureF > 85 { return Color.dinkrCoral }
        return Color.dinkrAmber
    }

    /// Simple apparent temperature: NWS wind chill below 50 °F,
    /// estimated +5 ° heat buffer above 90 °F.
    private var feelsLikeDisplay: String {
        guard let w = weather else { return "" }
        let t = w.temperatureF
        let v = w.windSpeedMph
        let apparent: Double
        if t <= 50 && v > 3 {
            // NWS wind chill formula
            apparent = 35.74 + 0.6215 * t - 35.75 * pow(v, 0.16) + 0.4275 * t * pow(v, 0.16)
        } else if t > 90 {
            // Rough heat buffer without humidity (conservative +5°)
            apparent = t + 5
        } else {
            apparent = t
        }
        let delta = Int(apparent) - Int(t)
        if delta == 0 { return "" }
        return "Feels \(Int(apparent))°"
    }

    private var moodText: String {
        guard let w = weather else { return "Checking conditions…" }
        if w.isRainy { return "Rain — courts may be wet" }
        if w.windSpeedMph > 20 { return "Too windy for lobs" }
        if w.windSpeedMph > 12 { return "Light wind" }
        if w.temperatureF > 90 { return "Hot day — hydrate!" }
        if w.temperatureF >= 65 && w.temperatureF <= 85 { return "Perfect conditions" }
        return "Decent conditions"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(emoji)
                Text("COURT VIBES")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(tempDisplay)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(tempColor)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4), value: tempDisplay)

                if !feelsLikeDisplay.isEmpty {
                    Text(feelsLikeDisplay)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            if let w = weather {
                Text(moodText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Wind chip
                if w.windSpeedMph > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "wind")
                            .font(.system(size: 9))
                            .foregroundStyle(w.isWindy ? Color.dinkrCoral : Color.secondary)
                        Text(windDisplay)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(w.isWindy ? Color.dinkrCoral : Color.secondary)
                        if w.isWindy {
                            Text("· Affects play")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.dinkrCoral.opacity(0.8))
                        }
                    }
                }

                // UV Index row
                HStack(spacing: 3) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.dinkrAmber)
                    Text("UV \(Int(w.uvIndex)) · \(w.uvLabel)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Loading…")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .redacted(reason: .placeholder)
            }

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "sportscourt.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.dinkrSky)
                Text("\(courtCount) courts open")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrSky)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4), value: courtCount)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(
            LinearGradient(
                colors: [Color.dinkrSky.opacity(0.18), Color.dinkrSky.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - 11b. WeekendForecastWidget
struct WeekendForecastWidget: View {
    let days: [DayForecast]
    /// Optional `WeekendDay` data for game-count display
    var weekendDays: [WeekendDay] = []

    private var tagline: String {
        let goodDays = days.filter { !$0.isRainy && $0.maxTempF >= 55 }
        if goodDays.count >= 2 { return "Perfect weekend for pickleball! 🏓" }
        if goodDays.count == 1 { return "One great day ahead 🏓" }
        return "Check the forecast before you play 🌧"
    }

    /// Total games across all weekend days (from WeekendDay overrides)
    private var totalWeekendGames: Int {
        weekendDays.reduce(0) { $0 + $1.gameCount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Text("WEEKEND FORECAST")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                if totalWeekendGames > 0 {
                    Text("\(totalWeekendGames) games")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            if days.isEmpty {
                HStack {
                    ProgressView()
                        .tint(.white)
                    Text("Loading forecast…")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            } else {
                HStack(spacing: 10) {
                    ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                        let wDay = weekendDays.first { $0.dateString == day.dateString }
                        WeekendDayCard(day: day, gameCount: wDay?.gameCount)
                    }
                }
            }

            // Tagline
            Text(tagline)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.dinkrSky, Color.dinkrGreen.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct WeekendDayCard: View {
    let day: DayForecast
    var gameCount: Int? = nil

    private var playColor: Color {
        switch day.playabilityColor {
        case "coral":  return Color.dinkrCoral
        case "amber":  return Color.dinkrAmber
        case "sky":    return Color.dinkrSky
        default:       return Color.dinkrGreen
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(day.dayName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)

            Text(day.emoji)
                .font(.title2)

            VStack(spacing: 2) {
                Text("\(Int(day.maxTempF))°")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(.white)
                Text("\(Int(day.minTempF))°")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
            }

            // Rain probability
            if day.precipProbability > 10 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.85))
                    Text("\(day.precipProbability)%")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }

            // Game count badge (if provided)
            if let count = gameCount {
                HStack(spacing: 2) {
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(.white.opacity(0.9))
                    Text("\(count) game\(count == 1 ? "" : "s")")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }

            // Play verdict pill
            Text(day.playabilityLabel)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.white.opacity(0.22))
                .clipShape(Capsule())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 14))
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
                BentoPostMiniRow(post: post, onLike: { onLike(post) })
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

private struct BentoPostMiniRow: View {
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
        Button {
            HapticManager.selection()
            action()
        } label: {
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

// MARK: - 13. VideoHighlightsWidget

struct VideoHighlightsWidget: View {
    let videos: [VideoHighlight]
    let onWatchAll: () -> Void
    let onWatchVideo: (VideoHighlight) -> Void

    @State private var selectedCategory: VideoCategory = .all

    private var filtered: [VideoHighlight] {
        selectedCategory == .all ? videos : videos.filter { $0.category == selectedCategory }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // ── Header row ──────────────────────────────────────────
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.dinkrCoral)
                    Text("VIDEO HIGHLIGHTS")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onWatchAll) {
                    HStack(spacing: 3) {
                        Text("Watch All")
                            .font(.system(size: 12, weight: .semibold))
                        Text("→")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(Color.dinkrGreen)
                }
                .buttonStyle(.plain)
            }

            // ── Category filter chips ────────────────────────────────
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(VideoCategory.allCases) { cat in
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                selectedCategory = cat
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 10, weight: .semibold))
                                Text(cat.rawValue)
                                    .font(.system(size: 11, weight: selectedCategory == cat ? .bold : .medium))
                            }
                            .foregroundStyle(selectedCategory == cat ? Color.white : Color.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedCategory == cat
                                    ? Color.dinkrNavy
                                    : Color.secondary.opacity(0.12)
                            )
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }

            // ── Horizontal video card scroll ─────────────────────────
            if filtered.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.secondary.opacity(0.1))
                                .frame(width: 140, height: 180)
                                .redacted(reason: .placeholder)
                        }
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filtered) { video in
                            VideoHighlightCard(video: video) {
                                HapticManager.selection()
                                onWatchVideo(video)
                            }
                        }
                    }
                    .padding(.bottom, 4)
                }
            }
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.dinkrNavy.opacity(0.07), lineWidth: 1)
        )
    }
}

// MARK: - VideoHighlightCard (140x180)

private struct VideoHighlightCard: View {
    let video: VideoHighlight
    let onTap: () -> Void

    private var gradientColors: [Color] {
        switch video.category {
        case .all:         return [Color.dinkrGreen.opacity(0.65),  Color.dinkrNavy]
        case .highlights:  return [Color.dinkrCoral.opacity(0.65),  Color.dinkrNavy]
        case .tutorials:   return [Color.dinkrSky.opacity(0.65),    Color.dinkrNavy]
        case .tournaments: return [Color.dinkrAmber.opacity(0.65),  Color.dinkrNavy]
        }
    }

    private var categoryLabel: String {
        switch video.category {
        case .all:         return "▶ Video"
        case .highlights:  return "🔥 Highlight"
        case .tutorials:   return "🎓 Tutorial"
        case .tournaments: return "🏆 Tournament"
        }
    }

    private func formattedViews(_ n: Int) -> String {
        n >= 1000 ? String(format: "%.1fK views", Double(n) / 1000) : "\(n) views"
    }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottom) {

                // ── Gradient thumbnail background ──
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 180)

                // ── Center play button ──
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(.white.opacity(0.88))
                    .shadow(color: .black.opacity(0.35), radius: 4)
                    .frame(maxHeight: .infinity, alignment: .center)

                // ── Duration badge (top-right) ──
                Text(video.duration)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .padding(7)
                    .frame(width: 140, height: 180, alignment: .topTrailing)

                // ── Bottom info overlay ──
                VStack(alignment: .leading, spacing: 3) {
                    Text(categoryLabel)
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.9))

                    Text(video.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(formattedViews(video.viewCount))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 8)
                .frame(width: 140, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.65)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(
                    .rect(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 14,
                        bottomTrailingRadius: 14,
                        topTrailingRadius: 0
                    )
                )
            }
            .frame(width: 140, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.dinkrNavy.opacity(0.18), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - TrendingGamesWidget

struct TrendingGamesWidget: View {
    let sessions: [GameSession]
    var onViewAll: (() -> Void)? = nil

    @State private var quickRSVPSession: GameSession?

    /// The session with the most RSVPs (most popular / "Hot")
    private var hottestSession: GameSession? {
        sessions.max(by: { $0.rsvps.count < $1.rsvps.count })
    }

    private func formatColor(_ format: GameFormat) -> Color {
        switch format {
        case .singles:      return Color.dinkrCoral
        case .doubles:      return Color.dinkrGreen
        case .mixed:        return Color.dinkrSky
        case .openPlay:     return Color.dinkrAmber
        case .round_robin:  return Color.dinkrNavy
        }
    }

    private func formatLabel(_ format: GameFormat) -> String {
        switch format {
        case .singles:      return "Singles"
        case .doubles:      return "Doubles"
        case .mixed:        return "Mixed"
        case .openPlay:     return "Open Play"
        case .round_robin:  return "Round Robin"
        }
    }

    private func countdownLabel(_ date: Date) -> String {
        let diff = date.timeIntervalSince(Date())
        if diff <= 0 { return "Now" }
        let hours = Int(diff / 3600)
        let minutes = Int((diff.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 { return "In \(hours)h" }
        return "In \(minutes)m"
    }

    /// True when the game is currently live (dateTime in the past but within 3 hours)
    private func isLive(_ session: GameSession) -> Bool {
        session.liveScore != nil ||
        (session.dateTime <= Date() && session.dateTime > Date().addingTimeInterval(-10800))
    }

    /// True when the game is nearly full (≤ 25% spots remaining, at least 1 spot gone)
    private func isFillingFast(_ session: GameSession) -> Bool {
        guard session.totalSpots > 0 else { return false }
        let remaining = session.spotsRemaining
        let ratio = Double(remaining) / Double(session.totalSpots)
        return ratio <= 0.25 && session.rsvps.count > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrCoral)
                    Text("Trending Games")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.dinkrNavy)
                }
                Spacer()
                Button {
                    HapticManager.selection()
                    onViewAll?()
                } label: {
                    Text("View All →")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                }
            }

            // Vertical list of game rows
            VStack(spacing: 0) {
                ForEach(sessions.prefix(4)) { session in
                    NavigationLink(destination: GameSessionDetailView(session: session, viewModel: PlayViewModel())) {
                        TrendingGameRow(
                            session: session,
                            formatLabel: formatLabel(session.format),
                            formatColor: formatColor(session.format),
                            countdownLabel: countdownLabel(session.dateTime),
                            isHot: session.id == hottestSession?.id,
                            isLive: isLive(session),
                            isFillingFast: isFillingFast(session)
                        )
                    }
                    .buttonStyle(.plain)

                    if session.id != sessions.prefix(4).last?.id {
                        Divider()
                            .padding(.horizontal, 4)
                    }
                }
            }

            // View All footer link
            Button {
                HapticManager.selection()
                onViewAll?()
            } label: {
                HStack {
                    Spacer()
                    Text("View all games →")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(Color.dinkrGreen.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        .sheet(item: $quickRSVPSession) { session in
            QuickRSVPView(session: session, viewModel: PlayViewModel())
        }
    }
}

// MARK: - TrendingGameRow

private struct TrendingGameRow: View {
    let session: GameSession
    let formatLabel: String
    let formatColor: Color
    let countdownLabel: String
    let isHot: Bool
    let isLive: Bool
    let isFillingFast: Bool

    var body: some View {
        HStack(spacing: 10) {
            // Host avatar + initials
            ZStack {
                Circle()
                    .fill(formatColor.opacity(0.18))
                    .frame(width: 38, height: 38)
                Text(hostInitials)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(formatColor)
            }

            // Center content
            VStack(alignment: .leading, spacing: 3) {
                // Court name + badges row
                HStack(spacing: 5) {
                    Text(session.courtName)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if isHot {
                        Text("🔥 Hot")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(Color.dinkrCoral)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.dinkrCoral.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    if isLive {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 5, height: 5)
                            Text("LIVE")
                                .font(.system(size: 8, weight: .heavy))
                                .foregroundStyle(Color.red)
                                .kerning(0.5)
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.10))
                        .clipShape(Capsule())
                    }
                }

                // Host name + format pill
                HStack(spacing: 6) {
                    Text("by \(session.hostName)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(formatLabel)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(formatColor)
                        .clipShape(Capsule())
                }
            }

            Spacer(minLength: 4)

            // Right side: spots + countdown + filling fast
            VStack(alignment: .trailing, spacing: 4) {
                // Countdown chip
                Text(countdownLabel)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.dinkrNavy.opacity(0.75))
                    .clipShape(Capsule())

                // Spots remaining
                Text("\(session.spotsRemaining) spot\(session.spotsRemaining == 1 ? "" : "s") left")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(session.spotsRemaining <= 2 ? Color.dinkrCoral : Color.dinkrGreen)

                // Filling fast urgency chip
                if isFillingFast && !isLive {
                    Text("Filling fast")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(Color.dinkrAmber)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.dinkrAmber.opacity(0.15))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.dinkrAmber.opacity(0.4), lineWidth: 0.8)
                        )
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }

    private var hostInitials: String {
        session.hostName
            .components(separatedBy: " ")
            .compactMap { $0.first.map(String.init) }
            .prefix(2)
            .joined()
            .uppercased()
    }
}

// MARK: - LiveActivityWidget

struct LiveActivityWidget: View {
    let session: GameSession

    @State private var pulsing = false

    var body: some View {
        ZStack {
            // dinkrCoral gradient background
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.dinkrCoral, Color.dinkrCoral.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Subtle court line pattern at 4% opacity
            Canvas { ctx, size in
                let lineColor = Color.white.opacity(0.04)
                // Kitchen line
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: 0, y: size.height * 0.45))
                    p.addLine(to: CGPoint(x: size.width, y: size.height * 0.45))
                }, with: .color(lineColor), lineWidth: 2)
                // Center line
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: size.width / 2, y: size.height * 0.45))
                    p.addLine(to: CGPoint(x: size.width / 2, y: size.height))
                }, with: .color(lineColor), lineWidth: 2)
                // Left sideline
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: size.width * 0.08, y: 0))
                    p.addLine(to: CGPoint(x: size.width * 0.08, y: size.height))
                }, with: .color(lineColor), lineWidth: 1.5)
                // Right sideline
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: size.width * 0.92, y: 0))
                    p.addLine(to: CGPoint(x: size.width * 0.92, y: size.height))
                }, with: .color(lineColor), lineWidth: 1.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Content
            VStack(alignment: .leading, spacing: 10) {
                // LIVE badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .scaleEffect(pulsing ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: pulsing)
                    Text("LIVE")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.white)
                        .kerning(1.5)
                    Spacer()
                    // Watch Live button
                    Button {
                        HapticManager.medium()
                    } label: {
                        Text("Watch Live")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.dinkrCoral)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                // Score display
                if let score = session.liveScore {
                    HStack(alignment: .center, spacing: 0) {
                        Text(score.teamAName)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                        Spacer()
                        Text("\(score.scoreA)")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("  —  ")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("\(score.scoreB)")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                        Text(score.teamBName)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                            .multilineTextAlignment(.trailing)
                    }
                }

                // Court + format
                HStack(spacing: 6) {
                    Image(systemName: "sportscourt.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(session.courtName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Text("·")
                        .foregroundStyle(.white.opacity(0.5))
                    Text(session.format.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .shadow(color: Color.dinkrCoral.opacity(0.35), radius: 12, x: 0, y: 5)
        .onAppear { pulsing = true }
    }
}

// MARK: - DailyTipWidget

struct DailyTipWidget: View {
    private static let tips: [String] = [
        "Keep your paddle up at the kitchen line",
        "Dink cross-court for safer angles",
        "Communicate with your partner before every serve",
        "Attack mid-court pop-ups with authority",
        "Stay out of no-man's land",
        "Use the erne sparingly but effectively",
        "Reset to neutral when in trouble"
    ]

    private var todaysTip: String {
        let dayIndex = Calendar.current.component(.weekday, from: Date()) - 1
        return Self.tips[dayIndex % Self.tips.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header pill
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrAmber)
                Text("Daily Tip")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dinkrNavy)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.dinkrAmber.opacity(0.12))
            .clipShape(Capsule())

            // Tip text
            Text("\"\(todaysTip)\"")
                .font(.subheadline.italic())
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Pro Tip badge
            HStack(spacing: 4) {
                Text("💡")
                    .font(.caption)
                Text("Pro Tip")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrAmber)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.dinkrAmber.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

// MARK: - ChallengesWidget

/// Lightweight model for displaying a challenger pair in the widget.
struct ChallengePairPreview: Identifiable {
    let id: String
    let challengerName: String
    let challengedName: String
    let isPending: Bool    // true = awaiting response, false = active
    let isUserWinning: Bool
}

struct ChallengesWidget: View {
    let activeCount: Int
    let winningCount: Int
    var pendingCount: Int = 0
    /// Optional preview pairs — up to 2 shown as mini avatar pairs
    var pairs: [ChallengePairPreview] = []

    @State private var showChallenges = false

    private var losingCount: Int { max(0, activeCount - winningCount) }
    private var hasPending: Bool { pendingCount > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header row
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.dinkrAmber.opacity(0.2), Color.dinkrAmber.opacity(0.08)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.dinkrAmber)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Challenges")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.dinkrNavy)

                        // Large active count bubble
                        ZStack {
                            Circle()
                                .fill(Color.dinkrAmber.opacity(0.18))
                                .frame(width: 28, height: 28)
                            Text("\(activeCount)")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundStyle(Color.dinkrAmber)
                        }
                    }

                    // Status pills row
                    HStack(spacing: 6) {
                        if winningCount > 0 {
                            HStack(spacing: 3) {
                                Circle().fill(Color.dinkrGreen).frame(width: 6, height: 6)
                                Text("\(winningCount) winning")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.dinkrGreen)
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.dinkrGreen.opacity(0.10))
                            .clipShape(Capsule())
                        }
                        if losingCount > 0 {
                            HStack(spacing: 3) {
                                Circle().fill(Color.dinkrCoral).frame(width: 6, height: 6)
                                Text("\(losingCount) behind")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.dinkrCoral)
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.dinkrCoral.opacity(0.10))
                            .clipShape(Capsule())
                        }
                        if activeCount == 0 && pendingCount == 0 {
                            Text("No active challenges")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            // Pending response urgency banner
            if hasPending {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrCoral)
                    Text("\(pendingCount) challenge\(pendingCount == 1 ? "" : "s") awaiting your response")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrCoral)
                    Spacer()
                    Text("Respond →")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.dinkrCoral)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.dinkrCoral.opacity(0.09))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.dinkrCoral.opacity(0.3), lineWidth: 0.8)
                )
            }

            // Mini avatar pairs
            if !pairs.isEmpty {
                VStack(spacing: 8) {
                    ForEach(pairs.prefix(2)) { pair in
                        ChallengePairRow(pair: pair)
                    }
                }
            }

            // View Challenges CTA
            Button {
                HapticManager.selection()
                showChallenges = true
            } label: {
                HStack {
                    Spacer()
                    Text("View Challenges →")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.vertical, 9)
                .background(
                    LinearGradient(
                        colors: [Color.dinkrAmber, Color.dinkrAmber.opacity(0.75)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: Color.dinkrAmber.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        .onTapGesture {
            HapticManager.selection()
            showChallenges = true
        }
        .sheet(isPresented: $showChallenges) {
            ChallengesView()
        }
    }
}

// MARK: - ChallengePairRow

private struct ChallengePairRow: View {
    let pair: ChallengePairPreview

    private func initials(_ name: String) -> String {
        name.components(separatedBy: " ")
            .compactMap { $0.first.map(String.init) }
            .prefix(2).joined().uppercased()
    }

    var body: some View {
        HStack(spacing: 8) {
            // Challenger avatar
            ZStack {
                Circle()
                    .fill(pair.isUserWinning ? Color.dinkrGreen.opacity(0.2) : Color.dinkrSky.opacity(0.2))
                    .frame(width: 28, height: 28)
                Text(initials(pair.challengerName))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(pair.isUserWinning ? Color.dinkrGreen : Color.dinkrSky)
            }

            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)

            // Challenged avatar
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 28, height: 28)
                Text(initials(pair.challengedName))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("\(pair.challengerName) vs \(pair.challengedName)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if pair.isPending {
                    Text("Pending response")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.dinkrCoral)
                } else if pair.isUserWinning {
                    Text("You're winning")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.dinkrGreen)
                } else {
                    Text("In progress")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            pair.isUserWinning && !pair.isPending
                ? Color.dinkrGreen.opacity(0.06)
                : (pair.isPending ? Color.dinkrCoral.opacity(0.05) : Color.secondary.opacity(0.05))
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - WeekAtAGlanceWidget

struct WeekAtAGlanceWidget: View {
    // Mock data: Tue = 1 game, Thu = 1 game, Sat = 1 upcoming event
    private let calendar = Calendar.current

    /// Returns the Monday that starts the current ISO week
    private var weekStart: Date {
        var comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        comps.weekday = 2 // Monday
        return calendar.date(from: comps) ?? Date()
    }

    /// All 7 days Mon-Sun
    private var weekDays: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    /// Mock game counts: index 1 = Tue (1 game), index 3 = Thu (1 game)
    private func gameCount(for index: Int) -> Int {
        index == 1 ? 1 : index == 3 ? 1 : 0
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    private func isPast(_ date: Date) -> Bool {
        date < Date() && !calendar.isDateInToday(date)
    }

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header pill
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dinkrGreen)
                Text("WEEK AT A GLANCE")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dinkrGreen)
                    .tracking(0.8)
                Spacer()
                // Week date range
                Text(weekRangeLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.dinkrGreen.opacity(0.08))
            .clipShape(Capsule())

            // 7-day strip
            HStack(spacing: 0) {
                ForEach(Array(weekDays.enumerated()), id: \.offset) { idx, day in
                    VStack(spacing: 4) {
                        Text(dayLabels[idx])
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)

                        ZStack {
                            if isToday(day) {
                                // Today: dinkrGreen ring
                                Circle()
                                    .strokeBorder(Color.dinkrGreen, lineWidth: 2)
                                    .frame(width: 34, height: 34)
                            } else if isPast(day) {
                                if gameCount(for: idx) > 0 {
                                    // Past day with games: filled dinkrGreen
                                    Circle()
                                        .fill(Color.dinkrGreen)
                                        .frame(width: 34, height: 34)
                                } else {
                                    // Past day, no games: grey fill
                                    Circle()
                                        .fill(Color.secondary.opacity(0.15))
                                        .frame(width: 34, height: 34)
                                }
                            } else {
                                // Future: grey ring
                                Circle()
                                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1.5)
                                    .frame(width: 34, height: 34)
                            }

                            // Day number
                            Text(dayNumber(day))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(
                                    isPast(day) && gameCount(for: idx) > 0
                                        ? .white
                                        : isToday(day)
                                            ? Color.dinkrGreen
                                            : .primary
                                )

                            // Game count dot (bottom-right)
                            if gameCount(for: idx) > 0 {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Circle()
                                            .fill(isPast(day) ? Color.white : Color.dinkrGreen)
                                            .frame(width: 8, height: 8)
                                            .overlay(
                                                Text("\(gameCount(for: idx))")
                                                    .font(.system(size: 5, weight: .bold))
                                                    .foregroundStyle(isPast(day) ? Color.dinkrGreen : .white)
                                            )
                                    }
                                }
                                .frame(width: 34, height: 34)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Divider()

            // Upcoming events this week
            VStack(alignment: .leading, spacing: 8) {
                Text("THIS WEEK")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)

                // Tue game
                WeekEventRow(icon: "figure.pickleball", color: Color.dinkrGreen, name: "Pickup Game", day: "Tue")
                // Thu game
                WeekEventRow(icon: "figure.pickleball", color: Color.dinkrGreen, name: "Pickup Game", day: "Thu")
                // Sat event
                WeekEventRow(icon: "trophy.fill", color: Color.dinkrAmber, name: "Saturday Tournament", day: "Sat")
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private func dayNumber(_ date: Date) -> String {
        let d = calendar.component(.day, from: date)
        return "\(d)"
    }

    private var weekRangeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let end = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "\(formatter.string(from: weekStart)) – \(formatter.string(from: end))"
    }
}

private struct WeekEventRow: View {
    let icon: String
    let color: Color
    let name: String
    let day: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(color)
            }
            Text(name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
            Spacer()
            Text(day)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())
        }
    }
}

// MARK: - StreakFireWidget

struct StreakFireWidget: View {
    let streak: Int

    private var isCold: Bool { streak == 0 }

    private var gradientColors: [Color] {
        isCold
            ? [Color.dinkrSky.opacity(0.85), Color.dinkrSky.opacity(0.5)]
            : [Color.dinkrAmber, Color(red: 1.0, green: 0.45, blue: 0.1)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(isCold ? "❄️" : "🔥")
                .font(.system(size: 60))
                .padding(.bottom, 2)

            Text("\(streak)")
                .font(.system(size: 46, weight: .heavy, design: .rounded))
                .foregroundStyle(isCold ? Color.dinkrSky : Color.dinkrAmber)

            Text("Day Streak")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))

            Text(isCold ? "Start a streak!" : "Best: 12 days")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: (isCold ? Color.dinkrSky : Color.dinkrAmber).opacity(0.35), radius: 10, x: 0, y: 4)
    }
}

// MARK: - ExploreDinkrWidget
/// Compact 2×2 grid of primary navigation shortcuts.
struct ExploreDinkrWidget: View {
    var onFindCourts: (() -> Void)? = nil
    var onJoinGroups: (() -> Void)? = nil
    var onBrowseEvents: (() -> Void)? = nil
    var onTradeGear: (() -> Void)? = nil

    private struct ExploreCard: Identifiable {
        let id = UUID()
        let emoji: String
        let name: String
        let gradient: [Color]
        let action: (() -> Void)?
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.dinkrAmber)
                Text("Explore Dinkr")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(.primary)
                Spacer()
            }

            // 2×2 grid
            let cards: [ExploreCard] = [
                ExploreCard(
                    emoji: "🏟️", name: "Find Courts",
                    gradient: [Color.dinkrSky.opacity(0.85), Color.dinkrSky.opacity(0.5)],
                    action: onFindCourts
                ),
                ExploreCard(
                    emoji: "👥", name: "Join Groups",
                    gradient: [Color.dinkrGreen.opacity(0.85), Color.dinkrGreen.opacity(0.5)],
                    action: onJoinGroups
                ),
                ExploreCard(
                    emoji: "📅", name: "Browse Events",
                    gradient: [Color.dinkrAmber.opacity(0.85), Color.dinkrAmber.opacity(0.5)],
                    action: onBrowseEvents
                ),
                ExploreCard(
                    emoji: "🛒", name: "Trade Gear",
                    gradient: [Color.dinkrCoral.opacity(0.85), Color.dinkrCoral.opacity(0.5)],
                    action: onTradeGear
                ),
            ]

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(cards) { card in
                    Button {
                        HapticManager.selection()
                        card.action?()
                    } label: {
                        HStack(spacing: 8) {
                            Text(card.emoji)
                                .font(.system(size: 22))
                                .frame(width: 36, height: 36)
                                .background(
                                    LinearGradient(
                                        colors: card.gradient,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            Text(card.name)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            Spacer(minLength: 0)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(Color.appBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

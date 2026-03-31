import SwiftUI

// MARK: - ProfileView

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @Environment(AuthService.self) private var authService
    @State private var selectedTab = 0
    @State private var showShareProfile = false
    @State private var showDUPRVerification = false
    @State private var showSearch = false
    @Namespace private var tabNamespace
    let tabs = ["Overview", "History", "Stats", "Achievements", "Friends"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if let user = viewModel.user {
                        PremiumProfileHeaderView(
                            user: user,
                            currentUserId: authService.currentUser?.id,
                            onEditTapped: { viewModel.showEditProfile = true }
                        )

                        // Custom segmented tab bar
                        PremiumTabBar(tabs: tabs, selectedTab: $selectedTab, namespace: tabNamespace)
                            .padding(.horizontal, 20)
                            .padding(.top, 4)

                        // Tab content
                        switch selectedTab {
                        case 0:
                            ProfileOverviewTab(user: user, viewModel: viewModel)
                        case 1:
                            GameHistoryView(userId: authService.currentUser?.id ?? User.mockCurrentUser.id)
                        case 2:
                            StatsView(user: user)
                        case 3:
                            AchievementsView(user: viewModel.user ?? User.mockCurrentUser, gameResults: viewModel.gameResults)
                        case 4:
                            FollowersListView()
                                .padding(.top, 8)
                        default:
                            EmptyView()
                        }
                    } else {
                        ProgressView()
                            .tint(Color.dinkrGreen)
                            .padding(.top, 80)
                    }
                }
                .padding(.bottom, 32)
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showShareProfile = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Edit Profile") { viewModel.showEditProfile = true }
                        Button("Get Verified") { showDUPRVerification = true }
                        Divider()
                        Button("Sign Out", role: .destructive) {
                            viewModel.signOut(authService: authService)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $viewModel.showEditProfile) {
            EditProfileView(user: viewModel.user ?? User.mockCurrentUser)
        }
        .sheet(isPresented: $showShareProfile) {
            ShareProfileSheet(user: viewModel.user ?? User.mockCurrentUser)
        }
        .sheet(isPresented: $showDUPRVerification) {
            DUPRVerificationView(onVerified: {
                Task { await viewModel.load(authService: authService) }
            })
        }
        .sheet(isPresented: $showSearch) {
            SearchView()
        }
        .task { await viewModel.load(authService: authService) }
    }
}

// MARK: - Premium Profile Header

struct PremiumProfileHeaderView: View {
    let user: User
    /// The ID of the currently signed-in user. Pass `nil` when auth is unavailable.
    var currentUserId: String? = nil
    /// Called when the Edit pill is tapped (only shown when viewing own profile).
    var onEditTapped: (() -> Void)? = nil

    private var isOwnProfile: Bool {
        guard let currentUserId else { return true }
        return currentUserId == user.id
    }

    @State private var drawProgress: Double = 0
    @State private var glowPulse: Bool = false

    // Banner sits behind the avatar; avatar overlaps its bottom edge
    private let bannerHeight: CGFloat = 190

    var body: some View {
        ZStack(alignment: .top) {

            // ── Cover photo banner ──────────────────────────────────────────
            ZStack {
                // Primary dinkrNavy → dinkrGreen gradient
                LinearGradient(
                    colors: [Color.dinkrNavy, Color.dinkrGreen.opacity(0.65)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Subtle secondary diagonal layer for depth
                LinearGradient(
                    colors: [Color.dinkrGreen.opacity(0.18), Color.clear],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                )

                // Animated court lines
                Canvas { ctx, size in
                    let path = headerCourtLinePath(size: size, progress: drawProgress)
                    ctx.stroke(path, with: .color(.white.opacity(0.055)), lineWidth: 1.5)
                }
                .allowsHitTesting(false)

                // Scattered depth circles
                Canvas { ctx, size in
                    let xs: [CGFloat] = [0.08, 0.22, 0.45, 0.60, 0.75, 0.88, 0.35, 0.92]
                    let ys: [CGFloat] = [0.18, 0.72, 0.35, 0.80, 0.25, 0.60, 0.88, 0.42]
                    let rs: [CGFloat] = [28, 18, 34, 14, 24, 10, 20, 16]
                    for i in 0..<xs.count {
                        let x = size.width * xs[i]
                        let y = size.height * ys[i]
                        let r = rs[i]
                        var c = Path()
                        c.addEllipse(in: CGRect(x: x - r/2, y: y - r/2, width: r, height: r))
                        ctx.fill(c, with: .color(.white.opacity(0.025)))
                    }
                }
                .allowsHitTesting(false)

                // Bottom fade to system background
                VStack(spacing: 0) {
                    Spacer()
                    LinearGradient(
                        colors: [Color.clear, Color(UIColor.systemBackground)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 56)
                }
            }
            .frame(height: bannerHeight)
            .frame(maxWidth: .infinity)
            .ignoresSafeArea(edges: .top)

            // ── Content column laid over the banner ─────────────────────────
            VStack(spacing: 0) {
                // Space for status bar / nav bar inside the banner
                Color.clear.frame(height: bannerHeight - 52)

                // Avatar — centre sits at the banner bottom edge, half below
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        // Pulsing glow halo
                        Circle()
                            .fill(Color.dinkrGreen.opacity(glowPulse ? 0.28 : 0.12))
                            .frame(width: 118, height: 118)
                            .blur(radius: 10)
                            .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: glowPulse)

                        // White ring separates avatar from banner
                        Circle()
                            .fill(Color(UIColor.systemBackground))
                            .frame(width: 106, height: 106)

                        // dinkrGreen accent ring
                        Circle()
                            .stroke(Color.dinkrGreen, lineWidth: 3)
                            .frame(width: 100, height: 100)

                        AvatarView(urlString: user.avatarURL, displayName: user.displayName, size: 93)
                            .shadow(color: Color.dinkrNavy.opacity(0.45), radius: 8, x: 0, y: 4)
                    }

                    // Edit pill (own profile) or Follow button (other user)
                    if isOwnProfile {
                        Button(action: { onEditTapped?() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Edit")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial.opacity(0.8))
                            .background(Color.white.opacity(0.15))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        }
                        .offset(x: 4, y: 4)
                    } else if let currentId = currentUserId {
                        FollowButton(
                            currentUserId: currentId,
                            targetUserId: user.id,
                            size: .regular
                        )
                        .offset(x: 4, y: 4)
                    }
                }

                // Name + verified badges
                HStack(spacing: 6) {
                    Text(user.displayName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    if let dupr = user.duprRating, dupr > 0 {
                        VerifiedBadgeSmall(type: .duprVerified)
                    }
                    VerifiedBadgeSmall(type: .identityVerified)
                }
                .padding(.top, 10)

                // @username
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 1)

                // Skill badge + DUPR with trend indicator + city
                HStack(spacing: 8) {
                    SkillBadge(level: user.skillLevel)

                    if let dupr = user.duprRating {
                        // DUPR pill with embedded trend chip
                        HStack(spacing: 5) {
                            Text("DUPR")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(Color.dinkrAmber)
                            Text(String(format: "%.2f", dupr))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.primary)
                            // Skill trend: ↑ rating (+0.15 this month)
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 8, weight: .black))
                                Text("+0.15")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundStyle(Color.dinkrGreen)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.dinkrGreen.opacity(0.14), in: Capsule())
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color.dinkrAmber.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.dinkrAmber.opacity(0.4), lineWidth: 1))
                    }

                    if !user.city.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(user.city)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 6)

                // Bio
                if !user.bio.isEmpty {
                    Text(user.bio)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.horizontal, 40)
                        .padding(.top, 5)
                }

                // Stats row: Games | Wins | Following | Followers — all tappable
                HStack(spacing: 0) {
                    // Games — non-nav column (tap handled upstream by switching to History tab)
                    PremiumStatColumn(value: "\(user.gamesPlayed)", label: "Games")
                    statDivider
                    // Wins
                    PremiumStatColumn(value: "\(user.wins)", label: "Wins")
                    statDivider
                    NavigationLink(destination: FollowersListView()) {
                        PremiumStatChip(value: formattedCount(user.followingCount), label: "Following")
                    }
                    .buttonStyle(.plain)
                    statDivider
                    NavigationLink(destination: FollowersListView()) {
                        PremiumStatChip(value: formattedCount(user.followersCount), label: "Followers")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            glowPulse = true
            withAnimation(.easeInOut(duration: 1.8)) {
                drawProgress = 1.0
            }
        }
    }

    private func formattedCount(_ count: Int) -> String {
        if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.22))
            .frame(width: 1, height: 32)
    }
}

// MARK: - Header court line path

private func headerCourtLinePath(size: CGSize, progress: Double) -> Path {
    var path = Path()
    let w = size.width
    let h = size.height

    // Horizontal baselines
    let horizontals: [CGFloat] = [0.22, 0.42, 0.60, 0.80]
    for ratio in horizontals {
        let y = h * ratio
        let endX = 24 + (w - 48) * progress
        path.move(to: CGPoint(x: 24, y: y))
        path.addLine(to: CGPoint(x: endX, y: y))
    }

    // Side lines
    let sideEndY = h * 0.22 + (h * 0.80 - h * 0.22) * progress
    path.move(to: CGPoint(x: 24, y: h * 0.22))
    path.addLine(to: CGPoint(x: 24, y: sideEndY))
    path.move(to: CGPoint(x: w - 24, y: h * 0.22))
    path.addLine(to: CGPoint(x: w - 24, y: sideEndY))

    // Center line
    let centerEndY = h * 0.22 + (h * 0.80 - h * 0.22) * progress
    path.move(to: CGPoint(x: w / 2, y: h * 0.22))
    path.addLine(to: CGPoint(x: w / 2, y: centerEndY))

    // Kitchen (NVZ) lines
    let nvzTop = h * 0.37
    let nvzBot = h * 0.63
    let nvzEndX = 24 + (w - 48) * progress
    path.move(to: CGPoint(x: 24, y: nvzTop))
    path.addLine(to: CGPoint(x: nvzEndX, y: nvzTop))
    path.move(to: CGPoint(x: 24, y: nvzBot))
    path.addLine(to: CGPoint(x: nvzEndX, y: nvzBot))

    return path
}

// MARK: - Premium Stat Column

struct PremiumStatColumn: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Premium Stat Chip (tappable follower/following count)

struct PremiumStatChip: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            HStack(spacing: 3) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(Color.dinkrGreen.opacity(0.85))
                    .textCase(.uppercase)
                    .tracking(0.5)
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(Color.dinkrGreen.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(Color.dinkrGreen.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.dinkrGreen.opacity(0.22), lineWidth: 1)
        )
        .padding(.horizontal, 6)
    }
}

// MARK: - Premium Tab Bar

struct PremiumTabBar: View {
    let tabs: [String]
    @Binding var selectedTab: Int
    let namespace: Namespace.ID

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = i
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(tabs[i])
                            .font(.subheadline.weight(selectedTab == i ? .bold : .regular))
                            .foregroundStyle(selectedTab == i ? Color.dinkrGreen : Color.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)

                        // Sliding indicator
                        ZStack {
                            if selectedTab == i {
                                Capsule()
                                    .fill(Color.dinkrGreen)
                                    .frame(height: 3)
                                    .matchedGeometryEffect(id: "tabIndicator", in: namespace)
                            } else {
                                Capsule()
                                    .fill(Color.clear)
                                    .frame(height: 3)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

// MARK: - Profile Overview Tab

private struct ProfileOverviewTab: View {
    let user: User
    let viewModel: ProfileViewModel

    @State private var showChallenges = false
    @State private var showDUPRVerification = false

    var body: some View {
        VStack(spacing: 0) {
            // Streak card
            NavigationLink {
                StreakDashboard()
            } label: {
                StreakPreviewCard()
                    .padding(.horizontal, 20)
            }
            .buttonStyle(.plain)
            .padding(.top, 20)

            // ── Highlight Reel ──────────────────────────────────────────
            HighlightReelSection()
                .padding(.top, 16)

            // Monthly Recap entry — Spotify Wrapped-style full-screen experience
            MonthlyRecapButton(stats: .mock(for: user))
                .padding(.horizontal, 20)
                .padding(.top, 12)

            // Challenges card
            Button {
                HapticManager.selection()
                showChallenges = true
            } label: {
                ProfileChallengesCard()
                    .padding(.horizontal, 20)
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
            .sheet(isPresented: $showChallenges) {
                ChallengesView()
            }

            // Recent Activity row
            NavigationLink(destination: RecentActivityView()) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.dinkrSky.opacity(0.14))
                            .frame(width: 48, height: 48)
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.dinkrSky)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Recent Activity")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.primary)
                        Text("Games, achievements, social & more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.dinkrSky.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            // Verification status + Get Verified card
            VerificationStatusCard(user: user, onGetVerified: { showDUPRVerification = true })
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .sheet(isPresented: $showDUPRVerification) {
                    DUPRVerificationView()
                }

            PremiumReputationCard(user: user)
                .padding(.horizontal, 20)
                .padding(.top, 16)

            // Social Links
            if !user.socialLinks.isEmpty {
                SocialLinksCard(links: user.socialLinks)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }

            Divider()
                .padding(.horizontal, 20)
                .padding(.vertical, 20)

            // Posts
            if viewModel.posts.isEmpty {
                EmptyStateView(
                    icon: "square.grid.2x2",
                    title: "No Posts Yet",
                    message: "Share your pickleball moments!"
                )
                .padding(.top, 12)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.posts) { post in
                        PostCardView(post: post, onLike: {}, onComment: {})
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
}

// MARK: - Premium Reputation Card

private struct PremiumReputationCard: View {
    let user: User

    @State private var xpAnimated: Bool = false

    private var level: Int {
        switch user.gamesPlayed {
        case 0..<10: return 1
        case 10..<25: return 2
        case 25..<50: return 3
        case 50..<75: return 4
        case 75..<100: return 5
        case 100..<125: return 6
        case 125..<150: return 7
        case 150..<200: return 8
        case 200..<300: return 9
        default: return 10
        }
    }

    private var levelTitle: String {
        switch level {
        case 1: return "Newbie"
        case 2: return "Rookie"
        case 3: return "Player"
        case 4: return "Regular"
        case 5: return "Competitor"
        case 6: return "Veteran"
        case 7: return "Dinkmaster"
        case 8: return "Court Legend"
        case 9: return "Pro Circuit"
        default: return "Hall of Fame"
        }
    }

    private var xpProgress: Double {
        let thresholds = [0, 10, 25, 50, 75, 100, 125, 150, 200, 300, Int.max]
        let lower = thresholds[level - 1]
        let upper = thresholds[level]
        let progress = Double(user.gamesPlayed - lower) / Double(upper - lower)
        return min(max(progress, 0), 1)
    }

    private var nextLevelGames: Int {
        let thresholds = [0, 10, 25, 50, 75, 100, 125, 150, 200, 300, 500]
        return thresholds[min(level, thresholds.count - 1)]
    }

    var body: some View {
        VStack(spacing: 16) {
            // Level + XP bar
            HStack(spacing: 16) {
                // Level badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.dinkrGreen.opacity(0.25), Color.dinkrSky.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    Circle()
                        .stroke(Color.dinkrGreen.opacity(0.35), lineWidth: 1.5)
                        .frame(width: 64, height: 64)
                    VStack(spacing: 0) {
                        Text("LVL")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(Color.dinkrGreen.opacity(0.8))
                        Text("\(level)")
                            .font(.title2.weight(.heavy))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                }

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 6) {
                        Text("Level \(level) · \(levelTitle)")
                            .font(.subheadline.weight(.bold))
                        if level >= 7 {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundStyle(Color.dinkrAmber)
                        }
                    }

                    // Animated XP gradient bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.12))
                                .frame(height: 9)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.dinkrGreen, Color.dinkrSky],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geo.size.width * (xpAnimated ? xpProgress : 0),
                                    height: 9
                                )
                                .animation(
                                    .spring(response: 1.0, dampingFraction: 0.75).delay(0.2),
                                    value: xpAnimated
                                )
                                .overlay(alignment: .trailing) {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 7, height: 7)
                                        .shadow(color: Color.dinkrGreen.opacity(0.6), radius: 3)
                                        .opacity(xpAnimated && xpProgress > 0.05 ? 1 : 0)
                                }
                        }
                    }
                    .frame(height: 9)

                    Text("\(user.gamesPlayed) games · \(nextLevelGames - user.gamesPlayed) to Level \(level + 1)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.dinkrGreen.opacity(0.3), Color.dinkrSky.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )

            // Stats row with gradient cards
            HStack(spacing: 10) {
                GradientStatCard(
                    value: String(format: "%.1f", user.reliabilityScore),
                    label: "Reliability",
                    icon: "star.fill",
                    gradient: [Color.dinkrAmber.opacity(0.18), Color.dinkrAmber.opacity(0.06)],
                    accentColor: Color.dinkrAmber
                )
                GradientStatCard(
                    value: "\(Int(user.winRate * 100))%",
                    label: "Win Rate",
                    icon: "trophy.fill",
                    gradient: [Color.dinkrGreen.opacity(0.18), Color.dinkrGreen.opacity(0.06)],
                    accentColor: Color.dinkrGreen
                )
                GradientStatCard(
                    value: "\(user.gamesPlayed)",
                    label: "Games",
                    icon: "figure.pickleball",
                    gradient: [Color.dinkrSky.opacity(0.18), Color.dinkrSky.opacity(0.06)],
                    accentColor: Color.dinkrSky
                )
            }

            // Badges
            if !user.badges.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Badges")
                            .font(.subheadline.weight(.bold))
                        Spacer()
                        NavigationLink(destination: BadgeShowcaseView(user: user)) {
                            HStack(spacing: 4) {
                                Text("View All")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.dinkrGreen)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(Color.dinkrGreen.opacity(0.8))
                            }
                        }
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(user.badges) { badge in
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.dinkrAmber.opacity(0.2), Color.dinkrAmber.opacity(0.06)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 50, height: 50)
                                        Circle()
                                            .stroke(Color.dinkrAmber.opacity(0.3), lineWidth: 1)
                                            .frame(width: 50, height: 50)
                                        Image(systemName: "medal.fill")
                                            .foregroundStyle(Color.dinkrAmber)
                                            .font(.title3)
                                    }
                                    Text(badge.label)
                                        .font(.caption2)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 64)
                                        .lineLimit(2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(16)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
            }
        }
        .onAppear {
            xpAnimated = true
        }
    }
}

// MARK: - Gradient Stat Card

private struct GradientStatCard: View {
    let value: String
    let label: String
    let icon: String
    let gradient: [Color]
    let accentColor: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(accentColor)
                .font(.callout)
            Text(value)
                .font(.title3.weight(.heavy))
                .foregroundStyle(accentColor)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Streak Preview Card (enhanced)

struct StreakPreviewCard: View {
    let streak = DailyChallenge.currentStreak
    let completedToday = DailyChallenge.mockChallenges.filter { $0.isCompleted }.count
    let totalToday = DailyChallenge.mockChallenges.count

    @State private var barAnimated = false

    var body: some View {
        HStack(spacing: 14) {
            Text("🔥")
                .font(.system(size: 36))
            VStack(alignment: .leading, spacing: 5) {
                Text("\(streak)-Day Streak")
                    .font(.headline.weight(.bold))
                Text("\(completedToday)/\(totalToday) challenges done today · Tap for details")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.dinkrAmber.opacity(0.18))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color.dinkrAmber, Color.dinkrCoral.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geo.size.width * (barAnimated ? Double(completedToday) / Double(max(totalToday, 1)) : 0),
                                height: 6
                            )
                            .animation(.spring(response: 0.9, dampingFraction: 0.7).delay(0.15), value: barAnimated)
                    }
                }
                .frame(height: 6)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [Color.dinkrAmber.opacity(0.1), Color.dinkrAmber.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.dinkrAmber.opacity(0.28), lineWidth: 1)
                )
        )
        .onAppear { barAnimated = true }
    }
}

// MARK: - Social Links Card

struct SocialLinksCard: View {
    let links: SocialLinks

    struct PlatformLink: Identifiable {
        let id: String
        let icon: String
        let label: String
        let handle: String
        let color: Color
        let urlPrefix: String
    }

    private var platforms: [PlatformLink] {
        var result: [PlatformLink] = []
        if !links.instagram.isEmpty {
            result.append(.init(id: "ig", icon: "camera.fill", label: "Instagram",
                                handle: "@\(links.instagram)", color: Color(red: 0.83, green: 0.19, blue: 0.55),
                                urlPrefix: "https://instagram.com/"))
        }
        if !links.tiktok.isEmpty {
            result.append(.init(id: "tt", icon: "music.note", label: "TikTok",
                                handle: "@\(links.tiktok)", color: .black,
                                urlPrefix: "https://tiktok.com/@"))
        }
        if !links.youtube.isEmpty {
            result.append(.init(id: "yt", icon: "play.rectangle.fill", label: "YouTube",
                                handle: "@\(links.youtube)", color: Color(red: 0.93, green: 0.16, blue: 0.16),
                                urlPrefix: "https://youtube.com/@"))
        }
        if !links.linkedin.isEmpty {
            result.append(.init(id: "li", icon: "briefcase.fill", label: "LinkedIn",
                                handle: links.linkedin, color: Color(red: 0.05, green: 0.46, blue: 0.74),
                                urlPrefix: "https://linkedin.com/in/"))
        }
        if !links.twitter.isEmpty {
            result.append(.init(id: "tw", icon: "text.bubble.fill", label: "X (Twitter)",
                                handle: "@\(links.twitter)", color: .black,
                                urlPrefix: "https://x.com/"))
        }
        if !links.website.isEmpty {
            let display = links.website
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
            result.append(.init(id: "web", icon: "globe", label: "Website",
                                handle: display, color: Color.dinkrSky,
                                urlPrefix: ""))
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "link")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Text("Social & Links")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.3)
            }

            VStack(spacing: 0) {
                ForEach(Array(platforms.enumerated()), id: \.element.id) { idx, platform in
                    Link(destination: URL(string: platform.urlPrefix.isEmpty
                                         ? links.website
                                         : platform.urlPrefix + (platform.id == "tt"
                                            ? links.tiktok
                                            : platform.handle.replacingOccurrences(of: "@", with: "")))
                         ?? URL(string: "https://dinkr.app")!) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(platform.color.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: platform.icon)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(platform.color)
                            }

                            VStack(alignment: .leading, spacing: 1) {
                                Text(platform.label)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.primary)
                                Text(platform.handle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if idx < platforms.count - 1 {
                        Divider().padding(.leading, 64)
                    }
                }
            }
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - StatColumn (kept for any external usage)

struct StatColumn: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.weight(.bold))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Verification Status Card

struct VerificationStatusCard: View {
    let user: User
    var onGetVerified: (() -> Void)? = nil

    // Derive active verified badge types from user data.
    // In production these come from user.verifications flags; here we derive from existing fields.
    private var earnedTypes: [VerifiedBadgeType] {
        var result: [VerifiedBadgeType] = []
        if let dupr = user.duprRating, dupr > 0 {
            result.append(.duprVerified)
        }
        // identity verified: treat mockCurrentUser (user_001) as verified for demo
        if user.id == "user_001" {
            result.append(.identityVerified)
        }
        if user.gamesPlayed >= 100 {
            result.append(.topPlayer)
        }
        return result
    }

    private var isDUPRVerified: Bool {
        earnedTypes.contains(.duprVerified)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dinkrGreen)
                Text("Verification")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.3)
                Spacer()
            }

            if !earnedTypes.isEmpty {
                // Status chips for earned verifications
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(earnedTypes) { type in
                            HStack(spacing: 5) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(type.color)
                                Text(type.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(type.color)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundStyle(type.color.opacity(0.7))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(type.color.opacity(0.1), in: Capsule())
                            .overlay(Capsule().stroke(type.color.opacity(0.3), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }

            // Get Verified row (always shown; label changes if DUPR already verified)
            Button {
                HapticManager.selection()
                onGetVerified?()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                isDUPRVerified
                                    ? Color.dinkrGreen.opacity(0.12)
                                    : Color.dinkrAmber.opacity(0.14)
                            )
                            .frame(width: 40, height: 40)
                        Image(systemName: isDUPRVerified ? "checkmark.seal.fill" : "chart.bar.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isDUPRVerified ? Color.dinkrGreen : Color.dinkrAmber)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isDUPRVerified ? "DUPR Verified" : "Verify Your DUPR Rating")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.primary)
                        Text(isDUPRVerified
                             ? "Your DUPR rating is linked and up to date"
                             : "Link your DUPR account to earn a verified badge")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: isDUPRVerified ? "checkmark.circle.fill" : "chevron.right")
                        .font(.system(size: isDUPRVerified ? 18 : 12, weight: .semibold))
                        .foregroundStyle(isDUPRVerified ? Color.dinkrGreen : Color.secondary)
                }
                .padding(14)
                .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isDUPRVerified ? Color.dinkrGreen.opacity(0.25) : Color.dinkrAmber.opacity(0.22),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }
}

#Preview {
    ProfileView()
        .environment(AuthService())
}

// MARK: - Profile Challenges Card

private struct ProfileChallengesCard: View {
    private var activeChallenges: [Challenge] {
        Challenge.mockChallenges.filter { $0.status == .active }
    }

    private var winningCount: Int {
        activeChallenges.filter { challenge in
            guard let me = challenge.participants.first(where: { $0.id == "user_001" }),
                  let leader = challenge.leadingParticipant else { return false }
            return leader.id == me.id
        }.count
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.dinkrAmber.opacity(0.2), Color.dinkrAmber.opacity(0.1)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.dinkrAmber)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Challenges")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.dinkrNavy)

                HStack(spacing: 8) {
                    Text("\(activeChallenges.count) active")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if winningCount > 0 {
                        HStack(spacing: 3) {
                            Circle().fill(Color.dinkrGreen).frame(width: 6, height: 6)
                            Text("winning \(winningCount)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.dinkrGreen)
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Highlight Reel Section

private struct HighlightItem: Identifiable {
    let id: Int
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color
    let gradient: [Color]
}

/// A horizontal scroll of 3 recent achievement / win highlight cards.
private struct HighlightReelSection: View {

    private let highlights: [HighlightItem] = [
        HighlightItem(
            id: 0,
            icon: "trophy.fill",
            title: "Win Streak",
            subtitle: "5 in a row",
            accent: Color.dinkrAmber,
            gradient: [Color.dinkrAmber.opacity(0.22), Color.dinkrAmber.opacity(0.06)]
        ),
        HighlightItem(
            id: 1,
            icon: "flame.fill",
            title: "Top Player",
            subtitle: "#3 this week",
            accent: Color.dinkrCoral,
            gradient: [Color.dinkrCoral.opacity(0.22), Color.dinkrCoral.opacity(0.06)]
        ),
        HighlightItem(
            id: 2,
            icon: "chart.line.uptrend.xyaxis",
            title: "DUPR Rise",
            subtitle: "+0.15 this month",
            accent: Color.dinkrGreen,
            gradient: [Color.dinkrGreen.opacity(0.22), Color.dinkrGreen.opacity(0.06)]
        ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Highlight Reel")
                    .font(.subheadline.weight(.bold))
                    .padding(.leading, 20)
                Spacer()
                Text("This Month")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 20)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(highlights) { item in
                        ProfileHighlightCard(item: item)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
    }
}

private struct ProfileHighlightCard: View {
    let item: HighlightItem

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: item.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                Circle()
                    .stroke(item.accent.opacity(0.35), lineWidth: 1.5)
                    .frame(width: 44, height: 44)
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(item.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                Text(item.subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(item.accent)
            }
        }
        .padding(16)
        .frame(width: 130)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(item.accent.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: item.accent.opacity(0.12), radius: 8, x: 0, y: 3)
        .scaleEffect(appeared ? 1 : 0.88)
        .opacity(appeared ? 1 : 0)
        .animation(
            .spring(response: 0.45, dampingFraction: 0.72).delay(Double(item.id) * 0.08),
            value: appeared
        )
        .onAppear { appeared = true }
    }
}

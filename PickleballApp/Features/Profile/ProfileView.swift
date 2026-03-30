import SwiftUI

// MARK: - ProfileView

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @Environment(AuthService.self) private var authService
    @State private var selectedTab = 0
    @Namespace private var tabNamespace
    let tabs = ["Overview", "History", "Achievements"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if let user = viewModel.user {
                        PremiumProfileHeaderView(user: user) {
                            viewModel.showEditProfile = true
                        }

                        // Custom segmented tab bar
                        PremiumTabBar(tabs: tabs, selectedTab: $selectedTab, namespace: tabNamespace)
                            .padding(.horizontal, 20)
                            .padding(.top, 4)

                        // Tab content
                        switch selectedTab {
                        case 0:
                            ProfileOverviewTab(user: user, viewModel: viewModel)
                        case 1:
                            GameHistoryView()
                        case 2:
                            AchievementsView()
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
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Edit Profile") { viewModel.showEditProfile = true }
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
        .task { await viewModel.load(authService: authService) }
    }
}

// MARK: - Premium Profile Header

struct PremiumProfileHeaderView: View {
    let user: User
    let onEditTapped: () -> Void

    @State private var drawProgress: Double = 0
    @State private var glowPulse: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Gradient background
            LinearGradient(
                colors: [Color.dinkrNavy, Color.dinkrNavy.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 260)

            // Animated court lines
            Canvas { ctx, size in
                let path = headerCourtLinePath(size: size, progress: drawProgress)
                ctx.stroke(path, with: .color(.white.opacity(0.04)), lineWidth: 1.5)
            }
            .frame(height: 260)
            .allowsHitTesting(false)

            // Gradient fade to background at bottom
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [Color.clear, Color(UIColor.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 48)
            }
            .frame(height: 260)

            // Header content
            VStack(spacing: 0) {
                // Safe area spacer
                Color.clear.frame(height: 56)

                // Avatar + edit button row
                ZStack(alignment: .bottomTrailing) {
                    // Avatar with glow ring
                    ZStack {
                        // Glow halo
                        Circle()
                            .fill(Color.dinkrGreen.opacity(glowPulse ? 0.25 : 0.12))
                            .frame(width: 110, height: 110)
                            .blur(radius: 8)
                            .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: glowPulse)

                        // Green ring border
                        Circle()
                            .stroke(Color.dinkrGreen, lineWidth: 3)
                            .frame(width: 97, height: 97)

                        AvatarView(urlString: user.avatarURL, displayName: user.displayName, size: 90)
                            .shadow(color: Color.dinkrNavy.opacity(0.5), radius: 8, x: 0, y: 4)
                    }

                    // Edit pill button
                    Button(action: onEditTapped) {
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
                }
                .padding(.bottom, 12)

                // Name
                Text(user.displayName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                // @username
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.top, 1)

                // Skill badge + city
                HStack(spacing: 10) {
                    SkillBadge(level: user.skillLevel)

                    if !user.city.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.55))
                            Text(user.city)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.top, 6)

                // Bio
                if !user.bio.isEmpty {
                    Text(user.bio)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(2)
                        .padding(.horizontal, 40)
                        .padding(.top, 6)
                }

                // Stats row
                HStack(spacing: 0) {
                    PremiumStatColumn(value: "\(user.gamesPlayed)", label: "Games")
                    statDivider
                    PremiumStatColumn(value: "\(user.followersCount)", label: "Followers")
                    statDivider
                    PremiumStatColumn(value: "\(user.followingCount)", label: "Following")
                }
                .padding(.horizontal, 32)
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

    private var statDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.18))
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

            // Premium Reputation card
            PremiumReputationCard(user: user)
                .padding(.horizontal, 20)
                .padding(.top, 16)

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
                        PostCardView(post: post, onLike: {})
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
                    Text("Badges")
                        .font(.subheadline.weight(.bold))
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

#Preview {
    ProfileView()
        .environment(AuthService())
}

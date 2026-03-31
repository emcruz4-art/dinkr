import SwiftUI

struct HomeView: View {
    @Environment(AuthService.self) private var authService
    @Environment(LocationService.self) private var locationService
    @State private var viewModel = HomeViewModel()
    @State private var showNotifications = false
    @State private var showMessages = false
    @State private var feedMode = 0
    @State private var showHighlightsFeed = false
    @State private var highlightsFeedCategory: VideoCategory = .all
    @State private var showHostGame = false
    @State private var showFindGame = false
    @State private var showStoriesSheet = false
    @State private var storiesStartIndex: Int = 0
    @State private var showStoryCreator = false
    @State private var showLogResult = false
    @State private var showLiveScoreFeed = false
    @State private var showLiveFeed = false
    @State private var showProfile = false
    @State private var showWeeklyDigest = false
    @State private var showSearch = false
    @State private var noShowService = NoShowService.shared

    // MARK: Rating prompt
    @AppStorage("gamesPlayedCount") private var gamesPlayedCount: Int = 0
    @AppStorage("hasRated") private var hasRated: Bool = false
    @State private var showRatingPrompt = false

    // MARK: Onboarding tips
    @AppStorage("hasSeenTips") private var hasSeenTips: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Rich app background gradient
                LinearGradient(
                    colors: [
                        Color.dinkrNavy.opacity(0.04),
                        Color.appBackground,
                        Color.dinkrGreen.opacity(0.02)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        DinkrHeaderView(
                            city: "Austin",
                            unreadNotificationCount: viewModel.unreadNotificationCount,
                            liveGameCount: viewModel.liveGameCount,
                            onMessagesTap: { showMessages = true },
                            onBellTap: { showNotifications = true },
                            onLiveChipTap: { showLiveFeed = true },
                            onAvatarTap: { showProfile = true },
                            onSearchTap: { showSearch = true }
                        )
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        // Check-in stories bar
                        CheckInStoriesBar(
                            checkIns: CheckInStoriesBar.mockCheckIns,
                            onAddCheckIn: {
                                HapticManager.medium()
                                showStoryCreator = true
                            }
                        )
                        .padding(.top, 6)
                        .onTapGesture {
                            storiesStartIndex = 0
                            showStoriesSheet = true
                        }

                        // For You / Following toggle
                        Picker("Feed", selection: $feedMode) {
                            Text("For You").tag(0)
                            Text("Following").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                        // Bento grid
                        LazyVStack(spacing: 14) {
                            // Hero banner
                            WelcomeHeroWidget(
                                greeting: viewModel.greetingText,
                                gameCount: viewModel.upcomingGameCount,
                                weather: viewModel.weatherSummary
                            )
                            .padding(.horizontal, 16)

                            // Live game activity (only shown when a session is active)
                            if let live = viewModel.liveSession {
                                LiveActivityWidget(session: live)
                                    .padding(.horizontal, 16)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            // Attendance confirmation banner (shown when a past session needs confirming)
                            ForEach(noShowService.pendingPrompts) { prompt in
                                AttendanceBanner(prompt: prompt)
                                    .padding(.horizontal, 16)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            // Quick actions
                            QuickActionsWidget(
                                onHostGame: {
                                    HapticManager.medium()
                                    showHostGame = true
                                },
                                onFindGame: {
                                    HapticManager.selection()
                                    showFindGame = true
                                },
                                onOpenPlay: {
                                    HapticManager.selection()
                                    showFindGame = true
                                },
                                onLogResult: {
                                    HapticManager.medium()
                                    showLogResult = true
                                },
                                onLiveFeed: {
                                    HapticManager.selection()
                                    showLiveScoreFeed = true
                                }
                            )
                            .padding(.horizontal, 16)

                            // Trending games filling fast
                            TrendingGamesWidget(sessions: viewModel.trendingGames)
                                .padding(.horizontal, 16)

                            // Active challenges snapshot
                            ChallengesWidget(
                                activeCount: 3,
                                winningCount: 2,
                                pendingCount: 1,
                                pairs: [
                                    ChallengePairPreview(
                                        id: "cp1",
                                        challengerName: "Alex Rivera",
                                        challengedName: "Jordan Smith",
                                        isPending: false,
                                        isUserWinning: true
                                    ),
                                    ChallengePairPreview(
                                        id: "cp2",
                                        challengerName: "Jamie Lee",
                                        challengedName: "Alex Rivera",
                                        isPending: true,
                                        isUserWinning: false
                                    )
                                ]
                            )
                            .padding(.horizontal, 16)

                            // Featured event + Nearby games
                            HStack(alignment: .top, spacing: 12) {
                                FeaturedEventWidget(event: viewModel.featuredEvent)
                                NearbyGamesWidget(
                                    count: viewModel.nearbyGameCount,
                                    distance: viewModel.nearestDistance
                                )
                                .frame(width: 130)
                            }
                            .padding(.horizontal, 16)

                            // Community spotlight
                            if let spotlight = viewModel.spotlight {
                                CommunitySpotlightWidget(spotlight: spotlight)
                                    .padding(.horizontal, 16)
                            }

                            // News + Players side by side
                            HStack(alignment: .top, spacing: 12) {
                                TopNewsWidget(articles: Array(viewModel.newsArticles.prefix(3)))
                                FindPlayersNearbyWidget(
                                    count: viewModel.nearbyPlayerCount,
                                    newThisWeek: viewModel.newPlayersThisWeek,
                                    onMatch: {
                                        HapticManager.selection()
                                        showFindGame = true
                                    }
                                )
                                .frame(width: 130)
                            }
                            .padding(.horizontal, 16)

                            // Groups horizontal scroll
                            MyGroupsWidget(groupInfos: [
                                GroupInfo(id: "g1", name: viewModel.myGroups.indices.contains(0) ? viewModel.myGroups[0] : "Austin Picklers",
                                          unreadCount: 3, isRecentlyActive: true, nextGameLabel: "Next game: Sun 9AM"),
                                GroupInfo(id: "g2", name: viewModel.myGroups.indices.contains(1) ? viewModel.myGroups[1] : "Westside Crew",
                                          unreadCount: 0, isRecentlyActive: false, nextGameLabel: "Next game: Tue 7PM"),
                                GroupInfo(id: "g3", name: viewModel.myGroups.indices.contains(2) ? viewModel.myGroups[2] : "Mueller Regulars",
                                          unreadCount: 7, isRecentlyActive: true, nextGameLabel: nil),
                            ])
                            .padding(.horizontal, 16)

                            // Daily pickleball tip
                            DailyTipWidget()
                                .padding(.horizontal, 16)

                            // Explore
                            ExploreSection()
                                .padding(.horizontal, 16)

                            // Explore Dinkr shortcuts (compact 2×2)
                            ExploreDinkrWidget()
                                .padding(.horizontal, 16)

                            // Women's corner + Court vibes + Streak
                            HStack(alignment: .top, spacing: 12) {
                                WomensCornerWidget()
                                VStack(spacing: 12) {
                                    StreakFireWidget(streak: viewModel.currentStreak)
                                    CourtVibesWidget(weather: viewModel.weather)
                                }
                            }
                            .padding(.horizontal, 16)

                            // Weekend Forecast (full width)
                            WeekendForecastWidget(
                                days: viewModel.weekendForecast,
                                weekendDays: viewModel.weekendDays
                            )
                            .padding(.horizontal, 16)

                            // Video Highlights
                            VideoHighlightsWidget(
                                videos: viewModel.videoHighlights,
                                onWatchAll: {
                                    highlightsFeedCategory = .all
                                    showHighlightsFeed = true
                                },
                                onWatchVideo: { _ in
                                    highlightsFeedCategory = .all
                                    showHighlightsFeed = true
                                }
                            )
                            .padding(.horizontal, 16)

                            // Week at a Glance
                            WeekAtAGlanceWidget()
                                .padding(.horizontal, 16)

                            // This Week digest banner
                            Button {
                                HapticManager.medium()
                                showWeeklyDigest = true
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.dinkrNavy, Color.dinkrNavy.opacity(0.75)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 48, height: 48)
                                        Image(systemName: "calendar.badge.checkmark")
                                            .font(.system(size: 22))
                                            .foregroundStyle(Color.dinkrGreen)
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Your Week in Pickleball")
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(Color.primary)
                                        Text("3 games · 67% win rate · See your highlights →")
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
                                        .stroke(Color.dinkrNavy.opacity(0.18), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)

                            // Feed preview
                            FeedPreviewWidget(
                                posts: Array(viewModel.posts.prefix(3)),
                                onLike: { viewModel.likePost($0, userId: viewModel.currentUserId ?? "") }
                            )
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 36)
                    }
                }
                .refreshable { await viewModel.loadFeed() }
                .navigationBarHidden(true)

                // Onboarding tips overlay — shown once for new users
                if !hasSeenTips {
                    QuickTipsView(spotlightFrames: [])
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: hasSeenTips)
                        .zIndex(10)
                }
            }
        }
        .sheet(isPresented: $showRatingPrompt) {
            AppRatingPromptView()
        }
        .sheet(isPresented: $showSearch) {
            SearchView()
        }
        .sheet(isPresented: $viewModel.showCreatePost) {
            CreatePostView()
        }
        .sheet(isPresented: $showHostGame) {
            HostGameView()
        }
        .sheet(isPresented: $showFindGame) {
            NearbyGamesView(viewModel: PlayViewModel())
        }
        .sheet(isPresented: $showNotifications) {
            NotificationCenterView()
        }
        .sheet(isPresented: $showMessages) {
            MessagesView()
                .environment(authService)
        }
        .sheet(isPresented: $showLogResult) {
            LogGameResultView()
        }
        .sheet(isPresented: $showLiveScoreFeed) {
            NavigationStack {
                LiveScoreFeedView()
            }
        }
        .sheet(isPresented: $showLiveFeed) {
            NavigationStack {
                LiveScoreFeedView()
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
                .environment(authService)
        }
        .fullScreenCover(isPresented: $showWeeklyDigest) {
            WeeklyDigestView()
        }
        .fullScreenCover(isPresented: $showStoriesSheet) {
            CheckInDetailView(stories: CheckInStory.mock, startIndex: storiesStartIndex)
        }
        .fullScreenCover(isPresented: $showStoryCreator) {
            StoryCreatorView()
        }
        .fullScreenCover(isPresented: $showHighlightsFeed) {
            VideoHighlightsFeedView(initialCategory: highlightsFeedCategory)
        }
        .task {
            await viewModel.loadFeed()
            let lat = locationService.currentLocation?.coordinate.latitude ?? 30.2672
            let lon = locationService.currentLocation?.coordinate.longitude ?? -97.7431
            await viewModel.fetchWeather(latitude: lat, longitude: lon)
            await viewModel.loadVideoHighlights()
            let userId = authService.currentUser?.id ?? User.mockCurrentUser.id
            await noShowService.loadPendingPrompts(for: userId)

            // Show rating prompt after 5+ games if user hasn't rated yet
            if AppRatingPromptView.shouldPrompt(gamesPlayed: gamesPlayedCount, hasRated: hasRated) {
                // Brief delay so the feed settles before the sheet appears
                try? await Task.sleep(for: .seconds(1.5))
                showRatingPrompt = true
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(AuthService())
        .environment(LocationService())
}

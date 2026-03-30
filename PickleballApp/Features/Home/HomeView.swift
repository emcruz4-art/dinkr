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
                        DinkrHeaderView(city: "Austin", onMessagesTap: { showMessages = true })
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        // Check-in stories bar
                        CheckInStoriesBar(checkIns: CheckInStoriesBar.mockCheckIns)
                            .padding(.top, 6)

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
                                gameCount: viewModel.upcomingGameCount
                            )
                            .padding(.horizontal, 16)

                            // Quick actions
                            QuickActionsWidget()
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
                                    newThisWeek: viewModel.newPlayersThisWeek
                                )
                                .frame(width: 130)
                            }
                            .padding(.horizontal, 16)

                            // Groups horizontal scroll
                            MyGroupsWidget(groups: viewModel.myGroups)
                                .padding(.horizontal, 16)

                            // Explore
                            ExploreSection()
                                .padding(.horizontal, 16)

                            // Women's corner + Court vibes
                            HStack(alignment: .top, spacing: 12) {
                                WomensCornerWidget()
                                CourtVibesWidget(weather: viewModel.weather)
                            }
                            .padding(.horizontal, 16)

                            // Weekend Forecast (full width)
                            WeekendForecastWidget(days: viewModel.weekendForecast)
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
            }
        }
        .sheet(isPresented: $viewModel.showCreatePost) {
            CreatePostView()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationCenterView()
        }
        .sheet(isPresented: $showMessages) {
            MessagesView()
                .environment(authService)
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
        }
    }
}

#Preview {
    HomeView()
        .environment(AuthService())
        .environment(LocationService())
}

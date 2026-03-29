import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var showNotifications = false
    @State private var feedMode = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    DinkrHeaderView(city: "Austin")
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Instagram-style check-in stories bar
                    CheckInStoriesBar(checkIns: CheckInStoriesBar.mockCheckIns)
                        .padding(.top, 4)

                    // For You / Following toggle
                    Picker("Feed", selection: $feedMode) {
                        Text("For You").tag(0)
                        Text("Following").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    LazyVStack(spacing: 12) {
                        WelcomeHeroWidget(greeting: viewModel.greetingText,
                                         gameCount: viewModel.upcomingGameCount)
                            .padding(.horizontal)

                        QuickActionsWidget()
                            .padding(.horizontal)

                        HStack(spacing: 10) {
                            FeaturedEventWidget(event: viewModel.featuredEvent)
                            NearbyGamesWidget(count: viewModel.nearbyGameCount,
                                             distance: viewModel.nearestDistance)
                        }
                        .padding(.horizontal)

                        if let spotlight = viewModel.spotlight {
                            CommunitySpotlightWidget(spotlight: spotlight)
                                .padding(.horizontal)
                        }

                        HStack(spacing: 10) {
                            TopNewsWidget(articles: Array(viewModel.newsArticles.prefix(3)))
                            FindPlayersNearbyWidget(count: viewModel.nearbyPlayerCount,
                                                   newThisWeek: viewModel.newPlayersThisWeek)
                        }
                        .padding(.horizontal)

                        MyGroupsWidget(groups: viewModel.myGroups)
                            .padding(.horizontal)

                        ExploreSection()
                            .padding(.horizontal)

                        HStack(spacing: 10) {
                            WomensCornerWidget()
                            CourtVibesWidget()
                        }
                        .padding(.horizontal)

                        FeedPreviewWidget(posts: Array(viewModel.posts.prefix(3)),
                                         onLike: { viewModel.likePost($0) })
                            .padding(.horizontal)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .refreshable { await viewModel.loadFeed() }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $viewModel.showCreatePost) {
            CreatePostView()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationCenterView()
        }
        .task { await viewModel.loadFeed() }
    }
}

#Preview {
    HomeView()
        .environment(AuthService())
}

import SwiftUI

struct RootTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.icon) }
                .tag(AppTab.home)

            PlayView()
                .tabItem { Label(AppTab.play.title, systemImage: AppTab.play.icon) }
                .tag(AppTab.play)

            GroupsView()
                .tabItem { Label(AppTab.groups.title, systemImage: AppTab.groups.icon) }
                .tag(AppTab.groups)

            EventsView()
                .tabItem { Label(AppTab.events.title, systemImage: AppTab.events.icon) }
                .tag(AppTab.events)

            MarketView()
                .tabItem { Label(AppTab.market.title, systemImage: AppTab.market.icon) }
                .tag(AppTab.market)

            ProfileView()
                .tabItem { Label(AppTab.profile.title, systemImage: AppTab.profile.icon) }
                .tag(AppTab.profile)
        }
        .tint(Color.dinkrGreen)
    }
}

enum AppTab: String, CaseIterable {
    case home, play, groups, events, market, profile

    var title: String {
        switch self {
        case .home: return "Home"
        case .play: return "Play"
        case .groups: return "Groups"
        case .events: return "Events"
        case .market: return "Market"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .play: return "figure.pickleball"
        case .groups: return "person.3.fill"
        case .events: return "calendar"
        case .market: return "tag.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

#Preview {
    RootTabView()
        .environment(AuthService())
        .environment(LocationService())
}

import SwiftUI

// MARK: - BadgeStore

/// Holds badge counts for tab items. In production, drive these from
/// NotificationService / real-time listeners. Mock values are used here.
@Observable
final class BadgeStore {
    static let shared = BadgeStore()

    var unreadNotifications: Int = 3   // Home tab
    var upcomingGamesToday: Int  = 1   // Play tab
    var unreadMessages: Int      = 4   // (reserved — no dedicated Messages tab yet)

    private init() {}
}

// MARK: - ScrollToTopTrigger

/// Published when a tab is re-selected so child views can scroll to top.
@Observable
final class ScrollToTopTrigger {
    static let shared = ScrollToTopTrigger()
    var tappedTab: AppTab?
    private init() {}
}

// MARK: - RootTabView

struct RootTabView: View {
    @State private var router      = TabRouter.shared
    @State private var badges      = BadgeStore.shared
    @State private var scrollTrig  = ScrollToTopTrigger.shared
    @State private var showCreatePost = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $router.selectedTab) {
                HomeView()
                    .tag(AppTab.home)
                    .toolbar(.hidden, for: .tabBar)
                    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 80) }

                PlayView()
                    .tag(AppTab.play)
                    .toolbar(.hidden, for: .tabBar)
                    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 80) }

                GroupsView()
                    .tag(AppTab.groups)
                    .toolbar(.hidden, for: .tabBar)
                    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 80) }

                EventsView()
                    .tag(AppTab.events)
                    .toolbar(.hidden, for: .tabBar)
                    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 80) }

                MarketView()
                    .tag(AppTab.market)
                    .toolbar(.hidden, for: .tabBar)
                    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 80) }

                ProfileView()
                    .tag(AppTab.profile)
                    .toolbar(.hidden, for: .tabBar)
                    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 80) }
            }
            .tint(Color.dinkrGreen)

            FloatingTabBar(
                selectedTab: $router.selectedTab,
                badges: badges,
                scrollTrig: scrollTrig,
                showCreatePost: $showCreatePost
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .ignoresSafeArea(.keyboard)
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showCreatePost) {
            CreatePostView()
        }
        .sheet(isPresented: $router.showSearch) {
            SearchView()
        }
        .toastContainer()
        .environment(ToastManager.shared)
        .environment(badges)
        .environment(scrollTrig)
        .whatIsNewSheet()
        .onAppear {
            configureTabBarBlur()
        }
    }

    // MARK: - UITabBarAppearance (blurred background)

    private func configureTabBarBlur() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        appearance.shadowColor = .clear

        let selectedColor = UIColor(red: 0.18, green: 0.74, blue: 0.38, alpha: 1)
        let unselectedColor = UIColor.tertiaryLabel

        for itemAppearance in [
            appearance.stackedLayoutAppearance,
            appearance.inlineLayoutAppearance,
            appearance.compactInlineLayoutAppearance,
        ] {
            itemAppearance.selected.iconColor = selectedColor
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
            itemAppearance.normal.iconColor = unselectedColor
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: unselectedColor]
        }

        UITabBar.appearance().standardAppearance   = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - FloatingTabBar

struct FloatingTabBar: View {
    @Binding var selectedTab: AppTab
    let badges: BadgeStore
    let scrollTrig: ScrollToTopTrigger
    @Binding var showCreatePost: Bool

    var body: some View {
        HStack(spacing: 0) {
            ForEach([AppTab.home, .play, .groups], id: \.self) { tab in
                FloatingTabItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    badgeCount: badgeCount(for: tab),
                    scrollTrig: scrollTrig
                ) {
                    handleTap(tab)
                }
            }

            // Center FAB
            Button {
                showCreatePost = true
                HapticManager.medium()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen)
                        .frame(width: 52, height: 52)
                        .shadow(color: Color.dinkrGreen.opacity(0.3), radius: 8, x: 0, y: 3)
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .offset(y: -8)
            .frame(maxWidth: .infinity)

            ForEach([AppTab.events, .market, .profile], id: \.self) { tab in
                FloatingTabItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    badgeCount: badgeCount(for: tab),
                    scrollTrig: scrollTrig
                ) {
                    handleTap(tab)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    // MARK: Helpers

    private func handleTap(_ tab: AppTab) {
        if selectedTab == tab {
            // Double-tap: signal scroll-to-top
            scrollTrig.tappedTab = tab
            HapticManager.selection()
        } else {
            selectedTab = tab
            HapticManager.selection()
        }
    }

    private func badgeCount(for tab: AppTab) -> Int {
        switch tab {
        case .home:    return badges.unreadNotifications
        case .play:    return badges.upcomingGamesToday
        default:       return 0
        }
    }
}

// MARK: - FloatingTabItem

struct FloatingTabItem: View {
    let tab: AppTab
    let isSelected: Bool
    let badgeCount: Int
    let scrollTrig: ScrollToTopTrigger
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.dinkrGreen : Color.secondary)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

                    if badgeCount > 0 {
                        TabBadgeView(count: badgeCount)
                            .offset(x: 8, y: -6)
                    }
                }

                Text(tab.title)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.dinkrGreen : Color.secondary)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// MARK: - TabBadgeView

private struct TabBadgeView: View {
    let count: Int

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.dinkrCoral)
                .frame(width: count < 10 ? 16 : 22, height: 16)
            Text(count < 100 ? "\(count)" : "99+")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
        }
        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: count)
    }
}

// MARK: - AppTab

enum AppTab: String, CaseIterable {
    case home, play, groups, events, market, profile

    var title: String {
        switch self {
        case .home:    return "Home"
        case .play:    return "Play"
        case .groups:  return "Groups"
        case .events:  return "Events"
        case .market:  return "Market"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home:    return "house.fill"
        case .play:    return "figure.pickleball"
        case .groups:  return "person.3.fill"
        case .events:  return "calendar.badge.plus"
        case .market:  return "bag.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

#Preview {
    RootTabView()
        .environment(AuthService())
        .environment(LocationService())
}

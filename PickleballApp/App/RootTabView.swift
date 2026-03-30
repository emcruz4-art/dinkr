import SwiftUI

// MARK: - RootTabView

struct RootTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showCreatePost = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
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

            FloatingTabBar(selectedTab: $selectedTab, showCreatePost: $showCreatePost)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .ignoresSafeArea(.keyboard)
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showCreatePost) {
            CreatePostView()
        }
    }
}

// MARK: - FloatingTabBar

struct FloatingTabBar: View {
    @Binding var selectedTab: AppTab
    @Binding var showCreatePost: Bool

    var body: some View {
        HStack(spacing: 0) {
            ForEach([AppTab.home, .play, .groups], id: \.self) { tab in
                FloatingTabItem(tab: tab, isSelected: selectedTab == tab) {
                    selectedTab = tab
                    HapticManager.selection()
                }
            }

            // Center FAB
            Button {
                showCreatePost = true
                HapticManager.medium()
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.82)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: Color.dinkrGreen.opacity(0.45), radius: 10, x: 0, y: 4)
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .offset(y: -8)
            .frame(maxWidth: .infinity)

            ForEach([AppTab.events, .market, .profile], id: \.self) { tab in
                FloatingTabItem(tab: tab, isSelected: selectedTab == tab) {
                    selectedTab = tab
                    HapticManager.selection()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
    }
}

// MARK: - FloatingTabItem

struct FloatingTabItem: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.dinkrGreen : Color.secondary)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

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
                .onEnded { _ in isPressed = false }
        )
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
        case .events:  return "calendar"
        case .market:  return "tag.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

#Preview {
    RootTabView()
        .environment(AuthService())
        .environment(LocationService())
}

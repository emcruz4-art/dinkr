import SwiftUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @Environment(AuthService.self) private var authService
    @State private var selectedTab = 0
    let tabs = ["Overview", "History", "Achievements"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if let user = viewModel.user {
                        ProfileHeaderView(user: user)

                        // Tab bar
                        HStack(spacing: 0) {
                            ForEach(tabs.indices, id: \.self) { i in
                                Button {
                                    selectedTab = i
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(tabs[i])
                                            .font(.subheadline.weight(selectedTab == i ? .bold : .regular))
                                            .foregroundStyle(selectedTab == i ? Color.dinkrGreen : .secondary)
                                        Rectangle()
                                            .fill(selectedTab == i ? Color.dinkrGreen : Color.clear)
                                            .frame(height: 2)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)

                        Divider()

                        switch selectedTab {
                        case 0:
                            // Overview: reputation + posts
                            VStack(spacing: 0) {
                                NavigationLink {
                                    StreakDashboard()
                                } label: {
                                    StreakPreviewCard()
                                        .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 16)

                                ReputationView(user: user)
                                    .padding(.horizontal)
                                    .padding(.top, 16)

                                Divider().padding(.vertical, 16)

                                if viewModel.posts.isEmpty {
                                    EmptyStateView(
                                        icon: "square.grid.2x2",
                                        title: "No Posts Yet",
                                        message: "Share your pickleball moments!"
                                    )
                                } else {
                                    LazyVStack(spacing: 12) {
                                        ForEach(viewModel.posts) { post in
                                            PostCardView(post: post, onLike: {})
                                                .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                        case 1:
                            GameHistoryView()
                        case 2:
                            AchievementsView()
                        default:
                            EmptyView()
                        }
                    } else {
                        ProgressView().padding(.top, 60)
                    }
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Profile")
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
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showEditProfile) {
            EditProfileView(user: viewModel.user ?? User.mockCurrentUser)
        }
        .task { await viewModel.load(authService: authService) }
    }
}

struct ProfileHeaderView: View {
    let user: User

    var body: some View {
        VStack(spacing: 12) {
            AvatarView(urlString: user.avatarURL, displayName: user.displayName, size: 88)
            Text(user.displayName).font(.title2.weight(.bold))
            Text("@\(user.username)").font(.subheadline).foregroundStyle(.secondary)
            if !user.bio.isEmpty {
                Text(user.bio)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
            }

            HStack(spacing: 32) {
                StatColumn(value: "\(user.gamesPlayed)", label: "Games")
                StatColumn(value: "\(user.followersCount)", label: "Followers")
                StatColumn(value: "\(user.followingCount)", label: "Following")
            }
            .padding(.top, 4)

            HStack(spacing: 8) {
                SkillBadge(level: user.skillLevel)
                Label(user.city, systemImage: "mappin")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

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

struct StreakPreviewCard: View {
    let streak = DailyChallenge.currentStreak
    let completedToday = DailyChallenge.mockChallenges.filter { $0.isCompleted }.count
    let totalToday = DailyChallenge.mockChallenges.count

    var body: some View {
        HStack(spacing: 14) {
            Text("🔥")
                .font(.system(size: 36))
            VStack(alignment: .leading, spacing: 4) {
                Text("\(streak)-Day Streak")
                    .font(.headline.weight(.bold))
                Text("\(completedToday)/\(totalToday) challenges done today · Tap for details")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.dinkrAmber.opacity(0.2))
                        RoundedRectangle(cornerRadius: 4).fill(Color.dinkrAmber)
                            .frame(width: geo.size.width * Double(completedToday) / Double(max(totalToday, 1)))
                    }
                }
                .frame(height: 5)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding(14)
        .background(Color.dinkrAmber.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.dinkrAmber.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ProfileView()
        .environment(AuthService())
}

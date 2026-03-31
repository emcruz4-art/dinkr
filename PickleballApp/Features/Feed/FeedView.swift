import SwiftUI

// MARK: - FeedTab

private enum FeedTab: String, CaseIterable {
    case forYou     = "For You"
    case following  = "Following"
}

// MARK: - FeedView

struct FeedView: View {
    @Environment(AuthService.self) private var authService

    // Feed state
    @State private var posts: [Post] = Post.mockPosts
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var pageCount = 1

    // Tab & filter state
    @State private var selectedTab: FeedTab = .forYou
    @State private var filterOptions = FeedFilterOptions()
    @State private var showFilterSheet = false

    // Create post sheet
    @State private var showCreatePost = false

    // Filter button pulse animation
    @State private var filterButtonPulse = false

    private var activeFilterCount: Int { filterOptions.activeCount }

    private var filteredPosts: [Post] {
        var result = posts

        // Following tab: filter to a subset (mock: posts with groupId)
        if selectedTab == .following {
            result = result.filter { $0.groupId != nil || $0.likes > 50 }
        }

        // Post type filter
        if !filterOptions.selectedPostTypes.isEmpty {
            result = result.filter { filterOptions.selectedPostTypes.contains($0.postType) }
        }

        // Time range filter
        let now = Date()
        switch filterOptions.timeRange {
        case .today:
            result = result.filter { Calendar.current.isDateInToday($0.createdAt) }
        case .thisWeek:
            let weekAgo = now.addingTimeInterval(-7 * 86400)
            result = result.filter { $0.createdAt >= weekAgo }
        case .thisMonth:
            let monthAgo = now.addingTimeInterval(-30 * 86400)
            result = result.filter { $0.createdAt >= monthAgo }
        case .allTime:
            break
        }

        // Sort
        switch filterOptions.sortBy {
        case .mostRecent:
            result.sort { $0.createdAt > $1.createdAt }
        case .mostLiked:
            result.sort { $0.likes > $1.likes }
        case .mostCommented:
            result.sort { $0.commentCount > $1.commentCount }
        case .trending:
            result.sort { lhs, rhs in
                let scoreL = lhs.likes + lhs.commentCount * 2
                let scoreR = rhs.likes + rhs.commentCount * 2
                return scoreL > scoreR
            }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
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

                if isLoading {
                    loadingSkeleton
                } else if filteredPosts.isEmpty {
                    emptyState
                } else {
                    feedList
                }

                // FAB — Create Post
                createPostFAB
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showFilterSheet) {
                FeedFilterSheet(options: $filterOptions)
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostView(
                    authorId: authService.currentUser?.id ?? "me",
                    authorName: authService.currentUser?.displayName ?? "You",
                    authorAvatarURL: authService.currentUser?.avatarURL
                )
            }
            .onChange(of: activeFilterCount) { _, newCount in
                guard newCount > 0 else { return }
                withAnimation(.easeInOut(duration: 0.2).repeatCount(2, autoreverses: true)) {
                    filterButtonPulse = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    filterButtonPulse = false
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            filterButton
        }
    }

    private var filterButton: some View {
        Button {
            HapticManager.medium()
            showFilterSheet = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "line.3.horizontal.decrease.circle\(activeFilterCount > 0 ? ".fill" : "")")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(activeFilterCount > 0 ? Color.dinkrGreen : Color.primary)
                    .scaleEffect(filterButtonPulse ? 1.18 : 1.0)

                if activeFilterCount > 0 {
                    Text("\(activeFilterCount)")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.dinkrCoral, in: Capsule())
                        .offset(x: 6, y: -6)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: filterButtonPulse)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: activeFilterCount)
    }

    // MARK: - FAB

    private var createPostFAB: some View {
        Button {
            HapticManager.medium()
            showCreatePost = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .bold))
                Text("Post")
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Capsule()
            )
            .shadow(color: Color.dinkrGreen.opacity(0.45), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20)
        .padding(.bottom, 24)
    }

    // MARK: - Feed list

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {

                // Stories bar
                CheckInStoriesBar(checkIns: CheckInStoriesBar.mockCheckIns)
                    .padding(.top, 4)
                    .padding(.bottom, 8)

                // Tab switcher
                tabSwitcher
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                // Active filter strip
                if activeFilterCount > 0 {
                    activeFilterStrip
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Post cards
                ForEach(filteredPosts) { post in
                    PostCardView(
                        post: post,
                        onLike: { likePost(post) },
                        onComment: {}
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }

                // Infinite scroll footer
                infiniteScrollFooter
                    .padding(.horizontal, 16)
                    .padding(.bottom, 90)  // room for FAB + tab bar
            }
            .padding(.top, 4)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: activeFilterCount)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
        }
        .refreshable { await refreshFeed() }
    }

    // MARK: - Tab Switcher

    private var tabSwitcher: some View {
        HStack(spacing: 0) {
            ForEach(FeedTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                    HapticManager.selection()
                } label: {
                    VStack(spacing: 4) {
                        Text(tab.rawValue)
                            .font(.subheadline.weight(selectedTab == tab ? .bold : .regular))
                            .foregroundStyle(selectedTab == tab ? Color.dinkrNavy : Color.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)

                        Capsule()
                            .fill(selectedTab == tab ? Color.dinkrGreen : Color.clear)
                            .frame(height: 3)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Infinite Scroll Footer

    @ViewBuilder
    private var infiniteScrollFooter: some View {
        if isLoadingMore {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(Color.dinkrGreen)
                Text("Loading more...")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        } else if pageCount < 3 {
            Button {
                Task { await loadMorePosts() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Load More")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Color.dinkrGreen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.dinkrGreen.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.dinkrGreen.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        } else {
            VStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.dinkrGreen.opacity(0.5))
                Text("You're all caught up!")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }

    // MARK: - Active filter strip

    private var activeFilterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.dinkrGreen)

                Text("\(activeFilterCount) filter\(activeFilterCount == 1 ? "" : "s") active")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrNavy)

                Divider().frame(height: 14)

                if !filterOptions.selectedPostTypes.isEmpty {
                    ForEach(Array(filterOptions.selectedPostTypes), id: \.self) { type in
                        activeFilterPill(label: type.filterLabel, color: type.filterColor) {
                            withAnimation { _ = filterOptions.selectedPostTypes.remove(type) }
                        }
                    }
                }

                if filterOptions.timeRange != .allTime {
                    activeFilterPill(label: filterOptions.timeRange.rawValue, color: Color.dinkrAmber) {
                        withAnimation { filterOptions.timeRange = .allTime }
                    }
                }

                if filterOptions.location != .all {
                    activeFilterPill(label: filterOptions.location.rawValue, color: Color.dinkrCoral) {
                        withAnimation { filterOptions.location = .all }
                    }
                }

                if filterOptions.sortBy != .mostRecent {
                    activeFilterPill(label: filterOptions.sortBy.rawValue, color: Color.dinkrSky) {
                        withAnimation { filterOptions.sortBy = .mostRecent }
                    }
                }

                if filterOptions.skillMin != .beginner20 || filterOptions.skillMax != .pro50 {
                    activeFilterPill(
                        label: "\(filterOptions.skillMin.label)–\(filterOptions.skillMax.label)",
                        color: Color.dinkrGreen
                    ) {
                        withAnimation {
                            filterOptions.skillMin = .beginner20
                            filterOptions.skillMax = .pro50
                        }
                    }
                }

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        filterOptions = .default
                    }
                    HapticManager.selection()
                } label: {
                    Text("Clear All")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.dinkrCoral)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.dinkrCoral.opacity(0.08), in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Material.ultraThinMaterial))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.dinkrGreen.opacity(0.2) as Color, lineWidth: 1)
        )
    }

    private func activeFilterPill(label: String, color: Color, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(color)
            Button(action: {
                onRemove()
                HapticManager.selection()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(color)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(color.opacity(0.1), in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Loading skeleton

    private var loadingSkeleton: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { _ in
                    FeedPostCardSkeleton()
                        .padding(.horizontal, 16)
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(Color.dinkrGreen.opacity(0.5))

            VStack(spacing: 8) {
                Text("No Posts Found")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.dinkrNavy)
                Text("Try adjusting your filters or check back later.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if activeFilterCount > 0 {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        filterOptions = .default
                    }
                    HapticManager.medium()
                } label: {
                    Label("Clear All Filters", systemImage: "xmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.dinkrGreen, in: Capsule())
                        .shadow(color: Color.dinkrGreen.opacity(0.3), radius: 6, y: 2)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func likePost(_ post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            let userId = authService.currentUser?.id ?? ""
            let isCurrentlyLiked = posts[index].likedBy.contains(userId)
            if isCurrentlyLiked {
                posts[index].likedBy.removeAll { $0 == userId }
                posts[index].isLiked = false
                posts[index].likes = max(0, posts[index].likes - 1)
            } else {
                if !userId.isEmpty { posts[index].likedBy.append(userId) }
                posts[index].isLiked = true
                posts[index].likes += 1
            }
        }
    }

    private func refreshFeed() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 800_000_000)
        pageCount = 1
        // In production this would fetch from FirestoreService
        isLoading = false
    }

    private func loadMorePosts() async {
        guard !isLoadingMore, pageCount < 3 else { return }
        isLoadingMore = true
        try? await Task.sleep(nanoseconds: 900_000_000)
        // In production: append next page from Firestore with cursor pagination
        pageCount += 1
        isLoadingMore = false
    }
}

// MARK: - PostCardSkeleton

private struct FeedPostCardSkeleton: View {
    @State private var shimmer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(shimmerGradient)
                    .frame(width: 42, height: 42)
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(shimmerGradient)
                        .frame(width: 120, height: 12)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(shimmerGradient)
                        .frame(width: 70, height: 10)
                }
                Spacer()
                RoundedRectangle(cornerRadius: 10)
                    .fill(shimmerGradient)
                    .frame(width: 54, height: 22)
            }
            RoundedRectangle(cornerRadius: 4).fill(shimmerGradient).frame(height: 12)
            RoundedRectangle(cornerRadius: 4).fill(shimmerGradient).frame(height: 12).padding(.trailing, 40)
            RoundedRectangle(cornerRadius: 4).fill(shimmerGradient).frame(width: 160, height: 12)
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 4).fill(shimmerGradient).frame(width: 60, height: 20)
                RoundedRectangle(cornerRadius: 4).fill(shimmerGradient).frame(width: 60, height: 20)
                Spacer()
                RoundedRectangle(cornerRadius: 4).fill(shimmerGradient).frame(width: 28, height: 20)
            }
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
    }

    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: shimmer
                ? [Color.secondary.opacity(0.07), Color.secondary.opacity(0.15), Color.secondary.opacity(0.07)]
                : [Color.secondary.opacity(0.12), Color.secondary.opacity(0.08), Color.secondary.opacity(0.12)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Preview

#Preview {
    FeedView()
        .environment(AuthService())
}

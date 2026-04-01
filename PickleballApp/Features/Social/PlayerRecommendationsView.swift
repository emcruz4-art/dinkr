import SwiftUI

// MARK: - Recommendation Section Model

private struct RecommendationSection: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var players: [RecommendedPlayer]
}

// MARK: - RecommendedPlayer Model

private struct RecommendedPlayer: Identifiable {
    let id: String
    let user: User
    let mutualCount: Int
    let reasonTag: String
    var connectionState: ConnectionState = .none

    enum ConnectionState {
        case none, pending, connected, skipped
    }
}

// MARK: - Swipeable Card Geometry

private struct SwipeCardView: View {
    let player: RecommendedPlayer
    let onConnect: () -> Void
    let onSkip: () -> Void

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0

    private let swipeThreshold: CGFloat = 90

    private var swipeProgress: CGFloat {
        min(abs(offset.width) / swipeThreshold, 1)
    }

    private var isSwipingRight: Bool { offset.width > 0 }
    private var isSwipingLeft:  Bool { offset.width < 0 }

    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 6)

            // Accept / skip overlays
            if isSwipingRight && swipeProgress > 0.15 {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.dinkrGreen.opacity(swipeProgress * 0.2))
                connectBadge
                    .opacity(swipeProgress)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(24)
            }

            if isSwipingLeft && swipeProgress > 0.15 {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.dinkrCoral.opacity(swipeProgress * 0.2))
                skipBadge
                    .opacity(swipeProgress)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(24)
            }

            // Card content
            VStack(spacing: 0) {
                // Avatar area
                ZStack {
                    LinearGradient(
                        colors: [Color.dinkrNavy, Color.dinkrSky.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 160)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 20,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 20
                        )
                    )

                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Text(String(player.user.displayName.prefix(2)).uppercased())
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        HStack(spacing: 6) {
                            SkillChip(skillLevel: player.user.skillLevel)
                            if let dupr = player.user.duprRating {
                                Text("DUPR \(String(format: "%.2f", dupr))")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(.white.opacity(0.18), in: Capsule())
                            }
                        }
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(player.user.displayName)
                                .font(.title3.weight(.bold))
                            Text("@\(player.user.username)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.2.fill")
                                    .font(.caption2)
                                    .foregroundStyle(Color.dinkrSky)
                                Text("\(player.mutualCount) mutual")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.dinkrSky)
                            }
                            HStack(spacing: 3) {
                                Image(systemName: "location.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(player.user.city)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Bio
                    if !player.user.bio.isEmpty {
                        Text(player.user.bio)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    // Reason tag
                    Text(player.reasonTag)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.dinkrGreen.opacity(0.1), in: Capsule())

                    // Stats row
                    HStack(spacing: 16) {
                        statPill(icon: "sportscourt.fill", value: "\(player.user.gamesPlayed)", label: "Games")
                        statPill(icon: "trophy.fill",     value: "\(Int(player.user.winRate * 100))%", label: "Win rate")
                        statPill(icon: "star.fill",       value: String(format: "%.1f", player.user.reliabilityScore), label: "Rating")
                    }

                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: onSkip) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.dinkrCoral)
                                .frame(width: 52, height: 52)
                                .background(Color.dinkrCoral.opacity(0.1), in: Circle())
                                .overlay(Circle().strokeBorder(Color.dinkrCoral.opacity(0.3), lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)

                        Button(action: onConnect) {
                            Label("Connect", systemImage: "person.badge.plus.fill")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
        .frame(maxWidth: .infinity)
        .offset(x: offset.width, y: offset.height * 0.2)
        .rotationEffect(.degrees(rotation))
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation
                    rotation = Double(value.translation.width / 20)
                }
                .onEnded { value in
                    if value.translation.width > swipeThreshold {
                        withAnimation(.spring(response: 0.4)) { offset = CGSize(width: 500, height: 0) }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onConnect() }
                    } else if value.translation.width < -swipeThreshold {
                        withAnimation(.spring(response: 0.4)) { offset = CGSize(width: -500, height: 0) }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onSkip() }
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            offset = .zero
                            rotation = 0
                        }
                    }
                }
        )
        .animation(.interactiveSpring(), value: offset)
    }

    private var connectBadge: some View {
        Text("CONNECT")
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .foregroundStyle(Color.dinkrGreen)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.dinkrGreen, lineWidth: 2)
            )
            .rotationEffect(.degrees(-15))
    }

    private var skipBadge: some View {
        Text("SKIP")
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .foregroundStyle(Color.dinkrCoral)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.dinkrCoral, lineWidth: 2)
            )
            .rotationEffect(.degrees(15))
    }

    private func statPill(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.dinkrAmber)
                Text(value)
                    .font(.system(size: 12, weight: .bold))
            }
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Skill Chip (local)

private struct SkillChip: View {
    let skillLevel: SkillLevel

    var body: some View {
        Text(skillLevel.label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.white.opacity(0.2), in: Capsule())
    }
}

// MARK: - Compact Player Card (list view)

private struct CompactPlayerCard: View {
    let player: RecommendedPlayer
    let onConnect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.dinkrNavy.opacity(0.12))
                    .frame(width: 46, height: 46)
                Text(String(player.user.displayName.prefix(2)).uppercased())
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dinkrNavy)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(player.user.displayName)
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    Text(player.user.skillLevel.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.dinkrGreen.opacity(0.1), in: Capsule())
                    if player.mutualCount > 0 {
                        Text("\(player.mutualCount) mutual")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Button(action: onConnect) {
                switch player.connectionState {
                case .none:
                    Text("Connect")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.dinkrGreen)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.dinkrGreen.opacity(0.12), in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.dinkrGreen.opacity(0.3), lineWidth: 1))
                case .pending:
                    Text("Pending")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.dinkrAmber)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.dinkrAmber.opacity(0.12), in: Capsule())
                case .connected:
                    Label("Connected", systemImage: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.secondary.opacity(0.08), in: Capsule())
                case .skipped:
                    EmptyView()
                }
            }
            .buttonStyle(.plain)
            .disabled(player.connectionState != .none)
        }
        .padding(14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - PlayerRecommendationsView

struct PlayerRecommendationsView: View {

    // MARK: State
    @State private var sections: [RecommendationSection] = []
    @State private var swipeMode = false
    @State private var currentSwipeSection = 0
    @State private var currentSwipeIndex  = 0
    @State private var connectedCount = 0
    @State private var isLoadingMore = false
    @State private var loadedMoreCount = 0
    @Environment(AuthService.self) private var authService

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if swipeMode {
                    swipeDeckView
                } else {
                    listView
                }
            }
            .navigationTitle("Players You Should Know")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            swipeMode.toggle()
                        }
                        HapticManager.selection()
                    } label: {
                        Label(
                            swipeMode ? "List" : "Swipe",
                            systemImage: swipeMode ? "list.bullet" : "hand.draw.fill"
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                    }
                }
            }
        }
        .task { await loadRecommendations() }
    }

    // MARK: - List View

    private var listView: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Swipe mode promo banner
                Button {
                    withAnimation(.spring(response: 0.4)) { swipeMode = true }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "hand.draw.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Color.dinkrAmber)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Try Swipe Mode")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.dinkrNavy)
                            Text("Right to connect, left to skip — like finding a game partner!")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(Color.dinkrAmber.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.dinkrAmber.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.top, 12)

                ForEach($sections) { $section in
                    let visiblePlayers = section.players.filter { $0.connectionState != .skipped }
                    if !visiblePlayers.isEmpty {
                        sectionView(section: $section)
                    }
                }

                // Load more
                Button {
                    loadMore()
                } label: {
                    Group {
                        if isLoadingMore {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(Color.dinkrGreen)
                                Text("Finding more players…")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.dinkrGreen)
                            }
                        } else {
                            Label(
                                loadedMoreCount > 0 ? "Load even more players" : "Load more players",
                                systemImage: "arrow.down.circle"
                            )
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.dinkrGreen.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.dinkrGreen.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .disabled(isLoadingMore)

                Spacer(minLength: 32)
            }
            .padding(.bottom, 24)
        }
    }

    private func sectionView(section: Binding<RecommendationSection>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(section.wrappedValue.iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: section.wrappedValue.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(section.wrappedValue.iconColor)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(section.wrappedValue.title)
                        .font(.subheadline.weight(.bold))
                    Text(section.wrappedValue.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)

            VStack(spacing: 10) {
                ForEach(section.players.indices, id: \.self) { idx in
                    if section.wrappedValue.players[idx].connectionState != .skipped {
                        CompactPlayerCard(
                            player: section.wrappedValue.players[idx],
                            onConnect: {
                                handleConnect(sectionBinding: section, index: idx)
                            }
                        )
                        .padding(.horizontal, 16)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
            }
        }
    }

    // MARK: - Swipe Deck View

    private var swipeDeckView: some View {
        VStack(spacing: 0) {
            // Mode header
            swipeModeHeader

            // Deck area
            ZStack {
                if let currentPlayer = currentSwipablePlayer {
                    SwipeCardView(
                        player: currentPlayer,
                        onConnect: {
                            handleSwipeConnect()
                        },
                        onSkip: {
                            handleSwipeSkip()
                        }
                    )
                    .padding(.horizontal, 20)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.9)),
                            removal: .opacity
                        )
                    )
                    .id(currentPlayer.id)
                } else {
                    deckEmptyView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            swipeHintBar
        }
    }

    private var swipeModeHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Swipe to Connect")
                    .font(.headline)
                Text("Right = Connect   Left = Skip")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if connectedCount > 0 {
                Label("\(connectedCount) connected", systemImage: "person.badge.plus.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.dinkrGreen.opacity(0.1), in: Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
    }

    private var swipeHintBar: some View {
        HStack(spacing: 0) {
            Label("Skip", systemImage: "xmark")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.dinkrCoral)
                .frame(maxWidth: .infinity)
            Label("Connect", systemImage: "person.badge.plus.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.dinkrGreen)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 14)
        .background(Color.cardBackground)
    }

    private var deckEmptyView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.dinkrGreen)
            }
            Text("You've seen everyone!")
                .font(.title3.weight(.bold))
            Text("Pull down to refresh or switch to list view to see all players.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                withAnimation(.spring(response: 0.4)) { swipeMode = false }
            } label: {
                Label("Back to List", systemImage: "list.bullet")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private var allSwipablePlayers: [RecommendedPlayer] {
        sections.flatMap { $0.players }.filter { $0.connectionState == .none || $0.connectionState == .pending }
    }

    private var currentSwipablePlayer: RecommendedPlayer? {
        let all = sections.flatMap { $0.players }.filter { $0.connectionState == .none }
        return all.first
    }

    private func handleConnect(sectionBinding: Binding<RecommendationSection>, index: Int) {
        HapticManager.success()
        withAnimation(.spring(response: 0.35)) {
            sectionBinding.wrappedValue.players[index].connectionState = .connected
        }
        connectedCount += 1
    }

    private func handleSwipeConnect() {
        HapticManager.success()
        markFirstVisiblePlayer(state: .connected)
        connectedCount += 1
    }

    private func handleSwipeSkip() {
        HapticManager.light()
        markFirstVisiblePlayer(state: .skipped)
    }

    private func markFirstVisiblePlayer(state: RecommendedPlayer.ConnectionState) {
        for si in sections.indices {
            for pi in sections[si].players.indices {
                if sections[si].players[pi].connectionState == .none {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        sections[si].players[pi].connectionState = state
                    }
                    return
                }
            }
        }
    }

    private func loadMore() {
        isLoadingMore = true
        HapticManager.light()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let newPlayers = Self.buildExtraPlayers(offset: loadedMoreCount)
            withAnimation(.spring(response: 0.5)) {
                if !sections.isEmpty {
                    sections[0].players.append(contentsOf: newPlayers)
                }
                loadedMoreCount += newPlayers.count
                isLoadingMore = false
            }
        }
    }

    // MARK: - Data builders

    private func loadRecommendations() async {
        let allUsers: [User] = (try? await FirestoreService.shared.queryCollectionOrdered(
            collection: FirestoreCollections.users,
            orderBy: "displayName",
            limit: 50
        )) ?? User.mockPlayers
        let currentId = authService.currentUser?.id ?? ""
        let others = allUsers.filter { $0.id != currentId }
        sections = Self.buildSections(from: others)
    }

    static fileprivate func buildSections() -> [RecommendationSection] {
        buildSections(from: User.mockPlayers)
    }

    static fileprivate func buildSections(from all: [User]) -> [RecommendationSection] {

        // Because you play at Westside (shared club IDs)
        let westsidePlayers = all.filter { $0.clubIds.contains("club_001") }.prefix(3).map { user in
            RecommendedPlayer(
                id: "w_\(user.id)",
                user: user,
                mutualCount: Int.random(in: 1...4),
                reasonTag: "Plays at Westside Courts"
            )
        }

        // Similar skill level in Austin
        let skillPlayers = all.filter {
            ($0.skillLevel == .intermediate35 || $0.skillLevel == .advanced40) &&
            $0.city.contains("Austin")
        }.prefix(4).map { user in
            RecommendedPlayer(
                id: "s_\(user.id)",
                user: user,
                mutualCount: Int.random(in: 0...3),
                reasonTag: "Similar skill level in Austin"
            )
        }

        // Friends of friends
        let fofPlayers = all.filter { $0.followersCount > 200 }.prefix(3).map { user in
            RecommendedPlayer(
                id: "f_\(user.id)",
                user: user,
                mutualCount: Int.random(in: 2...6),
                reasonTag: "Friend of a friend"
            )
        }

        return [
            RecommendationSection(
                icon: "mappin.and.ellipse",
                iconColor: Color.dinkrGreen,
                title: "Because you play at Westside...",
                subtitle: "Players who frequent the same courts",
                players: Array(westsidePlayers)
            ),
            RecommendationSection(
                icon: "chart.bar.fill",
                iconColor: Color.dinkrSky,
                title: "Similar skill level in Austin",
                subtitle: "Well-matched players near you",
                players: Array(skillPlayers)
            ),
            RecommendationSection(
                icon: "person.2.fill",
                iconColor: Color.dinkrAmber,
                title: "Friends of friends",
                subtitle: "Expand your pickleball network",
                players: Array(fofPlayers)
            ),
        ]
    }

    static fileprivate func buildExtraPlayers(offset: Int) -> [RecommendedPlayer] {
        let base = User.mockPlayers
        let start = offset % base.count
        let slice = Array(base[start...].prefix(3))
        return slice.enumerated().map { idx, user in
            RecommendedPlayer(
                id: "more_\(offset)_\(idx)_\(user.id)",
                user: user,
                mutualCount: Int.random(in: 0...5),
                reasonTag: "Active in your area"
            )
        }
    }
}

// MARK: - Preview

#Preview {
    PlayerRecommendationsView()
}

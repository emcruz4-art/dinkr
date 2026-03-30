import SwiftUI

struct PlayerMatchView: View {
    @State private var players = User.mockPlayers
    @State private var currentIndex = 0
    @State private var offset = CGSize.zero
    @State private var showMatchAlert = false
    @State private var matchedPlayer: User? = nil
    @State private var rotation = 0.0
    @State private var showFilters = false

    var currentPlayer: User? {
        guard currentIndex < players.count else { return nil }
        return players[currentIndex]
    }

    var body: some View {
        ZStack {
            if players.isEmpty || currentIndex >= players.count {
                EmptyStateView(
                    icon: "person.2.wave.2",
                    title: "You've seen everyone nearby",
                    message: "Check back later or expand your search radius to find more players."
                )
            } else {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Find Your Partner")
                                .font(.title2.weight(.bold))
                            Text("Swipe right to connect · left to skip")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        // Filter button
                        Button {
                            showFilters = true
                            HapticManager.selection()
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundStyle(Color.dinkrGreen)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    Spacer()

                    // Card stack
                    ZStack {
                        // Background cards
                        ForEach(min(currentIndex + 2, players.count - 1)..<min(currentIndex + 3, players.count), id: \.self) { i in
                            PlayerMatchCard(player: players[i])
                                .scaleEffect(0.92)
                                .offset(y: 20)
                        }
                        ForEach(min(currentIndex + 1, players.count - 1)..<min(currentIndex + 2, players.count), id: \.self) { i in
                            PlayerMatchCard(player: players[i])
                                .scaleEffect(0.96)
                                .offset(y: 10)
                        }

                        // Current top card
                        if let player = currentPlayer {
                            PlayerMatchCard(player: player)
                                .overlay(
                                    // Left/right swipe indicators
                                    HStack {
                                        // PASS label
                                        Text("PASS")
                                            .font(.headline.weight(.heavy))
                                            .foregroundStyle(Color.dinkrCoral)
                                            .padding(8)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dinkrCoral, lineWidth: 2))
                                            .rotationEffect(.degrees(15))
                                            .opacity(offset.width < -20 ? Double(-offset.width / 80) : 0)
                                            .padding(.leading, 20)
                                        Spacer()
                                        // CONNECT label
                                        Text("CONNECT")
                                            .font(.headline.weight(.heavy))
                                            .foregroundStyle(Color.dinkrGreen)
                                            .padding(8)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dinkrGreen, lineWidth: 2))
                                            .rotationEffect(.degrees(-15))
                                            .opacity(offset.width > 20 ? Double(offset.width / 80) : 0)
                                            .padding(.trailing, 20)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                                    .padding(.top, 20)
                                )
                                .offset(x: offset.width, y: offset.height * 0.3)
                                .rotationEffect(.degrees(Double(offset.width / 20)))
                                .gesture(
                                    DragGesture()
                                        .onChanged { gesture in
                                            offset = gesture.translation
                                        }
                                        .onEnded { gesture in
                                            let swipeThreshold: CGFloat = 100
                                            if gesture.translation.width > swipeThreshold {
                                                // Connect
                                                withAnimation(.spring()) {
                                                    offset = CGSize(width: 600, height: 0)
                                                }
                                                matchedPlayer = player
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    showMatchAlert = true
                                                    currentIndex += 1
                                                    offset = .zero
                                                }
                                            } else if gesture.translation.width < -swipeThreshold {
                                                // Skip
                                                withAnimation(.spring()) {
                                                    offset = CGSize(width: -600, height: 0)
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    currentIndex += 1
                                                    offset = .zero
                                                }
                                            } else {
                                                withAnimation(.spring()) {
                                                    offset = .zero
                                                }
                                            }
                                        }
                                )
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    // Action buttons
                    HStack(spacing: 24) {
                        // Skip
                        Button {
                            withAnimation(.spring()) {
                                offset = CGSize(width: -600, height: 0)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                currentIndex += 1
                                offset = .zero
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.dinkrCoral.opacity(0.12))
                                    .frame(width: 64, height: 64)
                                Image(systemName: "xmark")
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(Color.dinkrCoral)
                            }
                        }
                        .buttonStyle(.plain)

                        // Super match
                        Button {
                            if let player = currentPlayer {
                                HapticManager.medium()
                                withAnimation(.spring()) {
                                    offset = CGSize(width: 0, height: -600)
                                }
                                matchedPlayer = player
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showMatchAlert = true
                                    currentIndex += 1
                                    offset = .zero
                                }
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.dinkrAmber.opacity(0.12))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "star.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.dinkrAmber)
                            }
                        }
                        .buttonStyle(.plain)

                        // Connect
                        Button {
                            if let player = currentPlayer {
                                withAnimation(.spring()) {
                                    offset = CGSize(width: 600, height: 0)
                                }
                                matchedPlayer = player
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showMatchAlert = true
                                    currentIndex += 1
                                    offset = .zero
                                }
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.dinkrGreen.opacity(0.12))
                                    .frame(width: 64, height: 64)
                                Image(systemName: "checkmark")
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(Color.dinkrGreen)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .sheet(isPresented: $showMatchAlert) {
            if let player = matchedPlayer {
                MatchSuccessSheet(player: player)
            }
        }
        .sheet(isPresented: $showFilters) {
            NavigationStack {
                VStack(spacing: 20) {
                    Text("Filter Players")
                        .font(.headline)
                    Text("Skill, distance, and availability filters coming soon.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding(.top, 24)
                .padding(.horizontal)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showFilters = false }
                            .foregroundStyle(Color.dinkrGreen)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

struct PlayerMatchCard: View {
    let player: User

    var compatibilityScore: Int {
        // Mock compatibility based on skill level proximity
        let scores = [92, 88, 76, 94, 71, 85, 79, 90]
        return scores[abs(player.id.hashValue) % scores.count]
    }

    var sharedGroups: Int {
        [1, 2, 0, 3, 1, 2, 1, 0][abs(player.id.hashValue) % 8]
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Card background
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color.dinkrNavy, Color.dinkrNavy.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Avatar backdrop
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 200, height: 200)
                .offset(x: -30, y: -60)

            VStack(alignment: .leading, spacing: 0) {
                // Avatar centered at top
                HStack {
                    Spacer()
                    AvatarView(displayName: player.displayName, size: 100)
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
                    Spacer()
                }
                .padding(.top, 40)

                Spacer()

                // Info at bottom
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(player.displayName)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                            HStack(spacing: 8) {
                                SkillBadge(level: player.skillLevel)
                                Label(player.city.components(separatedBy: ",").first ?? player.city,
                                      systemImage: "mappin")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        Spacer()
                        // Compatibility score
                        VStack(spacing: 2) {
                            Text("\(compatibilityScore)%")
                                .font(.title3.weight(.heavy))
                                .foregroundStyle(compatibilityScore >= 85 ? Color.dinkrGreen : Color.dinkrAmber)
                            Text("match")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }

                    if !player.bio.isEmpty {
                        Text(player.bio)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(2)
                    }

                    HStack(spacing: 12) {
                        StatPill(icon: "figure.pickleball", value: "\(player.gamesPlayed) games")
                        StatPill(icon: "trophy.fill", value: "\(Int(player.winRate * 100))% win rate")
                        if sharedGroups > 0 {
                            StatPill(icon: "person.3.fill", value: "\(sharedGroups) shared groups")
                        }
                    }
                }
                .padding(20)
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.0), Color.black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .frame(height: 460)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
    }
}

private struct StatPill: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(value)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(.white.opacity(0.85))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.12))
        .clipShape(Capsule())
    }
}

struct MatchSuccessSheet: View {
    let player: User
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.dinkrNavy.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Confetti/celebration
                Text("🎉")
                    .font(.system(size: 64))

                Text("It's a Match!")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(.white)

                VStack(spacing: 4) {
                    Text("You and \(player.displayName) both want to connect.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    Text("Send a message or challenge them to a game!")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                HStack(spacing: 32) {
                    AvatarView(displayName: "Alex Rivera", size: 72)
                        .overlay(Circle().stroke(Color.dinkrGreen, lineWidth: 3))
                    Text("❤️")
                        .font(.title)
                    AvatarView(displayName: player.displayName, size: 72)
                        .overlay(Circle().stroke(Color.dinkrGreen, lineWidth: 3))
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Send Message")
                            .font(.headline)
                            .foregroundStyle(Color.dinkrNavy)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button {
                        dismiss()
                    } label: {
                        Text("Challenge to a Game")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.dinkrGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button("Keep Swiping") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .presentationDetents([.large])
    }
}

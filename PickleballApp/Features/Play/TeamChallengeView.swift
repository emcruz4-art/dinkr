import SwiftUI

// MARK: - Data Models

struct TeamChallengePlayer: Identifiable {
    let id: String
    let displayName: String
    let department: String
    let gamesPlayed: Int
    let wins: Int
    let duprRating: Double?
}

struct TeamChallengeMatch: Identifiable {
    let id: String
    let player1: String
    let player2: String
    let opponent1: String
    let opponent2: String
    let teamAWon: Bool?    // nil = not yet played
    let score: String?
    let scheduledDate: Date
}

private struct TeamTrashTalkMessage: Identifiable {
    let id: String
    let sender: String
    let department: String
    let message: String
    let timestamp: Date
    let isCurrentUser: Bool
}

// MARK: - TeamChallengeView

struct TeamChallengeView: View {

    @State private var selectedTab = 0
    @State private var showScheduleSheet = false
    @State private var newMessage = ""
    @State private var messageSent = false

    private let teamAName = "Engineering"
    private let teamBName = "Sales"
    private let teamAScore = 3
    private let teamBScore = 1
    private let bestOf = 5
    private let daysRemaining = 3

    // MARK: Mock rosters

    private let teamAPlayers: [TeamChallengePlayer] = [
        TeamChallengePlayer(id: "a1", displayName: "Chris Park",    department: "Engineering", gamesPlayed: 312, wins: 198, duprRating: 4.05),
        TeamChallengePlayer(id: "a2", displayName: "Maria Chen",    department: "Engineering", gamesPlayed: 203, wins: 148, duprRating: 3.87),
        TeamChallengePlayer(id: "a3", displayName: "Alex Rivera",   department: "Engineering", gamesPlayed: 142, wins: 89,  duprRating: 4.69),
    ]

    private let teamBPlayers: [TeamChallengePlayer] = [
        TeamChallengePlayer(id: "b1", displayName: "Jordan Smith",  department: "Sales",       gamesPlayed: 87,  wins: 51,  duprRating: 4.21),
        TeamChallengePlayer(id: "b2", displayName: "Taylor Kim",    department: "Sales",       gamesPlayed: 34,  wins: 18,  duprRating: 2.98),
        TeamChallengePlayer(id: "b3", displayName: "Morgan Davis",  department: "Sales",       gamesPlayed: 72,  wins: 40,  duprRating: 2.85),
    ]

    private let matches: [TeamChallengeMatch] = [
        TeamChallengeMatch(id: "m1", player1: "Chris Park",  player2: "Maria Chen",  opponent1: "Jordan Smith", opponent2: "Taylor Kim",   teamAWon: true,  score: "11-7, 11-5",  scheduledDate: Date().addingTimeInterval(-86400 * 4)),
        TeamChallengeMatch(id: "m2", player1: "Alex Rivera", player2: "Chris Park",  opponent1: "Morgan Davis", opponent2: "Jordan Smith",  teamAWon: true,  score: "11-9, 8-11, 11-6", scheduledDate: Date().addingTimeInterval(-86400 * 3)),
        TeamChallengeMatch(id: "m3", player1: "Maria Chen",  player2: "Alex Rivera", opponent1: "Taylor Kim",   opponent2: "Morgan Davis",  teamAWon: false, score: "7-11, 11-9, 9-11", scheduledDate: Date().addingTimeInterval(-86400 * 2)),
        TeamChallengeMatch(id: "m4", player1: "Chris Park",  player2: "Alex Rivera", opponent1: "Jordan Smith", opponent2: "Morgan Davis",  teamAWon: true,  score: "11-4, 11-8",  scheduledDate: Date().addingTimeInterval(-86400 * 1)),
        TeamChallengeMatch(id: "m5", player1: "TBD",         player2: "TBD",         opponent1: "TBD",          opponent2: "TBD",           teamAWon: nil,   score: nil,           scheduledDate: Date().addingTimeInterval(86400 * 2)),
    ]

    private let messages: [TeamTrashTalkMessage] = [
        TeamTrashTalkMessage(id: "msg1", sender: "Jordan Smith",  department: "Sales",       message: "Engineering's luck runs out this week. Sales closes every deal — on and off the court!", timestamp: Date().addingTimeInterval(-7200),  isCurrentUser: false),
        TeamTrashTalkMessage(id: "msg2", sender: "Chris Park",    department: "Engineering", message: "We debug and we dink. 3-1 doesn't lie. See you Thursday 🏓",                           timestamp: Date().addingTimeInterval(-5400),  isCurrentUser: false),
        TeamTrashTalkMessage(id: "msg3", sender: "Taylor Kim",    department: "Sales",       message: "Game 3 was a fluke. Our closer is ready for the last match.",                          timestamp: Date().addingTimeInterval(-3600),  isCurrentUser: false),
        TeamTrashTalkMessage(id: "msg4", sender: "Alex Rivera",   department: "Engineering", message: "Bold talk from a team down 3-1! May the best department win.",                         timestamp: Date().addingTimeInterval(-1800),  isCurrentUser: true),
    ]

    var body: some View {
        VStack(spacing: 0) {

            // ── Scoreboard header ──────────────────────────────────────────
            scoreboardHeader

            // ── Tab bar ────────────────────────────────────────────────────
            challengeTabBar

            // ── Content ────────────────────────────────────────────────────
            TabView(selection: $selectedTab) {
                overviewTab.tag(0)
                rostersTab.tag(1)
                matchesTab.tag(2)
                chatTab.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.22), value: selectedTab)
        }
        .navigationTitle("Team Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showScheduleSheet = true
                } label: {
                    Label("Schedule Match", systemImage: "calendar.badge.plus")
                        .tint(Color.dinkrGreen)
                }
            }
        }
        .sheet(isPresented: $showScheduleSheet) {
            ScheduleMatchSheet(teamAName: teamAName, teamBName: teamBName)
        }
    }

    // MARK: - Scoreboard Header

    private var scoreboardHeader: some View {
        ZStack {
            LinearGradient(
                colors: [Color.dinkrNavy, Color.dinkrNavy.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {

                // Challenge title
                HStack(spacing: 8) {
                    Image(systemName: "person.2.badge.gearshape.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrAmber)
                    Text("Best of \(bestOf) · This Week · \(daysRemaining) days left")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrAmber)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.dinkrAmber.opacity(0.15))
                .clipShape(Capsule())

                // Score tracker
                HStack(spacing: 0) {

                    // Team A
                    VStack(spacing: 4) {
                        Text(teamAName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                        Text("\(teamAScore)")
                            .font(.system(size: 52, weight: .heavy, design: .rounded))
                            .foregroundStyle(teamAScore > teamBScore ? Color.dinkrGreen : .white.opacity(0.6))
                        if teamAScore > teamBScore {
                            Text("LEADING")
                                .font(.system(size: 8, weight: .heavy))
                                .foregroundStyle(Color.dinkrGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.dinkrGreen.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // VS divider
                    VStack(spacing: 2) {
                        Text("VS")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(.white.opacity(0.5))
                        RoundedRectangle(cornerRadius: 1)
                            .fill(.white.opacity(0.2))
                            .frame(width: 1, height: 40)
                    }

                    // Team B
                    VStack(spacing: 4) {
                        Text(teamBName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                        Text("\(teamBScore)")
                            .font(.system(size: 52, weight: .heavy, design: .rounded))
                            .foregroundStyle(teamBScore > teamAScore ? Color.dinkrCoral : .white.opacity(0.6))
                        if teamBScore > teamAScore {
                            Text("LEADING")
                                .font(.system(size: 8, weight: .heavy))
                                .foregroundStyle(Color.dinkrCoral)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.dinkrCoral.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // Match pip indicators
                HStack(spacing: 6) {
                    ForEach(0..<bestOf, id: \.self) { i in
                        let match = i < matches.count ? matches[i] : nil
                        Circle()
                            .fill(pipColor(for: match))
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle().stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                            )
                    }
                }
            }
            .padding(.vertical, 20)
        }
    }

    private func pipColor(for match: TeamChallengeMatch?) -> Color {
        guard let match = match else { return .white.opacity(0.2) }
        if match.teamAWon == nil { return .white.opacity(0.2) }
        return match.teamAWon == true ? Color.dinkrGreen : Color.dinkrCoral
    }

    // MARK: - Tab Bar

    private var challengeTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(["Overview", "Rosters", "Matches", "Trash Talk"].enumerated()), id: \.offset) { index, label in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(label)
                            .font(.system(size: 12, weight: selectedTab == index ? .bold : .regular))
                            .foregroundStyle(selectedTab == index ? Color.dinkrGreen : Color.secondary)
                        Rectangle()
                            .fill(selectedTab == index ? Color.dinkrGreen : Color.clear)
                            .frame(height: 2)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.appBackground)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    // MARK: - Overview Tab

    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Status card
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundStyle(Color.dinkrAmber)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Challenge Status")
                                .font(.subheadline.weight(.bold))
                            Text("\(teamAName) needs \(neededToWin(teamAScore, teamBScore, bestOf)) more win(s) to claim the challenge")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }

                    // Progress bar
                    GeometryReader { geo in
                        let total = bestOf
                        let aWidth = geo.size.width * CGFloat(teamAScore) / CGFloat(total)
                        let bWidth = geo.size.width * CGFloat(teamBScore) / CGFloat(total)

                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.15))
                                .frame(height: 12)

                            HStack(spacing: 2) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.dinkrGreen)
                                    .frame(width: aWidth, height: 12)
                                Spacer()
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.dinkrCoral)
                                    .frame(width: bWidth, height: 12)
                            }
                        }
                    }
                    .frame(height: 12)

                    HStack {
                        Label(teamAName, systemImage: "circle.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.dinkrGreen)
                        Spacer()
                        Label(teamBName, systemImage: "circle.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.dinkrCoral)
                    }
                }
                .padding(16)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Upcoming match card
                if let upcoming = matches.first(where: { $0.teamAWon == nil }) {
                    upcomingMatchCard(match: upcoming)
                }

                // Recent results
                VStack(alignment: .leading, spacing: 10) {
                    Text("RECENT RESULTS")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.secondary)

                    ForEach(matches.filter { $0.teamAWon != nil }) { match in
                        resultRow(match: match)
                    }
                }
            }
            .padding(16)
        }
    }

    private func neededToWin(_ aScore: Int, _ bScore: Int, _ bestOf: Int) -> Int {
        let needed = (bestOf / 2) + 1
        return max(0, needed - aScore)
    }

    private func upcomingMatchCard(match: TeamChallengeMatch) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Color.dinkrSky)
                Text("NEXT MATCH")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(Color.dinkrSky)
                Spacer()
                Text(match.scheduledDate, style: .date)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack {
                VStack(spacing: 3) {
                    Text(teamAName)
                        .font(.subheadline.weight(.bold))
                    Text("Roster TBD")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Text("VS")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.secondary)

                VStack(spacing: 3) {
                    Text(teamBName)
                        .font(.subheadline.weight(.bold))
                    Text("Roster TBD")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            Button {
                showScheduleSheet = true
                HapticManager.selection()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                    Text("Schedule This Match")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Color.dinkrGreen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.dinkrGreen.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.dinkrGreen.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.dinkrSky.opacity(0.3), lineWidth: 1)
        )
    }

    private func resultRow(match: TeamChallengeMatch) -> some View {
        let won = match.teamAWon == true
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(won ? Color.dinkrGreen.opacity(0.12) : Color.dinkrCoral.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: won ? "checkmark" : "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(won ? Color.dinkrGreen : Color.dinkrCoral)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(match.player1) & \(match.player2)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrGreen)
                Text("vs \(match.opponent1) & \(match.opponent2)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(won ? "\(teamAName) won" : "\(teamBName) won")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(won ? Color.dinkrGreen : Color.dinkrCoral)
                if let score = match.score {
                    Text(score)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Rosters Tab

    private var rostersTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                rosterCard(teamName: teamAName, players: teamAPlayers, teamColor: Color.dinkrGreen, score: teamAScore)
                rosterCard(teamName: teamBName, players: teamBPlayers, teamColor: Color.dinkrCoral, score: teamBScore)
            }
            .padding(16)
        }
    }

    private func rosterCard(teamName: String, players: [TeamChallengePlayer], teamColor: Color, score: Int) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(teamColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Text(String(teamName.prefix(2)).uppercased())
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(teamColor)
                }
                Text(teamName)
                    .font(.headline.weight(.bold))
                Spacer()
                Text("\(score) wins")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(teamColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(teamColor.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(16)

            Divider()

            ForEach(players) { player in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(teamColor.opacity(0.12))
                            .frame(width: 38, height: 38)
                        Text(player.displayName.prefix(1).uppercased())
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(teamColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(player.displayName)
                            .font(.subheadline.weight(.medium))
                        HStack(spacing: 6) {
                            Text("\(player.gamesPlayed) games")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("·")
                                .foregroundStyle(.secondary)
                            Text("\(Int(Double(player.wins) / Double(max(1, player.gamesPlayed)) * 100))% win rate")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if let dupr = player.duprRating {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("DUPR")
                                .font(.system(size: 8, weight: .heavy))
                                .foregroundStyle(Color.dinkrAmber)
                            Text(String(format: "%.2f", dupr))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.dinkrAmber)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if player.id != players.last?.id {
                    Divider().padding(.horizontal)
                }
            }
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(teamColor.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Matches Tab

    private var matchesTab: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(Array(matches.enumerated()), id: \.element.id) { index, match in
                    matchCard(match: match, gameNumber: index + 1)
                }
            }
            .padding(16)
        }
    }

    private func matchCard(match: TeamChallengeMatch, gameNumber: Int) -> some View {
        let isUpcoming = match.teamAWon == nil
        let won = match.teamAWon == true

        return VStack(spacing: 10) {
            HStack {
                Text("GAME \(gameNumber)")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.secondary)
                Spacer()
                if isUpcoming {
                    Text("UPCOMING")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(Color.dinkrSky)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.dinkrSky.opacity(0.15))
                        .clipShape(Capsule())
                } else {
                    Text(won ? "\(teamAName) won" : "\(teamBName) won")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(won ? Color.dinkrGreen : Color.dinkrCoral)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background((won ? Color.dinkrGreen : Color.dinkrCoral).opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(teamAName)
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(Color.dinkrGreen)
                    Text("\(match.player1) / \(match.player2)")
                        .font(.caption)
                        .foregroundStyle(isUpcoming ? .secondary : (won ? .primary : .secondary))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 2) {
                    if let score = match.score {
                        Text(score)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text(match.scheduledDate, style: .date)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(width: 100)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(teamBName)
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(Color.dinkrCoral)
                    Text("\(match.opponent1) / \(match.opponent2)")
                        .font(.caption)
                        .foregroundStyle(isUpcoming ? .secondary : (!won ? .primary : .secondary))
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    isUpcoming ? Color.dinkrSky.opacity(0.3) :
                    (won ? Color.dinkrGreen.opacity(0.2) : Color.dinkrCoral.opacity(0.2)),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Chat Tab

    private var chatTab: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header banner
                    HStack(spacing: 8) {
                        Text("🗣️")
                        Text("Trash talk is encouraged. Respect is required.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.dinkrAmber.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    ForEach(messages) { msg in
                        chatBubble(msg: msg)
                    }

                    if messageSent {
                        chatBubble(msg: TeamTrashTalkMessage(
                            id: "new",
                            sender: "Alex Rivera",
                            department: "Engineering",
                            message: newMessage,
                            timestamp: Date(),
                            isCurrentUser: true
                        ))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(16)
            }

            // Message input bar
            HStack(spacing: 10) {
                TextField("Say something...", text: $newMessage)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.cardBackground)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1))

                Button {
                    guard !newMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        messageSent = true
                    }
                    HapticManager.success()
                    newMessage = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.dinkrGreen)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(newMessage.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.appBackground)
            .overlay(alignment: .top) { Divider() }
        }
    }

    private func chatBubble(msg: TeamTrashTalkMessage) -> some View {
        let deptColor: Color = {
            switch msg.department {
            case "Engineering": return Color.dinkrSky
            case "Sales":       return Color.dinkrCoral
            default:            return Color.secondary
            }
        }()

        return HStack(alignment: .bottom, spacing: 8) {
            if msg.isCurrentUser { Spacer(minLength: 60) }

            if !msg.isCurrentUser {
                ZStack {
                    Circle()
                        .fill(deptColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Text(msg.sender.prefix(1).uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(deptColor)
                }
            }

            VStack(alignment: msg.isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !msg.isCurrentUser {
                    HStack(spacing: 5) {
                        Text(msg.sender)
                            .font(.caption.weight(.semibold))
                        Text(msg.department)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(deptColor)
                            .clipShape(Capsule())
                    }
                }

                Text(msg.message)
                    .font(.callout)
                    .foregroundStyle(msg.isCurrentUser ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(msg.isCurrentUser ? Color.dinkrGreen : Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(msg.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !msg.isCurrentUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Schedule Match Sheet

struct ScheduleMatchSheet: View {
    @Environment(\.dismiss) private var dismiss
    let teamAName: String
    let teamBName: String

    @State private var selectedDate = Date().addingTimeInterval(60 * 60 * 48)
    @State private var selectedTime = Date()
    @State private var location = ""
    @State private var teamAPlayer1 = ""
    @State private var teamAPlayer2 = ""
    @State private var teamBPlayer1 = ""
    @State private var teamBPlayer2 = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Match Details") {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .tint(Color.dinkrGreen)
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .tint(Color.dinkrGreen)
                    TextField("Court / Location", text: $location)
                }

                Section("\(teamAName) Pair") {
                    TextField("Player 1", text: $teamAPlayer1)
                    TextField("Player 2", text: $teamAPlayer2)
                }

                Section("\(teamBName) Pair") {
                    TextField("Player 1", text: $teamBPlayer1)
                    TextField("Player 2", text: $teamBPlayer2)
                }

                Section {
                    Button {
                        HapticManager.success()
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Schedule Match")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.dinkrGreen)
                            .padding(.vertical, 2)
                    )
                }
            }
            .navigationTitle("Schedule Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TeamChallengeView()
    }
}

import SwiftUI
import FirebaseFirestore

// MARK: - Model

enum ServingTeam {
    case teamA, teamB
}

struct LiveScoreGame: Identifiable {
    var id: String
    var teamAName: String
    var teamBName: String
    var scoreA: Int
    var scoreB: Int
    var servingTeam: ServingTeam
    var winTo: Int
    var pointLog: [String]
    var isComplete: Bool
    var rallyCount: Int
}

extension LiveScoreGame {
    static func newGame(teamA: String, teamB: String, winTo: Int = 11) -> LiveScoreGame {
        LiveScoreGame(
            id: UUID().uuidString,
            teamAName: teamA,
            teamBName: teamB,
            scoreA: 0,
            scoreB: 0,
            servingTeam: .teamA,
            winTo: winTo,
            pointLog: ["Game started · \(teamA) serves"],
            isComplete: false,
            rallyCount: 0
        )
    }
}

// MARK: - ViewModel

@MainActor
class LiveScoreViewModel: ObservableObject {
    @Published var game: LiveScoreGame
    @Published var showWinBanner: Bool = false
    @Published var winnerName: String = ""
    @Published var bannerScale: CGFloat = 0.3
    @Published var bannerOpacity: Double = 0
    @Published var serverPulse: Bool = false
    @Published var showScoreFlash: Bool = false
    @Published var lastScorer: ServingTeam? = nil

    var gameSessionId: String? = nil

    private let db = Firestore.firestore()
    private var scoreListener: ListenerRegistration? = nil

    private var history: [LiveScoreGame] = []
    private var pulseTimer: Timer?

    init(game: LiveScoreGame = LiveScoreGame.newGame(teamA: "Team A", teamB: "Team B"),
         gameSessionId: String? = nil) {
        self.game = game
        self.gameSessionId = gameSessionId
        startPulse()
    }

    private func startPulse() {
        pulseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                withAnimation(.easeInOut(duration: 0.4)) {
                    self?.serverPulse.toggle()
                }
            }
        }
    }

    // MARK: - Firestore Sync

    private func syncToFirestore() async {
        guard let sessionId = gameSessionId else { return }
        let data: [String: Any] = [
            "liveScore": [
                "scoreA": game.scoreA,
                "scoreB": game.scoreB,
                "teamAName": game.teamAName,
                "teamBName": game.teamBName,
                "isComplete": game.isComplete,
                "servingTeam": game.servingTeam == .teamA ? "A" : "B"
            ]
        ]
        try? await db.collection("gameSessions").document(sessionId).updateData(data)
    }

    func startListening() {
        guard let sessionId = gameSessionId else { return }
        scoreListener = db.collection("gameSessions").document(sessionId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self, let data = snapshot?.data(),
                      let liveScoreMap = data["liveScore"] as? [String: Any] else { return }

                let remoteA = liveScoreMap["scoreA"] as? Int ?? 0
                let remoteB = liveScoreMap["scoreB"] as? Int ?? 0
                let remoteTeamA = liveScoreMap["teamAName"] as? String ?? self.game.teamAName
                let remoteTeamB = liveScoreMap["teamBName"] as? String ?? self.game.teamBName
                let remoteComplete = liveScoreMap["isComplete"] as? Bool ?? false
                let remoteServing = liveScoreMap["servingTeam"] as? String ?? "A"

                // Only update if the remote state differs from local to avoid echo loops
                if remoteA != self.game.scoreA || remoteB != self.game.scoreB {
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.game.scoreA = remoteA
                        self.game.scoreB = remoteB
                        self.game.teamAName = remoteTeamA
                        self.game.teamBName = remoteTeamB
                        self.game.isComplete = remoteComplete
                        self.game.servingTeam = remoteServing == "A" ? .teamA : .teamB
                    }
                }
            }
    }

    func stopListening() {
        scoreListener?.remove()
        scoreListener = nil
    }

    // MARK: - Game Actions

    func scorePoint(team: ServingTeam) {
        guard !game.isComplete else { return }
        history.append(game)
        lastScorer = team

        let prevScore = (game.scoreA, game.scoreB)
        switch team {
        case .teamA:
            game.scoreA += 1
            game.rallyCount += 1
            let entry = "\(game.teamAName) scores · \(game.scoreA)-\(game.scoreB)"
            game.pointLog.append(entry)
        case .teamB:
            game.scoreB += 1
            game.rallyCount += 1
            let entry = "\(game.teamBName) scores · \(game.scoreA)-\(game.scoreB)"
            game.pointLog.append(entry)
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            showScoreFlash = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showScoreFlash = false
        }

        _ = prevScore
        checkWinCondition()
        Task { await syncToFirestore() }
    }

    func sideOut() {
        guard !game.isComplete else { return }
        history.append(game)
        let newServer: ServingTeam = game.servingTeam == .teamA ? .teamB : .teamA
        game.servingTeam = newServer
        game.rallyCount = 0
        let serverName = newServer == .teamA ? game.teamAName : game.teamBName
        game.pointLog.append("Side out · \(serverName) serves")
        Task { await syncToFirestore() }
    }

    func undoLastPoint() {
        guard let last = history.last else { return }
        game = last
        history.removeLast()
        showWinBanner = false
    }

    func resetGame() {
        history.removeAll()
        game = LiveScoreGame.newGame(teamA: game.teamAName, teamB: game.teamBName, winTo: game.winTo)
        showWinBanner = false
        bannerScale = 0.3
        bannerOpacity = 0
        Task { await syncToFirestore() }
    }

    private func checkWinCondition() {
        let needed = game.winTo
        let a = game.scoreA
        let b = game.scoreB
        let winByTwo = abs(a - b) >= 2

        if (a >= needed || b >= needed) && winByTwo {
            game.isComplete = true
            winnerName = a > b ? game.teamAName : game.teamBName
            game.pointLog.append("🏆 \(winnerName) wins!")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    self.bannerScale = 1.0
                    self.bannerOpacity = 1.0
                    self.showWinBanner = true
                }
            }
        }
    }
}

// MARK: - Main View

struct LiveScoreView: View {
    @StateObject private var vm: LiveScoreViewModel
    @State private var showWinToSheet = false
    @State private var showRenameSheet = false
    @State private var tempTeamA = ""
    @State private var tempTeamB = ""
    @State private var showHistory = false

    init(gameSessionId: String? = nil) {
        _vm = StateObject(wrappedValue: LiveScoreViewModel(
            game: LiveScoreGame.newGame(teamA: "Team A", teamB: "Team B"),
            gameSessionId: gameSessionId
        ))
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                scoreboard
                actionRow
                scoreHistorySection
            }

            if vm.showWinBanner {
                winnerOverlay
            }
        }
        .navigationTitle("Live Score")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if vm.gameSessionId != nil { vm.startListening() }
        }
        .onDisappear {
            vm.stopListening()
        }
        .sheet(isPresented: $showRenameSheet) {
            renameSheet
        }
        .sheet(isPresented: $showWinToSheet) {
            winToSheet
        }
    }

    // MARK: Header Bar

    private var headerBar: some View {
        ZStack {
            Color.dinkrNavy

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Win to \(vm.game.winTo)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Button {
                        showWinToSheet = true
                    } label: {
                        Label("Change", systemImage: "slider.horizontal.3")
                            .font(.caption2)
                            .foregroundColor(Color.dinkrAmber)
                    }
                }

                Spacer()

                VStack(spacing: 2) {
                    Image(systemName: "sportscourt.fill")
                        .foregroundColor(Color.dinkrGreen)
                    Text("LIVE")
                        .font(.caption2.bold())
                        .foregroundColor(Color.dinkrGreen)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        vm.undoLastPoint()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 16))
                    }

                    Button {
                        showRenameSheet = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(height: 60)
    }

    // MARK: Scoreboard

    private var scoreboard: some View {
        HStack(spacing: 0) {
            teamColumn(
                name: vm.game.teamAName,
                score: vm.game.scoreA,
                team: .teamA,
                color: Color.dinkrGreen,
                isServer: vm.game.servingTeam == .teamA
            )

            Divider()
                .frame(width: 1)
                .background(Color.secondary.opacity(0.3))

            teamColumn(
                name: vm.game.teamBName,
                score: vm.game.scoreB,
                team: .teamB,
                color: Color.dinkrCoral,
                isServer: vm.game.servingTeam == .teamB
            )
        }
        .background(Color.cardBackground)
        .padding(.vertical, 8)
    }

    private func teamColumn(name: String, score: Int, team: ServingTeam, color: Color, isServer: Bool) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Text(name)
                    .font(.subheadline.bold())
                    .foregroundColor(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if isServer {
                    Circle()
                        .fill(Color.dinkrAmber)
                        .frame(width: 10, height: 10)
                        .scaleEffect(vm.serverPulse ? 1.3 : 0.85)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: vm.serverPulse)
                }
            }

            Text("\(score)")
                .font(.system(size: 88, weight: .black, design: .rounded))
                .foregroundColor(color)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: score)
                .frame(maxWidth: .infinity)

            Button {
                vm.scorePoint(team: team)
            } label: {
                Text("+1")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(vm.game.isComplete)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    // MARK: Action Row

    private var actionRow: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                rallyBadge

                Button {
                    vm.sideOut()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left.arrow.right")
                        Text("Side Out")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundColor(Color.dinkrNavy)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.dinkrNavy, lineWidth: 1.5)
                    )
                }
                .disabled(vm.game.isComplete)

                Button {
                    withAnimation { showHistory.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showHistory ? "chevron.up" : "list.bullet")
                        Text(showHistory ? "Hide" : "Log")
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundColor(Color.dinkrSky)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.dinkrSky, lineWidth: 1.5)
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .padding(.bottom, 4)
    }

    private var rallyBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .font(.caption)
                .foregroundColor(Color.dinkrAmber)
            Text("Rally \(vm.game.rallyCount)")
                .font(.caption.bold())
                .foregroundColor(Color.dinkrAmber)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.dinkrAmber.opacity(0.15))
        .clipShape(Capsule())
    }

    // MARK: Score History

    @ViewBuilder private var scoreHistorySection: some View {
        SwiftUI.Group {
            if showHistory {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Point Log")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(vm.game.pointLog.count) events")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    Divider()

                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(vm.game.pointLog.enumerated().reversed()), id: \.offset) { index, entry in
                                    HStack {
                                        Text("\(index + 1).")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .frame(width: 28, alignment: .trailing)

                                        Text(entry)
                                            .font(.caption)
                                            .foregroundColor(entryColor(entry))

                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(index % 2 == 0 ? Color.clear : Color.secondary.opacity(0.04))
                                    .id(index)
                                }
                            }
                        }
                        .frame(maxHeight: 180)
                        .onChange(of: vm.game.pointLog.count) { _, _ in
                            withAnimation {
                                proxy.scrollTo(vm.game.pointLog.count - 1)
                            }
                        }
                    }
                }
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func entryColor(_ entry: String) -> Color {
        if entry.contains(vm.game.teamAName) && entry.contains("scores") {
            return Color.dinkrGreen
        } else if entry.contains(vm.game.teamBName) && entry.contains("scores") {
            return Color.dinkrCoral
        } else if entry.contains("Side out") {
            return Color.dinkrSky
        } else if entry.contains("wins") {
            return Color.dinkrAmber
        }
        return .secondary
    }

    // MARK: Winner Overlay

    private var winnerOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("🏆")
                        .font(.system(size: 64))

                    Text("\(vm.winnerName) Wins!")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    Text("\(vm.game.scoreA) – \(vm.game.scoreB)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                }

                VStack(spacing: 12) {
                    Button {
                        vm.resetGame()
                    } label: {
                        Text("Play Again")
                            .font(.headline)
                            .foregroundColor(Color.dinkrNavy)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.dinkrGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        // Save result action — stub for integration
                        vm.resetGame()
                    } label: {
                        Text("Save Result")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 32)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.dinkrNavy)
                    .shadow(radius: 30)
            )
            .padding(.horizontal, 24)
            .scaleEffect(vm.bannerScale)
            .opacity(vm.bannerOpacity)
        }
    }

    // MARK: Rename Sheet

    private var renameSheet: some View {
        NavigationStack {
            Form {
                Section("Team Names") {
                    TextField("Team A", text: $tempTeamA)
                    TextField("Team B", text: $tempTeamB)
                }
            }
            .navigationTitle("Edit Teams")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showRenameSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !tempTeamA.isEmpty { vm.game.teamAName = tempTeamA }
                        if !tempTeamB.isEmpty { vm.game.teamBName = tempTeamB }
                        showRenameSheet = false
                    }
                }
            }
        }
        .onAppear {
            tempTeamA = vm.game.teamAName
            tempTeamB = vm.game.teamBName
        }
        .presentationDetents([.medium])
    }

    // MARK: Win To Sheet

    private var winToSheet: some View {
        NavigationStack {
            List {
                ForEach([11, 15, 21], id: \.self) { value in
                    Button {
                        vm.game.winTo = value
                        showWinToSheet = false
                    } label: {
                        HStack {
                            Text("First to \(value)")
                                .foregroundColor(.primary)
                            Spacer()
                            if vm.game.winTo == value {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.dinkrGreen)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Win Condition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showWinToSheet = false }
                }
            }
        }
        .presentationDetents([.height(260)])
    }
}

#Preview {
    NavigationStack {
        LiveScoreView()
    }
}

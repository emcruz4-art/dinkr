import SwiftUI

// MARK: - LogGameResultView

struct LogGameResultView: View {
    @Environment(\.dismiss) private var dismiss

    // Step state (0 = Find Game, 1 = Score, 2 = Details, 3 = Share)
    @State private var currentStep = 0
    private let totalSteps = 4

    // Step 0 — Find Game
    @State private var sessionSearchText = ""
    @State private var linkedSessionId: String? = nil
    @State private var isQuickLog = false
    @State private var quickLogFormat: GameFormat = .singles

    // Step 1 — Score Entry
    @State private var myScore = 0
    @State private var theirScore = 0
    @State private var selectedFormat: GameFormat = .singles
    @State private var isMultiSet = false
    @State private var sets: [SetScore] = [SetScore()]
    @State private var servingSide: ServingSide = .us
    @State private var explicitWinner: WinnerChoice = .autoDetect

    // Step 2 — Details
    @State private var searchText = ""
    @State private var selectedPlayer: User? = nil
    @State private var unknownOpponent = false
    @State private var courtName = ""
    @State private var matchDuration: Int = 30
    @State private var matchNotes = ""
    @State private var gameRating: Int = 0

    // Step 3 — Share
    @State private var shareImage: UIImage? = nil
    @State private var isRendering = false
    @State private var submitToDUPR = false
    @State private var cardRevealed = false

    // Win celebration
    @State private var showWinCelebration = false

    // MARK: - Mock recent sessions
    private let mockSessions: [MockSession] = [
        MockSession(id: "s1", title: "Mueller Open Play", date: Date().addingTimeInterval(-3600), format: .openPlay),
        MockSession(id: "s2", title: "Westside Doubles Night", date: Date().addingTimeInterval(-86400), format: .doubles),
        MockSession(id: "s3", title: "South Lamar Singles Ladder", date: Date().addingTimeInterval(-172800), format: .singles),
    ]

    private var filteredSessions: [MockSession] {
        if sessionSearchText.isEmpty { return mockSessions }
        return mockSessions.filter { $0.title.localizedCaseInsensitiveContains(sessionSearchText) }
    }

    private var filteredPlayers: [User] {
        if searchText.isEmpty { return User.mockPlayers }
        return User.mockPlayers.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
            || $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var effectiveFormat: GameFormat {
        isQuickLog ? quickLogFormat : selectedFormat
    }

    // Auto-detect win from score or use explicit picker
    private var isWin: Bool {
        switch explicitWinner {
        case .autoDetect: return myScore > theirScore
        case .me:         return true
        case .them:       return false
        }
    }

    private var canProceedStep0: Bool {
        isQuickLog || linkedSessionId != nil
    }

    private var canProceedStep1: Bool {
        if isMultiSet {
            return sets.allSatisfy { $0.myScore > 0 || $0.theirScore > 0 }
        }
        return myScore != theirScore // prevent tied score advancing
    }

    private var canProceedStep2: Bool {
        selectedPlayer != nil || unknownOpponent
    }

    private var celebrationScore: String { "\(myScore) – \(theirScore)" }
    private var celebrationOpponent: String {
        unknownOpponent ? "Unknown" : (selectedPlayer?.displayName ?? "Unknown")
    }

    private var builtResult: GameResult {
        GameResult(
            id: UUID().uuidString,
            sessionId: linkedSessionId ?? "",
            opponentId: selectedPlayer?.id ?? "",
            opponentName: unknownOpponent ? "Unknown" : (selectedPlayer?.displayName ?? "Unknown"),
            opponentSkill: selectedPlayer?.skillLevel ?? .intermediate35,
            myScore: myScore,
            opponentScore: theirScore,
            format: effectiveFormat,
            courtName: courtName.trimmingCharacters(in: .whitespaces),
            playedAt: Date()
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    stepIndicator
                        .padding(.top, 8)
                        .padding(.bottom, 20)

                    TabView(selection: $currentStep) {
                        findGameStep.tag(0)
                        scoreEntryStep.tag(1)
                        detailsStep.tag(2)
                        shareStep.tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.spring(response: 0.38, dampingFraction: 0.8), value: currentStep)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if currentStep == 0 {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(Color.dinkrGreen)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentStep > 0 {
                        Button {
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                                currentStep -= 1
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.subheadline.weight(.semibold))
                                Text("Back")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(Color.dinkrGreen)
                        }
                    }
                }
            }
        }
        .winCelebration(
            isPresented: $showWinCelebration,
            score: celebrationScore,
            opponent: celebrationOpponent,
            duprChange: 0.08
        )
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= currentStep ? Color.dinkrGreen : Color.secondary.opacity(0.25))
                    .frame(width: i == currentStep ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
            }
        }
    }

    // MARK: - Step 0: Find Game

    private var findGameStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Find your\ngame")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(Color.primary)
                    Text("Link to a session or log manually")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Quick Log toggle
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isQuickLog.toggle()
                        if isQuickLog { linkedSessionId = nil }
                    }
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isQuickLog ? Color.dinkrGreen.opacity(0.15) : Color.cardBackground)
                                .frame(width: 44, height: 44)
                            Image(systemName: isQuickLog ? "bolt.fill" : "bolt")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(isQuickLog ? Color.dinkrGreen : Color.secondary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Quick Log")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.primary)
                            Text("Manual entry — no session needed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: isQuickLog ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundStyle(isQuickLog ? Color.dinkrGreen : Color.secondary.opacity(0.3))
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isQuickLog ? Color.dinkrGreen.opacity(0.07) : Color.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(isQuickLog ? Color.dinkrGreen.opacity(0.4) : Color.secondary.opacity(0.15), lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)

                // Quick log format picker
                if isQuickLog {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Format")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(GameFormat.allCases, id: \.self) { format in
                                    let sel = quickLogFormat == format
                                    Button {
                                        quickLogFormat = format
                                        HapticManager.selection()
                                    } label: {
                                        Text(format.displayLabel)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(sel ? .white : Color.primary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(sel ? Color.dinkrGreen : Color.cardBackground)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule().strokeBorder(
                                                    sel ? Color.clear : Color.secondary.opacity(0.2),
                                                    lineWidth: 1
                                                )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Session search / list (only when not quick log)
                if !isQuickLog {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Sessions")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Search sessions...", text: $sessionSearchText)
                                .font(.subheadline)
                        }
                        .padding(12)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
                        )

                        VStack(spacing: 0) {
                            ForEach(filteredSessions) { session in
                                SessionRow(
                                    session: session,
                                    isSelected: linkedSessionId == session.id
                                ) {
                                    linkedSessionId = linkedSessionId == session.id ? nil : session.id
                                    HapticManager.selection()
                                }
                                if session.id != filteredSessions.last?.id {
                                    Divider().padding(.leading, 56)
                                }
                            }
                        }
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
                        )
                    }
                }

                nextButton(enabled: canProceedStep0, label: "Next") {
                    currentStep = 1
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Step 1: Score Entry

    private var scoreEntryStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("What was\nthe score?")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(Color.primary)
                    Text(isMultiSet ? "Enter each set separately" : "Tap +/− to set the score")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Multi-set toggle
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Set-Based Scoring")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.primary)
                        Text("For best-of-3 or best-of-5 matches")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $isMultiSet)
                        .tint(Color.dinkrGreen)
                        .labelsHidden()
                }
                .padding(16)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
                )

                if isMultiSet {
                    // Multi-set score entry
                    VStack(spacing: 12) {
                        ForEach(Array(sets.indices), id: \.self) { idx in
                            SetScoreRow(
                                label: "Set \(idx + 1)",
                                setScore: $sets[idx],
                                accentColor: idx % 2 == 0 ? Color.dinkrGreen : Color.dinkrSky
                            )
                        }
                        if sets.count < 5 {
                            Button {
                                sets.append(SetScore())
                                HapticManager.selection()
                            } label: {
                                Label("Add Set", systemImage: "plus.circle.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.dinkrGreen)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.dinkrGreen.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                        if sets.count > 1 {
                            Button {
                                sets.removeLast()
                                HapticManager.selection()
                            } label: {
                                Label("Remove Last Set", systemImage: "minus.circle")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.dinkrCoral)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    // Single game score
                    HStack(spacing: 16) {
                        ScoreStepper(label: "You", score: $myScore, accentColor: Color.dinkrGreen)
                        ScoreStepper(label: "Them", score: $theirScore, accentColor: Color.dinkrCoral)
                    }
                }

                // Serving side
                VStack(alignment: .leading, spacing: 10) {
                    Text("Who served first?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach(ServingSide.allCases, id: \.self) { side in
                            let selected = servingSide == side
                            Button {
                                servingSide = side
                                HapticManager.selection()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: side.icon)
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(side.label)
                                        .font(.subheadline.weight(.semibold))
                                }
                                .foregroundStyle(selected ? .white : Color.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selected ? Color.dinkrNavy : Color.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(
                                            selected ? Color.dinkrNavy : Color.secondary.opacity(0.2),
                                            lineWidth: 1
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Who won?
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Who won?")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        if explicitWinner == .autoDetect {
                            Text("Auto-detected from score")
                                .font(.caption)
                                .foregroundStyle(Color.dinkrGreen)
                        }
                    }

                    HStack(spacing: 8) {
                        ForEach(WinnerChoice.allCases, id: \.self) { choice in
                            let selected = explicitWinner == choice
                            Button {
                                explicitWinner = choice
                                HapticManager.selection()
                            } label: {
                                HStack(spacing: 5) {
                                    if let icon = choice.icon {
                                        Image(systemName: icon)
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    Text(choice.label)
                                        .font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(selected ? .white : Color.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selected ? winnerChoiceColor(choice) : Color.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(
                                            selected ? Color.clear : Color.secondary.opacity(0.2),
                                            lineWidth: 1
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                nextButton(enabled: canProceedStep1, label: "Next") {
                    currentStep = 2
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Step 2: Details

    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Add\ndetails")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(Color.primary)
                        Text("Who did you play? Where? How long?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Opponent search
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Opponent")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Search players...", text: $searchText)
                                .font(.subheadline)
                        }
                        .padding(12)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
                        )

                        VStack(spacing: 0) {
                            OpponentRow(
                                displayName: "Unknown Opponent",
                                username: "anonymous",
                                skillLevel: nil,
                                isSelected: unknownOpponent
                            ) {
                                unknownOpponent = true
                                selectedPlayer = nil
                                HapticManager.selection()
                            }
                            Divider().padding(.leading, 72)
                            ForEach(Array(filteredPlayers.prefix(5))) { player in
                                OpponentRow(
                                    displayName: player.displayName,
                                    username: player.username,
                                    skillLevel: player.skillLevel,
                                    isSelected: selectedPlayer?.id == player.id && !unknownOpponent
                                ) {
                                    selectedPlayer = player
                                    unknownOpponent = false
                                    HapticManager.selection()
                                }
                                if player.id != filteredPlayers.prefix(5).last?.id {
                                    Divider().padding(.leading, 72)
                                }
                            }
                        }
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
                        )
                    }

                    // Court selector
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Court")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(Color.dinkrGreen)
                                .font(.title3)
                            TextField("Which court?", text: $courtName)
                                .font(.subheadline)
                        }
                        .padding(14)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
                        )

                        // Nearby court suggestions
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(nearbyCourtSuggestions, id: \.self) { suggestion in
                                    Button {
                                        courtName = suggestion
                                        HapticManager.selection()
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "mappin.fill")
                                                .font(.system(size: 10, weight: .bold))
                                            Text(suggestion)
                                                .font(.caption.weight(.semibold))
                                        }
                                        .foregroundStyle(courtName == suggestion ? .white : Color.dinkrSky)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(
                                            courtName == suggestion
                                                ? Color.dinkrSky
                                                : Color.dinkrSky.opacity(0.12)
                                        )
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Duration
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Duration")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(matchDuration) min")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.dinkrAmber)
                        }
                        Slider(value: Binding(
                            get: { Double(matchDuration) },
                            set: { matchDuration = Int($0) }
                        ), in: 10...120, step: 5)
                        .tint(Color.dinkrAmber)

                        HStack {
                            Text("10 min")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("2 hrs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
                    )

                    // Match notes
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Notes (optional)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextField("How did it go? Any highlights or notes...", text: $matchNotes, axis: .vertical)
                            .font(.subheadline)
                            .lineLimit(3...5)
                            .padding(14)
                            .background(Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
                            )
                    }

                    // Game quality rating
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How was this game?")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    gameRating = gameRating == star ? 0 : star
                                    HapticManager.selection()
                                } label: {
                                    Image(systemName: star <= gameRating ? "star.fill" : "star")
                                        .font(.system(size: 28))
                                        .foregroundStyle(star <= gameRating ? Color.dinkrAmber : Color.secondary.opacity(0.3))
                                        .scaleEffect(star == gameRating ? 1.15 : 1.0)
                                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: gameRating)
                                }
                                .buttonStyle(.plain)
                            }
                            if gameRating > 0 {
                                Text(ratingLabel(gameRating))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.dinkrAmber)
                                    .transition(.opacity.combined(with: .move(edge: .leading)))
                            }
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: gameRating)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
                        )
                    }

                    nextButton(enabled: canProceedStep2, label: "Review & Share") {
                        currentStep = 3
                        renderShareCard()
                        if isWin {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showWinCelebration = true
                            }
                        }
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
                            cardRevealed = true
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Step 3: Share & DUPR

    private var shareStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isWin ? "Great game!" : "Game logged")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(Color.primary)
                        Text(isWin ? "You crushed it. Share the moment." : "Every game makes you better.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(isWin ? Color.dinkrGreen.opacity(0.15) : Color.secondary.opacity(0.1))
                            .frame(width: 52, height: 52)
                        Text(isWin ? "🏆" : "💪")
                            .font(.title2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Match summary card preview with animated reveal
                MatchShareCard(result: builtResult, player: User.mockCurrentUser)
                    .shadow(color: (isWin ? Color.dinkrGreen : Color.black).opacity(0.25), radius: 24, x: 0, y: 10)
                    .scaleEffect(cardRevealed ? 1.0 : 0.88)
                    .opacity(cardRevealed ? 1.0 : 0)
                    .animation(.spring(response: 0.55, dampingFraction: 0.72), value: cardRevealed)
                    .onAppear {
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.15)) {
                            cardRevealed = true
                        }
                    }

                // DUPR submit toggle
                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.dinkrAmber.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Text("D")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(Color.dinkrAmber)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Submit to DUPR")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.primary)
                            Text("Pending DUPR integration")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $submitToDUPR)
                            .tint(Color.dinkrAmber)
                            .labelsHidden()
                    }
                    .padding(16)

                    if submitToDUPR {
                        Divider().padding(.horizontal, 16)
                        HStack(spacing: 10) {
                            Image(systemName: isWin ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(isWin ? Color.dinkrGreen : Color.dinkrCoral)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Estimated DUPR Impact")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(isWin ? "+0.08 to your rating" : "−0.03 to your rating")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(isWin ? Color.dinkrGreen : Color.dinkrCoral)
                            }
                            Spacer()
                            Text("~24h")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.75), value: submitToDUPR)

                // Action buttons
                VStack(spacing: 12) {
                    if let img = shareImage {
                        ShareLink(
                            item: Image(uiImage: img),
                            preview: SharePreview(
                                "\(User.mockCurrentUser.displayName) \(builtResult.isWin ? "won" : "played") \(builtResult.scoreDisplay) on Dinkr",
                                image: Image(uiImage: img)
                            )
                        ) {
                            Label("Share Result", systemImage: "square.and.arrow.up")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 14))
                        }
                    } else {
                        Button {
                            renderShareCard()
                        } label: {
                            HStack(spacing: 8) {
                                if isRendering {
                                    ProgressView().tint(.white).scaleEffect(0.8)
                                }
                                Label(
                                    isRendering ? "Preparing…" : "Share Result",
                                    systemImage: "square.and.arrow.up"
                                )
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                isRendering ? Color.dinkrGreen.opacity(0.6) : Color.dinkrGreen,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                        }
                        .disabled(isRendering)
                    }

                    Button("Done") {
                        HapticManager.success()
                        dismiss()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.dinkrGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.dinkrGreen, lineWidth: 1.5)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Shared Next Button

    @ViewBuilder
    private func nextButton(enabled: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                action()
            }
        } label: {
            HStack(spacing: 6) {
                Text(label)
                    .font(.subheadline.weight(.bold))
                Image(systemName: "arrow.right")
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                enabled ? Color.dinkrGreen : Color.secondary.opacity(0.3),
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
        .disabled(!enabled)
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private var nearbyCourtSuggestions: [String] {
        ["Mueller Rec Center", "Westside Pickleball", "South Lamar Sports", "Barton Springs Tennis", "Walnut Creek"]
    }

    private func ratingLabel(_ stars: Int) -> String {
        switch stars {
        case 1: return "Rough one"
        case 2: return "Decent"
        case 3: return "Good game"
        case 4: return "Great game"
        case 5: return "Epic match!"
        default: return ""
        }
    }

    private func winnerChoiceColor(_ choice: WinnerChoice) -> Color {
        switch choice {
        case .autoDetect: return Color.dinkrNavy
        case .me:         return Color.dinkrGreen
        case .them:       return Color.dinkrCoral
        }
    }

    private func renderShareCard() {
        isRendering = true
        shareImage = nil
        Task { @MainActor in
            let renderer = ImageRenderer(
                content: MatchShareCard(result: builtResult, player: User.mockCurrentUser)
                    .environment(\.colorScheme, .dark)
            )
            renderer.scale = 3.0
            shareImage = renderer.uiImage
            isRendering = false
        }
    }
}

// MARK: - Supporting Types

struct SetScore {
    var myScore: Int = 0
    var theirScore: Int = 0
}

enum ServingSide: CaseIterable {
    case us, them

    var label: String {
        switch self {
        case .us:   return "We served"
        case .them: return "They served"
        }
    }

    var icon: String {
        switch self {
        case .us:   return "figure.pickleball"
        case .them: return "person.fill"
        }
    }
}

enum WinnerChoice: CaseIterable {
    case autoDetect, me, them

    var label: String {
        switch self {
        case .autoDetect: return "Auto"
        case .me:         return "I won"
        case .them:       return "They won"
        }
    }

    var icon: String? {
        switch self {
        case .autoDetect: return "wand.and.stars"
        case .me:         return "trophy.fill"
        case .them:       return nil
        }
    }
}

struct MockSession: Identifiable {
    let id: String
    let title: String
    let date: Date
    let format: GameFormat
}

// MARK: - SessionRow

private struct SessionRow: View {
    let session: MockSession
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.dinkrSky.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.dinkrSky)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.title)
                        .font(.subheadline.weight(isSelected ? .bold : .regular))
                        .foregroundStyle(Color.primary)
                    HStack(spacing: 6) {
                        Text(session.format.displayLabel)
                            .font(.caption)
                            .foregroundStyle(Color.dinkrGreen)
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(session.date, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? Color.dinkrGreen : Color.secondary.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.dinkrGreen.opacity(0.05) : Color.clear)
    }
}

// MARK: - SetScoreRow

private struct SetScoreRow: View {
    let label: String
    @Binding var setScore: SetScore
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .frame(width: 44, alignment: .leading)

            HStack(spacing: 10) {
                Button {
                    if setScore.myScore > 0 {
                        setScore.myScore -= 1
                        HapticManager.selection()
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(setScore.myScore > 0 ? Color.dinkrGreen : Color.secondary.opacity(0.3))
                }
                .buttonStyle(.plain)

                Text("\(setScore.myScore)")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(Color.dinkrGreen)
                    .frame(minWidth: 40)
                    .contentTransition(.numericText())

                Text("–")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.secondary)

                Text("\(setScore.theirScore)")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(Color.dinkrCoral)
                    .frame(minWidth: 40)
                    .contentTransition(.numericText())

                Button {
                    if setScore.theirScore > 0 {
                        setScore.theirScore -= 1
                        HapticManager.selection()
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(setScore.theirScore > 0 ? Color.dinkrCoral : Color.secondary.opacity(0.3))
                }
                .buttonStyle(.plain)

                Button {
                    if setScore.myScore < 21 {
                        setScore.myScore += 1
                        HapticManager.selection()
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color.dinkrGreen)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - ScoreStepper

private struct ScoreStepper: View {
    let label: String
    @Binding var score: Int
    let accentColor: Color

    var body: some View {
        VStack(spacing: 12) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 20) {
                Button {
                    if score > 0 {
                        score -= 1
                        HapticManager.selection()
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(score > 0 ? accentColor : Color.secondary.opacity(0.3))
                }
                .buttonStyle(.plain)

                Text("\(score)")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(accentColor)
                    .frame(minWidth: 60)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: score)

                Button {
                    if score < 21 {
                        score += 1
                        HapticManager.selection()
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(score < 21 ? accentColor : Color.secondary.opacity(0.3))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - OpponentRow

private struct OpponentRow: View {
    let displayName: String
    let username: String
    let skillLevel: SkillLevel?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AvatarView(displayName: displayName, size: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(displayName)
                        .font(.subheadline.weight(isSelected ? .bold : .regular))
                        .foregroundStyle(Color.primary)
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let skill = skillLevel {
                    SkillBadge(level: skill, compact: true)
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? Color.dinkrGreen : Color.secondary.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.dinkrGreen.opacity(0.05) : Color.clear)
    }
}

// MARK: - Preview

#Preview("Log Game Result") {
    LogGameResultView()
}

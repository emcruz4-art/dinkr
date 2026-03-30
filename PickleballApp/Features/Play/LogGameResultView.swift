import SwiftUI

// MARK: - LogGameResultView

struct LogGameResultView: View {
    @Environment(\.dismiss) private var dismiss

    // Step state
    @State private var currentStep = 0

    // Step 0 — Score Entry
    @State private var myScore = 0
    @State private var theirScore = 0
    @State private var selectedFormat: GameFormat = .singles
    @State private var courtName = ""

    // Step 1 — Opponent
    @State private var searchText = ""
    @State private var selectedPlayer: User? = nil
    @State private var unknownOpponent = false

    // Step 2 — Share
    @State private var shareImage: UIImage? = nil
    @State private var isRendering = false

    private var filteredPlayers: [User] {
        if searchText.isEmpty { return User.mockPlayers }
        return User.mockPlayers.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
            || $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var canProceedStep0: Bool {
        !courtName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var canProceedStep1: Bool {
        selectedPlayer != nil || unknownOpponent
    }

    private var builtResult: GameResult {
        GameResult(
            id: UUID().uuidString,
            sessionId: "",
            opponentId: selectedPlayer?.id ?? "",
            opponentName: unknownOpponent ? "Unknown" : (selectedPlayer?.displayName ?? "Unknown"),
            opponentSkill: selectedPlayer?.skillLevel ?? .intermediate35,
            myScore: myScore,
            opponentScore: theirScore,
            format: selectedFormat,
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

                    // Slide content
                    TabView(selection: $currentStep) {
                        scoreEntryStep.tag(0)
                        opponentStep.tag(1)
                        shareStep.tag(2)
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
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(i == currentStep ? Color.dinkrGreen : Color.secondary.opacity(0.25))
                    .frame(width: i == currentStep ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
            }
        }
    }

    // MARK: - Step 0: Score Entry

    private var scoreEntryStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("What was\nthe score?")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(Color.primary)

                // Score steppers
                HStack(spacing: 24) {
                    ScoreStepper(
                        label: "You",
                        score: $myScore,
                        accentColor: Color.dinkrGreen
                    )
                    ScoreStepper(
                        label: "Them",
                        score: $theirScore,
                        accentColor: Color.dinkrCoral
                    )
                }
                .frame(maxWidth: .infinity)

                // Format picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Format")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(GameFormat.allCases, id: \.self) { format in
                                let isSelected = selectedFormat == format
                                Button {
                                    selectedFormat = format
                                } label: {
                                    Text(formatLabel(format))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(isSelected ? .white : Color.primary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            isSelected
                                                ? Color.dinkrGreen
                                                : Color.cardBackground
                                        )
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(
                                                    isSelected ? Color.clear : Color.secondary.opacity(0.2),
                                                    lineWidth: 1
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Court name
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
                }

                // Next button
                Button {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                        currentStep = 1
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Next")
                            .font(.subheadline.weight(.bold))
                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        canProceedStep0
                            ? Color.dinkrGreen
                            : Color.secondary.opacity(0.3)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canProceedStep0)
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Step 1: Opponent

    private var opponentStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Who did you\nplay against?")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 24)

                // Search
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
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 12)

            // Player list
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Unknown opponent option
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

                    ForEach(filteredPlayers) { player in
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

                        if player.id != filteredPlayers.last?.id {
                            Divider().padding(.leading, 72)
                        }
                    }
                }
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }

            // Next button
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                    currentStep = 2
                    renderShareCard()
                }
            } label: {
                HStack(spacing: 6) {
                    Text("Next")
                        .font(.subheadline.weight(.bold))
                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    canProceedStep1
                        ? Color.dinkrGreen
                        : Color.secondary.opacity(0.3)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!canProceedStep1)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Step 2: Share

    private var shareStep: some View {
        ScrollView {
            VStack(spacing: 28) {
                Text("Game logged! 🎉")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Card preview
                MatchShareCard(result: builtResult, player: User.mockCurrentUser)
                    .shadow(color: .black.opacity(0.22), radius: 20, x: 0, y: 8)

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
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                }
                                Label(isRendering ? "Preparing…" : "Share Result", systemImage: "square.and.arrow.up")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                isRendering
                                    ? Color.dinkrGreen.opacity(0.6)
                                    : Color.dinkrGreen,
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

    // MARK: - Helpers

    private func formatLabel(_ format: GameFormat) -> String {
        switch format {
        case .singles:     return "Singles"
        case .doubles:     return "Doubles"
        case .mixed:       return "Mixed"
        case .openPlay:    return "Open Play"
        case .round_robin: return "Round Robin"
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

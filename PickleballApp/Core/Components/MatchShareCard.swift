import SwiftUI

// MARK: - Share Card View (rendered to image)

struct MatchShareCard: View {
    let result: GameResult
    let player: User

    private var isWin: Bool { result.isWin }
    private var accentColor: Color { isWin ? Color.dinkrGreen : Color.dinkrCoral }
    private var resultWord: String { isWin ? "WIN" : "LOSS" }

    var body: some View {
        ZStack {
            // Background — deep navy with win/loss tint
            cardBackground

            // Court lines watermark
            CourtLinesBackground()
                .opacity(0.055)

            // Radial glow behind score
            RadialGradient(
                colors: [accentColor.opacity(0.18), Color.clear],
                center: .center,
                startRadius: 20,
                endRadius: 180
            )

            // Content stack
            VStack(spacing: 0) {
                headerRow
                thinDivider
                scoreBlock
                thinDivider
                detailsRow
                Spacer(minLength: 0)
                bottomBrand
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
        .frame(width: 360, height: 480)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(
            // Win: subtle green border glow; Loss: muted
            RoundedRectangle(cornerRadius: 26)
                .strokeBorder(
                    LinearGradient(
                        colors: isWin
                            ? [Color.dinkrGreen.opacity(0.55), Color.dinkrGreen.opacity(0.1), Color.clear]
                            : [Color.white.opacity(0.08), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }

    // MARK: Background

    private var cardBackground: some View {
        LinearGradient(
            stops: isWin ? [
                .init(color: Color.dinkrNavy, location: 0),
                .init(color: Color(red: 0.04, green: 0.22, blue: 0.14), location: 0.6),
                .init(color: Color(red: 0.02, green: 0.15, blue: 0.09), location: 1.0),
            ] : [
                .init(color: Color.dinkrNavy, location: 0),
                .init(color: Color(red: 0.18, green: 0.06, blue: 0.06), location: 0.65),
                .init(color: Color(red: 0.12, green: 0.03, blue: 0.03), location: 1.0),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: Header

    private var headerRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(player.displayName)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.white)
                HStack(spacing: 6) {
                    Text("@\(player.username)")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.55))
                    if let dupr = player.duprRating {
                        Text("DUPR \(dupr, specifier: "%.2f")")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(Color.dinkrAmber)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Color.dinkrAmber.opacity(0.2), in: Capsule())
                    }
                }
            }
            Spacer()
            // Result badge
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 58, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(accentColor.opacity(0.35), lineWidth: 1)
                    )
                VStack(spacing: 1) {
                    Image(systemName: isWin ? "trophy.fill" : "figure.pickleball")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(accentColor)
                    Text(resultWord)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(accentColor)
                }
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: Score Block

    private var scoreBlock: some View {
        HStack(alignment: .center, spacing: 0) {
            // My score
            VStack(spacing: 5) {
                Text("\(result.myScore)")
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundStyle(accentColor)
                    .shadow(color: accentColor.opacity(0.3), radius: 12, x: 0, y: 4)
                Text("You")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .textCase(.uppercase)
                    .kerning(1)
            }
            .frame(maxWidth: .infinity)

            // Center divider dots
            VStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 4, height: 4)
                }
            }

            // Opponent score
            VStack(spacing: 5) {
                Text("\(result.opponentScore)")
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white.opacity(isWin ? 0.45 : 0.7))
                Text(result.opponentName.components(separatedBy: " ").first ?? result.opponentName)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .textCase(.uppercase)
                    .kerning(1)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 22)
    }

    // MARK: Details Row

    private var detailsRow: some View {
        HStack(spacing: 0) {
            // Court name
            DetailChip(
                icon: "mappin.circle.fill",
                text: courtDisplayName,
                color: Color.dinkrSky
            )
            Spacer()
            // Format
            DetailChip(
                icon: "figure.pickleball",
                text: result.format.displayLabel,
                color: Color.dinkrAmber
            )
            Spacer()
            // Date
            DetailChip(
                icon: "calendar",
                text: result.playedAt.formatted(.dateTime.month(.abbreviated).day().year()),
                color: Color.white.opacity(0.45)
            )
        }
        .padding(.vertical, 20)
    }

    private var courtDisplayName: String {
        let parts = result.courtName.components(separatedBy: " ")
        return parts.prefix(2).joined(separator: " ")
    }

    // MARK: Bottom Brand

    private var bottomBrand: some View {
        HStack(alignment: .center) {
            HStack(spacing: 6) {
                MiniPaddleIcon()
                Text("dinkr")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.85))
            }
            Spacer()
            // Court full name (if space)
            if !result.courtName.isEmpty {
                Text(result.courtName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.3))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 140, alignment: .trailing)
            } else {
                Text("dinkr.app")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
        }
        .padding(.top, 14)
    }

    private var thinDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.09))
            .frame(height: 1)
    }
}

// MARK: - Detail Chip

private struct DetailChip: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.75))
                .lineLimit(1)
        }
    }
}

// MARK: - Mini Paddle Icon

private struct MiniPaddleIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.dinkrGreen)
                .frame(width: 10, height: 14)
                .offset(y: -2)
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.dinkrGreen.opacity(0.7))
                .frame(width: 4, height: 5)
                .offset(y: 5)
        }
        .frame(width: 14, height: 18)
    }
}

// MARK: - Court Lines Background

private struct CourtLinesBackground: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            var path = Path()
            // Kitchen line (NVZ)
            path.move(to: CGPoint(x: 0, y: h * 0.38))
            path.addLine(to: CGPoint(x: w, y: h * 0.38))
            path.move(to: CGPoint(x: 0, y: h * 0.62))
            path.addLine(to: CGPoint(x: w, y: h * 0.62))
            // Center line
            path.move(to: CGPoint(x: w * 0.5, y: 0))
            path.addLine(to: CGPoint(x: w * 0.5, y: h))
            // Baselines
            path.move(to: CGPoint(x: 0, y: 0.04 * h))
            path.addLine(to: CGPoint(x: w, y: 0.04 * h))
            path.move(to: CGPoint(x: 0, y: 0.96 * h))
            path.addLine(to: CGPoint(x: w, y: 0.96 * h))
            // Sidelines
            path.move(to: CGPoint(x: 0.04 * w, y: 0))
            path.addLine(to: CGPoint(x: 0.04 * w, y: h))
            path.move(to: CGPoint(x: 0.96 * w, y: 0))
            path.addLine(to: CGPoint(x: 0.96 * w, y: h))
            context.stroke(path, with: .color(.white), lineWidth: 1.2)
        }
    }
}

// MARK: - Share Sheet Wrapper

struct MatchShareSheet: View {
    let result: GameResult
    let player: User
    @Environment(\.dismiss) private var dismiss

    @State private var shareImage: UIImage?
    @State private var isRendering = false
    @State private var cardAppeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 28) {
                    // Card preview with animated entrance
                    MatchShareCard(result: result, player: player)
                        .shadow(
                            color: (result.isWin ? Color.dinkrGreen : Color.black).opacity(0.28),
                            radius: 28, x: 0, y: 12
                        )
                        .scaleEffect(cardAppeared ? 1.0 : 0.9)
                        .opacity(cardAppeared ? 1.0 : 0)
                        .animation(.spring(response: 0.55, dampingFraction: 0.72), value: cardAppeared)
                        .padding(.top, 20)
                        .onAppear {
                            withAnimation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.1)) {
                                cardAppeared = true
                            }
                        }

                    // Action buttons
                    VStack(spacing: 12) {
                        if let img = shareImage {
                            ShareLink(
                                item: Image(uiImage: img),
                                preview: SharePreview(
                                    "\(player.displayName) \(result.isWin ? "won" : "played") \(result.scoreDisplay) on Dinkr",
                                    image: Image(uiImage: img)
                                )
                            ) {
                                Label("Share Result", systemImage: "square.and.arrow.up")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 14))
                            }
                            .padding(.horizontal, 24)
                        } else {
                            Button {
                                renderCard()
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
                                .padding(.vertical, 15)
                                .background(
                                    isRendering ? Color.dinkrGreen.opacity(0.6) : Color.dinkrGreen,
                                    in: RoundedRectangle(cornerRadius: 14)
                                )
                            }
                            .disabled(isRendering)
                            .padding(.horizontal, 24)
                        }

                        Button("Save to Photos") {
                            if let img = shareImage {
                                UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                                HapticManager.success()
                                dismiss()
                            } else {
                                renderCard { img in
                                    UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                                    HapticManager.success()
                                    dismiss()
                                }
                            }
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.dinkrGreen)
                        .padding(.horizontal, 24)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Share Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear { renderCard() }
    }

    // MARK: - Render

    private func renderCard(completion: ((UIImage) -> Void)? = nil) {
        isRendering = true
        Task { @MainActor in
            let renderer = ImageRenderer(content:
                MatchShareCard(result: result, player: player)
                    .environment(\.colorScheme, .dark)
            )
            renderer.scale = 3.0
            if let img = renderer.uiImage {
                shareImage = img
                completion?(img)
            }
            isRendering = false
        }
    }
}

// MARK: - Preview

#Preview("Share Card — Win") {
    MatchShareCard(result: GameResult.mockResults[0], player: User.mockCurrentUser)
        .padding()
        .background(Color.gray)
}

#Preview("Share Card — Loss") {
    MatchShareCard(result: GameResult.mockResults[1], player: User.mockCurrentUser)
        .padding()
        .background(Color.gray)
}

#Preview("Share Sheet") {
    MatchShareSheet(result: GameResult.mockResults[0], player: User.mockCurrentUser)
}

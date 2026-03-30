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
            // Background gradient
            LinearGradient(
                colors: [Color.dinkrNavy, isWin ? Color(red: 0.08, green: 0.35, blue: 0.20) : Color(red: 0.40, green: 0.12, blue: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle court line overlay
            CourtLinesBackground()
                .opacity(0.06)

            // Content
            VStack(spacing: 0) {
                headerRow
                dividerLine
                scoreBlock
                dividerLine
                detailsRow
                bottomBrand
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
        .frame(width: 360, height: 460)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: Header

    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(player.displayName)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.white)
                HStack(spacing: 6) {
                    Text("@\(player.username)")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.6))
                    if let dupr = player.duprRating {
                        Text("DUPR \(dupr, specifier: "%.2f")")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.dinkrAmber)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.dinkrAmber.opacity(0.18), in: Capsule())
                    }
                }
            }
            Spacer()
            // Result badge
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accentColor.opacity(0.22))
                    .frame(width: 52, height: 52)
                Text(resultWord)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(accentColor)
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: Score Block

    private var scoreBlock: some View {
        HStack(alignment: .center, spacing: 0) {
            // My score
            VStack(spacing: 4) {
                Text("\(result.myScore)")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(accentColor)
                Text("You")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.55))
            }
            .frame(maxWidth: .infinity)

            // Divider dash
            VStack(spacing: 6) {
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 5, height: 5)
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 5, height: 5)
            }

            // Opponent score
            VStack(spacing: 4) {
                Text("\(result.opponentScore)")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.5))
                Text(result.opponentName.components(separatedBy: " ").first ?? result.opponentName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
    }

    // MARK: Details Row

    private var detailsRow: some View {
        HStack(spacing: 0) {
            DetailChip(icon: "mappin.circle.fill", text: result.courtName.components(separatedBy: " ").prefix(2).joined(separator: " "), color: Color.dinkrSky)
            Spacer()
            DetailChip(icon: "figure.pickleball", text: result.format.rawValue.capitalized, color: Color.dinkrAmber)
            Spacer()
            DetailChip(icon: "calendar", text: result.playedAt.formatted(.dateTime.month(.abbreviated).day()), color: Color.white.opacity(0.5))
        }
        .padding(.vertical, 20)
    }

    // MARK: Bottom Brand

    private var bottomBrand: some View {
        HStack {
            HStack(spacing: 6) {
                // Mini paddle icon
                MiniPaddleIcon()
                Text("dinkr")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.8))
            }
            Spacer()
            Text("dinkr.app")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.35))
        }
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
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
            // Baseline
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
    @State private var showShareSheet = false
    @State private var isRendering = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 28) {
                    // Card preview
                    MatchShareCard(result: result, player: player)
                        .shadow(color: .black.opacity(0.28), radius: 24, x: 0, y: 10)
                        .padding(.top, 20)

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
                                .background(isRendering ? Color.dinkrGreen.opacity(0.6) : Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 14))
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

#Preview("Share Card") {
    MatchShareCard(result: GameResult.mockResults[0], player: User.mockCurrentUser)
        .padding()
        .background(Color.gray)
}

#Preview("Share Sheet") {
    MatchShareSheet(result: GameResult.mockResults[0], player: User.mockCurrentUser)
}

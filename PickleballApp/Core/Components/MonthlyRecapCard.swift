import SwiftUI

// MARK: - MonthlyRecapData

struct MonthlyRecapData {
    var playerName: String
    var monthYear: String           // e.g. "March 2026"
    var gamesPlayed: Int
    var wins: Int
    var losses: Int
    var courtsVisited: Int
    var topPartner: String          // most-played-with opponent name
    var topCourt: String            // most-played-at court name
    var challengesWon: Int
    var reliabilityScore: Double
    var duprChange: Double          // e.g. +0.12 or -0.05
    var winStreak: Int

    static func mock(for user: User) -> MonthlyRecapData {
        MonthlyRecapData(
            playerName: user.displayName,
            monthYear: "March 2026",
            gamesPlayed: 14,
            wins: 9,
            losses: 5,
            courtsVisited: 4,
            topPartner: "Maria Chen",
            topCourt: "Westside Complex",
            challengesWon: 3,
            reliabilityScore: user.reliabilityScore,
            duprChange: +0.12,
            winStreak: 4
        )
    }
}

// MARK: - Monthly Recap Card (360×520 shareable)

struct MonthlyRecapCard: View {
    let data: MonthlyRecapData

    var body: some View {
        ZStack {
            // ── Background gradient ───────────────────────────────────────
            LinearGradient(
                colors: [Color.dinkrNavy, Color.dinkrGreen.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // ── Court lines canvas overlay ────────────────────────────────
            Canvas { ctx, size in
                ctx.stroke(recapCourtLinePath(size: size),
                           with: .color(.white.opacity(0.05)),
                           lineWidth: 1.2)
            }
            .allowsHitTesting(false)

            // ── Card content ──────────────────────────────────────────────
            VStack(spacing: 0) {

                // Top: wordmark + month
                VStack(spacing: 4) {
                    Text("dinkr")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(Color.dinkrGreen)
                    Text(data.monthYear)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(1.5)
                }
                .padding(.top, 28)

                Spacer()

                // Hero stat: games played
                VStack(spacing: 4) {
                    Text("\(data.gamesPlayed)")
                        .font(.system(size: 72, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: Color.dinkrGreen.opacity(0.4), radius: 12)
                    Text("games played")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))
                        .textCase(.uppercase)
                        .tracking(1.2)
                }

                Spacer()

                // 2×2 stat tiles grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    RecapStatTile(icon: "trophy.fill",
                                  value: "\(data.wins)-\(data.losses)",
                                  label: "W-L Record",
                                  accent: Color.dinkrGreen)
                    RecapStatTile(icon: "mappin.circle.fill",
                                  value: "\(data.courtsVisited)",
                                  label: "Courts Visited",
                                  accent: Color.dinkrSky)
                    RecapStatTile(icon: "person.2.fill",
                                  value: "w/ \(data.topPartner)",
                                  label: "Top Partner",
                                  accent: Color.dinkrSky,
                                  smallValue: true)
                    RecapStatTile(icon: "flame.fill",
                                  value: "\(data.winStreak) streak 🔥",
                                  label: "Win Streak",
                                  accent: Color.dinkrAmber,
                                  smallValue: true)
                }
                .padding(.horizontal, 20)

                Spacer()

                // DUPR change row
                HStack(spacing: 10) {
                    Image(systemName: data.duprChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(data.duprChange >= 0 ? Color.dinkrAmber : Color.dinkrCoral)
                    Text(String(format: "%+.2f DUPR", data.duprChange))
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(data.duprChange >= 0 ? Color.dinkrAmber : Color.dinkrCoral)
                    Spacer()
                    Text("this month")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)

                Spacer()

                // Challenges Won + reliability
                HStack(spacing: 16) {
                    // Challenges won badge
                    HStack(spacing: 8) {
                        Image(systemName: "trophy.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.dinkrAmber)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(data.challengesWon)")
                                .font(.subheadline.weight(.heavy))
                                .foregroundStyle(Color.dinkrAmber)
                            Text("Challenges Won")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.6))
                                .textCase(.uppercase)
                                .tracking(0.5)
                        }
                    }

                    Divider()
                        .frame(height: 28)
                        .background(.white.opacity(0.2))

                    // Reliability stars
                    HStack(spacing: 4) {
                        ForEach(0..<5) { i in
                            Image(systemName: Double(i) + 0.5 <= data.reliabilityScore ? "star.fill" : "star")
                                .font(.system(size: 11))
                                .foregroundStyle(Double(i) < data.reliabilityScore
                                    ? Color.dinkrAmber : Color.white.opacity(0.25))
                        }
                        Text(String(format: "%.1f", data.reliabilityScore))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Bottom watermark
                Text("dinkr.app")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.bottom, 20)
            }
        }
        .frame(width: 360, height: 520)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }
}

// MARK: - Recap Stat Tile

private struct RecapStatTile: View {
    let icon: String
    let value: String
    let label: String
    let accent: Color
    var smallValue: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(accent)
            Text(value)
                .font(smallValue
                    ? .system(size: 13, weight: .bold)
                    : .system(size: 20, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
                .textCase(.uppercase)
                .tracking(0.4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Court line path for recap card

private func recapCourtLinePath(size: CGSize) -> Path {
    var p = Path()
    let w = size.width
    let h = size.height
    // Outer court rectangle
    p.addRect(CGRect(x: 20, y: 40, width: w - 40, height: h - 80))
    // Center line horizontal
    p.move(to: CGPoint(x: 20, y: h / 2))
    p.addLine(to: CGPoint(x: w - 20, y: h / 2))
    // Kitchen (NVZ) lines
    let nvzInset: CGFloat = (h - 80) * 0.22
    p.move(to: CGPoint(x: 20, y: 40 + nvzInset))
    p.addLine(to: CGPoint(x: w - 20, y: 40 + nvzInset))
    p.move(to: CGPoint(x: 20, y: h - 40 - nvzInset))
    p.addLine(to: CGPoint(x: w - 20, y: h - 40 - nvzInset))
    // Center vertical
    p.move(to: CGPoint(x: w / 2, y: 40))
    p.addLine(to: CGPoint(x: w / 2, y: h - 40))
    return p
}

// MARK: - MonthlyRecapSheet

struct MonthlyRecapSheet: View {
    let data: MonthlyRecapData
    @Environment(\.dismiss) private var dismiss
    @State private var renderedImage: Image?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    // Card preview with drop shadow
                    ZStack {
                        if let img = renderedImage {
                            img
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 300, height: 300 * 520 / 360)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 24, x: 0, y: 12)
                        } else {
                            MonthlyRecapCard(data: data)
                                .scaleEffect(300 / 360)
                                .frame(width: 300, height: 300 * 520 / 360)
                                .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 24, x: 0, y: 12)
                        }
                    }
                    .frame(width: 300, height: 300 * 520 / 360)

                    Spacer()

                    // Action buttons
                    VStack(spacing: 12) {
                        if let img = renderedImage {
                            ShareLink(
                                item: img,
                                preview: SharePreview(
                                    "\(data.playerName)'s \(data.monthYear) Recap",
                                    image: img
                                )
                            ) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share Recap")
                                        .font(.headline.weight(.bold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.dinkrGreen.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                        } else {
                            // Render in progress placeholder
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(.white)
                                Text("Preparing…")
                                    .font(.headline.weight(.bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.dinkrGreen.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
                        }

                        if let img = renderedImage {
                            SaveToPhotosButton(image: img)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("\(data.monthYear) Recap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            await renderCard()
        }
    }

    @MainActor
    private func renderCard() async {
        let renderer = ImageRenderer(content: MonthlyRecapCard(data: data))
        renderer.scale = 3
        if let uiImage = renderer.uiImage {
            renderedImage = Image(uiImage: uiImage)
        }
    }
}

// MARK: - Save To Photos Button

private struct SaveToPhotosButton: View {
    let image: Image
    @State private var saved = false

    var body: some View {
        Button {
            HapticManager.medium()
            // Render UIImage from the Image for saving
            let renderer = ImageRenderer(content: image)
            renderer.scale = 3
            if let uiImage = renderer.uiImage {
                UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            }
            withAnimation { saved = true }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: saved ? "checkmark.circle.fill" : "arrow.down.to.line")
                Text(saved ? "Saved!" : "Save to Photos")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(saved ? Color.dinkrGreen : Color.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    MonthlyRecapCard(data: .mock(for: .mockCurrentUser))
}

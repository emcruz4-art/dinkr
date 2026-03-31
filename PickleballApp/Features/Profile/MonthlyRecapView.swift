import SwiftUI

// MARK: - MonthlyRecapView

/// Spotify Wrapped-style full-screen monthly recap.
/// Auto-advances pages every 5 s; tap anywhere to jump forward; swipe down to dismiss.
struct MonthlyRecapView: View {

    let stats: MonthlyStats
    @Environment(\.dismiss) private var dismiss

    // MARK: Page state

    @State private var currentPage: Int = 0
    @State private var autoTimer: Timer? = nil

    // MARK: Per-page entrance animation flags
    @State private var pageVisible: Bool = false

    // MARK: Share card state (page 7)
    @State private var shareImage: UIImage? = nil
    @State private var isRenderingShare: Bool = false

    private let totalPages = 8   // pages 0–7
    private let autoAdvanceInterval: TimeInterval = 5.0

    // MARK: Body

    var body: some View {
        ZStack {
            // ── Deep navy gradient canvas ──────────────────────────────────
            backgroundGradient
                .ignoresSafeArea()

            // ── Subtle court lines on every page ──────────────────────────
            CourtLineOverlay()
                .ignoresSafeArea()

            // ── Page content ──────────────────────────────────────────────
            ZStack {
                switch currentPage {
                case 0: page0_intro
                case 1: page1_gamesPlayed
                case 2: page2_winRate
                case 3: page3_topCourt
                case 4: page4_bestWin
                case 5: page5_dupr
                case 6: page6_streak
                case 7: page7_shareCard
                default: EmptyView()
                }
            }
            .id(currentPage)                       // force re-render on advance
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal:   .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: currentPage)

            // ── Progress dots ──────────────────────────────────────────────
            VStack {
                PageProgressDots(currentPage: currentPage, totalPages: totalPages)
                    .padding(.top, 60)
                Spacer()
            }

            // ── Dismiss button ─────────────────────────────────────────────
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.12), in: Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 54)
                }
                Spacer()
            }

            // ── Tap zone to advance ────────────────────────────────────────
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { advancePage() }
                .ignoresSafeArea()
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    // Swipe down → dismiss; swipe left → advance; swipe right → back
                    if value.translation.height > 80 {
                        dismiss()
                    } else if value.translation.width < -50 {
                        advancePage()
                    } else if value.translation.width > 50 {
                        retreatPage()
                    }
                }
        )
        .preferredColorScheme(.dark)
        .onAppear {
            triggerEntrance()
            startAutoTimer()
        }
        .onDisappear {
            autoTimer?.invalidate()
        }
        .statusBarHidden(true)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            stops: [
                .init(color: Color.dinkrNavy, location: 0),
                .init(color: Color(red: 0.04, green: 0.22, blue: 0.32), location: 0.55),
                .init(color: Color.dinkrGreen.opacity(0.25), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Page 0 · Intro

    private var page0_intro: some View {
        RecapPageContainer(visible: pageVisible) {
            Spacer()

            // Dinkr logo mark
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.18))
                    .frame(width: 120, height: 120)
                Text("🏓")
                    .font(.system(size: 56))
            }
            .scaleEffect(pageVisible ? 1.0 : 0.5)
            .animation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.1), value: pageVisible)

            VStack(spacing: 10) {
                Text("YOUR")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dinkrGreen)
                    .tracking(3)

                Text(stats.month)
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text("\(stats.year)")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))

                Text("in Pickleball")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 4)
            }
            .offset(y: pageVisible ? 0 : 30)
            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.18), value: pageVisible)

            Spacer()

            Text("Tap to begin")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(1.2)
                .textCase(.uppercase)
                .padding(.bottom, 52)
                .opacity(pageVisible ? 1 : 0)
                .animation(.easeIn(duration: 0.5).delay(0.6), value: pageVisible)
        }
    }

    // MARK: - Page 1 · Games Played

    private var page1_gamesPlayed: some View {
        RecapPageContainer(visible: pageVisible) {
            Spacer()

            VStack(spacing: 8) {
                Text("You played")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))

                Text("\(stats.gamesPlayed)")
                    .font(.system(size: 110, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: Color.dinkrGreen.opacity(0.6), radius: 20)
                    .contentTransition(.numericText())
                    .scaleEffect(pageVisible ? 1 : 0.3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.62).delay(0.1), value: pageVisible)

                Text("games this month")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .offset(y: pageVisible ? 0 : 40)
            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.05), value: pageVisible)

            Spacer()

            // Percentile callout
            VStack(spacing: 6) {
                Text("That's more than")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.65))

                Text("\(stats.percentileBeat)%")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(Color.dinkrAmber)
                    .shadow(color: Color.dinkrAmber.opacity(0.5), radius: 12)

                Text("of Dinkr players!")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(24)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 32)
            .offset(y: pageVisible ? 0 : 50)
            .opacity(pageVisible ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.78).delay(0.22), value: pageVisible)

            Spacer()
        }
    }

    // MARK: - Page 2 · Win Rate

    private var page2_winRate: some View {
        RecapPageContainer(visible: pageVisible) {
            Spacer()

            Text("Win Rate")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dinkrGreen)
                .tracking(2)
                .textCase(.uppercase)

            // Circular progress ring
            ZStack {
                // Track
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 18)

                // Progress arc
                Circle()
                    .trim(from: 0, to: pageVisible ? stats.winRate : 0)
                    .stroke(
                        AngularGradient(
                            colors: [Color.dinkrGreen, Color.dinkrSky],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle:   .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.1, dampingFraction: 0.72).delay(0.12), value: pageVisible)

                // Center percentage
                VStack(spacing: 4) {
                    Text("\(Int(stats.winRate * 100))%")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("wins")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .frame(width: 220, height: 220)
            .padding(.vertical, 24)
            .scaleEffect(pageVisible ? 1 : 0.6)
            .opacity(pageVisible ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.08), value: pageVisible)

            // W-L record
            HStack(spacing: 0) {
                RecordPill(value: "\(stats.wins)", label: "Wins", color: Color.dinkrGreen)
                Text("—")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.horizontal, 8)
                RecordPill(value: "\(stats.losses)", label: "Losses", color: Color.dinkrCoral)
            }
            .offset(y: pageVisible ? 0 : 30)
            .opacity(pageVisible ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.78).delay(0.3), value: pageVisible)

            Spacer()
        }
    }

    // MARK: - Page 3 · Top Court

    private var page3_topCourt: some View {
        RecapPageContainer(visible: pageVisible) {
            Spacer()

            VStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.dinkrSky)
                    .shadow(color: Color.dinkrSky.opacity(0.5), radius: 16)
                    .scaleEffect(pageVisible ? 1.0 : 0.3)
                    .animation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.08), value: pageVisible)

                Text("Your Home Base")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dinkrSky)
                    .tracking(2)
                    .textCase(.uppercase)
                    .padding(.top, 8)
            }

            VStack(spacing: 10) {
                Text(stats.topCourtName)
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.65)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Image(systemName: "figure.pickleball")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.dinkrSky)
                    Text("\(stats.topCourtVisits) visits this month")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.white.opacity(0.1), in: Capsule())
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
            .offset(y: pageVisible ? 0 : 35)
            .opacity(pageVisible ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.78).delay(0.18), value: pageVisible)

            Spacer()

            // Court doodle
            CourtDoodle()
                .frame(height: 100)
                .padding(.horizontal, 60)
                .padding(.bottom, 60)
                .opacity(pageVisible ? 0.15 : 0)
                .animation(.easeIn(duration: 0.6).delay(0.4), value: pageVisible)
        }
    }

    // MARK: - Page 4 · Best Win

    private var page4_bestWin: some View {
        RecapPageContainer(visible: pageVisible) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.dinkrAmber)
                    .shadow(color: Color.dinkrAmber.opacity(0.6), radius: 16)
                    .scaleEffect(pageVisible ? 1.0 : 0.2)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.06), value: pageVisible)

                Text("Best Win")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dinkrAmber)
                    .tracking(2)
                    .textCase(.uppercase)
                    .padding(.top, 6)
            }

            VStack(spacing: 6) {
                Text("vs. \(stats.bestWinOpponent)")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)

                Text(stats.bestWinScore)
                    .font(.system(size: 58, weight: .black, design: .rounded))
                    .foregroundStyle(Color.dinkrGreen)
                    .shadow(color: Color.dinkrGreen.opacity(0.5), radius: 12)
            }
            .padding(.horizontal, 32)
            .padding(.top, 20)
            .offset(y: pageVisible ? 0 : 40)
            .opacity(pageVisible ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.2), value: pageVisible)

            Spacer()

            Text("Hardest match of the month")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))
                .italic()
                .padding(.bottom, 56)
                .opacity(pageVisible ? 1 : 0)
                .animation(.easeIn(duration: 0.5).delay(0.4), value: pageVisible)
        }
    }

    // MARK: - Page 5 · DUPR Change

    private var page5_dupr: some View {
        RecapPageContainer(visible: pageVisible) {
            Spacer()

            Text("Rating Progress")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dinkrAmber)
                .tracking(2)
                .textCase(.uppercase)

            // Before → arrow → After
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text(String(format: "%.2f", stats.duprBefore))
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                    Text("Before")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .textCase(.uppercase)
                        .tracking(1)
                }
                .frame(maxWidth: .infinity)

                Image(systemName: "arrow.right")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(stats.duprDelta >= 0 ? Color.dinkrGreen : Color.dinkrCoral)
                    .scaleEffect(pageVisible ? 1.0 : 0.2)
                    .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.22), value: pageVisible)

                VStack(spacing: 4) {
                    Text(String(format: "%.2f", stats.duprAfter))
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("After")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .textCase(.uppercase)
                        .tracking(1)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
            .offset(y: pageVisible ? 0 : 30)
            .opacity(pageVisible ? 1 : 0)
            .animation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.1), value: pageVisible)

            // Delta badge
            let isGain = stats.duprDelta >= 0
            HStack(spacing: 8) {
                Image(systemName: isGain ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(isGain ? Color.dinkrGreen : Color.dinkrCoral)
                Text(String(format: "%+.2f rating points", stats.duprDelta))
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(isGain ? Color.dinkrGreen : Color.dinkrCoral)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background((isGain ? Color.dinkrGreen : Color.dinkrCoral).opacity(0.14),
                        in: RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 40)
            .scaleEffect(pageVisible ? 1 : 0.7)
            .opacity(pageVisible ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.72).delay(0.28), value: pageVisible)

            Spacer()
        }
    }

    // MARK: - Page 6 · Streak

    private var page6_streak: some View {
        RecapPageContainer(visible: pageVisible) {
            Spacer()

            // Animated fire stack
            ZStack {
                ForEach(0..<3) { i in
                    Text("🔥")
                        .font(.system(size: 40 + CGFloat(i * 18)))
                        .offset(y: CGFloat(i * -14))
                        .opacity(0.3 + Double(i) * 0.35)
                }
                Text("🔥")
                    .font(.system(size: 88))
            }
            .scaleEffect(pageVisible ? 1.0 : 0.3)
            .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.06), value: pageVisible)

            VStack(spacing: 8) {
                Text("\(stats.streakDays)")
                    .font(.system(size: 100, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: Color.dinkrAmber.opacity(0.5), radius: 18)
                    .contentTransition(.numericText())

                Text("day streak")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .offset(y: pageVisible ? 0 : 40)
            .opacity(pageVisible ? 1 : 0)
            .animation(.spring(response: 0.55, dampingFraction: 0.75).delay(0.18), value: pageVisible)

            if stats.isStreakPersonalBest {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.dinkrAmber)
                    Text("Personal best!")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(Color.dinkrAmber)
                    Image(systemName: "star.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.dinkrAmber)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.dinkrAmber.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
                .padding(.top, 16)
                .scaleEffect(pageVisible ? 1.0 : 0.6)
                .opacity(pageVisible ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.32), value: pageVisible)
            }

            Spacer()
        }
    }

    // MARK: - Page 7 · Share Card

    private var page7_shareCard: some View {
        RecapPageContainer(visible: pageVisible) {
            VStack(spacing: 0) {
                Text("Share Your Recap")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 72)
                    .padding(.bottom, 24)
                    .opacity(pageVisible ? 1 : 0)
                    .animation(.easeIn(duration: 0.4).delay(0.1), value: pageVisible)

                // Card preview
                ZStack {
                    if let img = shareImage {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .shadow(color: Color.dinkrGreen.opacity(0.4), radius: 24, x: 0, y: 12)
                    } else {
                        // Live preview while rendering
                        MonthlyRecapCard(data: MonthlyRecapData(
                            playerName: stats.playerName,
                            monthYear: stats.monthYear,
                            gamesPlayed: stats.gamesPlayed,
                            wins: stats.wins,
                            losses: stats.losses,
                            courtsVisited: stats.topCourtVisits,
                            topPartner: stats.bestWinOpponent,
                            topCourt: stats.topCourtName,
                            challengesWon: 0,
                            reliabilityScore: 4.8,
                            duprChange: stats.duprDelta,
                            winStreak: stats.streakDays
                        ))
                        .scaleEffect(300.0 / 360.0)
                        .frame(width: 300, height: 300 * 520 / 360)
                        .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 24, x: 0, y: 12)

                        if isRenderingShare {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(.black.opacity(0.4))
                                .frame(width: 300, height: 300 * 520 / 360)
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.3)
                        }
                    }
                }
                .scaleEffect(pageVisible ? 1 : 0.85)
                .opacity(pageVisible ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: pageVisible)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    if let img = shareImage {
                        ShareLink(
                            item: Image(uiImage: img),
                            preview: SharePreview(
                                "\(stats.playerName)'s \(stats.monthYear) Recap",
                                image: Image(uiImage: img)
                            )
                        ) {
                            Label("Share Recap", systemImage: "square.and.arrow.up")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.dinkrGreen.opacity(0.45), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)

                        Button {
                            HapticManager.success()
                            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                        } label: {
                            Label("Save to Photos", systemImage: "arrow.down.to.line")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.dinkrGreen)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.dinkrGreen.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    } else {
                        // Preparing…
                        HStack(spacing: 8) {
                            ProgressView().tint(.white)
                            Text("Preparing share card…")
                                .font(.headline.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.dinkrGreen.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .opacity(pageVisible ? 1 : 0)
                .animation(.easeIn(duration: 0.5).delay(0.35), value: pageVisible)
            }
        }
        .task {
            guard shareImage == nil else { return }
            isRenderingShare = true
            shareImage = ShareCardRenderer.renderRecapCard(stats: stats)
            isRenderingShare = false
        }
    }

    // MARK: - Navigation Helpers

    private func advancePage() {
        HapticManager.selection()
        resetTimer()
        if currentPage < totalPages - 1 {
            withAnimation { currentPage += 1 }
            triggerEntrance()
        } else {
            dismiss()
        }
    }

    private func retreatPage() {
        HapticManager.selection()
        resetTimer()
        if currentPage > 0 {
            withAnimation { currentPage -= 1 }
            triggerEntrance()
        }
    }

    private func triggerEntrance() {
        pageVisible = false
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 50_000_000)  // 50 ms
            withAnimation { pageVisible = true }
        }
    }

    // MARK: - Auto-advance timer

    private func startAutoTimer() {
        autoTimer?.invalidate()
        autoTimer = Timer.scheduledTimer(withTimeInterval: autoAdvanceInterval, repeats: true) { _ in
            Task { @MainActor in
                if currentPage < totalPages - 1 {
                    withAnimation { currentPage += 1 }
                    triggerEntrance()
                } else {
                    autoTimer?.invalidate()
                }
            }
        }
    }

    private func resetTimer() {
        autoTimer?.invalidate()
        startAutoTimer()
    }
}

// MARK: - RecapPageContainer

/// Wraps page content in a centered, full-height VStack with fade entrance.
private struct RecapPageContainer<Content: View>: View {
    let visible: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 24) {
            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(visible ? 1 : 0)
    }
}

// MARK: - PageProgressDots

private struct PageProgressDots: View {
    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<totalPages, id: \.self) { idx in
                Capsule()
                    .fill(idx == currentPage ? Color.white : Color.white.opacity(0.25))
                    .frame(width: idx == currentPage ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentPage)
            }
        }
    }
}

// MARK: - RecordPill

private struct RecordPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - CourtLineOverlay

private struct CourtLineOverlay: View {
    var body: some View {
        Canvas { ctx, size in
            var p = Path()
            // Center horizontal
            p.move(to: CGPoint(x: 0, y: size.height * 0.5))
            p.addLine(to: CGPoint(x: size.width, y: size.height * 0.5))
            // NVZ lines
            p.move(to: CGPoint(x: 0, y: size.height * 0.32))
            p.addLine(to: CGPoint(x: size.width, y: size.height * 0.32))
            p.move(to: CGPoint(x: 0, y: size.height * 0.68))
            p.addLine(to: CGPoint(x: size.width, y: size.height * 0.68))
            // Center vertical
            p.move(to: CGPoint(x: size.width * 0.5, y: 0))
            p.addLine(to: CGPoint(x: size.width * 0.5, y: size.height))
            ctx.stroke(p, with: .color(.white.opacity(0.035)), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - CourtDoodle (decorative court outline)

private struct CourtDoodle: View {
    var body: some View {
        Canvas { ctx, size in
            var p = Path()
            p.addRect(CGRect(x: 0, y: 0, width: size.width, height: size.height))
            let nvz = size.height * 0.3
            p.move(to: CGPoint(x: 0, y: nvz))
            p.addLine(to: CGPoint(x: size.width, y: nvz))
            p.move(to: CGPoint(x: 0, y: size.height - nvz))
            p.addLine(to: CGPoint(x: size.width, y: size.height - nvz))
            p.move(to: CGPoint(x: size.width / 2, y: 0))
            p.addLine(to: CGPoint(x: size.width / 2, y: size.height))
            ctx.stroke(p, with: .color(.white), lineWidth: 2)
        }
    }
}

// MARK: - MonthlyRecapButton (entry point for ProfileView)

/// Drop-in button that presents MonthlyRecapView as a full-screen cover.
struct MonthlyRecapButton: View {
    let stats: MonthlyStats
    @State private var showRecap = false

    var body: some View {
        Button {
            HapticManager.selection()
            showRecap = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.dinkrAmber.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color.dinkrAmber)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("View Monthly Recap")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.primary)
                    Text("\(stats.monthYear) · \(stats.gamesPlayed) games · \(stats.wins)W–\(stats.losses)L")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dinkrAmber)
            }
            .padding(14)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.dinkrAmber.opacity(0.28), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showRecap) {
            MonthlyRecapView(stats: stats)
        }
    }
}

// MARK: - Preview

#Preview("Monthly Recap View") {
    MonthlyRecapView(stats: .mock(for: .mockCurrentUser))
}

#Preview("Monthly Recap Button") {
    VStack {
        MonthlyRecapButton(stats: .mock(for: .mockCurrentUser))
            .padding(.horizontal, 20)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
}

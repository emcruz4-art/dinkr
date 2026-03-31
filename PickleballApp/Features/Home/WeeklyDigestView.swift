import SwiftUI

// MARK: - WeeklyDigestView

struct WeeklyDigestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var autoAdvance = false
    @State private var autoAdvanceTimer: Timer? = nil
    @State private var showShareSheet = false

    private let pageCount = 6

    var body: some View {
        ZStack(alignment: .bottom) {
            // Full-screen dark navy gradient background
            LinearGradient(
                colors: [
                    Color.dinkrNavy,
                    Color(red: 0.04, green: 0.08, blue: 0.18),
                    Color(red: 0.02, green: 0.05, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle court-line watermark
            GeometryReader { geo in
                Canvas { ctx, size in
                    let w = size.width, h = size.height
                    var p = Path()
                    // Horizontal lines
                    for ratio in [0.18, 0.38, 0.56, 0.76] as [CGFloat] {
                        p.move(to: CGPoint(x: 20, y: h * ratio))
                        p.addLine(to: CGPoint(x: w - 20, y: h * ratio))
                    }
                    // Side lines
                    p.move(to: CGPoint(x: 20, y: h * 0.18))
                    p.addLine(to: CGPoint(x: 20, y: h * 0.76))
                    p.move(to: CGPoint(x: w - 20, y: h * 0.18))
                    p.addLine(to: CGPoint(x: w - 20, y: h * 0.76))
                    // Center
                    p.move(to: CGPoint(x: w / 2, y: h * 0.18))
                    p.addLine(to: CGPoint(x: w / 2, y: h * 0.76))
                    ctx.stroke(p, with: .color(.white.opacity(0.035)), lineWidth: 1)
                }
            }
            .ignoresSafeArea()

            // Page content
            TabView(selection: $currentPage) {
                DigestPage1()
                    .tag(0)
                DigestPage2()
                    .tag(1)
                DigestPage3()
                    .tag(2)
                DigestPage4()
                    .tag(3)
                DigestPage5()
                    .tag(4)
                DigestPage6(onShare: { showShareSheet = true })
                    .tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Bottom controls
            VStack(spacing: 14) {
                // Dot page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pageCount, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? Color.dinkrGreen : Color.white.opacity(0.3))
                            .frame(width: i == currentPage ? 20 : 8, height: 8)
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
                    }
                }

                // Auto-advance toggle
                Toggle(isOn: $autoAdvance) {
                    Label("Auto-advance", systemImage: "play.circle")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .toggleStyle(SwitchToggleStyle(tint: Color.dinkrGreen))
                .padding(.horizontal, 32)
                .onChange(of: autoAdvance) { _, newValue in
                    if newValue {
                        startAutoAdvance()
                    } else {
                        stopAutoAdvance()
                    }
                }
            }
            .padding(.bottom, 44)

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(16)
                    }
                }
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showShareSheet) {
            DigestShareSheet()
        }
        .onDisappear {
            stopAutoAdvance()
        }
    }

    private func startAutoAdvance() {
        stopAutoAdvance()
        autoAdvanceTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            withAnimation {
                if currentPage < pageCount - 1 {
                    currentPage += 1
                } else {
                    autoAdvance = false
                }
            }
        }
    }

    private func stopAutoAdvance() {
        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = nil
    }
}

// MARK: - Page 1: Your Week in Pickleball

private struct DigestPage1: View {
    @State private var appeared = false
    @State private var gamesCount = 0
    @State private var pointsCount = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Label
                Text("YOUR WEEK IN PICKLEBALL")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Color.dinkrGreen)
                    .tracking(2.5)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appeared)

                // Week date range
                Text("Mar 24 – Mar 30")
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(.white)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.25), value: appeared)

                // Divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.dinkrGreen, Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.horizontal, 60)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.5).delay(0.4), value: appeared)

                // Animated stat counters
                HStack(spacing: 40) {
                    DigestStatCounter(
                        value: gamesCount,
                        label: "Games Played",
                        icon: "figure.pickleball",
                        color: Color.dinkrGreen,
                        delay: 0.5
                    )

                    DigestStatCounter(
                        value: pointsCount,
                        label: "Points Scored",
                        icon: "star.fill",
                        color: Color.dinkrAmber,
                        delay: 0.65
                    )
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.45), value: appeared)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .onAppear {
            appeared = true
            // Animate counters
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 1.2)) {
                    gamesCount = 3
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                withAnimation(.easeOut(duration: 1.4)) {
                    pointsCount = 47
                }
            }
        }
    }
}

// MARK: - Page 2: Win Rate

private struct DigestPage2: View {
    @State private var appeared = false
    @State private var arcProgress: Double = 0

    private let winRate: Double = 0.67
    private let lastWeekRate: Double = 0.54

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                Text("YOUR WIN RATE")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Color.dinkrAmber)
                    .tracking(2.5)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.4).delay(0.1), value: appeared)

                // Arc progress ring
                ZStack {
                    // Track
                    Circle()
                        .trim(from: 0.1, to: 0.9)
                        .stroke(Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(90))
                        .frame(width: 200, height: 200)

                    // Fill
                    Circle()
                        .trim(from: 0.1, to: 0.1 + 0.8 * arcProgress)
                        .stroke(
                            LinearGradient(
                                colors: [Color.dinkrGreen, Color.dinkrSky],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .rotationEffect(.degrees(90))
                        .frame(width: 200, height: 200)
                        .animation(.spring(response: 1.4, dampingFraction: 0.7).delay(0.4), value: arcProgress)

                    VStack(spacing: 4) {
                        Text("\(Int(winRate * 100))%")
                            .font(.system(size: 56, weight: .black))
                            .foregroundStyle(.white)
                        Text("Win Rate")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.55))
                            .tracking(1)
                    }
                }

                // Comparison to last week
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .foregroundStyle(Color.dinkrGreen)
                        .font(.system(size: 18))

                    Text("Up from \(Int(lastWeekRate * 100))% last week")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))

                    Text("+\(Int((winRate - lastWeekRate) * 100))%")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(Color.dinkrGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.dinkrGreen.opacity(0.18))
                        .clipShape(Capsule())
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.9), value: appeared)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .onAppear {
            appeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                arcProgress = winRate
            }
        }
    }
}

// MARK: - Page 3: Top Court

private struct DigestPage3: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                Text("TOP COURT THIS WEEK")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Color.dinkrSky)
                    .tracking(2.5)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.4).delay(0.1), value: appeared)

                // Map thumbnail placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color.dinkrNavy.opacity(0.7), Color(red: 0.1, green: 0.22, blue: 0.38)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 240, height: 160)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.dinkrSky.opacity(0.35), lineWidth: 1.5)
                        )

                    // Simulated map grid
                    Canvas { ctx, size in
                        var p = Path()
                        let cols = 6, rows = 4
                        for c in 0...cols {
                            let x = size.width * CGFloat(c) / CGFloat(cols)
                            p.move(to: CGPoint(x: x, y: 0))
                            p.addLine(to: CGPoint(x: x, y: size.height))
                        }
                        for r in 0...rows {
                            let y = size.height * CGFloat(r) / CGFloat(rows)
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: size.width, y: y))
                        }
                        ctx.stroke(p, with: .color(.white.opacity(0.06)), lineWidth: 0.5)
                    }
                    .frame(width: 240, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    // Pin
                    VStack(spacing: 2) {
                        ZStack {
                            Circle()
                                .fill(Color.dinkrCoral)
                                .frame(width: 36, height: 36)
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                        }
                        Rectangle()
                            .fill(Color.dinkrCoral)
                            .frame(width: 2, height: 10)
                    }
                    .shadow(color: Color.dinkrCoral.opacity(0.5), radius: 8)
                }
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.85)
                .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.3), value: appeared)

                // Court name
                VStack(spacing: 8) {
                    Text("Westside Pickleball Complex")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 16) {
                        Label("4 visits", systemImage: "repeat.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrSky)
                        Label("Austin, TX", systemImage: "mappin")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.55), value: appeared)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .onAppear {
            appeared = true
        }
    }
}

// MARK: - Page 4: You vs Your Rivals

private struct DigestPage4: View {
    @State private var appeared = false
    @State private var barProgress: Double = 0

    private let myWins = 3
    private let theirWins = 1
    private let total = 4

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                Text("YOU VS YOUR RIVALS")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Color.dinkrCoral)
                    .tracking(2.5)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.4).delay(0.1), value: appeared)

                // Head to head avatars
                HStack(spacing: 0) {
                    // You
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.dinkrGreen.opacity(0.22))
                                .frame(width: 80, height: 80)
                            Circle()
                                .stroke(Color.dinkrGreen, lineWidth: 2.5)
                                .frame(width: 80, height: 80)
                            Text("YOU")
                                .font(.system(size: 16, weight: .black))
                                .foregroundStyle(Color.dinkrGreen)
                        }
                        Text("\(myWins) W")
                            .font(.system(size: 24, weight: .black))
                            .foregroundStyle(Color.dinkrGreen)
                        Text("This Week")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    VStack(spacing: 4) {
                        Text("VS")
                            .font(.system(size: 28, weight: .black))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .frame(width: 60)

                    // Rival
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.dinkrCoral.opacity(0.22))
                                .frame(width: 80, height: 80)
                            Circle()
                                .stroke(Color.dinkrCoral, lineWidth: 2.5)
                                .frame(width: 80, height: 80)
                            Text("MJ")
                                .font(.system(size: 20, weight: .black))
                                .foregroundStyle(Color.dinkrCoral)
                        }
                        Text("\(theirWins) W")
                            .font(.system(size: 24, weight: .black))
                            .foregroundStyle(Color.dinkrCoral)
                        Text("Maria J.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.9)
                .animation(.spring(response: 0.65, dampingFraction: 0.7).delay(0.3), value: appeared)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.dinkrCoral.opacity(0.35))
                            .frame(height: 14)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geo.size.width * barProgress,
                                height: 14
                            )
                            .animation(.spring(response: 1.2, dampingFraction: 0.7).delay(0.55), value: barProgress)
                    }
                }
                .frame(height: 14)
                .padding(.horizontal, 8)
                .opacity(appeared ? 1 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.5), value: appeared)

                Text("You're dominating this matchup 👊")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.4).delay(0.85), value: appeared)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .onAppear {
            appeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                barProgress = Double(myWins) / Double(total)
            }
        }
    }
}

// MARK: - Page 5: Your Highlight

private struct DigestPage5: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                Text("YOUR HIGHLIGHT")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Color.dinkrAmber)
                    .tracking(2.5)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.4).delay(0.1), value: appeared)

                // Trophy glow
                ZStack {
                    Circle()
                        .fill(Color.dinkrAmber.opacity(0.12))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                    Circle()
                        .fill(Color.dinkrAmber.opacity(0.08))
                        .frame(width: 100, height: 100)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.dinkrAmber)
                        .shadow(color: Color.dinkrAmber.opacity(0.6), radius: 12)
                }
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.75, dampingFraction: 0.6).delay(0.3), value: appeared)

                // Best win details
                VStack(spacing: 12) {
                    Text("Best Win of the Week")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.65))

                    // Score
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("11")
                                .font(.system(size: 64, weight: .black))
                                .foregroundStyle(Color.dinkrGreen)
                            Text("You")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        Text("–")
                            .font(.system(size: 40, weight: .black))
                            .foregroundStyle(.white.opacity(0.3))
                        VStack(spacing: 4) {
                            Text("4")
                                .font(.system(size: 64, weight: .black))
                                .foregroundStyle(Color.dinkrCoral)
                            Text("Carlos R.")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }

                    Text("Westside Pickleball Complex · Mar 28")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.45))
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: appeared)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .onAppear {
            appeared = true
        }
    }
}

// MARK: - Page 6: Share Card

private struct DigestPage6: View {
    let onShare: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Text("SHARE YOUR WEEK")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Color.dinkrGreen)
                    .tracking(2.5)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.4).delay(0.1), value: appeared)

                // Summary card
                VStack(spacing: 0) {
                    // Card header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dinkr Week in Review")
                                .font(.headline.weight(.black))
                                .foregroundStyle(.white)
                            Text("Mar 24 – Mar 30, 2025")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        Spacer()
                        Image(systemName: "figure.pickleball")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                    Divider().overlay(Color.white.opacity(0.1))

                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 0) {
                        ShareStatCell(value: "3", label: "Games", color: Color.dinkrGreen)
                        ShareStatCell(value: "67%", label: "Win Rate", color: Color.dinkrAmber)
                        ShareStatCell(value: "47", label: "Points", color: Color.dinkrSky)
                        ShareStatCell(value: "4", label: "Vs Maria", color: Color.dinkrCoral)
                    }

                    Divider().overlay(Color.white.opacity(0.1))

                    // Top court
                    HStack(spacing: 10) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(Color.dinkrSky)
                        Text("Top Court: Westside Pickleball Complex")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    // Dinkr tag
                    HStack {
                        Spacer()
                        Text("dinkr.app")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.dinkrGreen.opacity(0.7))
                            .tracking(1)
                        Spacer()
                    }
                    .padding(.bottom, 16)
                }
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.08, green: 0.14, blue: 0.28), Color(red: 0.04, green: 0.08, blue: 0.18)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.dinkrGreen.opacity(0.25), lineWidth: 1)
                        )
                )
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.9)
                .animation(.spring(response: 0.65, dampingFraction: 0.7).delay(0.25), value: appeared)

                // Share button
                Button(action: onShare) {
                    HStack(spacing: 10) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .bold))
                        Text("Share My Week")
                            .font(.headline.weight(.bold))
                    }
                    .foregroundStyle(Color.dinkrNavy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.dinkrGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.dinkrGreen.opacity(0.45), radius: 12, x: 0, y: 6)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.55), value: appeared)
            }
            .padding(.horizontal, 28)

            Spacer()
            Spacer()
        }
        .onAppear {
            appeared = true
        }
    }
}

// MARK: - Share Stat Cell

private struct ShareStatCell: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}

// MARK: - Digest Stat Counter

private struct DigestStatCounter: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color
    let delay: Double

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 64, height: 64)
                Circle()
                    .stroke(color.opacity(0.35), lineWidth: 1.5)
                    .frame(width: 64, height: 64)
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundStyle(color)
            }
            Text("\(value)")
                .font(.system(size: 40, weight: .black))
                .foregroundStyle(.white)
                .contentTransition(.numericText(value: Double(value)))
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .frame(width: 90)
        }
    }
}

// MARK: - Digest Share Sheet

private struct DigestShareSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            Text("Share Your Week")
                .font(.title3.weight(.bold))

            Text("Screenshot sharing coming soon.\nCopy your stats to clipboard!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(Color.dinkrGreen)

            Spacer()
        }
        .padding(.horizontal, 32)
        .presentationDetents([.fraction(0.3)])
    }
}

// MARK: - Preview

#Preview {
    WeeklyDigestView()
}

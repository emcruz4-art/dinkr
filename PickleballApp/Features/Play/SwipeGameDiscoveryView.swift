import SwiftUI

// MARK: - Filter Mode

private enum DiscoverFilter: String, CaseIterable {
    case all       = "All"
    case doubles   = "Doubles"
    case openPlay  = "Open Play"
    case today     = "Today"
}

// MARK: - SwipeGameDiscoveryView

struct SwipeGameDiscoveryView: View {

    @Environment(\.dismiss) private var dismiss

    // MARK: State

    @State private var deck: [GameSession] = GameSession.mockSessions
    @State private var rsvpedIDs: Set<String> = []
    @State private var savedIDs: Set<String> = []
    @State private var activeFilter: DiscoverFilter = .all
    @State private var toastMessage: String? = nil
    @State private var toastTimer: Timer? = nil
    @State private var exhausted = false

    // Per-card drag state
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    // MARK: - Computed deck

    private var filteredDeck: [GameSession] {
        switch activeFilter {
        case .all:
            return deck
        case .doubles:
            return deck.filter { $0.format == .doubles }
        case .openPlay:
            return deck.filter { $0.format == .openPlay }
        case .today:
            let cal = Calendar.current
            return deck.filter { cal.isDateInToday($0.dateTime) }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ─────────────────────────────────────────────────
                headerBar

                // ── Filter chips ───────────────────────────────────────────
                filterChips
                    .padding(.top, 12)
                    .padding(.horizontal, 20)

                Spacer(minLength: 0)

                // ── Card stack / empty state ────────────────────────────────
                if filteredDeck.isEmpty {
                    emptyState
                } else {
                    cardStack
                }

                Spacer(minLength: 0)

                // ── Bottom action bar ──────────────────────────────────────
                if !filteredDeck.isEmpty {
                    actionBar
                        .padding(.bottom, 32)
                }
            }

            // ── Toast overlay ─────────────────────────────────────────────
            if let msg = toastMessage {
                VStack {
                    Spacer()
                    toastBubble(msg)
                        .padding(.bottom, 120)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 36, height: 36)
                    .background(Color(UIColor.secondarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text("Discover")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                Text("\(filteredDeck.count) games nearby")
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
            }

            Spacer()

            // Balance the close button
            Circle()
                .fill(Color.clear)
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DiscoverFilter.allCases, id: \.self) { filter in
                    let selected = activeFilter == filter
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            activeFilter = filter
                            HapticManager.selection()
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 13, weight: selected ? .bold : .medium))
                            .foregroundStyle(selected ? .white : Color.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selected ? Color.dinkrGreen : Color(UIColor.secondarySystemBackground),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.3, dampingFraction: 0.75), value: selected)
                }
            }
        }
    }

    // MARK: - Card Stack

    private var cardStack: some View {
        ZStack {
            // Render up to 3 cards; back cards are offset/scaled for depth
            ForEach(Array(filteredDeck.prefix(3).enumerated().reversed()), id: \.element.id) { index, session in
                let isFront = index == 0

                DiscoveryCardView(session: session)
                    .padding(.horizontal, 24)
                    .scaleEffect(isFront ? 1.0 : (index == 1 ? 0.94 : 0.88))
                    .offset(y: isFront ? 0 : (index == 1 ? -14 : -26))
                    // Front card: apply drag offset
                    .offset(x: isFront ? dragOffset.width : 0,
                            y: isFront ? dragOffset.height * 0.2 : 0)
                    .rotationEffect(
                        isFront
                            ? .degrees(Double(dragOffset.width) / 22.0)
                            : .zero
                    )
                    // Swipe overlays on front card
                    .overlay {
                        if isFront {
                            swipeOverlay
                        }
                    }
                    .zIndex(isFront ? 10 : (index == 1 ? 5 : 0))
                    .gesture(
                        isFront
                            ? DragGesture()
                                .onChanged { value in
                                    isDragging = true
                                    withAnimation(.interactiveSpring()) {
                                        dragOffset = value.translation
                                    }
                                }
                                .onEnded { value in
                                    isDragging = false
                                    handleSwipeEnd(translation: value.translation)
                                }
                            : nil
                    )
                    .animation(
                        isFront ? nil : .spring(response: 0.4, dampingFraction: 0.72),
                        value: filteredDeck.count
                    )
            }
        }
        .frame(height: 460)
        .padding(.top, 12)
    }

    // MARK: - Swipe Overlays

    private var swipeOverlay: some View {
        ZStack {
            // JOIN overlay (drag right)
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.dinkrGreen.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.dinkrGreen, lineWidth: 3)
                )
                .overlay(
                    VStack(spacing: 6) {
                        Text("JOIN")
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(Color.dinkrGreen)
                        Text("✓")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                    .rotationEffect(.degrees(-18))
                    .padding(.leading, 28)
                    .padding(.top, 40),
                    alignment: .topLeading
                )
                .opacity(joinOverlayOpacity)
                .padding(.horizontal, 24)

            // SKIP overlay (drag left)
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.dinkrCoral.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.dinkrCoral, lineWidth: 3)
                )
                .overlay(
                    VStack(spacing: 6) {
                        Text("SKIP")
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(Color.dinkrCoral)
                        Text("✗")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color.dinkrCoral)
                    }
                    .rotationEffect(.degrees(18))
                    .padding(.trailing, 28)
                    .padding(.top, 40),
                    alignment: .topTrailing
                )
                .opacity(skipOverlayOpacity)
                .padding(.horizontal, 24)
        }
    }

    private var joinOverlayOpacity: Double {
        guard dragOffset.width > 0 else { return 0 }
        return min(1.0, Double(dragOffset.width) / 100.0)
    }

    private var skipOverlayOpacity: Double {
        guard dragOffset.width < 0 else { return 0 }
        return min(1.0, Double(-dragOffset.width) / 100.0)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 0) {
            Spacer()

            // Skip (X)
            actionButton(
                icon: "xmark",
                size: 26,
                foreground: Color.dinkrCoral,
                background: Color.dinkrCoral.opacity(0.12),
                frameSize: 60
            ) {
                HapticManager.medium()
                swipeTop(join: false)
            }

            Spacer()

            // Save (Star)
            actionButton(
                icon: "star.fill",
                size: 20,
                foreground: Color.dinkrAmber,
                background: Color.dinkrAmber.opacity(0.12),
                frameSize: 50
            ) {
                HapticManager.soft()
                saveTop()
            }

            Spacer()

            // Join (Checkmark)
            actionButton(
                icon: "checkmark",
                size: 26,
                foreground: .white,
                background: Color.dinkrGreen,
                frameSize: 60
            ) {
                HapticManager.success()
                swipeTop(join: true)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    @ViewBuilder
    private func actionButton(
        icon: String,
        size: CGFloat,
        foreground: Color,
        background: Color,
        frameSize: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(foreground)
                .frame(width: frameSize, height: frameSize)
                .background(background, in: Circle())
                .shadow(color: foreground.opacity(0.25), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Text("🏓")
                .font(.system(size: 64))

            Text("All caught up!")
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

            Text("You've seen all available games.\nCheck back soon for new sessions.")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    deck = GameSession.mockSessions
                    rsvpedIDs = []
                    savedIDs = []
                    HapticManager.medium()
                }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.dinkrGreen, in: Capsule())
            }
            .buttonStyle(.plain)
            .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 10, x: 0, y: 5)
        }
        .padding(.top, 20)
    }

    // MARK: - Swipe Logic

    private func handleSwipeEnd(translation: CGSize) {
        let threshold: CGFloat = 120
        if translation.width > threshold {
            // Swipe right → JOIN
            flyOff(direction: 1, join: true)
        } else if translation.width < -threshold {
            // Swipe left → SKIP
            flyOff(direction: -1, join: false)
        } else {
            // Snap back
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                dragOffset = .zero
            }
        }
    }

    private func flyOff(direction: CGFloat, join: Bool) {
        let screenWidth: CGFloat = 500
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            dragOffset = CGSize(width: direction * screenWidth, height: dragOffset.height)
        }
        // Complete swipe after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            commitSwipe(join: join)
        }
    }

    private func swipeTop(join: Bool) {
        guard !filteredDeck.isEmpty else { return }
        flyOff(direction: join ? 1 : -1, join: join)
    }

    private func saveTop() {
        guard let top = filteredDeck.first else { return }
        savedIDs.insert(top.id)
        showToast("Saved \(top.courtName)! ⭐")
        // Remove from deck but don't RSVP
        withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
            deck.removeAll { $0.id == top.id }
        }
    }

    private func commitSwipe(join: Bool) {
        guard let top = filteredDeck.first else {
            dragOffset = .zero
            return
        }

        if join {
            rsvpedIDs.insert(top.id)
            showToast("You're in! 🎉")
        }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
            deck.removeAll { $0.id == top.id }
            dragOffset = .zero
        }
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        toastTimer?.invalidate()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
            toastMessage = message
        }
        toastTimer = Timer.scheduledTimer(withTimeInterval: 2.4, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                toastMessage = nil
            }
        }
    }

    private func toastBubble(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 13)
            .background(Color.dinkrNavy.opacity(0.92), in: Capsule())
            .shadow(color: Color.dinkrNavy.opacity(0.35), radius: 12, x: 0, y: 6)
    }
}

// MARK: - DiscoveryCardView

/// Expanded card layout for the swipe discovery stack.
/// Uses large gradient header and richer content than the compact GameCardView.
private struct DiscoveryCardView: View {

    let session: GameSession

    private var gradientColors: [Color] {
        switch session.format {
        case .doubles:     return [Color.dinkrGreen,  Color.dinkrSky]
        case .singles:     return [Color.dinkrSky,    Color.dinkrNavy]
        case .openPlay:    return [Color.dinkrAmber,  Color.dinkrCoral.opacity(0.7)]
        case .mixed:       return [Color.dinkrCoral,  Color.dinkrAmber]
        case .round_robin: return [Color.dinkrNavy,   Color.dinkrSky]
        }
    }

    private var formatLabel: String {
        switch session.format {
        case .doubles:     return "Doubles"
        case .singles:     return "Singles"
        case .openPlay:    return "Open Play"
        case .mixed:       return "Mixed"
        case .round_robin: return "Round Robin"
        }
    }

    private var countdownText: String {
        let diff = session.dateTime.timeIntervalSinceNow
        if diff < 0  { return "In Progress" }
        if diff < 3600 { return "Starts in \(Int(diff/60))m" }
        if diff < 86400 {
            return "Starts in \(Int(diff/3600))h \(Int((diff.truncatingRemainder(dividingBy: 3600))/60))m"
        }
        return session.dateTime.formatted(.dateTime.weekday().month(.abbreviated).day().hour().minute())
    }

    private var isUrgent: Bool { session.dateTime.timeIntervalSinceNow < 3600 }

    private var skillPillColor: Color {
        switch session.skillRange.lowerBound {
        case .beginner20, .beginner25:         return Color.dinkrGreen
        case .intermediate30, .intermediate35: return Color.dinkrSky
        case .advanced40, .advanced45:         return Color.dinkrCoral
        case .pro50:                            return Color.dinkrNavy
        }
    }

    private var fillRatio: Double {
        guard session.totalSpots > 0 else { return 0 }
        return Double(session.rsvps.count) / Double(session.totalSpots)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Gradient hero header ────────────────────────────────────────
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 160)

                // Format + countdown overlay
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(formatLabel.uppercased())
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.white.opacity(0.9))
                            .tracking(1.5)

                        Spacer()

                        if let live = session.liveScore, !live.isComplete {
                            liveBadge
                        }
                    }

                    Text(session.courtName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Text(countdownText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(18)
            }
            .clipShape(
                .rect(
                    topLeadingRadius: 24,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 24
                )
            )

            // ── Card body ───────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 14) {

                // Date/time full row
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.dinkrGreen)
                    Text(
                        session.dateTime.formatted(
                            .dateTime.weekday(.wide).month(.wide).day().hour().minute()
                        )
                    )
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                }

                // Skill range pills
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(skillPillColor)

                    Text("\(session.skillRange.lowerBound.label) – \(session.skillRange.upperBound.label)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(skillPillColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(skillPillColor.opacity(0.12), in: Capsule())

                    Spacer()

                    // Spots remaining pill
                    let spots = session.spotsRemaining
                    Text(spots == 0 ? "Full" : "\(spots) spots left")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(spots <= 1 ? Color.dinkrCoral : Color.dinkrGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            (spots <= 1 ? Color.dinkrCoral : Color.dinkrGreen).opacity(0.12),
                            in: Capsule()
                        )
                }

                // Host row
                HStack(spacing: 10) {
                    AvatarView(displayName: session.hostName, size: 30)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hosted by")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.secondary)
                        Text(session.hostName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    // Fee badge
                    if let fee = session.fee {
                        Text(fee == 0 ? "Free" : "$\(Int(fee))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(fee == 0 ? Color.dinkrGreen : .white)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 5)
                            .background(
                                fee == 0 ? Color.dinkrGreen.opacity(0.15) : Color.dinkrAmber,
                                in: Capsule()
                            )
                    }
                }

                // Spots progress bar
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("\(session.rsvps.count) / \(session.totalSpots) joined")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.secondary)
                        Spacer()
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.dinkrGreen.opacity(0.15))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(session.isFull ? Color.dinkrCoral : Color.dinkrGreen)
                                .frame(width: geo.size.width * fillRatio)
                        }
                    }
                    .frame(height: 5)
                }

                // Notes
                if !session.notes.isEmpty {
                    Text(session.notes)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(2)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(18)
            .background(Color.cardBackground)
            .clipShape(
                .rect(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 24,
                    bottomTrailingRadius: 24,
                    topTrailingRadius: 0
                )
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: gradientColors[0].opacity(0.22), radius: 18, x: 0, y: 8)
    }

    // MARK: - Live badge

    @State private var livePulse = false

    private var liveBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .scaleEffect(livePulse ? 1.4 : 0.7)
                .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: livePulse)
                .onAppear { livePulse = true }
            Text("LIVE")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.red.opacity(0.3))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    SwipeGameDiscoveryView()
}

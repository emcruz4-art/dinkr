import SwiftUI

// MARK: - Main View

struct ReputationView: View {
    let user: User

    @State private var progressWidth: CGFloat = 0
    @State private var xpExpanded: Bool = false

    private var currentLevel: PlayerLevel { user.playerLevel }
    private var nextLevel: PlayerLevel? { currentLevel.next }

    var body: some View {
        VStack(spacing: 16) {
            levelCard
            howToEarnCard
            statsGrid
            if !user.badges.isEmpty {
                badgesCard
            }
            reliabilityCard
        }
    }
}

// MARK: - Level Card

private extension ReputationView {

    var levelCard: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient background derived from level color
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            currentLevel.color.opacity(0.85),
                            currentLevel.color.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 14) {
                // Icon + Headline row
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 64, height: 64)
                        Image(systemName: currentLevel.icon)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Level \(currentLevel.level) · \(currentLevel.title)")
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(.white)
                        Text("\(user.xp) XP total")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                }

                // XP Progress bar
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.25))
                                .frame(height: 10)
                            Capsule()
                                .fill(.white)
                                .frame(width: progressWidth == 0 ? 0 : geo.size.width * CGFloat(user.levelProgress),
                                       height: 10)
                                .animation(.spring(response: 0.9, dampingFraction: 0.75).delay(0.2), value: progressWidth)
                        }
                        .onAppear {
                            progressWidth = geo.size.width
                        }
                    }
                    .frame(height: 10)

                    HStack {
                        Text("\(user.xp) XP")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))
                        Spacer()
                        if let next = nextLevel {
                            Text("\(next.xpRequired) XP")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                }

                // Subtitle
                if let next = nextLevel {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.caption2)
                        Text("+\(user.xpToNextLevel) XP to Level \(next.level) · \(next.title)")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white.opacity(0.85))
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                        Text("Max Level Reached — You're a Legend!")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white.opacity(0.85))
                }

                Divider().overlay(.white.opacity(0.3))

                // Level history timeline
                levelTimeline
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var levelTimeline: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Level History")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.bottom, 2)

            ForEach(levelTimelineRows, id: \.level) { row in
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(row.reached ? Color.white : Color.white.opacity(0.2))
                            .frame(width: 22, height: 22)
                        Image(systemName: row.reached ? row.icon : "lock")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(row.reached ? currentLevel.color : .white.opacity(0.5))
                    }
                    Text("Level \(row.level) · \(row.title)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(row.reached ? .white : .white.opacity(0.45))
                    Spacer()
                    if row.reached {
                        Text("\(row.xpRequired) XP")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    } else {
                        Text("\(row.xpRequired) XP")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
            }
        }
    }

    struct TimelineRow {
        let level: Int
        let title: String
        let icon: String
        let xpRequired: Int
        let reached: Bool
    }

    var levelTimelineRows: [TimelineRow] {
        PlayerLevel.all.map { pl in
            TimelineRow(
                level: pl.level,
                title: pl.title,
                icon: pl.icon,
                xpRequired: pl.xpRequired,
                reached: user.xp >= pl.xpRequired
            )
        }
    }
}

// MARK: - How to Earn XP Card

private extension ReputationView {

    struct XPAction: Identifiable {
        let id = UUID()
        let label: String
        let icon: String
        let xp: Int
    }

    var xpActions: [XPAction] {[
        XPAction(label: "Play a game",        icon: "figure.pickleball",     xp: 100),
        XPAction(label: "Win a game",         icon: "trophy.fill",           xp: 50),
        XPAction(label: "Host a game",        icon: "person.badge.plus",     xp: 75),
        XPAction(label: "Get 5-star review",  icon: "star.fill",             xp: 200),
        XPAction(label: "Complete a challenge", icon: "bolt.circle.fill",    xp: 150),
        XPAction(label: "Join a tournament",  icon: "flag.checkered",        xp: 125),
        XPAction(label: "Refer a friend",     icon: "person.2.fill",         xp: 300),
        XPAction(label: "Complete profile",   icon: "checkmark.circle.fill", xp: 50),
    ]}

    var howToEarnCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    xpExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(Color.dinkrAmber)
                        .font(.subheadline)
                    Text("How to Earn XP")
                        .font(.subheadline.weight(.bold))
                    Spacer()
                    Image(systemName: xpExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if xpExpanded {
                Divider().padding(.horizontal, 14)
                VStack(spacing: 0) {
                    ForEach(xpActions) { action in
                        HStack(spacing: 12) {
                            Image(systemName: action.icon)
                                .font(.subheadline)
                                .foregroundStyle(Color.dinkrGreen)
                                .frame(width: 22)
                            Text(action.label)
                                .font(.subheadline)
                            Spacer()
                            Text("+\(action.xp) XP")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.dinkrAmber)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Color.dinkrAmber.opacity(0.14))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        if action.id != xpActions.last?.id {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Stats Mini-Grid

private extension ReputationView {

    var statsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Current Stats")
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, 14)
                .padding(.top, 14)

            HStack(spacing: 0) {
                ReputationStatItem(
                    value: "\(user.gamesPlayed)",
                    label: "Games Played",
                    icon: "figure.pickleball",
                    color: Color.dinkrSky
                )
                Divider().frame(height: 44)
                ReputationStatItem(
                    value: "\(Int(user.winRate * 100))%",
                    label: "Win Rate",
                    icon: "trophy.fill",
                    color: Color.dinkrGreen
                )
                Divider().frame(height: 44)
                ReputationStatItem(
                    value: user.duprRating.map { String(format: "%.2f", $0) } ?? "—",
                    label: "DUPR",
                    icon: "chart.bar.fill",
                    color: Color.dinkrAmber
                )
                Divider().frame(height: 44)
                ReputationStatItem(
                    value: String(format: "%.1f", user.reliabilityScore),
                    label: "Reliability",
                    icon: "star.fill",
                    color: Color.dinkrCoral
                )
            }
            .padding(.bottom, 8)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Badges Card

private extension ReputationView {

    var badgesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Badges")
                .font(.subheadline.weight(.bold))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(user.badges) { badge in
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(Color.dinkrAmber.opacity(0.12))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "medal.fill")
                                    .foregroundStyle(Color.dinkrAmber)
                                    .font(.title3)
                            }
                            Text(badge.label)
                                .font(.caption2)
                                .multilineTextAlignment(.center)
                                .frame(width: 60)
                                .lineLimit(2)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Reliability Card

private extension ReputationView {

    var reliabilityCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.dinkrAmber.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(Color.dinkrAmber)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Reliability Score")
                    .font(.subheadline.weight(.bold))
                Text(reliabilityLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(String(format: "%.1f", user.reliabilityScore))
                .font(.title2.weight(.heavy))
                .foregroundStyle(Color.dinkrAmber)
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    var reliabilityLabel: String {
        switch user.reliabilityScore {
        case 4.8...5.0: return "Exceptional — top 5% of players"
        case 4.5..<4.8: return "Excellent — highly dependable"
        case 4.0..<4.5: return "Good — solid track record"
        case 3.0..<4.0: return "Improving"
        default:        return "Needs attention"
        }
    }
}

// MARK: - Shared Stat Item

struct ReputationStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
            Text(value)
                .font(.title3.weight(.heavy))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        ReputationView(user: User.mockCurrentUser)
            .padding()
    }
}

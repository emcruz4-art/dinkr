import SwiftUI

// MARK: - Models

enum DrillCategory: String, CaseIterable, Identifiable {
    case dinking   = "Dinking"
    case serving   = "Serving"
    case returns   = "Returns"
    case volleys   = "Volleys"
    case movement  = "Movement"
    case strategy  = "Strategy"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .dinking:  return Color.dinkrGreen
        case .serving:  return Color.dinkrSky
        case .returns:  return Color.dinkrAmber
        case .volleys:  return Color.dinkrCoral
        case .movement: return Color.dinkrNavy
        case .strategy: return Color.purple
        }
    }

    var icon: String {
        switch self {
        case .dinking:  return "arrow.left.and.right"
        case .serving:  return "arrow.up.circle.fill"
        case .returns:  return "arrow.uturn.left"
        case .volleys:  return "bolt.fill"
        case .movement: return "figure.run"
        case .strategy: return "brain.head.profile"
        }
    }
}

enum DrillDifficulty: String, CaseIterable {
    case beginner     = "Beginner"
    case intermediate = "Intermediate"
    case advanced     = "Advanced"

    var color: Color {
        switch self {
        case .beginner:     return Color.dinkrGreen
        case .intermediate: return Color.dinkrAmber
        case .advanced:     return Color.dinkrCoral
        }
    }

    var stars: Int {
        switch self {
        case .beginner:     return 1
        case .intermediate: return 2
        case .advanced:     return 3
        }
    }
}

enum PlayerCount: String {
    case solo      = "Solo"
    case twoPlus   = "2+ Players"

    var icon: String {
        switch self {
        case .solo:    return "person.fill"
        case .twoPlus: return "person.2.fill"
        }
    }
}

struct Drill: Identifiable {
    let id = UUID()
    let name: String
    let category: DrillCategory
    let difficulty: DrillDifficulty
    let duration: Int        // minutes
    let playerCount: PlayerCount
    let description: String
    let steps: [String]
    let tips: [String]
    let relatedDrillNames: [String]
    var isFeatured: Bool = false
}

// MARK: - Mock Data

extension Drill {
    static let allDrills: [Drill] = [
        Drill(
            name: "Kitchen Consistency Rally",
            category: .dinking,
            difficulty: .beginner,
            duration: 10,
            playerCount: .twoPlus,
            description: "Build muscle memory and control by sustaining long dink rallies from the kitchen line. Focus on soft hands, low contact point, and placement over power.",
            steps: [
                "Both players position at their respective kitchen lines.",
                "Begin a slow cross-court dink rally, keeping the ball below net height.",
                "Count consecutive dinks without faults — target 20 in a row.",
                "Gradually vary placement: straight-on, cross-court, then middle.",
                "Reset after any fault and track personal best streaks."
            ],
            tips: [
                "Bend your knees and stay low — this prevents popping the ball up.",
                "Aim for the opponent's kitchen line, not their body.",
                "Use a continental or Eastern grip for better touch control."
            ],
            relatedDrillNames: ["Speed Dink Drill", "Cross-court Dink Battle", "Reset & Defend Sequence"]
        ),
        Drill(
            name: "Serve Box Target Practice",
            category: .serving,
            difficulty: .beginner,
            duration: 15,
            playerCount: .solo,
            description: "Sharpen serve accuracy by targeting specific zones in the service box. Consistent placement beats power every time at the recreational and tournament level.",
            steps: [
                "Set up 3 targets (cones or towels) in the opponent's service box: deep center, wide backhand, and T-junction.",
                "Serve 10 balls toward each target, tracking hits.",
                "Alternate between forehand and backhand serves.",
                "Focus on a smooth pendulum swing and consistent toss.",
                "Challenge yourself: 5 consecutive target hits before moving on."
            ],
            tips: [
                "Keep your serve motion loose and repeatable — tension kills touch.",
                "Contact the ball below waist height to stay within the rules.",
                "Watch your feet: avoid stepping into the kitchen before the ball lands."
            ],
            relatedDrillNames: ["Third Shot Drop Sequence", "Reset & Defend Sequence", "Erne Attack Pattern"]
        ),
        Drill(
            name: "Third Shot Drop Sequence",
            category: .returns,
            difficulty: .intermediate,
            duration: 20,
            playerCount: .twoPlus,
            description: "Master the third shot drop — pickleball's most important transition shot. This drill trains you to neutralize the net team and earn your way to the kitchen.",
            steps: [
                "Server hits a serve; returner hits a deep return and charges to the kitchen.",
                "Server hits the third shot drop, aiming to land in the kitchen.",
                "If the drop is successful and soft, server advances toward the kitchen.",
                "Returner dinks the ball back; server continues to drop until reaching NVZ.",
                "Rally out from kitchen. Rotate after 5 reps each side."
            ],
            tips: [
                "Think 'lift and arc,' not 'push and drive' — the ball should float down.",
                "Watch the ball all the way to your paddle face on contact.",
                "If your drop keeps going long, slow down your swing, not your feet."
            ],
            relatedDrillNames: ["Kitchen Consistency Rally", "Reset & Defend Sequence", "Serve Box Target Practice"]
        ),
        Drill(
            name: "Speed Dink Drill",
            category: .dinking,
            difficulty: .advanced,
            duration: 15,
            playerCount: .twoPlus,
            description: "Train rapid-fire kitchen exchanges to build reaction time, paddle speed, and attack/reset decision-making under pressure.",
            steps: [
                "Both players at kitchen line, begin a standard dink rally.",
                "One player calls 'speed' to initiate an accelerated exchange.",
                "Both players dink at maximum safe speed for 10 exchanges.",
                "First player to pop up or mis-hit concedes the point.",
                "Rest 15 seconds and repeat 8 rounds."
            ],
            tips: [
                "Keep the paddle up and ready — don't drop it between shots.",
                "Short backswing is key: big backswings cause errors at speed.",
                "Use your wrist to redirect rather than your whole arm."
            ],
            relatedDrillNames: ["Kitchen Consistency Rally", "Erne Attack Pattern", "Cross-court Dink Battle"]
        ),
        Drill(
            name: "Erne Attack Pattern",
            category: .volleys,
            difficulty: .advanced,
            duration: 20,
            playerCount: .twoPlus,
            description: "Learn to execute the Erne — a volley taken outside the sideline post — to attack wide dinks and surprise your opponents with an aggressive transition move.",
            steps: [
                "Feeder stands at baseline and feeds a wide dink toward the sideline kitchen corner.",
                "Erne player moves laterally, jumps around the NVZ corner, and volleys from outside the court.",
                "Focus on landing outside the kitchen, not inside, to avoid a fault.",
                "Practice the jump-and-land footwork pattern dry (no ball) 5 times first.",
                "Add live feeding once footwork is comfortable. Rotate every 5 reps."
            ],
            tips: [
                "Telegraph intent subtly — too obvious a setup and opponents will redirect away.",
                "Aim cross-court on the Erne volley for the highest percentage winner.",
                "Stay balanced on landing — a stumble gives your opponent time to recover."
            ],
            relatedDrillNames: ["Speed Dink Drill", "Footwork Ladder Circuit", "Cross-court Dink Battle"]
        ),
        Drill(
            name: "Footwork Ladder Circuit",
            category: .movement,
            difficulty: .intermediate,
            duration: 25,
            playerCount: .solo,
            description: "Build court-specific agility, split-step timing, and lateral quickness through a structured agility ladder circuit designed for pickleball movement patterns.",
            steps: [
                "Set up agility ladder along baseline. Warm up 5 minutes.",
                "Two-feet-in: step both feet into each square, forward and back — 3 passes.",
                "Lateral shuffle: side-step through each square maintaining paddle-ready position — 3 passes each direction.",
                "In-out crossover: mimicking kitchen approach footwork — 3 passes.",
                "Sprint finish: full-court sprint to kitchen and back after each circuit. Rest 90 seconds."
            ],
            tips: [
                "Stay on the balls of your feet throughout — no flat-footed stepping.",
                "Hold your paddle in ready position the entire circuit.",
                "Speed matters less than clean footwork form during the drill."
            ],
            relatedDrillNames: ["Erne Attack Pattern", "Kitchen Consistency Rally", "Reset & Defend Sequence"]
        ),
        Drill(
            name: "Cross-court Dink Battle",
            category: .dinking,
            difficulty: .intermediate,
            duration: 20,
            playerCount: .twoPlus,
            description: "Dominate the cross-court dinking game with this competitive drill that builds consistency, patience, and the ability to redirect under pressure.",
            steps: [
                "Both players at kitchen line, diagonal corners.",
                "Maintain cross-court dink rally. Neither player can go down-the-line.",
                "First to 11 points wins. A fault or pop-up concedes the point.",
                "Switch sides after each game to train both forehand and backhand.",
                "Add handicap: weaker player can go down-the-line, stronger player cannot."
            ],
            tips: [
                "Target the opponent's feet and kitchen line, not their chest.",
                "Reset with softness when you receive a heavy shot — don't counter hard.",
                "Move your feet into position; don't reach for shots."
            ],
            relatedDrillNames: ["Kitchen Consistency Rally", "Speed Dink Drill", "Erne Attack Pattern"]
        ),
        Drill(
            name: "Reset & Defend Sequence",
            category: .strategy,
            difficulty: .advanced,
            duration: 30,
            playerCount: .twoPlus,
            description: "Develop the mental and physical skills to survive high-pressure attacks and reset to a neutral kitchen battle. This drill separates intermediate from advanced players.",
            steps: [
                "One player at kitchen, one at mid-court (transition zone).",
                "Kitchen player drives or attacks toward mid-court player.",
                "Mid-court player must reset every ball softly into the kitchen — no counter-attacks.",
                "After 5 consecutive resets, mid-court player can advance to kitchen.",
                "Play out the point from kitchen-vs-kitchen. Rotate roles after 10 reps."
            ],
            tips: [
                "Soft hands on the reset: absorb the pace, don't fight it.",
                "Block with a slightly open face to aim the reset downward.",
                "Patience wins — resist the urge to attack from mid-court."
            ],
            relatedDrillNames: ["Third Shot Drop Sequence", "Kitchen Consistency Rally", "Footwork Ladder Circuit"]
        ),
        Drill(
            name: "Backhand Punch Volley",
            category: .volleys,
            difficulty: .intermediate,
            duration: 15,
            playerCount: .twoPlus,
            description: "Strengthen the backhand volley — often the weakest shot for newer players — through targeted repetition at the non-volley zone line.",
            steps: [
                "Feeder hand-feeds or paddle-feeds directly to volleyer's backhand at kitchen line.",
                "Volleyer punches ball cross-court, then down-the-line, alternating.",
                "Focus on a compact, forward punch motion with a firm wrist.",
                "Graduate to random feeds once compact form is consistent.",
                "Add footwork: feeder feeds wide so volleyer must step and punch."
            ],
            tips: [
                "Grip slightly firmer on the backhand volley than the dink.",
                "Elbow leads slightly — don't chicken-wing the swing outward.",
                "Contact in front of your body, not beside or behind you."
            ],
            relatedDrillNames: ["Erne Attack Pattern", "Speed Dink Drill", "Reset & Defend Sequence"]
        ),
        Drill(
            name: "Deep Return Placement",
            category: .returns,
            difficulty: .beginner,
            duration: 10,
            playerCount: .twoPlus,
            description: "Force your opponents into difficult third shots by landing consistently deep returns, pushing them back and giving you time to reach the kitchen.",
            steps: [
                "Server serves from baseline. Returner focuses on depth, not angle.",
                "Target: land every return within 3 feet of the baseline.",
                "Returner immediately moves to kitchen after contact — practice the approach.",
                "After 10 reps, add a wider target: aim at the server's weaker wing.",
                "Score 1 point per return that lands in the deep zone."
            ],
            tips: [
                "Use a full swing — don't block the return like a dink.",
                "Move your feet before contact for a balanced stroke.",
                "Deep and in beats wide and risky every time."
            ],
            relatedDrillNames: ["Third Shot Drop Sequence", "Serve Box Target Practice", "Reset & Defend Sequence"]
        ),
        Drill(
            name: "Lob Defense Sprint",
            category: .movement,
            difficulty: .advanced,
            duration: 20,
            playerCount: .twoPlus,
            description: "Build the ability to track down offensive lobs and respond with a controlled overhead or reset rather than panicking. Speed and decision-making under fatigue.",
            steps: [
                "Both players start at kitchen line.",
                "One player lobs over the other. Lobbed player sprints back and plays the ball.",
                "Goal: get it back in play every time, even if just a safe lob back.",
                "Add scoring: 1 point for successfully resetting a lob into the kitchen.",
                "Increase challenge: feeder lobs early to random sides without warning."
            ],
            tips: [
                "Turn sideways and run — don't backpedal, it's too slow.",
                "If you can't overhead comfortably, lob it back and reset.",
                "Call 'lob' to your partner in doubles so roles are clear."
            ],
            relatedDrillNames: ["Footwork Ladder Circuit", "Reset & Defend Sequence", "Erne Attack Pattern"]
        ),
        Drill(
            name: "Serving Spin Variety",
            category: .serving,
            difficulty: .intermediate,
            duration: 15,
            playerCount: .solo,
            description: "Add spin variation to your serve arsenal — topspin, slice, and flat — to keep opponents guessing and set up weaker returns.",
            steps: [
                "Hit 10 flat serves: focus on consistent contact and depth.",
                "Hit 10 topspin serves: brush up on the back of the ball at contact.",
                "Hit 10 slice serves: cut across the ball to generate side-to-side movement.",
                "Alternate spin types randomly for 20 more serves.",
                "Track which spin yields the most return errors or pop-ups."
            ],
            tips: [
                "Don't sacrifice placement for spin — spin without depth is easy to attack.",
                "Exaggerate the spin motion in practice; tone it down in match play.",
                "Mix up pace and spin together for maximum unpredictability."
            ],
            relatedDrillNames: ["Serve Box Target Practice", "Deep Return Placement", "Third Shot Drop Sequence"]
        ),
        Drill(
            name: "Stacking Transition Drill",
            category: .strategy,
            difficulty: .advanced,
            duration: 25,
            playerCount: .twoPlus,
            description: "Practice the stacking formation used in doubles to keep a stronger player's forehand in the middle or exploit opponent positioning.",
            steps: [
                "Team A stacks: both players start on the same side of the court post-serve.",
                "Player A serves, both players shift to preferred stacking positions.",
                "Play out the point while maintaining the intended formation.",
                "Practice communication: 'I got middle,' 'yours wide,' etc.",
                "Rotate sides and serving roles every 5 points."
            ],
            tips: [
                "Communication is more important than positioning — stay verbal.",
                "Poaching in stack formation is high reward, high risk — pick your spots.",
                "Drill the rotation movement pattern dry before adding live rallies."
            ],
            relatedDrillNames: ["Reset & Defend Sequence", "Third Shot Drop Sequence", "Footwork Ladder Circuit"]
        )
    ]

    static var featuredDrill: Drill {
        var drill = allDrills[2] // Third Shot Drop Sequence
        drill.isFeatured = true
        return drill
    }
}

// MARK: - PracticeLibraryView

struct PracticeLibraryView: View {
    @State private var searchText = ""
    @State private var selectedCategory: DrillCategory? = nil
    @State private var selectedDrill: Drill? = nil

    private var filteredDrills: [Drill] {
        var drills = Drill.allDrills
        if let cat = selectedCategory {
            drills = drills.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            drills = drills.filter {
                $0.name.lowercased().contains(q) ||
                $0.category.rawValue.lowercased().contains(q) ||
                $0.description.lowercased().contains(q)
            }
        }
        return drills
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.secondary)
                            .font(.system(size: 15))
                        TextField("Search drills...", text: $searchText)
                            .font(.system(size: 15))
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                    // Category filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(label: "All", icon: "square.grid.2x2.fill", color: Color.dinkrNavy, isSelected: selectedCategory == nil) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    selectedCategory = nil
                                }
                            }
                            ForEach(DrillCategory.allCases) { cat in
                                CategoryChip(label: cat.rawValue, icon: cat.icon, color: cat.color, isSelected: selectedCategory == cat) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        selectedCategory = selectedCategory == cat ? nil : cat
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }

                    // Only show featured when no search/filter active
                    if searchText.isEmpty && selectedCategory == nil {
                        FeaturedDrillCard(drill: Drill.featuredDrill)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }

                    // Results header
                    HStack {
                        Text(selectedCategory == nil ? "All Drills" : selectedCategory!.rawValue)
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(filteredDrills.count) drills")
                            .font(.caption2)
                            .foregroundStyle(Color.dinkrGreen)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                    // 2-column drill grid
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(filteredDrills) { drill in
                            NavigationLink(destination: DrillDetailView(drill: drill, allDrills: Drill.allDrills)) {
                                DrillCard(drill: drill)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Practice Library")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - CategoryChip

struct CategoryChip: View {
    let label: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .bold : .regular))
            }
            .foregroundStyle(isSelected ? .white : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? color : color.opacity(0.1))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FeaturedDrillCard

struct FeaturedDrillCard: View {
    let drill: Drill

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient background
            LinearGradient(
                colors: [Color.dinkrNavy, drill.category.color.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Drill of the Day", systemImage: "star.fill")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(Color.dinkrAmber)
                    Spacer()
                    DifficultyBadge(difficulty: drill.difficulty)
                }

                Spacer()

                Text(drill.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)

                Text(drill.description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 14) {
                    Label("\(drill.duration) min", systemImage: "clock")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Label(drill.playerCount.rawValue, systemImage: drill.playerCount.icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                    CategoryBadge(category: drill.category, small: true, inverted: true)
                }
            }
            .padding(20)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.dinkrNavy.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

// MARK: - DrillCard

struct DrillCard: View {
    let drill: Drill

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top: category badge
            HStack {
                CategoryBadge(category: drill.category, small: true, inverted: false)
                Spacer()
            }

            // Drill name
            Text(drill.name)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            // Difficulty badge
            DifficultyBadge(difficulty: drill.difficulty)

            // Duration + player count
            HStack(spacing: 8) {
                Label("\(drill.duration)m", systemImage: "clock")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary)
                Spacer()
                Label(drill.playerCount == .solo ? "Solo" : "2+", systemImage: drill.playerCount.icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Shared Badge Components

struct CategoryBadge: View {
    let category: DrillCategory
    var small: Bool = false
    var inverted: Bool = false

    var body: some View {
        Text(category.rawValue)
            .font(.system(size: small ? 10 : 11, weight: .bold))
            .foregroundStyle(inverted ? category.color : .white)
            .padding(.horizontal, small ? 8 : 10)
            .padding(.vertical, small ? 3 : 4)
            .background(inverted ? Color.white.opacity(0.2) : category.color)
            .clipShape(Capsule())
    }
}

struct DifficultyBadge: View {
    let difficulty: DrillDifficulty

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(i < difficulty.stars ? difficulty.color : difficulty.color.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
            Text(difficulty.rawValue)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(difficulty.color)
        }
    }
}

#Preview {
    PracticeLibraryView()
}

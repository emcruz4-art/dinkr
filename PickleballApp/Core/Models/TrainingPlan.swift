import SwiftUI

// MARK: - DrillCategory

enum DrillCategory: String, CaseIterable {
    case dinking   = "Dinking"
    case serving   = "Serving"
    case thirdShot = "Third Shot"
    case netPlay   = "Net Play"
    case footwork  = "Footwork"
    case fitness   = "Fitness"

    var color: Color {
        switch self {
        case .dinking:   return Color.dinkrGreen
        case .serving:   return Color.dinkrSky
        case .thirdShot: return Color.dinkrAmber
        case .netPlay:   return Color.dinkrCoral
        case .footwork:  return Color.dinkrNavy
        case .fitness:   return Color(red: 0.55, green: 0.35, blue: 0.85)
        }
    }

    var icon: String {
        switch self {
        case .dinking:   return "figure.pickleball"
        case .serving:   return "arrow.up.right.circle.fill"
        case .thirdShot: return "dot.circle.and.hand.point.up.left.fill"
        case .netPlay:   return "tennis.racket"
        case .footwork:  return "figure.run"
        case .fitness:   return "heart.fill"
        }
    }
}

// MARK: - Drill

struct Drill: Identifiable {
    var id: String
    var name: String
    var category: DrillCategory
    var difficulty: String   // "Beginner", "Intermediate", "Advanced"
    var durationMinutes: Int
    var description: String
    var tips: [String]
    var repsOrSets: String   // "3 sets of 10", "5 minutes", "20 rallies"
    var focusArea: String    // "Soft hands", "Court positioning", etc.
}

// MARK: - TrainingPlan

struct TrainingPlan: Identifiable {
    var id: String
    var name: String
    var level: String        // "Beginner", "Intermediate", "Advanced", "All Levels"
    var durationWeeks: Int
    var sessionsPerWeek: Int
    var totalDrills: Int
    var description: String
    var drillIds: [String]
    var colorGradient: [Color]   // two dinkr colors
    var badge: String            // SF symbol name
}

// MARK: - Mock Drills

extension Drill {
    static let mockDrills: [Drill] = [

        // ── DINKING ───────────────────────────────────────────────────────────
        Drill(
            id: "drill_001",
            name: "Cross-Court Dink Rally",
            category: .dinking,
            difficulty: "Beginner",
            durationMinutes: 10,
            description: "Stand at the kitchen line with a partner and sustain a cross-court dinking exchange. Focus on keeping the ball low over the net and landing it in the opponent's kitchen.",
            tips: [
                "Use a Continental or Eastern grip for better feel.",
                "Bend your knees and stay low — don't reach for the ball.",
                "Aim 2–4 inches above the net tape, not higher.",
                "Reset your paddle to ready position after every shot.",
                "Breathe — tense arms create errors."
            ],
            repsOrSets: "5-minute rally sets × 2",
            focusArea: "Soft hands"
        ),

        Drill(
            id: "drill_002",
            name: "Dink Speed Control Ladder",
            category: .dinking,
            difficulty: "Intermediate",
            durationMinutes: 12,
            description: "Trade dinks with a partner starting very slowly. Every 10 consecutive shots, deliberately slow down further to build feel, then gradually increase pace. The goal is precision at any speed.",
            tips: [
                "Keep your elbow close to your hip for consistent arm swing.",
                "Watch the ball all the way to contact.",
                "Short backswing — this is not a drive.",
                "Target the sideline kitchen corner to stretch your opponent.",
                "Count your rally aloud to track consistency milestones."
            ],
            repsOrSets: "3 sets of 30 consecutive dinks",
            focusArea: "Consistency under varying pace"
        ),

        Drill(
            id: "drill_003",
            name: "Erne Bait & Dink Reset",
            category: .dinking,
            difficulty: "Advanced",
            durationMinutes: 15,
            description: "One player attempts Erne attacks while the partner practices absorbing pace and resetting back to a neutral dink. This develops the high-pressure reset under a real Erne threat.",
            tips: [
                "Soften your grip to 3/10 when absorbing an Erne.",
                "Open your paddle face slightly on resets.",
                "Step back half a step if the ball is above net height.",
                "Communicate with your partner: 'Erne' before jumping.",
                "Rotate roles every 5 minutes."
            ],
            repsOrSets: "10 Erne attempts each side",
            focusArea: "Pressure resets"
        ),

        // ── SERVING ──────────────────────────────────────────────────────────
        Drill(
            id: "drill_004",
            name: "Deep Serve Targeting",
            category: .serving,
            difficulty: "Beginner",
            durationMinutes: 8,
            description: "Practice landing serves within 1 foot of the baseline. Place a towel or cone near the baseline as a target. Consistent deep serves push opponents back and set up stronger third shots.",
            tips: [
                "Strike the ball at hip height or below.",
                "Follow through toward your target.",
                "Use a smooth pendulum swing — avoid a wrist flick.",
                "Aim for the backhand corner to stress the receiver.",
                "Vary pace to keep opponents guessing."
            ],
            repsOrSets: "20 serves per side",
            focusArea: "Depth and placement"
        ),

        Drill(
            id: "drill_005",
            name: "Spin Serve Combinations",
            category: .serving,
            difficulty: "Intermediate",
            durationMinutes: 10,
            description: "Alternate between topspin, slice, and flat serves in a pre-set rotation. This builds serve variety and conditions opponents to face unpredictable ball behavior off the bounce.",
            tips: [
                "Topspin: brush up on the back of the ball at contact.",
                "Slice: contact the outside edge with a low-to-high motion.",
                "Flat: direct pendulum, hit through the center of the ball.",
                "Keep your toss (or drop) consistent across all serve types.",
                "Watch your partner's return stance to gauge which serve worked."
            ],
            repsOrSets: "3 sets of 9 (3 of each type)",
            focusArea: "Serve variety"
        ),

        // ── THIRD SHOT ────────────────────────────────────────────────────────
        Drill(
            id: "drill_006",
            name: "Third Shot Drop Basket Feed",
            category: .thirdShot,
            difficulty: "Beginner",
            durationMinutes: 12,
            description: "Partner feeds from the kitchen while you practice third-shot drops from the baseline. Goal is to land the ball in the kitchen soft enough that your partner cannot attack it.",
            tips: [
                "Start the swing low and finish high.",
                "Use a continental grip — not western.",
                "Weight should shift forward through contact.",
                "Aim 6 inches past the net for a good kitchen landing.",
                "Resist the urge to watch the ball land — move forward immediately."
            ],
            repsOrSets: "3 sets of 15 drops",
            focusArea: "Transition zone entry"
        ),

        Drill(
            id: "drill_007",
            name: "Third Shot Drive/Drop Decision",
            category: .thirdShot,
            difficulty: "Intermediate",
            durationMinutes: 15,
            description: "Play out points from the serve. After the return, make a real-time decision to drive or drop based on the return depth and pace. Coach or partner calls 'Short!' or 'Deep!' after the return to reinforce pattern recognition.",
            tips: [
                "Short/weak return → consider a drive.",
                "Deep/fast return → default to drop.",
                "Commit fully — a half-hearted drive is the worst choice.",
                "After a drive, be ready for a speed-up or block.",
                "Track your drive-to-drop ratio over a session."
            ],
            repsOrSets: "20 decision-based rallies",
            focusArea: "Shot selection"
        ),

        // ── NET PLAY ─────────────────────────────────────────────────────────
        Drill(
            id: "drill_008",
            name: "Volley Punch Warm-Up",
            category: .netPlay,
            difficulty: "Beginner",
            durationMinutes: 8,
            description: "Partners stand inside the transition zone and trade punched volleys back and forth without letting the ball bounce. Focus on compact swings and fast paddle recovery.",
            tips: [
                "Keep the paddle in front of your body — never let it drop.",
                "Punch through the ball rather than swinging.",
                "Soft hands on incoming pace — redirect, don't swing.",
                "Stay on your toes, not your heels.",
                "Eyes stay up on your opponent, not the ball at your feet."
            ],
            repsOrSets: "3-minute rally sets × 3",
            focusArea: "Compact volley mechanics"
        ),

        Drill(
            id: "drill_009",
            name: "Speed-Up Recognition Drill",
            category: .netPlay,
            difficulty: "Advanced",
            durationMinutes: 15,
            description: "Both players start in a dink rally. One player (attacker) can speed up any ball at will; the other (defender) must block or reset. Switch roles every 10 attacks. Builds defensive reflexes.",
            tips: [
                "Block by presenting the paddle face — no swing needed.",
                "Absorb pace by pulling the paddle backward slightly on contact.",
                "Aim blocks at the attacker's feet to end the rally.",
                "Don't flinch — flinching opens your body.",
                "Call 'yours' or 'mine' with a partner in doubles."
            ],
            repsOrSets: "10 attacks per role × 3 rounds",
            focusArea: "Reflexes and blocking"
        ),

        // ── FOOTWORK ─────────────────────────────────────────────────────────
        Drill(
            id: "drill_010",
            name: "Split-Step Timing Practice",
            category: .footwork,
            difficulty: "Beginner",
            durationMinutes: 8,
            description: "Shadow drill at the kitchen line. Partner calls 'Now!' and you perform a split-step followed by a side-shuffle in the called direction. Builds the reactive step that sets up every winning volley.",
            tips: [
                "Split when your opponent contacts the ball — not before or after.",
                "Land shoulder-width apart, slight bend in knees.",
                "Toes should point slightly outward at split.",
                "Keep the paddle up during the split — not at your hip.",
                "Practice at 50%, 75%, then 100% speed across 3 rounds."
            ],
            repsOrSets: "30 split-steps total (3 sets of 10)",
            focusArea: "Reactive readiness"
        ),

        Drill(
            id: "drill_011",
            name: "Transition Zone Approach Footwork",
            category: .footwork,
            difficulty: "Intermediate",
            durationMinutes: 12,
            description: "Start at the baseline. Hit a drop, then advance using 3 short power steps to stop just behind the kitchen line before the next shot arrives. Mirrors the real third-shot-to-net approach sequence.",
            tips: [
                "First step is a drop step — wide and explosive.",
                "Stay low during the approach run.",
                "Come to a balanced stop before hitting the next ball.",
                "Don't run and hit at the same time — stop, then swing.",
                "Use the sideline as a visual lane guide for straight paths."
            ],
            repsOrSets: "15 approach sequences per session",
            focusArea: "Kitchen line approach timing"
        ),

        // ── FITNESS ──────────────────────────────────────────────────────────
        Drill(
            id: "drill_012",
            name: "Court Sprint Intervals",
            category: .fitness,
            difficulty: "Beginner",
            durationMinutes: 10,
            description: "Sprint baseline to kitchen line and back 10 times with 20-second rest between each set. Simulates the short explosive bursts required during active points.",
            tips: [
                "Drive your arms — upper body powers your legs.",
                "Touch the line with your foot, don't just get close.",
                "Stay on the balls of your feet the entire interval.",
                "Count reps aloud to avoid losing track.",
                "Finish the 10 sets even if pace slows — conditioning adapts."
            ],
            repsOrSets: "10 court sprints × 3 sets",
            focusArea: "Explosive lateral speed"
        ),

        Drill(
            id: "drill_013",
            name: "Lateral Shuffle Agility Ladder",
            category: .fitness,
            difficulty: "Intermediate",
            durationMinutes: 10,
            description: "Use an agility ladder or court lines for lateral shuffle patterns. Perform two-in, two-out footwork focusing on hip rotation and proper weight transfer. Directly translates to wide dink defense.",
            tips: [
                "Quick small steps beat big lunge steps for court coverage.",
                "Keep chest up and knees bent throughout.",
                "Paddle stays in ready position the entire drill.",
                "Increase speed gradually over 5 reps before going full intensity.",
                "Film yourself to check if you're crossing your feet (don't)."
            ],
            repsOrSets: "5 ladder passes × 4 rounds",
            focusArea: "Hip rotation and court coverage"
        ),

        Drill(
            id: "drill_014",
            name: "Core Stability Press Series",
            category: .fitness,
            difficulty: "Beginner",
            durationMinutes: 8,
            description: "Off-court paddle press drill: hold your paddle at arm's length and perform slow controlled circles, figure-eights, and press-holds. Builds the forearm and shoulder endurance needed for 2+ hour sessions.",
            tips: [
                "Keep your wrist locked — movement comes from shoulder and elbow.",
                "Start with 30-second holds, progress to 60.",
                "Do not shrug your shoulders — keep them packed down.",
                "Pair with diaphragm breathing, not chest breathing.",
                "3x per week is enough — over-training causes elbow fatigue."
            ],
            repsOrSets: "3 sets of 45-second holds",
            focusArea: "Paddle endurance"
        ),

        Drill(
            id: "drill_015",
            name: "Full-Court Endurance Rally",
            category: .fitness,
            difficulty: "Advanced",
            durationMinutes: 20,
            description: "Sustain a continuous rally covering all court zones: baseline drives, transition drops, and kitchen dinks. One player drives from the baseline while the other resets and dinks. Switch roles every 5 minutes. Conditions every energy system used in competition.",
            tips: [
                "Set a rally goal — 100 combined shots per round.",
                "Don't rush transitions — patience builds aerobic base.",
                "Sip water at role switches to maintain performance.",
                "Mental focus: treat every shot as if the score is 10-10-2.",
                "Track your total rally count per session to measure endurance gains."
            ],
            repsOrSets: "20 minutes continuous (4 × 5-min role rounds)",
            focusArea: "Full-match conditioning"
        )
    ]
}

// MARK: - Mock Training Plans

extension TrainingPlan {
    static let mockPlans: [TrainingPlan] = [
        TrainingPlan(
            id: "plan_001",
            name: "Foundation Series",
            level: "Beginner",
            durationWeeks: 4,
            sessionsPerWeek: 3,
            totalDrills: 5,
            description: "Build the fundamentals that every strong pickleball game is built on. Covers service mechanics, dinking, basic footwork, and kitchen line positioning over four structured weeks.",
            drillIds: ["drill_001", "drill_004", "drill_006", "drill_010", "drill_012"],
            colorGradient: [Color.dinkrGreen, Color.dinkrSky],
            badge: "figure.pickleball"
        ),
        TrainingPlan(
            id: "plan_002",
            name: "Dink Master",
            level: "Intermediate",
            durationWeeks: 6,
            sessionsPerWeek: 4,
            totalDrills: 7,
            description: "Elevate your soft game to a weapon. Six weeks dedicated to cross-court consistency, speed-control, Erne threats, and the net-play exchanges that decide close matches.",
            drillIds: ["drill_001", "drill_002", "drill_003", "drill_007", "drill_008", "drill_011", "drill_013"],
            colorGradient: [Color.dinkrNavy, Color.dinkrGreen],
            badge: "trophy.fill"
        ),
        TrainingPlan(
            id: "plan_003",
            name: "Tournament Prep",
            level: "Advanced",
            durationWeeks: 8,
            sessionsPerWeek: 5,
            totalDrills: 10,
            description: "Eight weeks of high-intensity preparation for competitive play. Combines every skill zone — third-shot decision-making, speed-up defense, advanced footwork, and peak-performance conditioning.",
            drillIds: ["drill_002", "drill_003", "drill_005", "drill_007", "drill_009", "drill_011", "drill_013", "drill_014", "drill_015", "drill_001"],
            colorGradient: [Color.dinkrCoral, Color.dinkrAmber],
            badge: "medal.fill"
        ),
        TrainingPlan(
            id: "plan_004",
            name: "Quick Wins",
            level: "All Levels",
            durationWeeks: 2,
            sessionsPerWeek: 3,
            totalDrills: 4,
            description: "A compact two-week program designed to sharpen three or four high-impact skills fast. Great for players returning after a break or prepping for a casual tournament weekend.",
            drillIds: ["drill_004", "drill_006", "drill_008", "drill_012"],
            colorGradient: [Color.dinkrAmber, Color.dinkrSky],
            badge: "bolt.fill"
        )
    ]
}

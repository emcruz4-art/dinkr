import SwiftUI

// MARK: - Compatibility Score Model

struct CompatibilityScore {
    let overall: Int // 0–100
    let skillMatch: Int     // weighted 40%
    let scheduleMatch: Int  // weighted 30%
    let playStyle: Int      // weighted 20%
    let location: Int       // weighted 10%

    static func compute(current: User, candidate: User) -> CompatibilityScore {
        // Skill match: penalise each level gap
        let skillGap = abs(current.skillLevel.sortIndex - candidate.skillLevel.sortIndex)
        let skillScore = max(0, 100 - skillGap * 25)

        // Schedule match: shared availability days
        let currentDays = Set(current.availabilityDays ?? [])
        let candidateDays = Set(candidate.availabilityDays ?? [])
        let sharedDays = currentDays.intersection(candidateDays).count
        let totalDays = max(currentDays.union(candidateDays).count, 1)
        let scheduleScore = Int(Double(sharedDays) / Double(totalDays) * 100)

        // Play style: exact match = 100, both nil = 60 (unknown), mismatch = 30
        let styleScore: Int
        if let cs = current.playStyle, let ps = candidate.playStyle {
            styleScore = cs == ps ? 100 : 30
        } else {
            styleScore = 60
        }

        // Location: based on distance in degrees (rough proxy)
        let locationScore: Int
        if let cl = current.location, let pl = candidate.location {
            let dLat = cl.latitude - pl.latitude
            let dLon = cl.longitude - pl.longitude
            let dist = sqrt(dLat * dLat + dLon * dLon) // degrees, ~69 mi/degree
            let miles = dist * 69
            locationScore = max(0, 100 - Int(miles * 4))
        } else {
            locationScore = 50
        }

        let overall = Int(
            Double(skillScore) * 0.40 +
            Double(scheduleScore) * 0.30 +
            Double(styleScore) * 0.20 +
            Double(locationScore) * 0.10
        )

        return CompatibilityScore(
            overall: overall,
            skillMatch: skillScore,
            scheduleMatch: scheduleScore,
            playStyle: styleScore,
            location: locationScore
        )
    }
}

// MARK: - Compatibility Badge (inline)

struct CompatibilityScoreBadge: View {
    let score: CompatibilityScore
    @State private var showDetail = false

    private var badgeColor: Color {
        if score.overall >= 80 { return Color.dinkrGreen }
        if score.overall >= 60 { return Color.dinkrAmber }
        return Color.dinkrSky
    }

    var body: some View {
        Button {
            HapticManager.selection()
            showDetail = true
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 9, weight: .bold))
                Text("\(score.overall)%")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(badgeColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.13))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(badgeColor.opacity(0.3), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            CompatibilityScoreDetailSheet(score: score)
        }
    }
}

// MARK: - Compatibility Detail Sheet

struct CompatibilityScoreDetailSheet: View {
    let score: CompatibilityScore
    @Environment(\.dismiss) private var dismiss

    private var overallColor: Color {
        if score.overall >= 80 { return Color.dinkrGreen }
        if score.overall >= 60 { return Color.dinkrAmber }
        return Color.dinkrSky
    }

    private var explanationText: String {
        if score.overall >= 80 {
            return "You and this player are a great match! Similar skill level, overlapping availability, and compatible play styles make for a strong pairing."
        } else if score.overall >= 60 {
            return "There's solid potential here. A few differences in schedule or play style exist, but you'd likely enjoy playing together with some flexibility."
        } else {
            return "You and this player differ in a few key areas — skill level, schedule, or location — but every game is a chance to grow."
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    // Overall score ring
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(overallColor.opacity(0.15), lineWidth: 10)
                                .frame(width: 110, height: 110)
                            Circle()
                                .trim(from: 0, to: CGFloat(score.overall) / 100)
                                .stroke(overallColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .frame(width: 110, height: 110)
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: score.overall)
                            VStack(spacing: 0) {
                                Text("\(score.overall)%")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(overallColor)
                                Text("Match")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text("Compatibility Breakdown")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    // Category bars
                    VStack(spacing: 16) {
                        CategoryBar(
                            label: "Skill Match",
                            icon: "chart.bar.fill",
                            score: score.skillMatch,
                            weight: "40%",
                            color: Color.dinkrGreen
                        )
                        CategoryBar(
                            label: "Schedule Match",
                            icon: "calendar",
                            score: score.scheduleMatch,
                            weight: "30%",
                            color: Color.dinkrSky
                        )
                        CategoryBar(
                            label: "Play Style",
                            icon: "figure.mind.and.body",
                            score: score.playStyle,
                            weight: "20%",
                            color: Color.dinkrAmber
                        )
                        CategoryBar(
                            label: "Location",
                            icon: "location.fill",
                            score: score.location,
                            weight: "10%",
                            color: Color.dinkrCoral
                        )
                    }
                    .padding(.horizontal, 20)

                    // Explanation card
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Why this score?", systemImage: "info.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrNavy)

                        Text(explanationText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.dinkrNavy.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)

                    // Methodology note
                    Text("Score is calculated from skill gap, shared availability days, play style alignment, and distance.")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 24)
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Match Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Category Bar

private struct CategoryBar: View {
    let label: String
    let icon: String
    let score: Int
    let weight: String
    let color: Color

    @State private var animated = false

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(color)
                        .frame(width: 16)
                    Text(label)
                        .font(.subheadline.weight(.medium))
                }
                Spacer()
                HStack(spacing: 6) {
                    Text("(weight: \(weight))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(score)%")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(color)
                        .frame(minWidth: 38, alignment: .trailing)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.12))
                        .frame(height: 7)
                    Capsule()
                        .fill(color)
                        .frame(width: animated ? geo.size.width * CGFloat(score) / 100 : 0, height: 7)
                        .animation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1), value: animated)
                }
            }
            .frame(height: 7)
        }
        .onAppear { animated = true }
    }
}

// MARK: - Preview

#Preview("Badge") {
    let score = CompatibilityScore.compute(current: .mockCurrentUser, candidate: User.mockPlayers[0])
    return CompatibilityScoreBadge(score: score)
        .padding()
}

#Preview("Detail Sheet") {
    let score = CompatibilityScore.compute(current: .mockCurrentUser, candidate: User.mockPlayers[0])
    return CompatibilityScoreDetailSheet(score: score)
}

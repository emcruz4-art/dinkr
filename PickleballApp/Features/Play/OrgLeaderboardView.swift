import SwiftUI

// MARK: - Data Model

struct OrgLeaderboardEntry: Identifiable {
    let id: String
    let rank: Int
    let displayName: String
    let username: String
    let department: String
    let gamesPlayed: Int
    let wins: Int
    let duprRating: Double?
    let reliabilityScore: Double
    let wellnessPoints: Int
}

// MARK: - OrgLeaderboardView

struct OrgLeaderboardView: View {

    // Sort mode: 0 = DUPR Rating, 1 = Wellness Points
    @State private var sortMode = 0
    @State private var selectedDepartment: String = "All"

    // MARK: Mock data — 8 players from Acme Corp
    private let allEntries: [OrgLeaderboardEntry] = [
        OrgLeaderboardEntry(id: "user_001", rank: 0, displayName: "Alex Rivera",    username: "pickleking",         department: "Engineering",  gamesPlayed: 142, wins: 89,  duprRating: 4.69, reliabilityScore: 4.8, wellnessPoints: 1240),
        OrgLeaderboardEntry(id: "user_002", rank: 0, displayName: "Maria Chen",     username: "maria_plays",        department: "Engineering",  gamesPlayed: 203, wins: 148, duprRating: 3.87, reliabilityScore: 4.9, wellnessPoints: 1580),
        OrgLeaderboardEntry(id: "user_003", rank: 0, displayName: "Jordan Smith",   username: "jordan_4point0",     department: "Sales",        gamesPlayed: 87,  wins: 51,  duprRating: 4.21, reliabilityScore: 4.5, wellnessPoints: 960),
        OrgLeaderboardEntry(id: "user_004", rank: 0, displayName: "Sarah Johnson",  username: "sarahj_pb",          department: "Marketing",    gamesPlayed: 176, wins: 102, duprRating: nil,  reliabilityScore: 5.0, wellnessPoints: 1420),
        OrgLeaderboardEntry(id: "user_005", rank: 0, displayName: "Chris Park",     username: "chrisp_dink",        department: "Engineering",  gamesPlayed: 312, wins: 198, duprRating: 4.05, reliabilityScore: 4.7, wellnessPoints: 2100),
        OrgLeaderboardEntry(id: "user_006", rank: 0, displayName: "Taylor Kim",     username: "tkim_pickles",       department: "Sales",        gamesPlayed: 34,  wins: 18,  duprRating: 2.98, reliabilityScore: 4.3, wellnessPoints: 420),
        OrgLeaderboardEntry(id: "user_007", rank: 0, displayName: "Jamie Lee",      username: "jamiepb",            department: "Design",       gamesPlayed: 445, wins: 301, duprRating: 4.52, reliabilityScore: 4.6, wellnessPoints: 1875),
        OrgLeaderboardEntry(id: "user_008", rank: 0, displayName: "Riley Torres",   username: "riley_dinkmaster",   department: "Marketing",    gamesPlayed: 121, wins: 73,  duprRating: 3.55, reliabilityScore: 4.8, wellnessPoints: 790),
    ]

    private var uniqueDepartments: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for entry in allEntries {
            if !seen.contains(entry.department) {
                seen.insert(entry.department)
                result.append(entry.department)
            }
        }
        return result.sorted()
    }

    private var filtered: [OrgLeaderboardEntry] {
        let base = selectedDepartment == "All"
            ? allEntries
            : allEntries.filter { $0.department == selectedDepartment }

        let sorted: [OrgLeaderboardEntry]
        if sortMode == 0 {
            sorted = base.sorted {
                let lhs = $0.duprRating ?? 0
                let rhs = $1.duprRating ?? 0
                return lhs > rhs
            }
        } else {
            sorted = base.sorted { $0.wellnessPoints > $1.wellnessPoints }
        }

        return sorted.enumerated().map { index, entry in
            OrgLeaderboardEntry(
                id: entry.id,
                rank: index + 1,
                displayName: entry.displayName,
                username: entry.username,
                department: entry.department,
                gamesPlayed: entry.gamesPlayed,
                wins: entry.wins,
                duprRating: entry.duprRating,
                reliabilityScore: entry.reliabilityScore,
                wellnessPoints: entry.wellnessPoints
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── Company header banner ──────────────────────────────────
                ZStack {
                    LinearGradient(
                        colors: [Color.dinkrNavy, Color.dinkrGreen],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "building.2.fill")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.9))
                            Text("Acme Corp")
                                .font(.title2.weight(.heavy))
                                .foregroundStyle(.white)
                        }
                        Text("Internal Leaderboard")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .padding(.vertical, 20)
                }
                .clipShape(RoundedRectangle(cornerRadius: 0))

                VStack(spacing: 16) {

                    // ── Sort toggle ────────────────────────────────────────
                    Picker("Sort", selection: $sortMode) {
                        Text("DUPR Rating").tag(0)
                        Text("Wellness Points").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 14)

                    // ── Department filter chips ────────────────────────────
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            DeptChip(label: "All", isSelected: selectedDepartment == "All") {
                                selectedDepartment = "All"
                            }
                            ForEach(uniqueDepartments, id: \.self) { dept in
                                DeptChip(label: dept, isSelected: selectedDepartment == dept) {
                                    selectedDepartment = dept
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // ── Leaderboard list ───────────────────────────────────
                    VStack(spacing: 0) {
                        ForEach(filtered) { entry in
                            OrgLeaderboardRow(entry: entry, isCurrentUser: entry.id == "user_001", sortMode: sortMode)
                            if entry.id != filtered.last?.id {
                                Divider().padding(.horizontal)
                            }
                        }
                    }
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Company Rankings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Department Filter Chip

private struct DeptChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? .white : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.dinkrGreen : Color.cardBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.clear : Color.secondary.opacity(0.25),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Org Leaderboard Row

struct OrgLeaderboardRow: View {
    let entry: OrgLeaderboardEntry
    let isCurrentUser: Bool
    let sortMode: Int

    private var rankColor: Color {
        switch entry.rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0)   // gold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.78) // silver
        case 3: return Color(red: 0.80, green: 0.52, blue: 0.25) // bronze
        default: return Color.secondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {

            // Rank indicator
            ZStack {
                if entry.rank <= 3 {
                    ZStack {
                        Circle()
                            .fill(rankColor.opacity(0.18))
                            .frame(width: 30, height: 30)
                        Text("\(entry.rank)")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(rankColor)
                    }
                } else {
                    Text("#\(entry.rank)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, alignment: .leading)
                }
            }
            .frame(width: 30)

            // Avatar initials circle
            ZStack {
                Circle()
                    .fill(isCurrentUser ? Color.dinkrGreen.opacity(0.15) : Color.secondary.opacity(0.1))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Circle()
                            .stroke(isCurrentUser ? Color.dinkrGreen : Color.clear, lineWidth: 1.5)
                    )
                Text(entry.displayName.prefix(1).uppercased())
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isCurrentUser ? Color.dinkrGreen : .secondary)
            }

            // Name + department + username
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(entry.displayName)
                        .font(.subheadline.weight(isCurrentUser ? .bold : .regular))
                    if isCurrentUser {
                        Text("YOU")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.dinkrGreen)
                            .clipShape(Capsule())
                    }
                }

                // Department badge
                HStack(spacing: 3) {
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(Color.dinkrSky)
                    Text(entry.department)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.dinkrSky)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.dinkrSky.opacity(0.1))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color.dinkrSky.opacity(0.3), lineWidth: 0.5))

                Text("@\(entry.username)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Right-side metric
            VStack(alignment: .trailing, spacing: 4) {
                if sortMode == 0 {
                    // DUPR rating
                    if let dupr = entry.duprRating {
                        HStack(spacing: 3) {
                            Text("DUPR")
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(Color.dinkrAmber)
                            Text(String(format: "%.2f", dupr))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(isCurrentUser ? Color.dinkrAmber : Color.primary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.dinkrAmber.opacity(isCurrentUser ? 0.18 : 0.08))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.dinkrAmber.opacity(0.3), lineWidth: 0.5))
                    } else {
                        Text("No DUPR")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text("\(entry.wins)W")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    // Wellness points
                    HStack(spacing: 3) {
                        Text("⚡")
                            .font(.caption)
                        Text("\(entry.wellnessPoints)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.dinkrAmber)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.dinkrAmber.opacity(0.1))
                    .clipShape(Capsule())
                    Text("\(entry.wins)W")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isCurrentUser ? Color.dinkrGreen.opacity(0.04) : Color.clear)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OrgLeaderboardView()
    }
}

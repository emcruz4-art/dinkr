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

    var winRate: Double {
        gamesPlayed > 0 ? Double(wins) / Double(gamesPlayed) : 0.0
    }
}

// MARK: - OrgLeaderboardView

struct OrgLeaderboardView: View {

    // Sort mode: 0 = Games Played, 1 = Win Rate, 2 = Wellness Points
    @State private var sortMode = 0
    @State private var selectedDepartment: String = "All"
    @State private var showTournamentSheet = false

    private let companyName = "Acme Corp"
    private let currentUserId = "user_001"

    // MARK: Mock data — Acme Corp employees
    private let allEntries: [OrgLeaderboardEntry] = [
        OrgLeaderboardEntry(id: "user_001", rank: 0, displayName: "Alex Rivera",    username: "pickleking",         department: "Engineering",  gamesPlayed: 142, wins: 89,  duprRating: 4.69, reliabilityScore: 4.8, wellnessPoints: 1240),
        OrgLeaderboardEntry(id: "user_002", rank: 0, displayName: "Maria Chen",     username: "maria_plays",        department: "Engineering",  gamesPlayed: 203, wins: 148, duprRating: 3.87, reliabilityScore: 4.9, wellnessPoints: 1580),
        OrgLeaderboardEntry(id: "user_003", rank: 0, displayName: "Jordan Smith",   username: "jordan_4point0",     department: "Sales",        gamesPlayed: 87,  wins: 51,  duprRating: 4.21, reliabilityScore: 4.5, wellnessPoints: 960),
        OrgLeaderboardEntry(id: "user_004", rank: 0, displayName: "Sarah Johnson",  username: "sarahj_pb",          department: "Marketing",    gamesPlayed: 176, wins: 102, duprRating: nil,  reliabilityScore: 5.0, wellnessPoints: 1420),
        OrgLeaderboardEntry(id: "user_005", rank: 0, displayName: "Chris Park",     username: "chrisp_dink",        department: "Engineering",  gamesPlayed: 312, wins: 198, duprRating: 4.05, reliabilityScore: 4.7, wellnessPoints: 2100),
        OrgLeaderboardEntry(id: "user_006", rank: 0, displayName: "Taylor Kim",     username: "tkim_pickles",       department: "Sales",        gamesPlayed: 34,  wins: 18,  duprRating: 2.98, reliabilityScore: 4.3, wellnessPoints: 420),
        OrgLeaderboardEntry(id: "user_007", rank: 0, displayName: "Jamie Lee",      username: "jamiepb",            department: "HR",           gamesPlayed: 445, wins: 301, duprRating: 4.52, reliabilityScore: 4.6, wellnessPoints: 1875),
        OrgLeaderboardEntry(id: "user_008", rank: 0, displayName: "Riley Torres",   username: "riley_dinkmaster",   department: "Marketing",    gamesPlayed: 121, wins: 73,  duprRating: 3.55, reliabilityScore: 4.8, wellnessPoints: 790),
        OrgLeaderboardEntry(id: "user_009", rank: 0, displayName: "Drew Patel",     username: "drew_dink",          department: "Executive",    gamesPlayed: 58,  wins: 34,  duprRating: 3.12, reliabilityScore: 4.2, wellnessPoints: 610),
        OrgLeaderboardEntry(id: "user_010", rank: 0, displayName: "Casey Nguyen",   username: "casey_pb",           department: "HR",           gamesPlayed: 99,  wins: 61,  duprRating: 3.42, reliabilityScore: 4.6, wellnessPoints: 870),
        OrgLeaderboardEntry(id: "user_011", rank: 0, displayName: "Morgan Davis",   username: "morganplays",        department: "Sales",        gamesPlayed: 72,  wins: 40,  duprRating: 2.85, reliabilityScore: 4.0, wellnessPoints: 540),
        OrgLeaderboardEntry(id: "user_012", rank: 0, displayName: "Sam Ortega",     username: "sam_ortega",         department: "Marketing",    gamesPlayed: 44,  wins: 21,  duprRating: 2.60, reliabilityScore: 3.9, wellnessPoints: 310),
    ]

    // Fixed department list to always show all chips
    private let departments = ["All", "Engineering", "Sales", "Marketing", "HR", "Executive"]

    private var filtered: [OrgLeaderboardEntry] {
        let base = selectedDepartment == "All"
            ? allEntries
            : allEntries.filter { $0.department == selectedDepartment }

        let sorted: [OrgLeaderboardEntry]
        switch sortMode {
        case 0:
            sorted = base.sorted { $0.gamesPlayed > $1.gamesPlayed }
        case 1:
            sorted = base.sorted { $0.winRate > $1.winRate }
        default:
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

    private var currentUserEntry: OrgLeaderboardEntry? {
        filtered.first { $0.id == currentUserId }
    }

    private var mostActiveDepartment: String {
        let deptGames = Dictionary(grouping: allEntries, by: { $0.department })
            .mapValues { $0.reduce(0) { $0 + $1.gamesPlayed } }
        return deptGames.max(by: { $0.value < $1.value })?.key ?? "Engineering"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── Company header banner ──────────────────────────────────
                companyHeader

                VStack(spacing: 16) {

                    // ── Weekly challenge card ──────────────────────────────
                    weeklyChallengeCard
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                    // ── Company stats ──────────────────────────────────────
                    companyStatsRow
                        .padding(.horizontal, 16)

                    // ── Sort toggle ────────────────────────────────────────
                    Picker("Sort", selection: $sortMode) {
                        Text("Games Played").tag(0)
                        Text("Win Rate").tag(1)
                        Text("Wellness Pts").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // ── Department filter chips ────────────────────────────
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(departments, id: \.self) { dept in
                                OrgDeptChip(label: dept, isSelected: selectedDepartment == dept) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        selectedDepartment = dept
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // ── Your rank callout ──────────────────────────────────
                    if let userEntry = currentUserEntry {
                        yourRankCard(entry: userEntry)
                            .padding(.horizontal, 16)
                    }

                    // ── Leaderboard list ───────────────────────────────────
                    VStack(spacing: 0) {
                        ForEach(filtered) { entry in
                            OrgLeaderboardRow(entry: entry, isCurrentUser: entry.id == currentUserId, sortMode: sortMode)
                            if entry.id != filtered.last?.id {
                                Divider().padding(.horizontal)
                            }
                        }
                    }
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // ── Organize tournament button ─────────────────────────
                    Button {
                        showTournamentSheet = true
                        HapticManager.success()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "trophy.circle.fill")
                                .font(.title3)
                            Text("Organize a Company Tournament")
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                colors: [Color.dinkrGreen, Color.dinkrNavy],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Company Rankings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTournamentSheet) {
            OrganizeTournamentSheet(companyName: companyName)
        }
    }

    // MARK: - Company Header

    private var companyHeader: some View {
        ZStack {
            LinearGradient(
                colors: [Color.dinkrNavy, Color.dinkrGreen],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 10) {
                // Logo placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.18))
                        .frame(width: 56, height: 56)
                    Text("AC")
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(.white)
                }

                HStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(companyName)
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(.white)
                }

                Text("Internal Pickleball Leaderboard")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(.vertical, 24)
        }
    }

    // MARK: - Weekly Challenge Card

    private var weeklyChallengeCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.dinkrAmber.opacity(0.18))
                    .frame(width: 44, height: 44)
                Text("🍕")
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("WEEKLY CHALLENGE")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(Color.dinkrAmber)
                    Text("4 days left")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.dinkrAmber.opacity(0.8))
                        .clipShape(Capsule())
                }
                Text("Most games played wins lunch")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Chris Park leads with 312 games")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.dinkrAmber.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Company Stats Row

    private var companyStatsRow: some View {
        HStack(spacing: 12) {
            OrgStatTile(
                icon: "person.3.fill",
                iconColor: Color.dinkrSky,
                value: "47",
                label: "Employees Playing"
            )
            OrgStatTile(
                icon: "flame.fill",
                iconColor: Color.dinkrCoral,
                value: mostActiveDepartment,
                label: "Most Active Dept"
            )
            OrgStatTile(
                icon: "gamecontroller.fill",
                iconColor: Color.dinkrGreen,
                value: "\(allEntries.reduce(0) { $0 + $1.gamesPlayed })",
                label: "Total Games"
            )
        }
    }

    // MARK: - Your Rank Card

    private func yourRankCard(entry: OrgLeaderboardEntry) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.18))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle().stroke(Color.dinkrGreen, lineWidth: 1.5)
                    )
                Text(entry.displayName.prefix(1).uppercased())
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Color.dinkrGreen)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Your Rank in \(companyName)")
                        .font(.subheadline.weight(.bold))
                    Text("YOU")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.dinkrGreen)
                        .clipShape(Capsule())
                }
                HStack(spacing: 6) {
                    Label(entry.department, systemImage: "briefcase.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.dinkrSky)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text("\(entry.gamesPlayed) games · \(Int(entry.winRate * 100))% win rate")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("#\(entry.rank)")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(Color.dinkrGreen)
                Text("of \(filtered.count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color.dinkrGreen.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.dinkrGreen.opacity(0.45), lineWidth: 1.5)
        )
    }
}

// MARK: - Department Filter Chip

private struct OrgDeptChip: View {
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

// MARK: - Org Stat Tile

private struct OrgStatTile: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor)
            Text(value)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
        )
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

    private var deptColor: Color {
        switch entry.department {
        case "Engineering": return Color.dinkrSky
        case "Sales":       return Color.dinkrGreen
        case "Marketing":   return Color.dinkrCoral
        case "HR":          return Color.dinkrAmber
        case "Executive":   return Color.dinkrNavy
        default:            return Color.secondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {

            // Rank indicator
            ZStack {
                if entry.rank <= 3 {
                    Circle()
                        .fill(rankColor.opacity(0.18))
                        .frame(width: 30, height: 30)
                    Text("\(entry.rank)")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(rankColor)
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
                        .lineLimit(1)
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
                        .foregroundStyle(deptColor)
                    Text(entry.department)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(deptColor)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(deptColor.opacity(0.1))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(deptColor.opacity(0.3), lineWidth: 0.5))
            }

            Spacer()

            // Right-side metric
            VStack(alignment: .trailing, spacing: 4) {
                switch sortMode {
                case 0:
                    // Games played
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(entry.gamesPlayed)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(isCurrentUser ? Color.dinkrSky : Color.primary)
                        Text("games")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                case 1:
                    // Win rate
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(entry.winRate * 100))%")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(isCurrentUser ? Color.dinkrGreen : Color.primary)
                        Text("\(entry.wins)W")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                default:
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
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isCurrentUser ? Color.dinkrGreen.opacity(0.04) : Color.clear)
    }
}

// MARK: - Organize Tournament Sheet

struct OrganizeTournamentSheet: View {
    @Environment(\.dismiss) private var dismiss
    let companyName: String

    @State private var tournamentName = ""
    @State private var selectedFormat = 0
    @State private var selectedDate = Date().addingTimeInterval(60 * 60 * 24 * 7)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.dinkrGreen.opacity(0.2), Color.dinkrNavy.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                            Image(systemName: "trophy.fill")
                                .font(.title3)
                                .foregroundStyle(Color.dinkrGreen)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(companyName) Tournament")
                                .font(.headline.weight(.bold))
                            Text("Invite colleagues to compete")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Tournament Details") {
                    TextField("Tournament Name", text: $tournamentName)
                        .autocorrectionDisabled()

                    Picker("Format", selection: $selectedFormat) {
                        Text("Singles").tag(0)
                        Text("Doubles").tag(1)
                        Text("Mixed Doubles").tag(2)
                        Text("Round Robin").tag(3)
                    }

                    DatePicker("Date", selection: $selectedDate, displayedComponents: [.date])
                        .tint(Color.dinkrGreen)
                }

                Section("What happens next") {
                    ForEach([
                        ("envelope.badge", Color.dinkrSky, "Invitations sent to all \(companyName) employees"),
                        ("calendar.badge.plus", Color.dinkrGreen, "RSVP tracking in the Events tab"),
                        ("trophy.fill", Color.dinkrAmber, "Bracket auto-generated when registration closes"),
                    ], id: \.0) { icon, color, text in
                        HStack(spacing: 12) {
                            Image(systemName: icon)
                                .foregroundStyle(color)
                                .frame(width: 20)
                            Text(text)
                                .font(.callout)
                                .foregroundStyle(.primary)
                        }
                    }
                }

                Section {
                    Button {
                        HapticManager.success()
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Create Tournament")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [Color.dinkrGreen, Color.dinkrNavy],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .padding(.vertical, 2)
                    )
                }
            }
            .navigationTitle("New Tournament")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OrgLeaderboardView()
    }
}

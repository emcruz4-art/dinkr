import SwiftUI

// MARK: - Models

enum ChallengeFormat: String, CaseIterable, Codable {
    case singles = "Singles"
    case doubles = "Doubles"
}

enum ChallengeStatus: String, Codable {
    case pending   = "Pending"
    case accepted  = "Accepted"
    case declined  = "Declined"
    case completed = "Completed"
}

struct Challenge: Identifiable, Codable {
    var id: String
    var challengerId: String
    var challengerName: String
    var challengeeId: String
    var challengeeName: String
    var format: ChallengeFormat
    var skillMin: Double
    var skillMax: Double
    var proposedDate: Date
    var message: String
    var status: ChallengeStatus
    var createdAt: Date
}

extension Challenge {
    static let mockChallenges: [Challenge] = {
        let now = Date()
        let cal = Calendar.current
        return [
            Challenge(
                id: "ch_001",
                challengerId: "user_003",
                challengerName: "Jordan Smith",
                challengeeId: "user_001",
                challengeeName: "Alex Rivera",
                format: .singles,
                skillMin: 3.5,
                skillMax: 4.0,
                proposedDate: cal.date(byAdding: .day, value: 2, to: now) ?? now,
                message: "Let's run some singles — I'll bring the Selkirk.",
                status: .pending,
                createdAt: cal.date(byAdding: .hour, value: -3, to: now) ?? now
            ),
            Challenge(
                id: "ch_002",
                challengerId: "user_007",
                challengerName: "Jamie Lee",
                challengeeId: "user_001",
                challengeeName: "Alex Rivera",
                format: .doubles,
                skillMin: 4.0,
                skillMax: 4.5,
                proposedDate: cal.date(byAdding: .day, value: 5, to: now) ?? now,
                message: "Need a solid partner for doubles practice. You in?",
                status: .pending,
                createdAt: cal.date(byAdding: .hour, value: -1, to: now) ?? now
            ),
            Challenge(
                id: "ch_003",
                challengerId: "user_001",
                challengerName: "Alex Rivera",
                challengeeId: "user_002",
                challengeeName: "Maria Chen",
                format: .singles,
                skillMin: 3.5,
                skillMax: 3.5,
                proposedDate: cal.date(byAdding: .day, value: 3, to: now) ?? now,
                message: "Rematch! Last time was too close to call.",
                status: .accepted,
                createdAt: cal.date(byAdding: .day, value: -1, to: now) ?? now
            ),
            Challenge(
                id: "ch_004",
                challengerId: "user_001",
                challengerName: "Alex Rivera",
                challengeeId: "user_005",
                challengeeName: "Chris Park",
                format: .doubles,
                skillMin: 3.5,
                skillMax: 4.0,
                proposedDate: cal.date(byAdding: .day, value: 7, to: now) ?? now,
                message: "Heard you're the kitchen king. Let's test that.",
                status: .pending,
                createdAt: cal.date(byAdding: .hour, value: -8, to: now) ?? now
            ),
            Challenge(
                id: "ch_005",
                challengerId: "user_001",
                challengerName: "Alex Rivera",
                challengeeId: "user_009",
                challengeeName: "Riley Torres",
                format: .singles,
                skillMin: 3.5,
                skillMax: 3.5,
                proposedDate: cal.date(byAdding: .day, value: -2, to: now) ?? now,
                message: "",
                status: .declined,
                createdAt: cal.date(byAdding: .day, value: -4, to: now) ?? now
            )
        ]
    }()
}

// MARK: - ViewModel

@MainActor
class ChallengeViewModel: ObservableObject {
    @Published var challenges: [Challenge] = Challenge.mockChallenges
    @Published var showSendSheet: Bool = false

    var incoming: [Challenge] {
        challenges.filter { $0.challengeeId == "user_001" }
    }

    var sent: [Challenge] {
        challenges.filter { $0.challengerId == "user_001" }
    }

    func accept(_ challenge: Challenge) {
        if let idx = challenges.firstIndex(where: { $0.id == challenge.id }) {
            challenges[idx].status = .accepted
        }
    }

    func decline(_ challenge: Challenge) {
        if let idx = challenges.firstIndex(where: { $0.id == challenge.id }) {
            challenges[idx].status = .declined
        }
    }

    func sendChallenge(
        opponentId: String,
        opponentName: String,
        format: ChallengeFormat,
        proposedDate: Date,
        message: String
    ) {
        let new = Challenge(
            id: UUID().uuidString,
            challengerId: "user_001",
            challengerName: "Alex Rivera",
            challengeeId: opponentId,
            challengeeName: opponentName,
            format: format,
            skillMin: 3.5,
            skillMax: 4.0,
            proposedDate: proposedDate,
            message: message,
            status: .pending,
            createdAt: Date()
        )
        challenges.append(new)
        showSendSheet = false
    }
}

// MARK: - Challenge Row

private struct ChallengeRow: View {
    let challenge: Challenge
    let isIncoming: Bool
    let onAccept: (() -> Void)?
    let onDecline: (() -> Void)?

    private var opponentName: String {
        isIncoming ? challenge.challengerName : challenge.challengeeName
    }

    private var opponentInitial: String {
        String(opponentName.prefix(1)).uppercased()
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: challenge.proposedDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                avatarCircle
                infoStack
                Spacer()
                statusChip(challenge.status)
            }

            if !challenge.message.isEmpty {
                Text("\"\(challenge.message)\"")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .lineLimit(2)
                    .padding(.leading, 48)
            }

            if isIncoming && challenge.status == .pending {
                HStack(spacing: 10) {
                    Spacer()
                    Button {
                        onDecline?()
                    } label: {
                        Text("Decline")
                            .font(.caption.bold())
                            .foregroundColor(Color.dinkrCoral)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.dinkrCoral, lineWidth: 1.5)
                            )
                    }

                    Button {
                        onAccept?()
                    } label: {
                        Text("Accept")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(Color.dinkrGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var avatarCircle: some View {
        ZStack {
            Circle()
                .fill(isIncoming ? Color.dinkrGreen.opacity(0.2) : Color.dinkrSky.opacity(0.2))
                .frame(width: 40, height: 40)
            Text(opponentInitial)
                .font(.headline.bold())
                .foregroundColor(isIncoming ? Color.dinkrGreen : Color.dinkrSky)
        }
    }

    private var infoStack: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(opponentName)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                formatBadge
            }
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var formatBadge: some View {
        Text(challenge.format.rawValue)
            .font(.caption2.bold())
            .foregroundColor(challenge.format == .singles ? Color.dinkrNavy : Color.dinkrSky)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                challenge.format == .singles
                    ? Color.dinkrNavy.opacity(0.12)
                    : Color.dinkrSky.opacity(0.15)
            )
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func statusChip(_ status: ChallengeStatus) -> some View {
        let config = chipConfig(for: status)
        Text(status.rawValue)
            .font(.caption2.bold())
            .foregroundColor(config.text)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(config.bg)
            .clipShape(Capsule())
    }

    private func chipConfig(for status: ChallengeStatus) -> (text: Color, bg: Color) {
        switch status {
        case .pending:   return (Color.dinkrAmber, Color.dinkrAmber.opacity(0.18))
        case .accepted:  return (Color.dinkrGreen, Color.dinkrGreen.opacity(0.15))
        case .declined:  return (Color.dinkrCoral, Color.dinkrCoral.opacity(0.15))
        case .completed: return (Color.dinkrSky, Color.dinkrSky.opacity(0.15))
        }
    }
}

// MARK: - Empty State

private struct ChallengeEmptyView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(.secondary.opacity(0.5))
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.secondary)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Send Challenge Sheet

struct SendChallengeSheet: View {
    @ObservedObject var vm: ChallengeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedOpponent: User? = nil
    @State private var format: ChallengeFormat = .singles
    @State private var proposedDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @State private var message: String = ""
    @State private var showOpponentPicker = false

    private let players = User.mockPlayers.filter { $0.id != "user_001" }

    var body: some View {
        NavigationStack {
            Form {
                Section("Opponent") {
                    if let opponent = selectedOpponent {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.dinkrGreen.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                Text(String(opponent.displayName.prefix(1)))
                                    .font(.headline.bold())
                                    .foregroundColor(Color.dinkrGreen)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(opponent.displayName)
                                    .font(.subheadline.bold())
                                Text(opponent.skillLevel.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Change") { showOpponentPicker = true }
                                .font(.caption)
                                .foregroundColor(Color.dinkrGreen)
                        }
                    } else {
                        Button {
                            showOpponentPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                    .foregroundColor(Color.dinkrGreen)
                                Text("Select Opponent")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }

                Section("Format") {
                    Picker("Format", selection: $format) {
                        ForEach(ChallengeFormat.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                }

                Section("Proposed Date") {
                    DatePicker("Date", selection: $proposedDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }

                Section("Trash Talk (Optional)") {
                    TextField("Say something bold...", text: $message, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                Section {
                    Button {
                        guard let opponent = selectedOpponent else { return }
                        vm.sendChallenge(
                            opponentId: opponent.id,
                            opponentName: opponent.displayName,
                            format: format,
                            proposedDate: proposedDate,
                            message: message
                        )
                    } label: {
                        HStack {
                            Spacer()
                            Label("Send Challenge", systemImage: "paperplane.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(selectedOpponent == nil ? Color.dinkrGreen.opacity(0.4) : Color.dinkrGreen)
                    .disabled(selectedOpponent == nil)
                }
            }
            .navigationTitle("New Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showOpponentPicker) {
                opponentPickerSheet
            }
        }
    }

    private var opponentPickerSheet: some View {
        NavigationStack {
            List(players) { player in
                Button {
                    selectedOpponent = player
                    showOpponentPicker = false
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.dinkrSky.opacity(0.2))
                                .frame(width: 38, height: 38)
                            Text(String(player.displayName.prefix(1)))
                                .font(.headline.bold())
                                .foregroundColor(Color.dinkrSky)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(player.displayName)
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            HStack(spacing: 4) {
                                Text(player.skillLevel.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("·")
                                    .foregroundColor(.secondary)
                                Text(player.city)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if selectedOpponent?.id == player.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.dinkrGreen)
                        }
                    }
                }
            }
            .navigationTitle("Pick Opponent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showOpponentPicker = false }
                }
            }
        }
    }
}

// MARK: - Main View

struct ChallengeView: View {
    @StateObject private var vm = ChallengeViewModel()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
                    incomingSection
                    sentSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .padding(.bottom, 80)
            }
            .background(Color(UIColor.systemGroupedBackground))

            floatingAddButton
        }
        .navigationTitle("Challenges")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $vm.showSendSheet) {
            SendChallengeSheet(vm: vm)
        }
    }

    // MARK: Incoming Section

    private var incomingSection: some View {
        Section {
            if vm.incoming.isEmpty {
                ChallengeEmptyView(
                    icon: "tray",
                    title: "No Incoming Challenges",
                    subtitle: "When someone challenges you, it'll appear here."
                )
            } else {
                ForEach(vm.incoming) { challenge in
                    ChallengeRow(
                        challenge: challenge,
                        isIncoming: true,
                        onAccept: { vm.accept(challenge) },
                        onDecline: { vm.decline(challenge) }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
        } header: {
            sectionHeader(
                title: "Incoming",
                icon: "arrow.down.circle.fill",
                color: Color.dinkrGreen,
                count: vm.incoming.count
            )
        }
    }

    // MARK: Sent Section

    private var sentSection: some View {
        Section {
            if vm.sent.isEmpty {
                ChallengeEmptyView(
                    icon: "paperplane",
                    title: "No Sent Challenges",
                    subtitle: "Tap + to challenge a player."
                )
            } else {
                ForEach(vm.sent) { challenge in
                    ChallengeRow(
                        challenge: challenge,
                        isIncoming: false,
                        onAccept: nil,
                        onDecline: nil
                    )
                }
            }
        } header: {
            sectionHeader(
                title: "Sent",
                icon: "paperplane.fill",
                color: Color.dinkrSky,
                count: vm.sent.count
            )
        }
    }

    // MARK: Section Header

    private func sectionHeader(title: String, icon: String, color: Color, count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundColor(color)
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            Spacer()
            if count > 0 {
                Text("\(count)")
                    .font(.caption2.bold())
                    .foregroundColor(color)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(color.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: Floating Button

    private var floatingAddButton: some View {
        Button {
            vm.showSendSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.dinkrGreen)
                .clipShape(Circle())
                .shadow(color: Color.dinkrGreen.opacity(0.4), radius: 10, x: 0, y: 4)
        }
        .padding(.trailing, 24)
        .padding(.bottom, 28)
    }
}

#Preview {
    NavigationStack {
        ChallengeView()
    }
}

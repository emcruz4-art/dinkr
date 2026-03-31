import SwiftUI
import Observation

// MARK: - HostGameViewModel

@Observable
final class HostGameViewModel {
    // Step 1 — Format & Details
    var selectedFormat: GameFormat = .doubles
    var minSkill: SkillLevel = .intermediate30
    var maxSkill: SkillLevel = .advanced40
    var totalSpots: Int = 4
    var isPaid: Bool = false
    var feeText: String = ""

    // Step 2 — Time & Location
    var selectedDate: Date = {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.day = (components.day ?? 1) + 1
        components.hour = 10
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components) ?? Date().addingTimeInterval(86400)
    }()
    var selectedCourt: CourtVenue? = nil
    var courtSearchText: String = ""
    var selectedDuration: GameDuration = .twoHours
    var isRecurring: Bool = false

    // Step 3 — Visibility & Notes
    var visibility: GameVisibility = .public_
    var notes: String = ""
    var invitedPlayerIds: [String] = []
    var inviteSearchText: String = ""
    var inviteAllGroupMembers: Bool = false
    var selectedGroupId: String? = nil

    // Status
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var didPost: Bool = false

    var canSubmit: Bool {
        selectedCourt != nil && minSkill <= maxSkill
    }

    var parsedFee: Double? {
        guard isPaid else { return nil }
        return Double(feeText)
    }

    var filteredCourts: [CourtVenue] {
        let all = austinCourts
        let q = courtSearchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return all }
        return all.filter {
            $0.name.lowercased().contains(q) || $0.address.lowercased().contains(q)
        }
    }

    var filteredInvitePlayers: [User] {
        let q = inviteSearchText.trimmingCharacters(in: .whitespaces).lowercased()
        let all = User.mockPlayers
        if q.isEmpty { return Array(all.prefix(12)) }
        return all.filter {
            $0.displayName.lowercased().contains(q) || $0.username.lowercased().contains(q)
        }
    }

    func quickFill() {
        switch selectedFormat {
        case .singles:     totalSpots = 2
        case .doubles:     totalSpots = 4
        case .mixed:       totalSpots = 4
        case .openPlay:    totalSpots = 12
        case .round_robin: totalSpots = 8
        }
        HapticManager.medium()
    }

    func buildPreviewSession(hostId: String, hostName: String) -> GameSession {
        let court = selectedCourt ?? CourtVenue.mockVenues[0]
        return GameSession(
            id: UUID().uuidString,
            hostId: hostId,
            hostName: hostName,
            courtId: court.id,
            courtName: court.name,
            dateTime: selectedDate,
            format: selectedFormat,
            skillRange: minSkill...maxSkill,
            totalSpots: totalSpots,
            rsvps: [hostId],
            waitlist: [],
            isPublic: visibility == .public_,
            notes: notes.trimmingCharacters(in: .whitespaces),
            fee: parsedFee
        )
    }

    func submit(hostId: String, hostName: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let session = buildPreviewSession(hostId: hostId, hostName: hostName)

        try await FirestoreService.shared.setDocument(
            session,
            collection: FirestoreCollections.gameSessions,
            documentId: session.id
        )

        didPost = true
    }
}

// MARK: - Supporting Enums

enum GameDuration: String, CaseIterable, Identifiable {
    case oneHour      = "1h"
    case oneHalfHours = "1.5h"
    case twoHours     = "2h"
    case threeHours   = "3h"
    case openEnded    = "Open"

    var id: String { rawValue }
    var label: String { rawValue }

    var minutes: Int? {
        switch self {
        case .oneHour:      return 60
        case .oneHalfHours: return 90
        case .twoHours:     return 120
        case .threeHours:   return 180
        case .openEnded:    return nil
        }
    }

    var icon: String {
        switch self {
        case .oneHour:      return "timer"
        case .oneHalfHours: return "timer"
        case .twoHours:     return "clock.fill"
        case .threeHours:   return "clock.fill"
        case .openEnded:    return "infinity"
        }
    }
}

enum GameVisibility: String, CaseIterable, Identifiable {
    case public_      = "Public"
    case friendsOnly  = "Friends Only"
    case privateGroup = "DinkrGroup"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .public_:      return "globe"
        case .friendsOnly:  return "person.2.fill"
        case .privateGroup: return "person.3.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .public_:      return "Anyone can find & join"
        case .friendsOnly:  return "Your followers can see it"
        case .privateGroup: return "Invite-only within group"
        }
    }

    var accentColor: Color {
        switch self {
        case .public_:      return Color.dinkrGreen
        case .friendsOnly:  return Color.dinkrSky
        case .privateGroup: return Color.dinkrAmber
        }
    }
}

// MARK: - Step Enum (4 steps)

private enum HostStep: Int, CaseIterable {
    case format       = 0
    case timeLocation = 1
    case visibility   = 2
    case review       = 3

    var title: String {
        switch self {
        case .format:       return "Format"
        case .timeLocation: return "Time"
        case .visibility:   return "Details"
        case .review:       return "Review"
        }
    }
}

// MARK: - HostGameView

struct HostGameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var auth

    @State private var vm = HostGameViewModel()
    @State private var currentStep: HostStep = .format
    @State private var showSuccess: Bool = false
    @State private var publishedSession: GameSession? = nil

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Step indicator
                    StepIndicatorView(currentStep: currentStep)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 20)

                    // Step content
                    ScrollView {
                        VStack(spacing: 0) {
                            switch currentStep {
                            case .format:
                                FormatDetailsStepView(vm: vm)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .leading).combined(with: .opacity),
                                        removal: .move(edge: .trailing).combined(with: .opacity)
                                    ))
                            case .timeLocation:
                                TimeLocationStepView(vm: vm)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            case .visibility:
                                VisibilityNotesStepView(vm: vm)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            case .review:
                                ReviewPublishStepView(
                                    vm: vm,
                                    onEditStep: { step in
                                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                                            currentStep = step
                                        }
                                    }
                                )
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 120)
                    }
                }

                // Bottom navigation
                BottomNavBar(
                    currentStep: $currentStep,
                    vm: vm,
                    onPost: {
                        Task {
                            let hostId   = auth.currentUser?.id ?? "preview_host"
                            let hostName = auth.currentUser?.displayName ?? "You"
                            let preview  = vm.buildPreviewSession(hostId: hostId, hostName: hostName)
                            do {
                                try await vm.submit(hostId: hostId, hostName: hostName)
                                publishedSession = preview
                                HapticManager.success()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    showSuccess = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    dismiss()
                                }
                            } catch {
                                vm.errorMessage = error.localizedDescription
                                HapticManager.error()
                            }
                        }
                    }
                )
            }
            .navigationTitle("Host a Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.dinkrCoral)
                }
            }
            .overlay(alignment: .top) {
                if let err = vm.errorMessage {
                    ToastView(
                        message: ToastMessage(type: .error, title: err),
                        onDismiss: { vm.errorMessage = nil }
                    )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.errorMessage)
            .overlay {
                if showSuccess {
                    SuccessOverlayView(session: publishedSession)
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showSuccess)
        }
    }
}

// MARK: - Step Indicator

private struct StepIndicatorView: View {
    let currentStep: HostStep

    var body: some View {
        HStack(spacing: 0) {
            ForEach(HostStep.allCases, id: \.self) { step in
                HStack(spacing: 0) {
                    ZStack {
                        Capsule()
                            .fill(dotBackground(for: step))
                            .frame(width: step == currentStep ? 68 : 30, height: 30)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentStep)

                        if step.rawValue < currentStep.rawValue {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        } else if step == currentStep {
                            Text(step.title)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .padding(.horizontal, 4)
                        } else {
                            Text("\(step.rawValue + 1)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.dinkrNavy.opacity(0.35))
                        }
                    }

                    if step != .review {
                        Rectangle()
                            .fill(step.rawValue < currentStep.rawValue
                                  ? Color.dinkrGreen
                                  : Color.dinkrNavy.opacity(0.14))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func dotBackground(for step: HostStep) -> Color {
        if step == currentStep || step.rawValue < currentStep.rawValue { return Color.dinkrGreen }
        return Color.dinkrNavy.opacity(0.12)
    }
}

// MARK: - Step 1: Format & Details

private struct FormatDetailsStepView: View {
    @Bindable var vm: HostGameViewModel

    private let spotOptions: [Int] = [2, 4, 6, 8, 12, 16]

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {

            // Format cards
            VStack(alignment: .leading, spacing: 12) {
                HostGameViewSectionHeader(title: "Game Format", icon: "sportscourt.fill")
                FormatCardGrid(selection: $vm.selectedFormat)
            }

            // Skill range
            VStack(alignment: .leading, spacing: 14) {
                HostGameViewSectionHeader(title: "Skill Range", icon: "chart.bar.fill")
                DualSkillRangePicker(minSkill: $vm.minSkill, maxSkill: $vm.maxSkill)
            }

            // Max players with court layout visual
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HostGameViewSectionHeader(title: "Max Players", icon: "person.3.fill")
                    Spacer()
                    Button {
                        vm.quickFill()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 11))
                            Text("Quick Fill")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(Color.dinkrGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.dinkrGreen.opacity(0.1), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                SpotPickerView(selectedSpots: $vm.totalSpots, options: spotOptions)
            }

            // Entry fee
            VStack(alignment: .leading, spacing: 12) {
                HostGameViewSectionHeader(title: "Entry Fee", icon: "dollarsign.circle.fill")
                FeeToggleView(isPaid: $vm.isPaid, feeText: $vm.feeText)
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Format Card Grid

private struct FormatCardGrid: View {
    @Binding var selection: GameFormat

    private struct FormatOption {
        let format: GameFormat
        let icon: String
        let label: String
        let description: String
        let recommendedPlayers: String
    }

    private let options: [FormatOption] = [
        FormatOption(format: .doubles,     icon: "person.2.fill",
                     label: "Doubles",     description: "Classic 2v2 play",
                     recommendedPlayers: "4 players"),
        FormatOption(format: .singles,     icon: "person.fill",
                     label: "Singles",     description: "Head-to-head 1v1",
                     recommendedPlayers: "2 players"),
        FormatOption(format: .mixed,       icon: "person.2.wave.2.fill",
                     label: "Mixed",       description: "Co-ed doubles",
                     recommendedPlayers: "4 players"),
        FormatOption(format: .openPlay,    icon: "circle.grid.3x3.fill",
                     label: "Open Play",   description: "Casual drop-in",
                     recommendedPlayers: "8–16 players"),
        FormatOption(format: .round_robin, icon: "arrow.triangle.2.circlepath",
                     label: "Round Robin", description: "Rotating partners",
                     recommendedPlayers: "8–12 players"),
    ]

    var body: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(options, id: \.format) { option in
                FormatCard(
                    icon: option.icon,
                    label: option.label,
                    description: option.description,
                    recommendedPlayers: option.recommendedPlayers,
                    isSelected: selection == option.format
                ) {
                    HapticManager.selection()
                    selection = option.format
                }
            }
        }
    }
}

private struct FormatCard: View {
    let icon: String
    let label: String
    let description: String
    let recommendedPlayers: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.dinkrGreen.opacity(0.15) : Color.dinkrNavy.opacity(0.07))
                            .frame(width: 40, height: 40)
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isSelected ? Color.dinkrGreen : Color.dinkrNavy.opacity(0.5))
                    }
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.dinkrGreen)
                            .font(.system(size: 16))
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isSelected ? Color.dinkrNavy : Color.dinkrNavy.opacity(0.7))
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.dinkrNavy.opacity(0.45))
                }

                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 9))
                    Text(recommendedPlayers)
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(isSelected ? Color.dinkrGreen : Color.dinkrNavy.opacity(0.35))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    isSelected ? Color.dinkrGreen.opacity(0.1) : Color.dinkrNavy.opacity(0.06),
                    in: Capsule()
                )
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.dinkrGreen : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: isSelected ? Color.dinkrGreen.opacity(0.18) : Color.clear,
                radius: 8, y: 3
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Dual Skill Range Picker

private struct DualSkillRangePicker: View {
    @Binding var minSkill: SkillLevel
    @Binding var maxSkill: SkillLevel

    @State private var showMinPicker = false
    @State private var showMaxPicker = false

    var body: some View {
        VStack(spacing: 14) {
            // Two tappable pills
            HStack(spacing: 12) {
                SkillPill(
                    label: "Min",
                    skill: minSkill,
                    isExpanded: showMinPicker
                ) {
                    HapticManager.light()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showMinPicker.toggle()
                        if showMinPicker { showMaxPicker = false }
                    }
                }

                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.dinkrNavy.opacity(0.3))

                SkillPill(
                    label: "Max",
                    skill: maxSkill,
                    isExpanded: showMaxPicker
                ) {
                    HapticManager.light()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showMaxPicker.toggle()
                        if showMaxPicker { showMinPicker = false }
                    }
                }
            }

            if showMinPicker {
                SkillLevelPickerSheet(
                    title: "Minimum Skill",
                    selection: $minSkill,
                    highlighted: maxSkill
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if showMaxPicker {
                SkillLevelPickerSheet(
                    title: "Maximum Skill",
                    selection: $maxSkill,
                    highlighted: minSkill
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if minSkill > maxSkill {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Min must be ≤ Max")
                }
                .font(.caption)
                .foregroundStyle(Color.dinkrCoral)
                .transition(.opacity)
            }

            // Live range pill preview
            HStack(spacing: 8) {
                SkillRangePillView(min: minSkill, max: maxSkill)
                Spacer()
            }
        }
        .padding(14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showMinPicker)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showMaxPicker)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: minSkill > maxSkill)
    }
}

private struct SkillPill: View {
    let label: String
    let skill: SkillLevel
    let isExpanded: Bool
    let action: () -> Void

    private var pillColor: Color {
        switch skill {
        case .beginner20, .beginner25:         return Color.dinkrGreen
        case .intermediate30, .intermediate35: return Color.dinkrSky
        case .advanced40, .advanced45:         return Color.dinkrCoral
        case .pro50:                           return Color.dinkrNavy
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(pillColor.opacity(0.75))
                    Text(skill.label)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(pillColor)
                }
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(pillColor.opacity(0.65))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(pillColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isExpanded ? pillColor.opacity(0.5) : pillColor.opacity(0.2), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isExpanded)
    }
}

private struct SkillLevelPickerSheet: View {
    let title: String
    @Binding var selection: SkillLevel
    let highlighted: SkillLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.dinkrNavy.opacity(0.5))
                .padding(.horizontal, 4)

            HStack(spacing: 8) {
                ForEach(SkillLevel.allCases, id: \.self) { level in
                    Button {
                        HapticManager.selection()
                        selection = level
                    } label: {
                        Text(level.label)
                            .font(.system(size: 13, weight: selection == level ? .bold : .medium))
                            .foregroundStyle(selection == level ? .white : Color.dinkrNavy.opacity(0.65))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                selection == level ? Color.dinkrGreen : Color.dinkrNavy.opacity(0.06),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        level == highlighted ? Color.dinkrAmber.opacity(0.5) : Color.clear,
                                        lineWidth: 1.5
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: selection)
                }
            }
        }
    }
}

private struct SkillRangePillView: View {
    let min: SkillLevel
    let max: SkillLevel

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 10))
                .foregroundStyle(Color.dinkrSky)
            Text(min == max ? min.label : "\(min.label) – \(max.label)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.dinkrSky)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.dinkrSky.opacity(0.12), in: Capsule())
    }
}

// MARK: - Spot Picker

private struct SpotPickerView: View {
    @Binding var selectedSpots: Int
    let options: [Int]

    var body: some View {
        VStack(spacing: 14) {
            // Scroll-row selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(options, id: \.self) { count in
                        Button {
                            HapticManager.selection()
                            selectedSpots = count
                        } label: {
                            VStack(spacing: 3) {
                                Text("\(count)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(selectedSpots == count ? .white : Color.dinkrNavy)
                                Text("players")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(selectedSpots == count
                                                     ? .white.opacity(0.85)
                                                     : Color.dinkrNavy.opacity(0.4))
                            }
                            .frame(width: 66, height: 54)
                            .background(
                                selectedSpots == count ? Color.dinkrGreen : Color.dinkrNavy.opacity(0.06),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        selectedSpots == count ? Color.clear : Color.dinkrNavy.opacity(0.12),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: selectedSpots)
                    }
                }
                .padding(.vertical, 2)
            }

            // Court layout visualization
            CourtLayoutView(spots: selectedSpots)
        }
        .padding(14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct CourtLayoutView: View {
    let spots: Int

    private let maxDisplay = 16

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.dinkrGreen.opacity(0.08))
                    .frame(height: 2)
                Text("court layout")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.dinkrNavy.opacity(0.3))
                    .padding(.horizontal, 8)
                Rectangle()
                    .fill(Color.dinkrGreen.opacity(0.08))
                    .frame(height: 2)
            }

            let display = min(spots, maxDisplay)
            let rows = Int(ceil(Double(display) / 4.0))

            VStack(spacing: 6) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 6) {
                        let start = row * 4
                        let end = min(start + 4, display)
                        ForEach(start..<end, id: \.self) { index in
                            PlayerSlotDot(index: index, isFilled: index == 0)
                        }
                        if (end - start) < 4 {
                            ForEach(0..<(4 - (end - start)), id: \.self) { _ in
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                }
            }

            if spots > maxDisplay {
                Text("+\(spots - maxDisplay) more")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.dinkrNavy.opacity(0.4))
            }
        }
    }
}

private struct PlayerSlotDot: View {
    let index: Int
    let isFilled: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isFilled ? Color.dinkrGreen.opacity(0.2) : Color.dinkrGreen.opacity(0.08))
                .frame(width: 20, height: 20)
            Circle()
                .stroke(isFilled ? Color.dinkrGreen : Color.dinkrGreen.opacity(0.3), lineWidth: 1.5)
                .frame(width: 20, height: 20)
            if isFilled {
                Image(systemName: "person.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.dinkrGreen)
            }
        }
    }
}

// MARK: - Fee Toggle

private struct FeeToggleView: View {
    @Binding var isPaid: Bool
    @Binding var feeText: String

    var body: some View {
        VStack(spacing: 12) {
            // Free / Paid selector
            HStack(spacing: 10) {
                FeeOptionTile(
                    title: "Free",
                    subtitle: "No cost to join",
                    icon: "gift.fill",
                    color: Color.dinkrGreen,
                    isSelected: !isPaid
                ) {
                    HapticManager.selection()
                    isPaid = false
                }
                FeeOptionTile(
                    title: "Paid",
                    subtitle: "Set entry fee",
                    icon: "dollarsign.circle.fill",
                    color: Color.dinkrAmber,
                    isSelected: isPaid
                ) {
                    HapticManager.selection()
                    isPaid = true
                }
            }

            if isPaid {
                HStack(spacing: 10) {
                    Text("$")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.dinkrAmber)
                    TextField("0.00", text: $feeText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.dinkrNavy)
                    Spacer()
                    Text("per player")
                        .font(.caption)
                        .foregroundStyle(Color.dinkrNavy.opacity(0.4))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.dinkrAmber.opacity(0.4), lineWidth: 1.5)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPaid)
    }
}

private struct FeeOptionTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(isSelected ? color : Color.dinkrNavy.opacity(0.35))
                    .font(.system(size: 16))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.dinkrNavy : Color.dinkrNavy.opacity(0.5))
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.dinkrNavy.opacity(0.4))
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(color)
                        .font(.system(size: 14))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? color.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Austin Courts Data

private let austinCourts: [CourtVenue] = [
    CourtVenue(id: "court_001", name: "Westside Pickleball Complex",
               address: "4501 W 35th St, Austin, TX 78703",
               coordinates: GeoPoint(latitude: 30.2889, longitude: -97.7681),
               courtCount: 12, surface: .hardcourt, hasLighting: true, isIndoor: false,
               openPlaySchedule: "Mon–Fri 6am–9pm", amenities: [],
               rating: 4.7, reviewCount: 234, websiteURL: nil, phoneNumber: nil),
    CourtVenue(id: "court_002", name: "Mueller Recreation Center",
               address: "4730 Mueller Blvd, Austin, TX 78723",
               coordinates: GeoPoint(latitude: 30.3042, longitude: -97.7024),
               courtCount: 6, surface: .hardcourt, hasLighting: true, isIndoor: false,
               openPlaySchedule: "Daily 6am–10pm", amenities: [],
               rating: 4.4, reviewCount: 178, websiteURL: nil, phoneNumber: nil),
    CourtVenue(id: "court_003", name: "South Lamar Sports Club",
               address: "1600 S Lamar Blvd, Austin, TX 78704",
               coordinates: GeoPoint(latitude: 30.2473, longitude: -97.7528),
               courtCount: 4, surface: .indoor, hasLighting: true, isIndoor: true,
               openPlaySchedule: "Members only — 24/7", amenities: [],
               rating: 4.9, reviewCount: 89, websiteURL: nil, phoneNumber: nil),
    CourtVenue(id: "court_004", name: "Barton Springs Tennis Center",
               address: "2101 Barton Springs Rd, Austin, TX 78746",
               coordinates: GeoPoint(latitude: 30.2620, longitude: -97.7713),
               courtCount: 8, surface: .hardcourt, hasLighting: false, isIndoor: false,
               openPlaySchedule: "Daily 7am–9pm", amenities: [],
               rating: 4.6, reviewCount: 112, websiteURL: nil, phoneNumber: nil),
    CourtVenue(id: "court_005", name: "Zilker Park Courts",
               address: "2100 Barton Springs Rd, Austin, TX 78704",
               coordinates: GeoPoint(latitude: 30.2652, longitude: -97.7682),
               courtCount: 6, surface: .concrete, hasLighting: false, isIndoor: false,
               openPlaySchedule: "Daily sunrise–sunset", amenities: [],
               rating: 4.3, reviewCount: 201, websiteURL: nil, phoneNumber: nil),
]

// MARK: - Step 2: Time & Location

private struct TimeLocationStepView: View {
    @Bindable var vm: HostGameViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {

            // Date & Time
            VStack(alignment: .leading, spacing: 14) {
                HostGameViewSectionHeader(title: "Date & Time", icon: "calendar.badge.clock")
                DateChipRow(selectedDate: $vm.selectedDate)
                DatePicker(
                    "Date & Time",
                    selection: $vm.selectedDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(Color.dinkrGreen)
                .padding(12)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
            }

            // Duration
            VStack(alignment: .leading, spacing: 12) {
                HostGameViewSectionHeader(title: "Duration", icon: "hourglass")
                DurationPickerView(selection: $vm.selectedDuration)
            }

            // Court search
            VStack(alignment: .leading, spacing: 12) {
                HostGameViewSectionHeader(title: "Court", icon: "mappin.circle.fill")
                CourtSearchView(vm: vm)
            }

            // Recurring
            VStack(alignment: .leading, spacing: 12) {
                HostGameViewSectionHeader(title: "Recurring", icon: "repeat")
                RecurringToggleView(
                    isRecurring: $vm.isRecurring,
                    selectedDate: vm.selectedDate
                )
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Date Chip Row

private struct DateChipRow: View {
    @Binding var selectedDate: Date

    private var today: Date {
        Calendar.current.startOfDay(for: Date())
    }

    private var chips: [(label: String, date: Date)] {
        let cal = Calendar.current
        return [
            ("Today",    today),
            ("Tomorrow", cal.date(byAdding: .day, value: 1, to: today)!),
            ("Sat",      nextWeekday(2, from: today)),
            ("Sun",      nextWeekday(1, from: today)),
            ("Next Sat", nextWeekday(2, from: today, skip: true)),
        ]
    }

    private func nextWeekday(_ weekday: Int, from date: Date, skip: Bool = false) -> Date {
        let cal = Calendar.current
        var comps = DateComponents()
        comps.weekday = weekday
        var next = cal.nextDate(after: date, matching: comps, matchingPolicy: .nextTime) ?? date
        if skip {
            next = cal.nextDate(after: next, matching: comps, matchingPolicy: .nextTime) ?? next
        }
        return next
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chips, id: \.label) { chip in
                    let isSelected = Calendar.current.isDate(selectedDate, inSameDayAs: chip.date)
                    Button {
                        HapticManager.selection()
                        var comps = Calendar.current.dateComponents(
                            [.year, .month, .day], from: chip.date
                        )
                        let timeComps = Calendar.current.dateComponents(
                            [.hour, .minute], from: selectedDate
                        )
                        comps.hour   = timeComps.hour ?? 10
                        comps.minute = timeComps.minute ?? 0
                        if let newDate = Calendar.current.date(from: comps) {
                            selectedDate = newDate
                        }
                    } label: {
                        Text(chip.label)
                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? .white : Color.dinkrNavy.opacity(0.7))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                isSelected ? Color.dinkrGreen : Color.dinkrNavy.opacity(0.07),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Duration Picker

private struct DurationPickerView: View {
    @Binding var selection: GameDuration

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(GameDuration.allCases) { dur in
                    Button {
                        HapticManager.selection()
                        selection = dur
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: dur.icon)
                                .font(.system(size: 12))
                            Text(dur.label)
                                .font(.system(size: 13, weight: selection == dur ? .bold : .medium))
                        }
                        .foregroundStyle(selection == dur ? .white : Color.dinkrNavy.opacity(0.65))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            selection == dur ? Color.dinkrGreen : Color.dinkrNavy.opacity(0.07),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    selection == dur ? Color.clear : Color.dinkrNavy.opacity(0.12),
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: selection)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Court Search

private struct CourtSearchView: View {
    @Bindable var vm: HostGameViewModel

    var body: some View {
        VStack(spacing: 10) {
            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.dinkrNavy.opacity(0.4))
                    .font(.system(size: 14))
                TextField("Search courts…", text: $vm.courtSearchText)
                    .font(.system(size: 15))
                if !vm.courtSearchText.isEmpty {
                    Button {
                        vm.courtSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.dinkrNavy.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.dinkrNavy.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))

            if vm.courtSearchText.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.dinkrNavy.opacity(0.3))
                    Text("Recent courts shown first")
                        .font(.caption)
                        .foregroundStyle(Color.dinkrNavy.opacity(0.35))
                    Spacer()
                }
                .padding(.horizontal, 4)
            }

            // Court list
            let courts = vm.filteredCourts
            VStack(spacing: 1) {
                ForEach(Array(courts.enumerated()), id: \.element.id) { index, court in
                    CourtRow(
                        court: court,
                        isSelected: vm.selectedCourt?.id == court.id,
                        isFirst: index == 0,
                        isLast: index == courts.count - 1
                    ) {
                        HapticManager.selection()
                        vm.selectedCourt = court
                    }
                    if index < courts.count - 1 {
                        Divider().padding(.leading, 56).background(Color.cardBackground)
                    }
                }
            }
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))

            if courts.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.dinkrNavy.opacity(0.25))
                        Text("No courts found")
                            .font(.subheadline)
                            .foregroundStyle(Color.dinkrNavy.opacity(0.4))
                    }
                    Spacer()
                }
                .padding(.vertical, 20)
            }
        }
    }
}

// MARK: - Court Row

private struct CourtRow: View {
    let court: CourtVenue
    let isSelected: Bool
    let isFirst: Bool
    let isLast: Bool
    let action: () -> Void

    private var surfaceLabel: String {
        switch court.surface {
        case .hardcourt: return "Hardcourt"
        case .concrete:  return "Concrete"
        case .asphalt:   return "Asphalt"
        case .indoor:    return "Indoor"
        case .clay:      return "Clay"
        }
    }

    private var surfaceColor: Color {
        switch court.surface {
        case .indoor:    return Color.dinkrSky
        case .hardcourt: return Color.dinkrGreen
        case .concrete:  return Color.dinkrNavy
        case .asphalt:   return Color.dinkrNavy
        case .clay:      return Color.dinkrAmber
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.dinkrGreen.opacity(0.15) : Color.dinkrNavy.opacity(0.07))
                        .frame(width: 40, height: 40)
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "sportscourt.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(isSelected ? Color.dinkrGreen : Color.dinkrNavy.opacity(0.45))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(court.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Text(court.address)
                            .font(.caption)
                            .foregroundStyle(Color.dinkrNavy.opacity(0.5))
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(surfaceLabel)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(surfaceColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(surfaceColor.opacity(0.12), in: Capsule())
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(Color.dinkrAmber)
                        Text(String(format: "%.1f", court.rating))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.dinkrNavy.opacity(0.55))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isSelected ? Color.dinkrGreen.opacity(0.05) : Color.cardBackground)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Recurring Toggle

private struct RecurringToggleView: View {
    @Binding var isRecurring: Bool
    let selectedDate: Date

    private var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(isRecurring ? "Repeats Weekly" : "One-Time Game")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.dinkrNavy)
                Text(isRecurring
                     ? "Every \(weekdayName) at the same time"
                     : "Tap to make this a weekly game")
                    .font(.caption)
                    .foregroundStyle(Color.dinkrNavy.opacity(0.5))
            }
            Spacer()
            Toggle("", isOn: $isRecurring)
                .tint(Color.dinkrGreen)
                .labelsHidden()
                .onChange(of: isRecurring) { _, _ in HapticManager.light() }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isRecurring ? Color.dinkrGreen.opacity(0.3) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isRecurring)
    }
}

// MARK: - Step 3: Visibility & Notes

private struct VisibilityNotesStepView: View {
    @Bindable var vm: HostGameViewModel

    private let mockGroups = DinkrGroup.mockGroups

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {

            // Visibility selector
            VStack(alignment: .leading, spacing: 12) {
                HostGameViewSectionHeader(title: "Visibility", icon: "eye.fill")
                VStack(spacing: 10) {
                    ForEach(GameVisibility.allCases) { option in
                        VisibilityCard(
                            option: option,
                            isSelected: vm.visibility == option
                        ) {
                            HapticManager.selection()
                            vm.visibility = option
                        }
                    }
                }
            }

            // Notes with character counter
            VStack(alignment: .leading, spacing: 12) {
                HostGameViewSectionHeader(title: "Notes", icon: "text.bubble.fill")
                NotesEditorView(notes: $vm.notes)
            }

            // Invite specific players
            VStack(alignment: .leading, spacing: 12) {
                HostGameViewSectionHeader(title: "Invite Players", icon: "person.badge.plus")
                InvitePlayersView(vm: vm)
            }

            // Invite all group members
            if !mockGroups.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HostGameViewSectionHeader(title: "DinkrGroup Invite", icon: "person.3.fill")
                    GroupInviteToggle(
                        groups: mockGroups,
                        inviteAll: $vm.inviteAllGroupMembers,
                        selectedGroupId: $vm.selectedGroupId
                    )
                }
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Visibility Card

private struct VisibilityCard: View {
    let option: GameVisibility
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected
                              ? option.accentColor.opacity(0.15)
                              : Color.dinkrNavy.opacity(0.06))
                        .frame(width: 44, height: 44)
                    Image(systemName: option.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? option.accentColor : Color.dinkrNavy.opacity(0.4))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(option.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.dinkrNavy : Color.dinkrNavy.opacity(0.55))
                    Text(option.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.dinkrNavy.opacity(0.45))
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? option.accentColor : Color.dinkrNavy.opacity(0.2),
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(option.accentColor)
                            .frame(width: 13, height: 13)
                    }
                }
            }
            .padding(14)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? option.accentColor.opacity(0.4) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: isSelected ? option.accentColor.opacity(0.1) : Color.clear,
                radius: 6, y: 2
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Notes Editor

private struct NotesEditorView: View {
    @Binding var notes: String

    private let maxChars = 280

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("Special instructions, what to bring, parking tips…")
                        .foregroundStyle(Color.dinkrNavy.opacity(0.3))
                        .font(.system(size: 15))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $notes)
                    .font(.system(size: 15))
                    .frame(minHeight: 96)
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .onChange(of: notes) { _, newVal in
                        if newVal.count > maxChars {
                            notes = String(newVal.prefix(maxChars))
                        }
                    }
            }
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))

            HStack {
                // Formatting hints
                HStack(spacing: 12) {
                    FormattingHint(icon: "info.circle", text: "Include start time")
                    FormattingHint(icon: "drop.fill", text: "Mention water/snacks")
                }
                Spacer()
                // Character counter
                Text("\(notes.count)/\(maxChars)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(
                        notes.count > Int(Double(maxChars) * 0.85)
                        ? Color.dinkrCoral
                        : Color.dinkrNavy.opacity(0.35)
                    )
                    .animation(.easeInOut(duration: 0.2), value: notes.count)
            }
            .padding(.horizontal, 4)
        }
    }
}

private struct FormattingHint: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(Color.dinkrNavy.opacity(0.3))
            Text(text)
                .font(.system(size: 10))
                .foregroundStyle(Color.dinkrNavy.opacity(0.3))
        }
    }
}

// MARK: - Invite Players

private struct InvitePlayersView: View {
    @Bindable var vm: HostGameViewModel
    private let maxInvites = 8

    var body: some View {
        VStack(spacing: 12) {
            // Invited players chips
            if !vm.invitedPlayerIds.isEmpty {
                let invited = User.mockPlayers.filter { vm.invitedPlayerIds.contains($0.id) }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(invited) { player in
                            InvitedPlayerChip(player: player) {
                                HapticManager.light()
                                vm.invitedPlayerIds.removeAll { $0 == player.id }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            // Search field
            if vm.invitedPlayerIds.count < maxInvites {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.dinkrNavy.opacity(0.35))
                        .font(.system(size: 13))
                    TextField("Search players to invite…", text: $vm.inviteSearchText)
                        .font(.system(size: 14))
                    if !vm.inviteSearchText.isEmpty {
                        Button { vm.inviteSearchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.dinkrNavy.opacity(0.3))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color.dinkrNavy.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))

                // Results
                let results = vm.filteredInvitePlayers.filter {
                    !vm.invitedPlayerIds.contains($0.id)
                }
                if !results.isEmpty {
                    VStack(spacing: 1) {
                        ForEach(results.prefix(6)) { player in
                            PlayerInviteRow(player: player) {
                                HapticManager.selection()
                                if !vm.invitedPlayerIds.contains(player.id) {
                                    vm.invitedPlayerIds.append(player.id)
                                }
                                vm.inviteSearchText = ""
                            }
                            if player.id != results.prefix(6).last?.id {
                                Divider().padding(.leading, 48)
                                    .background(Color.cardBackground)
                            }
                        }
                    }
                    .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                }
            }

            if vm.invitedPlayerIds.count >= maxInvites {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.dinkrGreen)
                    Text("Max \(maxInvites) direct invites")
                        .font(.caption)
                        .foregroundStyle(Color.dinkrNavy.opacity(0.5))
                }
                .font(.system(size: 12))
            } else {
                HStack {
                    Spacer()
                    Text("\(vm.invitedPlayerIds.count)/\(maxInvites) invited")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.dinkrNavy.opacity(0.35))
                }
            }
        }
    }
}

private struct InvitedPlayerChip: View {
    let player: User
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.15))
                    .frame(width: 28, height: 28)
                Text(String(player.displayName.prefix(1)))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.dinkrGreen)
            }
            Text(player.displayName.components(separatedBy: " ").first ?? player.displayName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.dinkrNavy)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.dinkrNavy.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.dinkrGreen.opacity(0.08), in: Capsule())
        .overlay(Capsule().stroke(Color.dinkrGreen.opacity(0.25), lineWidth: 1))
    }
}

private struct PlayerInviteRow: View {
    let player: User
    let onInvite: () -> Void

    var body: some View {
        Button(action: onInvite) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.dinkrNavy.opacity(0.08))
                        .frame(width: 36, height: 36)
                    Text(String(player.displayName.prefix(1)))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.dinkrNavy.opacity(0.6))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.dinkrNavy)
                    Text("@\(player.username) · \(player.skillLevel.label)")
                        .font(.caption)
                        .foregroundStyle(Color.dinkrNavy.opacity(0.45))
                }
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.dinkrGreen)
                    .font(.system(size: 20))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - DinkrGroup Invite Toggle

private struct GroupInviteToggle: View {
    let groups: [DinkrGroup]
    @Binding var inviteAll: Bool
    @Binding var selectedGroupId: String?

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(inviteAll ? "Notifying group members" : "Invite all group members")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.dinkrNavy)
                    Text(inviteAll ? "All members will receive a notification" : "Send invite to everyone in a group")
                        .font(.caption)
                        .foregroundStyle(Color.dinkrNavy.opacity(0.5))
                }
                Spacer()
                Toggle("", isOn: $inviteAll)
                    .tint(Color.dinkrGreen)
                    .labelsHidden()
                    .onChange(of: inviteAll) { _, newVal in
                        HapticManager.light()
                        if newVal && selectedGroupId == nil {
                            selectedGroupId = groups.first?.id
                        }
                    }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(inviteAll ? Color.dinkrGreen.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )

            if inviteAll {
                Picker("Select DinkrGroup", selection: Binding(
                    get: { selectedGroupId ?? groups.first?.id ?? "" },
                    set: { selectedGroupId = $0 }
                )) {
                    ForEach(groups) { group in
                        Text(group.name).tag(group.id)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.dinkrGreen)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.dinkrGreen.opacity(0.25), lineWidth: 1)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: inviteAll)
    }
}

// MARK: - Step 4: Review & Publish

private struct ReviewPublishStepView: View {
    let vm: HostGameViewModel
    let onEditStep: (HostStep) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HostGameViewSectionHeader(title: "Review Your Game", icon: "checkmark.seal.fill")

            // Live GameCard preview
            VStack(alignment: .leading, spacing: 8) {
                Text("How it appears to players")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.dinkrNavy.opacity(0.5))

                GameCardView(
                    session: GameSession(
                        id: "preview",
                        hostId: "preview_host",
                        hostName: "You",
                        courtId: vm.selectedCourt?.id ?? "preview_court",
                        courtName: vm.selectedCourt?.name ?? "Select a Court",
                        dateTime: vm.selectedDate,
                        format: vm.selectedFormat,
                        skillRange: vm.minSkill...vm.maxSkill,
                        totalSpots: vm.totalSpots,
                        rsvps: ["preview_host"],
                        waitlist: [],
                        isPublic: vm.visibility == .public_,
                        notes: vm.notes,
                        fee: vm.isPaid ? (Double(vm.feeText) ?? 0.0) : nil
                    )
                )
                .allowsHitTesting(false)
            }

            // Pre-publish checklist
            VStack(alignment: .leading, spacing: 10) {
                Text("Checklist")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrNavy.opacity(0.5))
                    .padding(.horizontal, 2)

                VStack(spacing: 1) {
                    ChecklistRow(
                        icon: "mappin.circle.fill",
                        color: Color.dinkrCoral,
                        label: "Court confirmed",
                        isDone: vm.selectedCourt != nil
                    )
                    Divider().padding(.leading, 40).background(Color.cardBackground)
                    ChecklistRow(
                        icon: "calendar.badge.clock",
                        color: Color.dinkrSky,
                        label: "Date & time set",
                        isDone: true
                    )
                    Divider().padding(.leading, 40).background(Color.cardBackground)
                    ChecklistRow(
                        icon: "person.badge.plus",
                        color: Color.dinkrGreen,
                        label: "Players invited",
                        isDone: !vm.invitedPlayerIds.isEmpty || vm.inviteAllGroupMembers
                    )
                    Divider().padding(.leading, 40).background(Color.cardBackground)
                    ChecklistRow(
                        icon: "bell.fill",
                        color: Color.dinkrAmber,
                        label: "Reminder set (on publish)",
                        isDone: true
                    )
                }
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
            }

            // Detail edit rows
            VStack(spacing: 1) {
                ReviewEditRow(
                    icon: "sportscourt.fill",
                    color: Color.dinkrGreen,
                    label: "Format",
                    value: formatLabel(vm.selectedFormat)
                ) { onEditStep(.format) }

                Divider().padding(.leading, 48).background(Color.cardBackground)

                ReviewEditRow(
                    icon: "chart.bar.fill",
                    color: Color.dinkrSky,
                    label: "Skill",
                    value: "\(vm.minSkill.label) – \(vm.maxSkill.label)"
                ) { onEditStep(.format) }

                Divider().padding(.leading, 48).background(Color.cardBackground)

                ReviewEditRow(
                    icon: "person.3.fill",
                    color: Color.dinkrNavy,
                    label: "Players",
                    value: "\(vm.totalSpots) spots"
                ) { onEditStep(.format) }

                Divider().padding(.leading, 48).background(Color.cardBackground)

                ReviewEditRow(
                    icon: "dollarsign.circle.fill",
                    color: Color.dinkrAmber,
                    label: "Fee",
                    value: feeDisplay
                ) { onEditStep(.format) }

                Divider().padding(.leading, 48).background(Color.cardBackground)

                ReviewEditRow(
                    icon: "calendar",
                    color: Color.dinkrCoral,
                    label: "Date",
                    value: vm.selectedDate.formatted(date: .abbreviated, time: .shortened)
                ) { onEditStep(.timeLocation) }

                Divider().padding(.leading, 48).background(Color.cardBackground)

                ReviewEditRow(
                    icon: "hourglass",
                    color: Color.dinkrSky,
                    label: "Duration",
                    value: vm.selectedDuration.label
                ) { onEditStep(.timeLocation) }

                Divider().padding(.leading, 48).background(Color.cardBackground)

                ReviewEditRow(
                    icon: "mappin.circle.fill",
                    color: Color.dinkrCoral,
                    label: "Court",
                    value: vm.selectedCourt?.name ?? "Not selected"
                ) { onEditStep(.timeLocation) }

                Divider().padding(.leading, 48).background(Color.cardBackground)

                ReviewEditRow(
                    icon: vm.visibility.icon,
                    color: vm.visibility.accentColor,
                    label: "Visibility",
                    value: vm.visibility.rawValue
                ) { onEditStep(.visibility) }

                if !vm.notes.isEmpty {
                    Divider().padding(.leading, 48).background(Color.cardBackground)
                    ReviewEditRow(
                        icon: "text.bubble.fill",
                        color: Color.dinkrNavy.opacity(0.6),
                        label: "Notes",
                        value: vm.notes
                    ) { onEditStep(.visibility) }
                }

                if !vm.invitedPlayerIds.isEmpty {
                    Divider().padding(.leading, 48).background(Color.cardBackground)
                    ReviewEditRow(
                        icon: "person.badge.plus",
                        color: Color.dinkrGreen,
                        label: "Invited",
                        value: "\(vm.invitedPlayerIds.count) player\(vm.invitedPlayerIds.count == 1 ? "" : "s")"
                    ) { onEditStep(.visibility) }
                }
            }
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(.top, 4)
    }

    private var feeDisplay: String {
        guard vm.isPaid else { return "Free" }
        let amount = Double(vm.feeText) ?? 0.0
        return String(format: "$%.2f", amount)
    }

    private func formatLabel(_ format: GameFormat) -> String {
        switch format {
        case .singles:     return "Singles"
        case .doubles:     return "Doubles"
        case .mixed:       return "Mixed"
        case .openPlay:    return "Open Play"
        case .round_robin: return "Round Robin"
        }
    }
}

// MARK: - Checklist Row

private struct ChecklistRow: View {
    let icon: String
    let color: Color
    let label: String
    let isDone: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isDone ? color.opacity(0.12) : Color.dinkrNavy.opacity(0.06))
                    .frame(width: 28, height: 28)
                Image(systemName: isDone ? "checkmark" : icon)
                    .font(.system(size: isDone ? 12 : 13, weight: .semibold))
                    .foregroundStyle(isDone ? color : Color.dinkrNavy.opacity(0.3))
            }
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(isDone ? Color.dinkrNavy : Color.dinkrNavy.opacity(0.45))
            Spacer()
            if isDone {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.dinkrGreen)
                    .font(.system(size: 16))
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(Color.dinkrNavy.opacity(0.2))
                    .font(.system(size: 16))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isDone)
    }
}

// MARK: - Review Edit Row

private struct ReviewEditRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 15))
                    .frame(width: 24)

                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(Color.dinkrNavy.opacity(0.55))
                    .frame(width: 76, alignment: .leading)

                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.dinkrNavy)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.dinkrNavy.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Success Overlay with Confetti

private struct SuccessOverlayView: View {
    let session: GameSession?

    @State private var confettiParticles: [HostConfettiParticle] = []
    @State private var animateIn = false

    private var shareText: String {
        guard let s = session else { return "Join my pickleball game on Dinkr!" }
        let dateStr = s.dateTime.formatted(date: .abbreviated, time: .shortened)
        return "Join my \(s.format.rawValue) game at \(s.courtName) on \(dateStr)! Sign up on Dinkr."
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()

            // Confetti layer
            ForEach(confettiParticles) { particle in
                HostConfettiPiece(particle: particle)
            }

            // Card
            VStack(spacing: 0) {
                // Top gradient banner
                LinearGradient(
                    colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 6)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))

                VStack(spacing: 22) {
                    // Success icon
                    ZStack {
                        Circle()
                            .fill(Color.dinkrGreen.opacity(0.12))
                            .frame(width: 88, height: 88)
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.75)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 68, height: 68)
                        Image(systemName: "checkmark")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                            .scaleEffect(animateIn ? 1 : 0.5)
                            .opacity(animateIn ? 1 : 0)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 8) {
                        Text("Your game is live!")
                            .font(.title2.bold())
                            .foregroundStyle(Color.dinkrNavy)
                        Text("Players can now discover and join your game.")
                            .font(.subheadline)
                            .foregroundStyle(Color.dinkrNavy.opacity(0.55))
                            .multilineTextAlignment(.center)
                    }

                    if let s = session {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(Color.dinkrCoral)
                                .font(.system(size: 13))
                            Text(s.courtName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.dinkrNavy)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.dinkrNavy.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                    }

                    // Share button
                    ShareLink(item: shareText) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Share Game")
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.82)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 8, y: 3)
                    }
                    .padding(.horizontal, 4)

                    Text("Dismissing automatically…")
                        .font(.caption)
                        .foregroundStyle(Color.dinkrNavy.opacity(0.35))
                        .padding(.bottom, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .padding(.top, 16)
            }
            .frame(maxWidth: 340)
            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.dinkrNavy.opacity(0.18), radius: 30, y: 10)
            .scaleEffect(animateIn ? 1 : 0.88)
            .opacity(animateIn ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                animateIn = true
            }
            spawnConfetti()
        }
    }

    private func spawnConfetti() {
        let colors: [Color] = [
            Color.dinkrGreen, Color.dinkrCoral, Color.dinkrAmber, Color.dinkrSky, .white
        ]
        confettiParticles = (0..<45).map { i in
            HostConfettiParticle(
                id: i,
                color: colors[i % colors.count],
                x: CGFloat.random(in: 0.05...0.95),
                size: CGFloat.random(in: 6...12),
                rotation: Double.random(in: 0...360),
                delay: Double.random(in: 0...0.6)
            )
        }
    }
}

// MARK: - Confetti

private struct HostConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let x: CGFloat
    let size: CGFloat
    let rotation: Double
    let delay: Double
}

private struct HostConfettiPiece: View {
    let particle: HostConfettiParticle
    @State private var drop = false
    @State private var opacity = 1.0

    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 2)
                .fill(particle.color)
                .frame(width: particle.size, height: particle.size * 1.6)
                .rotationEffect(.degrees(drop ? particle.rotation + 180 : particle.rotation))
                .position(
                    x: geo.size.width * particle.x,
                    y: drop ? geo.size.height + 20 : -20
                )
                .opacity(opacity)
                .onAppear {
                    withAnimation(
                        .easeIn(duration: 1.6).delay(particle.delay)
                    ) {
                        drop = true
                    }
                    withAnimation(
                        .easeIn(duration: 0.5).delay(particle.delay + 1.1)
                    ) {
                        opacity = 0
                    }
                }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Bottom Navigation Bar

private struct BottomNavBar: View {
    @Binding var currentStep: HostStep
    let vm: HostGameViewModel
    let onPost: () -> Void

    private var canAdvanceFromFormat: Bool { vm.minSkill <= vm.maxSkill }
    private var canAdvanceFromTimeLocation: Bool { vm.selectedCourt != nil }
    private var canAdvanceFromVisibility: Bool { true }

    private var nextDisabled: Bool {
        switch currentStep {
        case .format:       return !canAdvanceFromFormat
        case .timeLocation: return !canAdvanceFromTimeLocation
        case .visibility:   return !canAdvanceFromVisibility
        case .review:       return !vm.canSubmit || vm.isLoading
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                if currentStep != .format {
                    Button {
                        HapticManager.light()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            currentStep = HostStep(rawValue: currentStep.rawValue - 1) ?? .format
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Back")
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(Color.dinkrNavy.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }

                if currentStep == .review {
                    Button(action: onPost) {
                        ZStack {
                            if vm.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                    Text("Publish Game")
                                        .fontWeight(.bold)
                                }
                                .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            vm.canSubmit
                                ? LinearGradient(
                                    colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.82)],
                                    startPoint: .leading, endPoint: .trailing
                                  )
                                : LinearGradient(
                                    colors: [Color.dinkrNavy.opacity(0.18), Color.dinkrNavy.opacity(0.13)],
                                    startPoint: .leading, endPoint: .trailing
                                  ),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .shadow(
                            color: vm.canSubmit ? Color.dinkrGreen.opacity(0.32) : .clear,
                            radius: 10, y: 4
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(nextDisabled)
                } else {
                    Button {
                        HapticManager.medium()
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                            currentStep = HostStep(rawValue: currentStep.rawValue + 1) ?? .review
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text("Next")
                                .fontWeight(.semibold)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            nextDisabled
                                ? Color.dinkrNavy.opacity(0.18)
                                : Color.dinkrGreen,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(nextDisabled)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
        }
    }
}

// MARK: - Toast View

private struct HostToastView: View {
    let message: String
    var isError: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "xmark.circle.fill" : "info.circle.fill")
                .foregroundStyle(isError ? Color.dinkrCoral : Color.dinkrSky)
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.dinkrNavy)
                .lineLimit(2)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.dinkrNavy.opacity(0.08), radius: 10, y: 4)
        .padding(.horizontal, 20)
    }
}

// MARK: - Section Header

private struct HostGameViewSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.dinkrGreen)
                .font(.system(size: 15))
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.dinkrNavy)
        }
    }
}

// MARK: - Preview

#Preview {
    HostGameView()
        .environment(AuthService())
}

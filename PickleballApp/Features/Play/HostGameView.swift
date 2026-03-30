import SwiftUI
import Observation

// MARK: - HostGameViewModel

@Observable
final class HostGameViewModel {
    var courtName: String = ""
    var courtId: String = ""
    var selectedFormat: GameFormat = .doubles
    var minSkill: SkillLevel = .intermediate30
    var maxSkill: SkillLevel = .advanced40
    var selectedDate: Date = {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.day = (components.day ?? 1) + 1
        components.hour = 10
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components) ?? Date().addingTimeInterval(86400)
    }()
    var totalSpots: Int = 4
    var fee: Double? = nil
    var notes: String = ""
    var isPublic: Bool = true
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var didPost: Bool = false

    // Fee input helper (separate from fee to allow empty string)
    var feeText: String = ""
    var isPaid: Bool = false

    var canSubmit: Bool {
        !courtName.trimmingCharacters(in: .whitespaces).isEmpty &&
        minSkill <= maxSkill
    }

    func submit(hostId: String, hostName: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let resolvedFee: Double? = isPaid ? Double(feeText) : nil

        let session = GameSession(
            id: UUID().uuidString,
            hostId: hostId,
            hostName: hostName,
            courtId: courtId.isEmpty ? UUID().uuidString : courtId,
            courtName: courtName.trimmingCharacters(in: .whitespaces),
            dateTime: selectedDate,
            format: selectedFormat,
            skillRange: minSkill...maxSkill,
            totalSpots: totalSpots,
            rsvps: [hostId],
            waitlist: [],
            isPublic: isPublic,
            notes: notes.trimmingCharacters(in: .whitespaces),
            fee: resolvedFee
        )

        try await FirestoreService.shared.setDocument(
            session,
            collection: FirestoreCollections.gameSessions,
            documentId: session.id
        )

        didPost = true
    }
}

// MARK: - Step Enum

private enum HostStep: Int, CaseIterable {
    case location = 0
    case details  = 1
    case review   = 2

    var title: String {
        switch self {
        case .location: return "Location"
        case .details:  return "Details"
        case .review:   return "Review"
        }
    }
}

// MARK: - HostGameView

struct HostGameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var auth

    @State private var vm = HostGameViewModel()
    @State private var currentStep: HostStep = .location
    @State private var showComingSoonToast: Bool = false

    private let recentCourts: [CourtVenue] = Array(CourtVenue.mockVenues.prefix(3))

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
                            case .location:
                                LocationStepView(vm: vm, recentCourts: recentCourts, showComingSoonToast: $showComingSoonToast)
                            case .details:
                                DetailsStepView(vm: vm)
                            case .review:
                                ReviewStepView(vm: vm)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100) // room for nav buttons
                    }
                }

                // Bottom navigation
                BottomNavBar(
                    currentStep: $currentStep,
                    vm: vm,
                    onPost: {
                        Task {
                            let hostId   = auth.currentUser?.id   ?? "preview_host"
                            let hostName = auth.currentUser?.displayName ?? "You"
                            do {
                                try await vm.submit(hostId: hostId, hostName: hostName)
                                HapticManager.success()
                                dismiss()
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
                if showComingSoonToast {
                    ToastView(message: "Map search coming soon 🗺️")
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }
            }
            .overlay(alignment: .top) {
                if let err = vm.errorMessage {
                    ToastView(message: err, isError: true)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showComingSoonToast)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.errorMessage)
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
                    // Dot
                    ZStack {
                        Circle()
                            .fill(dotBackground(for: step))
                            .frame(width: 32, height: 32)
                        if step.rawValue < currentStep.rawValue {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        } else {
                            Text("\(step.rawValue + 1)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(step == currentStep ? .white : Color.dinkrNavy.opacity(0.4))
                        }
                    }

                    // Label below handled via VStack wrapper
                    // Connecting line (not after last step)
                    if step != .review {
                        Rectangle()
                            .fill(step.rawValue < currentStep.rawValue ? Color.dinkrGreen : Color.dinkrNavy.opacity(0.15))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            // Labels row
            HStack {
                ForEach(HostStep.allCases, id: \.self) { step in
                    Text(step.title)
                        .font(.system(size: 10, weight: step == currentStep ? .semibold : .regular))
                        .foregroundStyle(step == currentStep ? Color.dinkrGreen : Color.dinkrNavy.opacity(0.45))
                        .frame(maxWidth: .infinity)
                }
            }
            .offset(y: 20)
        }
        .padding(.bottom, 16)
    }

    private func dotBackground(for step: HostStep) -> Color {
        if step == currentStep { return Color.dinkrGreen }
        if step.rawValue < currentStep.rawValue { return Color.dinkrGreen }
        return Color.dinkrNavy.opacity(0.12)
    }
}

// MARK: - Step 1: Location

private struct LocationStepView: View {
    @Bindable var vm: HostGameViewModel
    let recentCourts: [CourtVenue]
    @Binding var showComingSoonToast: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionHeader(title: "Where are you playing?", icon: "mappin.circle.fill")

            // Court name field
            VStack(alignment: .leading, spacing: 8) {
                Text("Court Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.dinkrNavy.opacity(0.7))

                TextField("e.g. Westside Pickleball Complex", text: $vm.courtName)
                    .font(.system(size: 17))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(vm.courtName.isEmpty ? Color.clear : Color.dinkrGreen.opacity(0.5), lineWidth: 1.5)
                    )
            }

            // Quick picks
            VStack(alignment: .leading, spacing: 10) {
                Text("Recent Courts")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.dinkrNavy.opacity(0.7))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(recentCourts) { court in
                            CourtChip(
                                name: court.name,
                                isSelected: vm.courtName == court.name
                            ) {
                                HapticManager.selection()
                                vm.courtName = court.name
                                vm.courtId   = court.id
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            // Map placeholder row
            Button {
                showComingSoonToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    showComingSoonToast = false
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.dinkrSky.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "map.fill")
                            .foregroundStyle(Color.dinkrSky)
                            .font(.system(size: 18))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Find on Map")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.dinkrNavy)
                        Text("Search nearby courts")
                            .font(.caption)
                            .foregroundStyle(Color.dinkrNavy.opacity(0.5))
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.dinkrSky)
                }
                .padding(14)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.dinkrSky.opacity(0.25), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }
}

private struct CourtChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .foregroundStyle(isSelected ? .white : Color.dinkrNavy)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.dinkrGreen : Color.cardBackground,
                    in: Capsule()
                )
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : Color.dinkrNavy.opacity(0.15), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 2: Details

private struct DetailsStepView: View {
    @Bindable var vm: HostGameViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {

            // Format
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Game Format", icon: "sportscourt.fill")
                FormatSegmentedPicker(selection: $vm.selectedFormat)
            }

            // Skill range
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Skill Range", icon: "chart.bar.fill")
                HStack(spacing: 14) {
                    SkillPicker(label: "Min", selection: $vm.minSkill)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(Color.dinkrNavy.opacity(0.35))
                        .font(.system(size: 13))
                    SkillPicker(label: "Max", selection: $vm.maxSkill)
                }

                if vm.minSkill > vm.maxSkill {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Min skill must be ≤ Max skill")
                    }
                    .font(.caption)
                    .foregroundStyle(Color.dinkrCoral)
                }
            }

            // Date & Time
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Date & Time", icon: "calendar.badge.clock")
                DatePicker(
                    "Date & Time",
                    selection: $vm.selectedDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(Color.dinkrGreen)
                .padding(12)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
            }

            // Spots
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Spots", icon: "person.3.fill")
                SpotsStepperView(totalSpots: $vm.totalSpots)
            }

            // Fee
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Entry Fee", icon: "dollarsign.circle.fill")
                FeeToggleView(isPaid: $vm.isPaid, feeText: $vm.feeText)
            }

            // Notes
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Notes", icon: "text.bubble.fill")
                NotesEditorView(notes: $vm.notes)
            }

            // Visibility
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Visibility", icon: "eye.fill")
                VisibilityToggleView(isPublic: $vm.isPublic)
            }
        }
        .padding(.top, 4)
    }
}

private struct FormatSegmentedPicker: View {
    @Binding var selection: GameFormat

    private let formats: [GameFormat] = [.singles, .doubles, .mixed, .openPlay]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(formats, id: \.self) { format in
                Button {
                    HapticManager.selection()
                    selection = format
                } label: {
                    Text(formatLabel(format))
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                        .foregroundStyle(selection == format ? .white : Color.dinkrNavy.opacity(0.6))
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            selection == format ? Color.dinkrGreen : Color.clear,
                            in: RoundedRectangle(cornerRadius: 9)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 13))
    }

    private func formatLabel(_ format: GameFormat) -> String {
        switch format {
        case .singles:    return "Singles"
        case .doubles:    return "Doubles"
        case .mixed:      return "Mixed"
        case .openPlay:   return "Open Play"
        case .round_robin: return "Round Robin"
        }
    }
}

private struct SkillPicker: View {
    let label: String
    @Binding var selection: SkillLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.dinkrNavy.opacity(0.55))

            Picker(label, selection: $selection) {
                ForEach(SkillLevel.allCases, id: \.self) { level in
                    Text(level.label).tag(level)
                }
            }
            .pickerStyle(.menu)
            .tint(Color.dinkrGreen)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.dinkrGreen.opacity(0.3), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SpotsStepperView: View {
    @Binding var totalSpots: Int

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(totalSpots) spots")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.dinkrNavy)

                Spacer()

                HStack(spacing: 0) {
                    Button {
                        HapticManager.light()
                        if totalSpots > 2 { totalSpots -= 1 }
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 36, height: 36)
                            .foregroundStyle(totalSpots > 2 ? Color.dinkrNavy : Color.dinkrNavy.opacity(0.3))
                    }
                    .buttonStyle(.plain)

                    Text("\(totalSpots)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.dinkrGreen)
                        .frame(width: 36)

                    Button {
                        HapticManager.light()
                        if totalSpots < 8 { totalSpots += 1 }
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 36, height: 36)
                            .foregroundStyle(totalSpots < 8 ? Color.dinkrNavy : Color.dinkrNavy.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 10))
            }

            // Dot row
            HStack(spacing: 6) {
                ForEach(0..<totalSpots, id: \.self) { index in
                    // Host always occupies first slot
                    Circle()
                        .fill(index == 0 ? Color.dinkrGreen : Color.dinkrGreen.opacity(0.2))
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(Color.dinkrGreen.opacity(0.5), lineWidth: 1)
                        )
                }
                Spacer()
            }
        }
        .padding(14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct FeeToggleView: View {
    @Binding var isPaid: Bool
    @Binding var feeText: String

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(isPaid ? "Paid Entry" : "Free to Join")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.dinkrNavy)
                Spacer()
                Toggle("", isOn: $isPaid)
                    .tint(Color.dinkrGreen)
                    .labelsHidden()
                    .onChange(of: isPaid) { _, _ in HapticManager.light() }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))

            if isPaid {
                HStack(spacing: 10) {
                    Text("$")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.dinkrAmber)
                    TextField("0.00", text: $feeText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 17))
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

private struct NotesEditorView: View {
    @Binding var notes: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            if notes.isEmpty {
                Text("Any special instructions...")
                    .foregroundStyle(Color.dinkrNavy.opacity(0.3))
                    .font(.system(size: 15))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $notes)
                .font(.system(size: 15))
                .frame(minHeight: 90)
                .padding(10)
                .scrollContentBackground(.hidden)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
        }
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct VisibilityToggleView: View {
    @Binding var isPublic: Bool

    var body: some View {
        HStack(spacing: 14) {
            Button {
                HapticManager.selection()
                isPublic = true
            } label: {
                VisibilityOptionTile(
                    title: "Public",
                    subtitle: "Anyone can find & join",
                    icon: "globe",
                    color: Color.dinkrGreen,
                    isSelected: isPublic
                )
            }
            .buttonStyle(.plain)

            Button {
                HapticManager.selection()
                isPublic = false
            } label: {
                VisibilityOptionTile(
                    title: "Friends Only",
                    subtitle: "Invite-only visibility",
                    icon: "person.2.fill",
                    color: Color.dinkrSky,
                    isSelected: !isPublic
                )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct VisibilityOptionTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(isSelected ? color : Color.dinkrNavy.opacity(0.4))
                    .font(.system(size: 16))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(color)
                        .font(.system(size: 14))
                }
            }
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? Color.dinkrNavy : Color.dinkrNavy.opacity(0.5))
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(Color.dinkrNavy.opacity(0.4))
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? color.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
    }
}

// MARK: - Step 3: Review

private struct ReviewStepView: View {
    let vm: HostGameViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Review Your Game", icon: "checkmark.seal.fill")

            // Summary card
            VStack(spacing: 0) {
                ReviewRow(icon: "mappin.circle.fill", color: Color.dinkrCoral,
                          label: "Court",
                          value: vm.courtName.isEmpty ? "No court selected" : vm.courtName)
                Divider().padding(.leading, 48)

                ReviewRow(icon: "sportscourt.fill", color: Color.dinkrGreen,
                          label: "Format",
                          value: formatLabel(vm.selectedFormat))
                Divider().padding(.leading, 48)

                ReviewRow(icon: "chart.bar.fill", color: Color.dinkrSky,
                          label: "Skill Range",
                          value: "\(vm.minSkill.label) – \(vm.maxSkill.label)")
                Divider().padding(.leading, 48)

                ReviewRow(icon: "calendar", color: Color.dinkrAmber,
                          label: "Date & Time",
                          value: vm.selectedDate.formatted(date: .abbreviated, time: .shortened))
                Divider().padding(.leading, 48)

                ReviewRow(icon: "person.3.fill", color: Color.dinkrNavy,
                          label: "Spots",
                          value: "\(vm.totalSpots) total")
                Divider().padding(.leading, 48)

                ReviewRow(icon: "dollarsign.circle.fill", color: Color.dinkrAmber,
                          label: "Fee",
                          value: feeDisplay)
                Divider().padding(.leading, 48)

                ReviewRow(icon: "eye.fill", color: Color.dinkrSky,
                          label: "Visibility",
                          value: vm.isPublic ? "Public" : "Friends Only")

                if !vm.notes.isEmpty {
                    Divider().padding(.leading, 48)
                    ReviewRow(icon: "text.bubble.fill", color: Color.dinkrNavy.opacity(0.6),
                              label: "Notes",
                              value: vm.notes)
                }
            }
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))

            // Map placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.dinkrSky.opacity(0.25), Color.dinkrGreen.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)

                VStack(spacing: 8) {
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.dinkrGreen.opacity(0.7))
                    Text("Austin, TX")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.dinkrNavy.opacity(0.7))
                }
            }

            // Estimated reach
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundStyle(Color.dinkrGreen)
                        .font(.system(size: 18))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Estimated Reach")
                        .font(.caption)
                        .foregroundStyle(Color.dinkrNavy.opacity(0.55))
                    Text("~\(estimatedReach) players match your skill range")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.dinkrNavy)
                }
            }
            .padding(14)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
        }
        .padding(.top, 4)
    }

    private var feeDisplay: String {
        guard vm.isPaid else { return "Free" }
        let amount = Double(vm.feeText) ?? 0.0
        return String(format: "$%.2f", amount)
    }

    private var estimatedReach: Int {
        // Simple heuristic: wider skill range = more players
        let levels = SkillLevel.allCases
        guard let minIdx = levels.firstIndex(of: vm.minSkill),
              let maxIdx = levels.firstIndex(of: vm.maxSkill) else { return 47 }
        let spread = maxIdx - minIdx + 1
        return spread * 12 + 11
    }

    private func formatLabel(_ format: GameFormat) -> String {
        switch format {
        case .singles:    return "Singles"
        case .doubles:    return "Doubles"
        case .mixed:      return "Mixed"
        case .openPlay:   return "Open Play"
        case .round_robin: return "Round Robin"
        }
    }
}

private struct ReviewRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 16))
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.dinkrNavy.opacity(0.55))
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.dinkrNavy)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Bottom Navigation Bar

private struct BottomNavBar: View {
    @Binding var currentStep: HostStep
    let vm: HostGameViewModel
    let onPost: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 16) {
                // Previous button
                if currentStep != .location {
                    Button {
                        HapticManager.light()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            currentStep = HostStep(rawValue: currentStep.rawValue - 1) ?? .location
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Previous")
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(Color.dinkrNavy.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }

                // Next / Post button
                if currentStep == .review {
                    Button(action: onPost) {
                        ZStack {
                            if vm.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                HStack(spacing: 6) {
                                    Text("Post Game")
                                        .fontWeight(.bold)
                                    Text("🏓")
                                }
                                .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            vm.canSubmit ? Color.dinkrGreen : Color.dinkrNavy.opacity(0.2),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!vm.canSubmit || vm.isLoading)
                } else {
                    Button {
                        HapticManager.medium()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
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
                        .padding(.vertical, 14)
                        .background(
                            (currentStep == .location && vm.courtName.isEmpty)
                                ? Color.dinkrNavy.opacity(0.2)
                                : Color.dinkrGreen,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(currentStep == .location && vm.courtName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
        }
    }
}

// MARK: - Toast View

private struct ToastView: View {
    let message: String
    var isError: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "xmark.circle.fill" : "info.circle.fill")
                .foregroundStyle(isError ? Color.dinkrCoral : Color.dinkrSky)
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
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

private struct SectionHeader: View {
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

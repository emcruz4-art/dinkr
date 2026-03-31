import SwiftUI

// MARK: - Create Event View Model

@Observable
final class CreateEventViewModel {
    // Step 1
    var selectedType: EventType? = nil
    var eventName: String = ""
    var eventDescription: String = ""

    // Step 2
    var eventDate: Date = Date().addingTimeInterval(86400 * 7)
    var duration: DurationOption = .twoHour
    var selectedCourt: CourtVenue? = nil
    var entryFeeEnabled: Bool = false
    var entryFeeAmount: String = ""
    var maxParticipants: Double = 32

    // Step 3
    var selectedSkillLevels: Set<SkillLevel> = []
    var equipmentProvided: Bool = false
    var refreshmentsProvided: Bool = false
    var prizeMoney: Bool = false
    var prizeAmount: String = ""
    var registrationDeadline: Date = Date().addingTimeInterval(86400 * 5)

    // Publishing state
    var isPublishing: Bool = false
    var isPublished: Bool = false

    enum DurationOption: String, CaseIterable {
        case twoHour = "2h"
        case fourHour = "4h"
        case fullDay = "Full Day"
    }

    var isStep1Valid: Bool {
        selectedType != nil && !eventName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var isStep2Valid: Bool {
        selectedCourt != nil
    }

    func publish() async {
        isPublishing = true
        try? await Task.sleep(for: .seconds(2))
        isPublishing = false
        isPublished = true
    }
}

// MARK: - Create Event View

struct CreateEventView: View {
    @State private var vm = CreateEventViewModel()
    @State private var currentStep: Int = 0
    @Environment(\.dismiss) private var dismiss

    private let steps = ["Basics", "When & Where", "Details", "Review"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if vm.isPublished {
                    PublishSuccessView(eventName: vm.eventName) {
                        dismiss()
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.85).combined(with: .opacity),
                        removal: .opacity
                    ))
                } else {
                    VStack(spacing: 0) {
                        // Progress dots
                        StepProgressDots(currentStep: currentStep, totalSteps: steps.count, labels: steps)
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 12)

                        // Step content in TabView
                        TabView(selection: $currentStep) {
                            Step1EventTypeBasics(vm: vm)
                                .tag(0)
                            Step2WhenWhere(vm: vm)
                                .tag(1)
                            Step3Details(vm: vm)
                                .tag(2)
                            Step4Review(vm: vm)
                                .tag(3)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .animation(.easeInOut(duration: 0.35), value: currentStep)

                        // Navigation buttons
                        StepNavBar(
                            currentStep: $currentStep,
                            totalSteps: steps.count,
                            canAdvance: canAdvanceFromCurrentStep,
                            isPublishing: vm.isPublishing
                        ) {
                            Task { await vm.publish() }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Host Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !vm.isPublished {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(Color.dinkrCoral)
                    }
                }
            }
        }
    }

    private var canAdvanceFromCurrentStep: Bool {
        switch currentStep {
        case 0: return vm.isStep1Valid
        case 1: return vm.isStep2Valid
        default: return true
        }
    }
}

// MARK: - Step Progress Dots

struct StepProgressDots: View {
    let currentStep: Int
    let totalSteps: Int
    let labels: [String]

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.dinkrGreen : Color.dinkrGreen.opacity(0.2))
                        .frame(width: index == currentStep ? 12 : 8, height: index == currentStep ? 12 : 8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)

                    if index < totalSteps - 1 {
                        Rectangle()
                            .fill(index < currentStep ? Color.dinkrGreen : Color.dinkrGreen.opacity(0.2))
                            .frame(height: 2)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 0) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Text(labels[index])
                        .font(.system(size: 10, weight: index == currentStep ? .bold : .regular))
                        .foregroundStyle(index == currentStep ? Color.dinkrGreen : Color.secondary.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .animation(.easeInOut(duration: 0.2), value: currentStep)
                }
            }
        }
    }
}

// MARK: - Step Nav Bar

struct StepNavBar: View {
    @Binding var currentStep: Int
    let totalSteps: Int
    let canAdvance: Bool
    let isPublishing: Bool
    let onPublish: () -> Void

    var isLastStep: Bool { currentStep == totalSteps - 1 }

    var body: some View {
        HStack(spacing: 12) {
            if currentStep > 0 {
                Button {
                    withAnimation { currentStep -= 1 }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.subheadline.weight(.semibold))
                        Text("Back")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Color.dinkrNavy)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.dinkrNavy.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if isLastStep {
                Button {
                    onPublish()
                } label: {
                    HStack(spacing: 8) {
                        if isPublishing {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.85)
                            Text("Publishing…")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.subheadline.weight(.bold))
                            Text("Publish Event")
                                .font(.subheadline.weight(.bold))
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.dinkrNavy, Color.dinkrGreen],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.dinkrGreen.opacity(0.4), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(isPublishing)
            } else {
                Button {
                    withAnimation { currentStep += 1 }
                } label: {
                    HStack(spacing: 6) {
                        Text("Next")
                            .font(.subheadline.weight(.bold))
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(
                        canAdvance
                            ? LinearGradient(colors: [Color.dinkrNavy, Color.dinkrGreen],
                                             startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color.secondary.opacity(0.3), Color.secondary.opacity(0.3)],
                                             startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                    .shadow(
                        color: canAdvance ? Color.dinkrGreen.opacity(0.3) : .clear,
                        radius: 6, y: 3
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canAdvance)
            }
        }
    }
}

// MARK: - Step 1: Event Type & Basics

struct Step1EventTypeBasics: View {
    @Bindable var vm: CreateEventViewModel

    private struct EventTypeOption {
        let type: EventType
        let label: String
        let icon: String
        let color: Color
    }

    private let typeOptions: [EventTypeOption] = [
        .init(type: .tournament,  label: "Tournament",   icon: "trophy.fill",          color: Color.dinkrCoral),
        .init(type: .clinic,      label: "Clinic",       icon: "figure.strengthtraining.traditional", color: Color.dinkrSky),
        .init(type: .openPlay,    label: "Open Play",    icon: "sportscourt.fill",     color: Color.dinkrGreen),
        .init(type: .social,      label: "Social",       icon: "person.3.fill",        color: Color.dinkrAmber),
        .init(type: .womenOnly,   label: "Women's Only", icon: "star.fill",            color: .pink),
        .init(type: .fundraiser,  label: "Fundraiser",   icon: "heart.fill",           color: .purple),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("What kind of event?")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.dinkrNavy)
                    Text("Choose a type to get started")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // Event type grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(typeOptions, id: \.type) { option in
                        EventTypeCard(
                            label: option.label,
                            icon: option.icon,
                            color: option.color,
                            isSelected: vm.selectedType == option.type
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                vm.selectedType = option.type
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Event name
                VStack(alignment: .leading, spacing: 8) {
                    Label("Event Name", systemImage: "pencil")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)

                    TextField("e.g. Sunday Social Mixer", text: $vm.eventName)
                        .padding(12)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(vm.eventName.isEmpty ? Color.secondary.opacity(0.2) : Color.dinkrGreen.opacity(0.5), lineWidth: 1.5)
                        )
                }
                .padding(.horizontal)

                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Label("Description", systemImage: "text.alignleft")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $vm.eventDescription)
                            .frame(minHeight: 96)
                            .padding(8)
                            .background(Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(vm.eventDescription.isEmpty ? Color.secondary.opacity(0.2) : Color.dinkrGreen.opacity(0.5), lineWidth: 1.5)
                            )

                        if vm.eventDescription.isEmpty {
                            Text("Tell players what to expect…")
                                .foregroundStyle(Color.secondary.opacity(0.5))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 80)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Event Type Card

struct EventTypeCard: View {
    let label: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : color.opacity(0.12))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : color)
                }

                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.dinkrNavy : Color.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 6)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.dinkrGreen : Color.clear, lineWidth: 2.5)
            )
            .shadow(
                color: isSelected ? Color.dinkrGreen.opacity(0.25) : .black.opacity(0.04),
                radius: isSelected ? 8 : 4, y: 3
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 2: When & Where

struct Step2WhenWhere: View {
    @Bindable var vm: CreateEventViewModel
    @State private var showCourtPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("When & Where")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.dinkrNavy)
                    Text("Set the time and location")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // Date picker
                VStack(alignment: .leading, spacing: 8) {
                    Label("Date & Time", systemImage: "calendar")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)
                        .padding(.horizontal)

                    DatePicker("", selection: $vm.eventDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .tint(Color.dinkrGreen)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                }

                // Duration chips
                VStack(alignment: .leading, spacing: 10) {
                    Label("Duration", systemImage: "clock.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)

                    HStack(spacing: 10) {
                        ForEach(CreateEventViewModel.DurationOption.allCases, id: \.self) { option in
                            DurationChip(
                                label: option.rawValue,
                                isSelected: vm.duration == option
                            ) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    vm.duration = option
                                }
                            }
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal)

                // Court selector
                VStack(alignment: .leading, spacing: 10) {
                    Label("Court / Venue", systemImage: "sportscourt.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)

                    VStack(spacing: 0) {
                        ForEach(CourtVenue.mockVenues) { court in
                            CourtSelectRow(
                                court: court,
                                isSelected: vm.selectedCourt?.id == court.id
                            ) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    vm.selectedCourt = vm.selectedCourt?.id == court.id ? nil : court
                                }
                            }

                            if court.id != CourtVenue.mockVenues.last?.id {
                                Divider()
                                    .padding(.leading, 56)
                            }
                        }
                    }
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(vm.selectedCourt != nil ? Color.dinkrGreen.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
                }
                .padding(.horizontal)

                // Entry fee
                VStack(alignment: .leading, spacing: 10) {
                    Label("Entry Fee", systemImage: "dollarsign.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)

                    VStack(spacing: 12) {
                        HStack {
                            Text("Charge entry fee")
                                .font(.subheadline)
                                .foregroundStyle(Color.dinkrNavy)
                            Spacer()
                            Toggle("", isOn: $vm.entryFeeEnabled)
                                .tint(Color.dinkrGreen)
                        }

                        if vm.entryFeeEnabled {
                            HStack {
                                Text("$")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(Color.dinkrGreen)
                                TextField("0.00", text: $vm.entryFeeAmount)
                                    .keyboardType(.decimalPad)
                                    .font(.title3.weight(.semibold))
                            }
                            .padding(12)
                            .background(Color.dinkrGreen.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.dinkrGreen.opacity(0.3), lineWidth: 1.5)
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(14)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)

                // Max participants slider
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Max Participants", systemImage: "person.3.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrNavy)
                        Spacer()
                        Text("\(Int(vm.maxParticipants))")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.dinkrGreen)
                            .monospacedDigit()
                    }

                    Slider(value: $vm.maxParticipants, in: 4...200, step: 4)
                        .tint(Color.dinkrGreen)

                    HStack {
                        Text("4")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("200")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                Spacer(minLength: 80)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Duration Chip

struct DurationChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : Color.dinkrNavy)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isSelected ? Color.dinkrGreen : Color.cardBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Color.dinkrGreen : Color.secondary.opacity(0.25), lineWidth: 1.5)
                )
                .shadow(color: isSelected ? Color.dinkrGreen.opacity(0.3) : .clear, radius: 5, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Court Select Row

struct CourtSelectRow: View {
    let court: CourtVenue
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.dinkrGreen : Color.dinkrSky.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: court.isIndoor ? "building.2.fill" : "sportscourt.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : Color.dinkrSky)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(court.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)
                    Text(court.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.dinkrGreen)
                        .font(.title3)
                }
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 3: Details

struct Step3Details: View {
    @Bindable var vm: CreateEventViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Event Details")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.dinkrNavy)
                    Text("Help players know what to expect")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // Skill level multi-select
                VStack(alignment: .leading, spacing: 10) {
                    Label("Skill Levels", systemImage: "chart.bar.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)

                    Text("Tap to include skill levels (all welcome if none selected)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    EventFlowLayout(spacing: 8) {
                        ForEach(SkillLevel.allCases, id: \.self) { level in
                            SkillLevelPill(
                                level: level,
                                isSelected: vm.selectedSkillLevels.contains(level)
                            ) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    if vm.selectedSkillLevels.contains(level) {
                                        vm.selectedSkillLevels.remove(level)
                                    } else {
                                        vm.selectedSkillLevels.insert(level)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Toggles card
                VStack(spacing: 0) {
                    DetailToggleRow(
                        icon: "tennis.racket",
                        label: "Equipment Provided",
                        sublabel: "Paddles and balls will be available",
                        color: Color.dinkrSky,
                        isOn: $vm.equipmentProvided
                    )
                    Divider().padding(.leading, 54)

                    DetailToggleRow(
                        icon: "fork.knife",
                        label: "Refreshments",
                        sublabel: "Food and/or drinks will be available",
                        color: Color.dinkrAmber,
                        isOn: $vm.refreshmentsProvided
                    )
                    Divider().padding(.leading, 54)

                    DetailToggleRow(
                        icon: "trophy.fill",
                        label: "Prize Money",
                        sublabel: "Cash or prizes for top finishers",
                        color: Color.dinkrCoral,
                        isOn: $vm.prizeMoney
                    )

                    if vm.prizeMoney {
                        HStack {
                            Text("$")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Color.dinkrCoral)
                            TextField("Prize amount or description", text: $vm.prizeAmount)
                                .font(.subheadline)
                        }
                        .padding(12)
                        .padding(.leading, 40)
                        .background(Color.dinkrCoral.opacity(0.06))
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                // Registration deadline
                VStack(alignment: .leading, spacing: 8) {
                    Label("Registration Deadline", systemImage: "calendar.badge.clock")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)

                    DatePicker(
                        "",
                        selection: $vm.registrationDeadline,
                        in: Date()...vm.eventDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .tint(Color.dinkrGreen)
                    .padding(12)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                // Cover photo placeholder
                VStack(alignment: .leading, spacing: 8) {
                    Label("Cover Photo", systemImage: "photo.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)

                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.secondary.opacity(0.1))
                            .frame(height: 140)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            )

                        VStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(Color.secondary.opacity(0.5))

                            Text("Add Cover Photo")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 80)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Skill Level Pill

struct SkillLevelPill: View {
    let level: SkillLevel
    let isSelected: Bool
    let action: () -> Void

    private var levelColor: Color {
        switch level {
        case .beginner20, .beginner25: return Color.dinkrGreen
        case .intermediate30, .intermediate35: return Color.dinkrSky
        case .advanced40, .advanced45: return Color.dinkrAmber
        case .pro50: return Color.dinkrCoral
        }
    }

    var body: some View {
        Button(action: action) {
            Text(level.rawValue)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isSelected ? .white : levelColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? levelColor : levelColor.opacity(0.12))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? levelColor : levelColor.opacity(0.4), lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Detail Toggle Row

struct DetailToggleRow: View {
    let icon: String
    let label: String
    let sublabel: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dinkrNavy)
                Text(sublabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(Color.dinkrGreen)
        }
        .padding(14)
    }
}

// MARK: - Flow Layout

private struct EventFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxY: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > containerWidth && x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxY = max(maxY, y + rowHeight)
        }

        return CGSize(width: containerWidth, height: maxY)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}

// MARK: - Step 4: Review & Publish

struct Step4Review: View {
    @Bindable var vm: CreateEventViewModel

    private var entryFeeDisplay: String {
        if !vm.entryFeeEnabled { return "Free" }
        let raw = Double(vm.entryFeeAmount) ?? 0
        return raw == 0 ? "Free" : "$\(vm.entryFeeAmount)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Review & Publish")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.dinkrNavy)
                    Text("Double-check everything before going live")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // Summary card
                VStack(spacing: 0) {

                    // Card banner
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(
                            colors: [Color.dinkrNavy, Color.dinkrGreen.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 100)
                        .clipShape(
                            .rect(topLeadingRadius: 20, bottomLeadingRadius: 0,
                                  bottomTrailingRadius: 0, topTrailingRadius: 20)
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            if let type = vm.selectedType {
                                Text(type.rawValue.capitalized)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.25))
                                    .clipShape(Capsule())
                            }

                            Text(vm.eventName.isEmpty ? "Unnamed Event" : vm.eventName)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                        }
                        .padding(16)
                    }

                    // Details rows
                    VStack(spacing: 0) {
                        EventReviewRow(icon: "calendar", color: Color.dinkrSky,
                                  label: "Date",
                                  value: vm.eventDate.formatted(.dateTime.weekday(.wide).month().day().hour().minute()))
                        Divider().padding(.leading, 44)

                        EventReviewRow(icon: "clock.fill", color: Color.dinkrAmber,
                                  label: "Duration",
                                  value: vm.duration.rawValue)
                        Divider().padding(.leading, 44)

                        EventReviewRow(icon: "mappin.circle.fill", color: Color.dinkrCoral,
                                  label: "Venue",
                                  value: vm.selectedCourt?.name ?? "—")
                        Divider().padding(.leading, 44)

                        EventReviewRow(icon: "dollarsign.circle.fill", color: Color.dinkrGreen,
                                  label: "Entry Fee",
                                  value: entryFeeDisplay)
                        Divider().padding(.leading, 44)

                        EventReviewRow(icon: "person.3.fill", color: Color.dinkrNavy,
                                  label: "Max Players",
                                  value: "\(Int(vm.maxParticipants))")
                        Divider().padding(.leading, 44)

                        EventReviewRow(
                            icon: "chart.bar.fill", color: Color.dinkrAmber,
                            label: "Skill Levels",
                            value: vm.selectedSkillLevels.isEmpty
                                ? "All Welcome"
                                : vm.selectedSkillLevels.sorted().map(\.rawValue).joined(separator: ", ")
                        )
                        Divider().padding(.leading, 44)

                        EventReviewRow(icon: "calendar.badge.clock", color: Color.dinkrSky,
                                  label: "Reg. Deadline",
                                  value: vm.registrationDeadline.formatted(.dateTime.month().day().hour().minute()))
                    }

                    // Amenities row
                    if vm.equipmentProvided || vm.refreshmentsProvided || vm.prizeMoney {
                        Divider().padding(.leading, 44)
                        HStack(alignment: .top, spacing: 10) {
                            ZStack {
                                Circle().fill(Color.dinkrGreen.opacity(0.12)).frame(width: 28, height: 28)
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.dinkrGreen)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Included")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 6) {
                                    if vm.equipmentProvided {
                                        AmenityBadge(label: "Equipment", color: Color.dinkrSky)
                                    }
                                    if vm.refreshmentsProvided {
                                        AmenityBadge(label: "Refreshments", color: Color.dinkrAmber)
                                    }
                                    if vm.prizeMoney {
                                        AmenityBadge(label: "Prize Money", color: Color.dinkrCoral)
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                    }

                    // Description preview
                    if !vm.eventDescription.isEmpty {
                        Divider().padding(.leading, 14)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(vm.eventDescription)
                                .font(.subheadline)
                                .foregroundStyle(Color.dinkrNavy)
                                .lineLimit(4)
                        }
                        .padding(14)
                    }
                }
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color.dinkrNavy.opacity(0.10), radius: 12, y: 6)
                .padding(.horizontal)

                // Notice
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Color.dinkrSky)
                    Text("Your event will be visible to all Dinkr players once published. You can edit or cancel it from your profile.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color.dinkrSky.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                Spacer(minLength: 80)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Review Row

private struct EventReviewRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
            }

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.dinkrNavy)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Amenity Badge

struct AmenityBadge: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - Publish Success View

struct PublishSuccessView: View {
    let eventName: String
    let onDone: () -> Void

    @State private var confettiParticles: [ConfettiParticle] = []
    @State private var showContent = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            // Confetti layer
            ForEach(confettiParticles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }

            VStack(spacing: 28) {
                Spacer()

                // Success icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.dinkrNavy, Color.dinkrGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.dinkrGreen.opacity(0.4), radius: 20, y: 8)

                    Image(systemName: "checkmark")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(showContent ? 1 : 0.4)
                .animation(.spring(response: 0.5, dampingFraction: 0.65), value: showContent)

                VStack(spacing: 8) {
                    Text("Event Published!")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(Color.dinkrNavy)

                    Text(eventName.isEmpty ? "Your event is live" : "\"\(eventName)\" is live")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)

                // Stats mini-card
                HStack(spacing: 20) {
                    SuccessStat(icon: "person.3.fill", color: Color.dinkrGreen, label: "Spots Available", value: "Open")
                    Divider().frame(height: 36)
                    SuccessStat(icon: "eye.fill", color: Color.dinkrSky, label: "Visibility", value: "All Players")
                    Divider().frame(height: 36)
                    SuccessStat(icon: "bell.fill", color: Color.dinkrAmber, label: "Notifications", value: "Sent")
                }
                .padding(16)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
                .padding(.horizontal, 24)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.35), value: showContent)

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        // Share stub
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.subheadline.weight(.bold))
                            Text("Share Event")
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.dinkrNavy, Color.dinkrGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)

                    Button {
                        onDone()
                    } label: {
                        Text("Done")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrNavy)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.dinkrNavy.opacity(0.08))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.5), value: showContent)

                Spacer()
            }
        }
        .onAppear {
            showContent = true
            spawnConfetti()
        }
    }

    private func spawnConfetti() {
        let colors: [Color] = [
            Color.dinkrGreen, Color.dinkrCoral, Color.dinkrAmber,
            Color.dinkrSky, Color.dinkrNavy, .white
        ]
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        for i in 0..<60 {
            let particle = ConfettiParticle(
                id: i,
                color: colors[i % colors.count],
                size: CGFloat.random(in: 5...12),
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: CGFloat.random(in: -50...screenHeight * 0.6)
                ),
                opacity: Double.random(in: 0.6...1.0)
            )
            confettiParticles.append(particle)
        }

        withAnimation(.easeOut(duration: 2.5)) {
            for i in confettiParticles.indices {
                confettiParticles[i].position.y += CGFloat.random(in: 200...500)
                confettiParticles[i].opacity = 0
            }
        }
    }
}

// MARK: - Confetti Particle

struct ConfettiParticle: Identifiable {
    let id: Int
    var color: Color
    var size: CGFloat
    var position: CGPoint
    var opacity: Double
}

// MARK: - Success Stat

struct SuccessStat: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.dinkrNavy)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    CreateEventView()
}

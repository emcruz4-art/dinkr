import SwiftUI

// MARK: - ViewModel

@Observable
final class TrainingViewModel {
    var selectedPlan: TrainingPlan?
    var completedDrillIds: Set<String> = []
    var todaysDrills: [Drill] = []
    var selectedCategory: DrillCategory?

    init() {
        todaysDrills = Array(Drill.mockDrills.shuffled().prefix(3))
    }

    var filteredDrills: [Drill] {
        guard let category = selectedCategory else { return Drill.mockDrills }
        return Drill.mockDrills.filter { $0.category == category }
    }

    var todaysTotalMinutes: Int {
        todaysDrills.reduce(0) { $0 + $1.durationMinutes }
    }

    var todaysCompletionFraction: Double {
        guard !todaysDrills.isEmpty else { return 0 }
        let done = todaysDrills.filter { completedDrillIds.contains($0.id) }.count
        return Double(done) / Double(todaysDrills.count)
    }

    func toggleComplete(drill: Drill) {
        if completedDrillIds.contains(drill.id) {
            completedDrillIds.remove(drill.id)
        } else {
            completedDrillIds.insert(drill.id)
        }
    }

    func activatePlan(_ plan: TrainingPlan) {
        selectedPlan = (selectedPlan?.id == plan.id) ? nil : plan
    }

    func planButtonLabel(for plan: TrainingPlan) -> String {
        guard let active = selectedPlan else { return "Start Plan" }
        return active.id == plan.id ? "Active ✓" : "Start Plan"
    }

    func planProgress(for plan: TrainingPlan) -> Double {
        let done = plan.drillIds.filter { completedDrillIds.contains($0) }.count
        return plan.drillIds.isEmpty ? 0 : Double(done) / Double(plan.drillIds.count)
    }
}

// MARK: - TrainingView

struct TrainingView: View {
    @State private var viewModel = TrainingViewModel()
    @State private var showWalkthrough = false
    @State private var selectedDrill: Drill?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    TodaysSessionCard(
                        viewModel: viewModel,
                        onStart: { showWalkthrough = true }
                    )
                    .padding(.horizontal)

                    trainingPlansSection

                    drillLibrarySection
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color.appBackground)
            .navigationTitle("Training")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showWalkthrough) {
            DrillWalkthroughSheet(drills: viewModel.todaysDrills, viewModel: viewModel)
        }
        .sheet(item: $selectedDrill) { drill in
            DrillDetailSheet(drill: drill, viewModel: viewModel)
        }
    }

    // MARK: Training Plans Section

    private var trainingPlansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Plans")
                .font(.title3.weight(.bold))
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(TrainingPlan.mockPlans) { plan in
                        TrainingPlanCard(plan: plan, viewModel: viewModel)
                            .frame(width: 230)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: Drill Library Section

    private var drillLibrarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Drill Library")
                .font(.title3.weight(.bold))
                .padding(.horizontal)

            categoryFilterRow

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(viewModel.filteredDrills) { drill in
                    DrillCard(drill: drill, isCompleted: viewModel.completedDrillIds.contains(drill.id))
                        .onTapGesture { selectedDrill = drill }
                }
            }
            .padding(.horizontal)
        }
    }

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    label: "All",
                    color: Color.dinkrGreen,
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    viewModel.selectedCategory = nil
                }

                ForEach(DrillCategory.allCases, id: \.self) { cat in
                    CategoryChip(
                        label: cat.rawValue,
                        color: cat.color,
                        isSelected: viewModel.selectedCategory == cat
                    ) {
                        viewModel.selectedCategory = viewModel.selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 2)
        }
    }
}

// MARK: - TodaysSessionCard

struct TodaysSessionCard: View {
    let viewModel: TrainingViewModel
    let onStart: () -> Void

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date())
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background gradient
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color.dinkrNavy, Color.dinkrNavy.opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Decorative ring behind content
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 40)
                .frame(width: 220, height: 220)
                .offset(x: 60, y: -60)

            VStack(alignment: .leading, spacing: 16) {
                // Header row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TODAY'S TRAINING")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(Color.dinkrGreen)
                            .tracking(1.2)
                        Text(dateString)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    completionRing
                }

                // Drill chips
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(viewModel.todaysTotalMinutes) min total")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.6))

                    HStack(spacing: 8) {
                        ForEach(viewModel.todaysDrills) { drill in
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(drill.category.color)
                                    .frame(width: 6, height: 6)
                                Text(drill.focusArea)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.white.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }

                // Start button
                Button(action: onStart) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Start Session")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(Color.dinkrNavy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.dinkrGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
    }

    private var completionRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 6)
                .frame(width: 52, height: 52)

            Circle()
                .trim(from: 0, to: viewModel.todaysCompletionFraction)
                .stroke(Color.dinkrGreen, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 52, height: 52)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: viewModel.todaysCompletionFraction)

            VStack(spacing: 0) {
                Text("\(Int(viewModel.todaysCompletionFraction * 100))")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(.white)
                Text("%")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}

// MARK: - TrainingPlanCard

struct TrainingPlanCard: View {
    let plan: TrainingPlan
    let viewModel: TrainingViewModel
    @State private var pulseActive = false

    private var isActive: Bool { viewModel.selectedPlan?.id == plan.id }
    private var progress: Double { viewModel.planProgress(for: plan) }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient background
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: plan.colorGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 190)

            // Decorative icon watermark
            Image(systemName: plan.badge)
                .font(.system(size: 80))
                .foregroundStyle(.white.opacity(0.08))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.trailing, 12)
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 10) {
                // Level badge
                Text(plan.level.uppercased())
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())

                // Plan name
                Text(plan.name)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                // Stats row
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(plan.durationWeeks) wks · \(plan.sessionsPerWeek)x/week")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                    Text("\(plan.totalDrills) drills")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }

                // Progress bar (shown if active plan)
                if isActive {
                    VStack(alignment: .leading, spacing: 4) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.white.opacity(0.2))
                                    .frame(height: 5)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white)
                                    .frame(width: geo.size.width * progress, height: 5)
                                    .animation(.easeInOut, value: progress)
                            }
                        }
                        .frame(height: 5)
                        Text("\(Int(progress * 100))% complete")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                // Action button
                Button {
                    viewModel.activatePlan(plan)
                } label: {
                    Text(viewModel.planButtonLabel(for: plan))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isActive ? .white : plan.colorGradient.first ?? Color.dinkrGreen)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(isActive ? Color.white.opacity(0.25) : Color.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isActive ? Color.dinkrGreen : Color.clear,
                    lineWidth: isActive ? 3 : 0
                )
                .scaleEffect(pulseActive ? 1.03 : 1.0)
                .opacity(isActive ? 1 : 0)
                .animation(
                    isActive
                        ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                        : .default,
                    value: pulseActive
                )
        )
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
        .onAppear {
            if isActive { pulseActive = true }
        }
        .onChange(of: isActive) { _, newValue in
            pulseActive = newValue
        }
    }
}

// MARK: - DrillCard

struct DrillCard: View {
    let drill: Drill
    let isCompleted: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 0) {
                // Category accent bar
                Rectangle()
                    .fill(drill.category.color)
                    .frame(width: 4)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 2)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    // Difficulty badge
                    Text(drill.difficulty)
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(difficultyColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(difficultyColor.opacity(0.15))
                        .clipShape(Capsule())

                    Text(drill.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(drill.durationMinutes) min")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Text(drill.focusArea)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(drill.category.color)
                        .lineLimit(1)
                }
                .padding(12)
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)

            // Checkmark overlay
            if isCompleted {
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen)
                        .frame(width: 24, height: 24)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.white)
                }
                .padding(8)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: isCompleted)
    }

    private var difficultyColor: Color {
        switch drill.difficulty {
        case "Beginner":     return Color.dinkrGreen
        case "Intermediate": return Color.dinkrAmber
        case "Advanced":     return Color.dinkrCoral
        default:             return Color.dinkrSky
        }
    }
}

// MARK: - CategoryChip

private struct CategoryChip: View {
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? color : color.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - DrillDetailSheet

struct DrillDetailSheet: View {
    let drill: Drill
    let viewModel: TrainingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showCheckmark = false

    private var isCompleted: Bool { viewModel.completedDrillIds.contains(drill.id) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // ── Header card ──────────────────────────────────────
                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [drill.category.color, drill.category.color.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 140)

                        Image(systemName: drill.category.icon)
                            .font(.system(size: 70))
                            .foregroundStyle(.white.opacity(0.1))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding()

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                // Category badge
                                Text(drill.category.rawValue)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 4)
                                    .background(.white.opacity(0.2))
                                    .clipShape(Capsule())

                                // Difficulty badge
                                Text(drill.difficulty)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(drill.category.color)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 4)
                                    .background(Color.white)
                                    .clipShape(Capsule())

                                // Duration
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.fill")
                                        .font(.caption2)
                                    Text("\(drill.durationMinutes) min")
                                        .font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(.white.opacity(0.85))
                            }

                            Text(drill.name)
                                .font(.title2.weight(.heavy))
                                .foregroundStyle(.white)
                        }
                        .padding(16)
                    }
                    .padding(.horizontal)

                    // ── Description ───────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text(drill.description)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal)

                    // ── Reps / Sets badge ─────────────────────────────────
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Image(systemName: "repeat.circle.fill")
                                .font(.title2)
                                .foregroundStyle(drill.category.color)
                            Text(drill.repsOrSets)
                                .font(.headline.weight(.heavy))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                            Text("REPS / SETS")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(.secondary)
                                .tracking(1)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(drill.category.color.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        Spacer()
                    }
                    .padding(.horizontal)

                    // ── Focus area chip ───────────────────────────────────
                    HStack {
                        Image(systemName: "scope")
                            .foregroundStyle(drill.category.color)
                        Text("Focus: ")
                            .font(.subheadline.weight(.semibold))
                        Text(drill.focusArea)
                            .font(.subheadline)
                            .foregroundStyle(drill.category.color)
                    }
                    .padding(.horizontal)

                    // ── How to do it ──────────────────────────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How to Do It")
                            .font(.title3.weight(.bold))
                            .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(drill.tips.enumerated()), id: \.offset) { index, tip in
                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(drill.category.color)
                                            .frame(width: 24, height: 24)
                                        Text("\(index + 1)")
                                            .font(.system(size: 11, weight: .heavy))
                                            .foregroundStyle(.white)
                                    }
                                    Text(tip)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // ── Action buttons ────────────────────────────────────
                    VStack(spacing: 12) {
                        Button {
                            withAnimation(.spring(duration: 0.4)) {
                                viewModel.toggleComplete(drill: drill)
                                showCheckmark = !viewModel.completedDrillIds.contains(drill.id) == false
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.headline)
                                Text(isCompleted ? "Completed!" : "Mark Complete")
                                    .font(.subheadline.weight(.bold))
                            }
                            .foregroundStyle(isCompleted ? .white : Color.dinkrGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isCompleted ? Color.dinkrGreen : Color.dinkrGreen.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .animation(.spring(duration: 0.35), value: isCompleted)
                        }
                        .buttonStyle(.plain)

                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle")
                                Text("Add to Today")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(Color.dinkrSky)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.dinkrSky.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
                .padding(.top, 8)
            }
            .background(Color.appBackground)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .tint(Color.dinkrGreen)
                }
            }
        }
    }
}

// MARK: - DrillWalkthroughSheet

struct DrillWalkthroughSheet: View {
    let drills: [Drill]
    let viewModel: TrainingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex = 0
    @State private var showBurst = false

    private var currentDrill: Drill { drills[currentIndex] }
    private var isLast: Bool { currentIndex == drills.count - 1 }
    private var progressFraction: Double {
        drills.isEmpty ? 0 : Double(currentIndex + 1) / Double(drills.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Progress bar ──────────────────────────────────────
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.15))
                                .frame(height: 4)
                            Rectangle()
                                .fill(Color.dinkrGreen)
                                .frame(width: geo.size.width * progressFraction, height: 4)
                                .animation(.easeInOut(duration: 0.3), value: progressFraction)
                        }
                    }
                    .frame(height: 4)

                    ScrollView {
                        VStack(spacing: 20) {

                            // ── Step indicator ────────────────────────────
                            HStack {
                                Text("Drill \(currentIndex + 1) of \(drills.count)")
                                    .font(.caption.weight(.heavy))
                                    .foregroundStyle(.secondary)
                                    .tracking(0.5)
                                Spacer()
                                Text("\(currentDrill.durationMinutes) min")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.dinkrGreen)
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)

                            // ── Drill header ──────────────────────────────
                            ZStack(alignment: .bottomLeading) {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        LinearGradient(
                                            colors: [currentDrill.category.color, currentDrill.category.color.opacity(0.65)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 180)

                                Image(systemName: currentDrill.category.icon)
                                    .font(.system(size: 90))
                                    .foregroundStyle(.white.opacity(0.09))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                    .padding()

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(currentDrill.category.rawValue.uppercased())
                                        .font(.system(size: 10, weight: .heavy))
                                        .foregroundStyle(.white.opacity(0.75))
                                        .tracking(1.2)
                                    Text(currentDrill.name)
                                        .font(.title2.weight(.heavy))
                                        .foregroundStyle(.white)
                                    Text(currentDrill.focusArea)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                                .padding(20)
                            }
                            .padding(.horizontal)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            .id(currentDrill.id)

                            // ── Description ───────────────────────────────
                            Text(currentDrill.description)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal)

                            // ── Reps badge ────────────────────────────────
                            HStack {
                                Spacer()
                                VStack(spacing: 4) {
                                    Text(currentDrill.repsOrSets)
                                        .font(.headline.weight(.heavy))
                                    Text("REPS / SETS")
                                        .font(.system(size: 9, weight: .heavy))
                                        .foregroundStyle(.secondary)
                                        .tracking(1)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(currentDrill.category.color.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                Spacer()
                            }
                            .padding(.horizontal)

                            // ── Tips ──────────────────────────────────────
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Key Tips")
                                    .font(.subheadline.weight(.bold))

                                ForEach(Array(currentDrill.tips.prefix(3).enumerated()), id: \.offset) { index, tip in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "\(index + 1).circle.fill")
                                            .foregroundStyle(currentDrill.category.color)
                                            .font(.subheadline)
                                        Text(tip)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 120)
                    }

                    // ── Navigation bar ────────────────────────────────────
                    VStack(spacing: 0) {
                        Divider()
                        HStack(spacing: 12) {
                            if currentIndex > 0 {
                                Button {
                                    withAnimation(.spring(duration: 0.35)) {
                                        currentIndex -= 1
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "chevron.left")
                                        Text("Previous")
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.dinkrNavy)
                                    .padding(.vertical, 14)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                            }

                            if isLast {
                                Button {
                                    withAnimation {
                                        showBurst = true
                                        for drill in drills {
                                            viewModel.completedDrillIds.insert(drill.id)
                                        }
                                    }
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        dismiss()
                                    }
                                } label: {
                                    Text("Complete All 🎉")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 14)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.dinkrGreen)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button {
                                    withAnimation(.spring(duration: 0.35)) {
                                        viewModel.completedDrillIds.insert(currentDrill.id)
                                        currentIndex += 1
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    HStack(spacing: 6) {
                                        Text("Next")
                                        Image(systemName: "chevron.right")
                                    }
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 14)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.dinkrGreen)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Color.appBackground)
                    }
                }

                // ── Confetti-style emoji burst ────────────────────────────
                if showBurst {
                    EmojiConfettiBurst()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .tint(Color.dinkrGreen)
                }
            }
        }
    }
}

// MARK: - EmojiConfettiBurst

private struct EmojiConfettiBurst: View {
    @State private var animate = false

    private let emojis = ["🎉", "🏆", "🎊", "⭐️", "🔥", "💪", "🥒", "🎯"]

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Session Complete!")
                    .font(.title.weight(.heavy))
                    .foregroundStyle(.white)

                Text("Great work today 💚")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))

                ZStack {
                    ForEach(0..<emojis.count, id: \.self) { i in
                        let angle = Double(i) / Double(emojis.count) * 360.0
                        let radius: CGFloat = animate ? 120 : 0

                        Text(emojis[i])
                            .font(.system(size: 32))
                            .offset(
                                x: radius * cos(angle * .pi / 180),
                                y: radius * sin(angle * .pi / 180)
                            )
                            .opacity(animate ? 1 : 0)
                            .scaleEffect(animate ? 1.2 : 0.2)
                            .animation(
                                .spring(duration: 0.6).delay(Double(i) * 0.05),
                                value: animate
                            )
                    }

                    Text("🏅")
                        .font(.system(size: 64))
                        .scaleEffect(animate ? 1.0 : 0.3)
                        .animation(.spring(duration: 0.5), value: animate)
                }
                .frame(width: 260, height: 260)
            }
        }
        .onAppear { animate = true }
    }
}

// MARK: - Preview

#Preview {
    TrainingView()
}

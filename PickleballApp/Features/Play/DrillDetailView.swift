import SwiftUI

struct DrillDetailView: View {
    let drill: Drill
    let allDrills: [Drill]

    @State private var addedToPlan = false
    @State private var logSessionPresented = false
    @Environment(\.dismiss) private var dismiss

    private var relatedDrills: [Drill] {
        allDrills.filter { drill.relatedDrillNames.contains($0.name) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Hero Header
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [Color.dinkrNavy, drill.category.color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 220)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            CategoryBadge(category: drill.category, small: false, inverted: true)
                            DifficultyBadge(difficulty: drill.difficulty)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Capsule())
                            Spacer()
                        }
                        Text(drill.name)
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(3)
                    }
                    .padding(24)
                }

                // MARK: Stats Row
                HStack(spacing: 0) {
                    StatPill(icon: "clock.fill", value: "\(drill.duration) min", label: "Duration", color: Color.dinkrSky)
                    Divider().frame(height: 36)
                    StatPill(icon: drill.playerCount.icon, value: drill.playerCount.rawValue, label: "Format", color: Color.dinkrAmber)
                    Divider().frame(height: 36)
                    StatPill(icon: "chart.bar.fill", value: drill.difficulty.rawValue, label: "Level", color: drill.difficulty.color)
                }
                .padding(.vertical, 14)
                .background(Color.cardBackground)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(Color.secondary.opacity(0.1)),
                    alignment: .bottom
                )

                VStack(alignment: .leading, spacing: 24) {

                    // MARK: Description
                    VStack(alignment: .leading, spacing: 8) {
                        DrillSectionHeader(icon: "text.alignleft", title: "About This Drill")
                        Text(drill.description)
                            .font(.body)
                            .foregroundStyle(Color.primary.opacity(0.85))
                            .lineSpacing(4)
                    }

                    Divider()

                    // MARK: How to Execute
                    VStack(alignment: .leading, spacing: 12) {
                        DrillSectionHeader(icon: "list.number", title: "How to Execute")
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(drill.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.dinkrGreen)
                                            .frame(width: 26, height: 26)
                                        Text("\(index + 1)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                    Text(step)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.primary.opacity(0.85))
                                        .lineSpacing(3)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    Divider()

                    // MARK: Tips
                    VStack(alignment: .leading, spacing: 12) {
                        DrillSectionHeader(icon: "lightbulb.fill", title: "Pro Tips")
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(drill.tips.enumerated()), id: \.offset) { _, tip in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(Color.dinkrGreen)
                                        .padding(.top, 1)
                                    Text(tip)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.primary.opacity(0.85))
                                        .lineSpacing(3)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    Divider()

                    // MARK: Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            HapticManager.success()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                addedToPlan = true
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: addedToPlan ? "checkmark.circle.fill" : "plus.circle.fill")
                                    .font(.system(size: 17, weight: .semibold))
                                Text(addedToPlan ? "Added to Practice Plan" : "Add to My Practice Plan")
                                    .font(.subheadline.weight(.bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(addedToPlan ? Color.dinkrGreen.opacity(0.75) : Color.dinkrGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .disabled(addedToPlan)

                        Button {
                            logSessionPresented = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "pencil.and.list.clipboard")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Log Practice Session")
                                    .font(.subheadline.weight(.bold))
                            }
                            .foregroundStyle(Color.dinkrNavy)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Color.dinkrNavy.opacity(0.6), lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // MARK: Related Drills
                    if !relatedDrills.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            DrillSectionHeader(icon: "rectangle.grid.1x2.fill", title: "Related Drills")

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(relatedDrills) { related in
                                        NavigationLink(destination: DrillDetailView(drill: related, allDrills: allDrills)) {
                                            RelatedDrillCard(drill: related)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 1)
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(Color.appBackground)
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $logSessionPresented) {
            LogPracticeSessionSheet(drill: drill)
        }
    }
}

// MARK: - Supporting Views

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.primary)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DrillSectionHeader: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.dinkrGreen)
            Text(title)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(.secondary)
        }
    }
}

struct RelatedDrillCard: View {
    let drill: Drill

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CategoryBadge(category: drill.category, small: true, inverted: false)

            Text(drill.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Label("\(drill.duration)m", systemImage: "clock")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.secondary)
                Spacer()
                DifficultyBadge(difficulty: drill.difficulty)
            }
        }
        .padding(12)
        .frame(width: 155, height: 120, alignment: .topLeading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Log Practice Session Sheet

struct LogPracticeSessionSheet: View {
    let drill: Drill
    @Environment(\.dismiss) private var dismiss
    @State private var duration = 15.0
    @State private var notes = ""
    @State private var rating = 3

    var body: some View {
        NavigationStack {
            Form {
                Section("Drill") {
                    HStack {
                        CategoryBadge(category: drill.category)
                        Text(drill.name)
                            .font(.headline)
                    }
                }

                Section("Session Duration") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(Int(duration)) minutes")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen)
                        Slider(value: $duration, in: 5...90, step: 5)
                            .tint(Color.dinkrGreen)
                    }
                }

                Section("How did it go?") {
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundStyle(star <= rating ? Color.dinkrAmber : Color.secondary.opacity(0.3))
                                .onTapGesture { rating = star }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Notes") {
                    TextField("How did the drill feel? What to improve?", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        HapticManager.success()
                        dismiss()
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    NavigationStack {
        DrillDetailView(drill: Drill.allDrills[0], allDrills: Drill.allDrills)
    }
}

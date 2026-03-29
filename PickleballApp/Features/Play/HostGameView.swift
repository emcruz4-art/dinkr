import SwiftUI

struct HostGameView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var courtName = ""
    @State private var selectedDate = Date().addingTimeInterval(86400)
    @State private var selectedFormat: GameFormat = .doubles
    @State private var totalSpots = 4
    @State private var minSkill: SkillLevel = .intermediate30
    @State private var maxSkill: SkillLevel = .advanced40
    @State private var notes = ""
    @State private var isPublic = true
    @State private var isPosting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    TextField("Court or venue name", text: $courtName)
                }

                Section("When") {
                    DatePicker("Date & Time", selection: $selectedDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                }

                Section("Game Details") {
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(GameFormat.allCases, id: \.self) { fmt in
                            Text(fmt.rawValue).tag(fmt)
                        }
                    }
                    Stepper("Total spots: \(totalSpots)", value: $totalSpots, in: 2...24)
                    Toggle("Public (visible to everyone)", isOn: $isPublic)
                }

                Section("Skill Level") {
                    Picker("Minimum", selection: $minSkill) {
                        ForEach(SkillLevel.allCases, id: \.self) { level in
                            Text(level.label).tag(level)
                        }
                    }
                    Picker("Maximum", selection: $maxSkill) {
                        ForEach(SkillLevel.allCases, id: \.self) { level in
                            Text(level.label).tag(level)
                        }
                    }
                }

                Section("Notes (optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Host a Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        isPosting = true
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            isPosting = false
                            dismiss()
                        }
                    }
                    .disabled(courtName.isEmpty || isPosting)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    HostGameView()
}

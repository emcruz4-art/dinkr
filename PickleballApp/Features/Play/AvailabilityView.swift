import SwiftUI

struct AvailabilityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var availableDays: Set<Int> = [3, 6, 0] // Wed, Sat, Sun
    @State private var preferredFormat: GameFormat? = .doubles
    @State private var minSkill = SkillLevel.intermediate30
    @State private var maxSkill = SkillLevel.advanced40
    @State private var notifyOnOpen = true
    @State private var notifyOnInvite = true
    @State private var maxDistance = 5.0

    let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Available Days") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(0..<7, id: \.self) { day in
                            Button {
                                if availableDays.contains(day) {
                                    availableDays.remove(day)
                                } else {
                                    availableDays.insert(day)
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Text(dayNames[day])
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(availableDays.contains(day) ? .white : .secondary)
                                    Circle()
                                        .fill(availableDays.contains(day) ? Color.dinkrGreen : Color.secondary.opacity(0.2))
                                        .frame(width: 8, height: 8)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(availableDays.contains(day) ? Color.dinkrGreen : Color.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Preferred Format") {
                    Picker("Format", selection: $preferredFormat) {
                        Text("Any").tag(Optional<GameFormat>.none)
                        ForEach(GameFormat.allCases, id: \.self) { format in
                            Text(format.rawValue.capitalized).tag(Optional(format))
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Max Distance") {
                    HStack {
                        Text("Within \(Int(maxDistance)) miles")
                        Slider(value: $maxDistance, in: 1...25, step: 1)
                            .tint(Color.dinkrGreen)
                    }
                }

                Section("Notifications") {
                    Toggle("Ping me when a session opens", isOn: $notifyOnOpen)
                        .tint(Color.dinkrGreen)
                    Toggle("Ping me for direct invites", isOn: $notifyOnInvite)
                        .tint(Color.dinkrGreen)
                }
            }
            .navigationTitle("My Availability")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
    }
}

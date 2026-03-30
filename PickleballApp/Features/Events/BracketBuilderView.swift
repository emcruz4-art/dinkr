import SwiftUI

// MARK: - BracketBuilderView

struct BracketBuilderView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var eventName: String = ""
    @State private var selectedFormat: BracketFormat = .singleElimination
    @State private var participantCount: Int = 8
    @State private var step: Int = 1
    @State private var generatedBracket: Bracket? = nil

    private let countOptions = [4, 8, 16, 32]

    var body: some View {
        NavigationStack {
            ZStack {
                if step == 1 {
                    setupStep
                } else {
                    previewStep
                }
            }
            .navigationTitle(step == 1 ? "Create Bracket" : "Preview Bracket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Step 1: Setup

    private var setupStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Event name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Event Name")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.secondary)
                    TextField("e.g. Austin Open Singles", text: $eventName)
                        .padding(12)
                        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 10))
                }

                // Format picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Format")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.secondary)

                    ForEach(BracketFormat.allCases, id: \.self) { format in
                        formatCard(format)
                    }
                }

                // Participant count
                VStack(alignment: .leading, spacing: 10) {
                    Text("Participant Count")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.secondary)

                    HStack(spacing: 10) {
                        ForEach(countOptions, id: \.self) { count in
                            Button {
                                participantCount = count
                            } label: {
                                Text("\(count)")
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        participantCount == count
                                            ? Color.dinkrGreen
                                            : Color.cardBackground,
                                        in: RoundedRectangle(cornerRadius: 10)
                                    )
                                    .foregroundStyle(
                                        participantCount == count ? Color.white : Color.primary
                                    )
                                    .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Generate button
                Button {
                    generateBracket()
                } label: {
                    Label("Generate Bracket", systemImage: "arrow.right.circle.fill")
                }
                .primaryButton()
                .disabled(eventName.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(eventName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)

                Spacer(minLength: 32)
            }
            .padding()
        }
        .background(Color.appBackground.ignoresSafeArea())
    }

    @ViewBuilder
    private func formatCard(_ format: BracketFormat) -> some View {
        let isSelected = selectedFormat == format
        Button {
            selectedFormat = format
        } label: {
            HStack(spacing: 14) {
                Image(systemName: format.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Color.dinkrGreen : Color.secondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(format.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? Color.primary : Color.primary)
                    Text(format.description)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? Color.dinkrGreen : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 2: Preview

    private var previewStep: some View {
        VStack(spacing: 0) {
            if let bracket = generatedBracket {
                // Embedded bracket scroll (reuse BracketView layout without full NavigationStack)
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Format badge
                        HStack {
                            Label(bracket.format.rawValue, systemImage: bracket.format.icon)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.dinkrGreen)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.dinkrGreen.opacity(0.12), in: Capsule())
                            Spacer()
                        }
                        .padding(.horizontal)

                        // Bracket columns
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 0) {
                                ForEach(Array(bracket.rounds.enumerated()), id: \.offset) { idx, roundMatches in
                                    let roundNum = idx + 1
                                    let isLast = roundNum == bracket.rounds.count

                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(bracket.roundLabel(for: roundNum))
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(Color.secondary)
                                            .frame(width: 160, alignment: .center)

                                        ForEach(roundMatches) { match in
                                            BracketMatchCard(match: match)
                                        }
                                    }
                                    .padding(.leading, idx == 0 ? 16 : 0)

                                    if !isLast {
                                        Rectangle()
                                            .fill(Color.secondary.opacity(0.3))
                                            .frame(width: 20, height: 1)
                                            .padding(.top, 56)
                                    }
                                }
                            }
                            .padding(.trailing, 16)
                            .padding(.bottom, 8)
                        }

                        // Participants summary
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(bracket.participants.count) Participants")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal)
                            ForEach(bracket.participants.prefix(6)) { p in
                                HStack {
                                    Text("#\(p.seed)")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.dinkrGreen)
                                        .frame(width: 28, alignment: .trailing)
                                    Text(p.displayName)
                                        .font(.subheadline)
                                    Spacer()
                                    Text(p.skillLevel.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)
                                }
                                .padding(.horizontal)
                            }
                            if bracket.participants.count > 6 {
                                Text("+ \(bracket.participants.count - 6) more")
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                                    .padding(.horizontal)
                            }
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.vertical)
                }
            }

            // Bottom action buttons
            VStack(spacing: 12) {
                Button {
                    publishBracket()
                } label: {
                    Label("Publish Bracket", systemImage: "checkmark.seal.fill")
                }
                .primaryButton()

                Button {
                    step = 1
                } label: {
                    Text("Back — Adjust Settings")
                }
                .secondaryButton()
            }
            .padding()
            .background(
                Color.appBackground
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: -2)
            )
        }
        .background(Color.appBackground.ignoresSafeArea())
    }

    // MARK: - Actions

    private func generateBracket() {
        let mockParticipants = User.mockPlayers.prefix(participantCount).enumerated().map { idx, user in
            BracketParticipant(
                id: user.id,
                displayName: user.displayName,
                skillLevel: user.skillLevel,
                seed: idx + 1,
                duprRating: user.duprRating
            )
        }
        generatedBracket = Bracket.generateSingleElimination(
            eventId: UUID().uuidString,
            eventName: eventName.trimmingCharacters(in: .whitespaces),
            participants: Array(mockParticipants)
        )
        withAnimation { step = 2 }
    }

    private func publishBracket() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    BracketBuilderView()
}

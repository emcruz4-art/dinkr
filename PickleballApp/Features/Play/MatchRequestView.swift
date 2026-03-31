import SwiftUI

// MARK: - Match Format

private enum MatchFormat: String, CaseIterable {
    case singles = "Singles"
    case doubles = "Doubles"
}

// MARK: - MatchRequestView

struct MatchRequestView: View {
    let opponent: User
    @Environment(\.dismiss) private var dismiss

    @State private var step: Int = 1
    @State private var selectedFormat: MatchFormat = .singles
    @State private var matchDate: Date = Date().addingTimeInterval(86400)
    @State private var selectedCourt: String = "Austin Tennis & Pickleball Center"
    @State private var message: String = ""
    @State private var checkmarkScale: CGFloat = 0

    private let courts = [
        "Austin Tennis & Pickleball Center",
        "Mueller Lake Park Courts",
        "Auditorium Shores Courts",
        "Millennium Youth Complex"
    ]

    private let maxMessageLength = 200

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Step indicator
                    if step < 3 {
                        StepIndicator(current: step, total: 2)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                    }

                    // Content
                    ZStack {
                        if step == 1 {
                            Step1View(
                                opponent: opponent,
                                selectedFormat: $selectedFormat,
                                matchDate: $matchDate,
                                selectedCourt: $selectedCourt,
                                courts: courts,
                                onNext: { step = 2 }
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        } else if step == 2 {
                            Step2View(
                                opponent: opponent,
                                format: selectedFormat,
                                matchDate: matchDate,
                                court: selectedCourt,
                                message: $message,
                                maxLength: maxMessageLength,
                                onSend: {
                                    HapticManager.medium()
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                                        step = 3
                                    }
                                    withAnimation(.spring(response: 0.55, dampingFraction: 0.6).delay(0.15)) {
                                        checkmarkScale = 1
                                    }
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        } else {
                            Step3View(
                                opponentFirstName: opponent.displayName.components(separatedBy: " ").first ?? opponent.displayName,
                                checkmarkScale: $checkmarkScale,
                                onDone: { dismiss() }
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.28), value: step)
                }
            }
            .navigationTitle(step == 3 ? "" : "Challenge \(opponent.displayName.components(separatedBy: " ").first ?? opponent.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if step < 3 {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(.secondary)
                    }
                    if step == 2 {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.28)) { step = 1 }
                            } label: {
                                Label("Back", systemImage: "chevron.left")
                                    .labelStyle(.iconOnly)
                            }
                            .foregroundStyle(Color.dinkrGreen)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Step Indicator

private struct StepIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...total, id: \.self) { i in
                Capsule()
                    .fill(i <= current ? Color.dinkrGreen : Color.secondary.opacity(0.2))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: current)
            }
        }
    }
}

// MARK: - Step 1: Match Setup

private struct Step1View: View {
    let opponent: User
    @Binding var selectedFormat: MatchFormat
    @Binding var matchDate: Date
    @Binding var selectedCourt: String
    let courts: [String]
    let onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Opponent header
                OpponentHeaderView(opponent: opponent)
                    .padding(.top, 8)

                // Format picker
                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel(title: "Format")
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(MatchFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 20)

                // Date/time picker
                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel(title: "Date & Time")
                    DatePicker(
                        "Match Date",
                        selection: $matchDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .tint(Color.dinkrGreen)
                    .labelsHidden()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)

                // Court selector
                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel(title: "Court")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(courts, id: \.self) { court in
                                CourtChip(
                                    name: court,
                                    isSelected: selectedCourt == court,
                                    onTap: {
                                        HapticManager.selection()
                                        selectedCourt = court
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 2)
                    }
                }

                // Next button
                Button(action: {
                    HapticManager.light()
                    withAnimation(.easeInOut(duration: 0.28)) { onNext() }
                }) {
                    HStack {
                        Text("Next")
                            .font(.headline)
                        Image(systemName: "arrow.right")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Step 2: Message

private struct Step2View: View {
    let opponent: User
    let format: MatchFormat
    let matchDate: Date
    let court: String
    @Binding var message: String
    let maxLength: Int
    let onSend: () -> Void

    @FocusState private var isEditorFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Match summary recap card
                MatchSummaryCard(
                    opponent: opponent,
                    format: format,
                    matchDate: matchDate,
                    court: court
                )
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Message editor
                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel(title: "Add a Message")
                    ZStack(alignment: .topLeading) {
                        if message.isEmpty {
                            Text("Bring your A game! 🏓")
                                .foregroundStyle(Color.secondary.opacity(0.6))
                                .font(.body)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $message)
                            .focused($isEditorFocused)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(minHeight: 110)
                            .onChange(of: message) { _, newValue in
                                if newValue.count > maxLength {
                                    message = String(newValue.prefix(maxLength))
                                }
                            }
                    }
                    .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isEditorFocused ? Color.dinkrGreen.opacity(0.5) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
                    .animation(.easeInOut(duration: 0.2), value: isEditorFocused)

                    HStack {
                        Spacer()
                        Text("\(message.count)/\(maxLength)")
                            .font(.caption2)
                            .foregroundStyle(message.count >= maxLength ? Color.dinkrCoral : Color.secondary)
                    }
                }
                .padding(.horizontal, 20)

                // Send button
                Button(action: onSend) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.headline)
                        Text("Send Challenge")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.dinkrGreen, Color.dinkrSky.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Step 3: Confirmation

private struct Step3View: View {
    let opponentFirstName: String
    @Binding var checkmarkScale: CGFloat
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Animated checkmark
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.12))
                    .frame(width: 120, height: 120)
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.2))
                    .frame(width: 96, height: 96)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.dinkrGreen)
            }
            .scaleEffect(checkmarkScale)

            VStack(spacing: 10) {
                Text("Challenge Sent!")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)

                Text("We'll notify \(opponentFirstName) when she accepts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            Button(action: onDone) {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Opponent Header

private struct OpponentHeaderView: View {
    let opponent: User

    var body: some View {
        VStack(spacing: 14) {
            AvatarView(urlString: opponent.avatarURL, displayName: opponent.displayName, size: 72)
                .overlay(Circle().stroke(Color.dinkrGreen.opacity(0.4), lineWidth: 2))

            VStack(spacing: 6) {
                Text(opponent.displayName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                SkillBadge(level: opponent.skillLevel)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                colors: [Color.dinkrNavy.opacity(0.06), Color.dinkrGreen.opacity(0.04)],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Match Summary Card

private struct MatchSummaryCard: View {
    let opponent: User
    let format: MatchFormat
    let matchDate: Date
    let court: String

    private var formattedDate: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: matchDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tinted header band
            HStack(spacing: 10) {
                AvatarView(urlString: opponent.avatarURL, displayName: opponent.displayName, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text("vs \(opponent.displayName)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    SkillBadge(level: opponent.skillLevel, compact: true)
                }
                Spacer()
                Text(format.rawValue)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2), in: Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color.dinkrNavy, Color.dinkrNavy.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )

            // Details rows
            VStack(spacing: 0) {
                SummaryRow(icon: "calendar", label: formattedDate)
                Divider().padding(.leading, 38)
                SummaryRow(icon: "mappin.circle.fill", label: court)
            }
            .padding(.vertical, 4)
            .background(Color.dinkrNavy.opacity(0.05))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.dinkrGreen.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Summary Row

private struct SummaryRow: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.dinkrGreen)
                .frame(width: 22)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Court Chip

private struct CourtChip: View {
    let name: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(name)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.dinkrGreen : Color.cardBackground,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.clear : Color.secondary.opacity(0.25),
                            lineWidth: 1
                        )
                )
                .animation(.easeInOut(duration: 0.18), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Label

private struct SectionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

// MARK: - Preview

#Preview {
    MatchRequestView(opponent: User.mockPlayers[0])
}

import SwiftUI

// MARK: - NewChallengeView

struct NewChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0

    // Step state
    @State private var selectedOpponent: User? = nil
    @State private var selectedType: ChallengeType? = nil
    @State private var goalValue: Double = 10
    @State private var durationIndex = 1 // 0=3d, 1=1w, 2=2w, 3=30d
    @State private var isPublic = true
    @State private var trashTalk = ""

    private let durations: [(String, Int)] = [
        ("3 days", 3), ("1 week", 7), ("2 weeks", 14), ("30 days", 30)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Step indicator
                    StepIndicator(current: step, total: 4)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 20)

                    // Step content
                    ZStack {
                        if step == 0 {
                            ChooseOpponentStep(selected: $selectedOpponent)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        } else if step == 1 {
                            ChooseChallengeTypeStep(selected: $selectedType)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        } else if step == 2 {
                            if let type = selectedType {
                                SetTermsStep(
                                    type: type,
                                    goalValue: $goalValue,
                                    durationIndex: $durationIndex,
                                    isPublic: $isPublic,
                                    trashTalk: $trashTalk,
                                    durations: durations
                                )
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            }
                        } else {
                            if let opponent = selectedOpponent, let type = selectedType {
                                PreviewSendStep(
                                    opponent: opponent,
                                    type: type,
                                    goalValue: goalValue,
                                    duration: durations[durationIndex],
                                    isPublic: isPublic,
                                    trashTalk: trashTalk,
                                    onSend: {
                                        HapticManager.medium()
                                        dismiss()
                                    }
                                )
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            }
                        }
                    }
                    .animation(.spring(response: 0.38, dampingFraction: 0.82), value: step)

                    Spacer()

                    // Navigation buttons
                    HStack(spacing: 16) {
                        if step > 0 {
                            Button {
                                HapticManager.selection()
                                withAnimation { step -= 1 }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Back")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .foregroundStyle(Color.dinkrNavy)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }

                        if step < 3 {
                            Button {
                                HapticManager.selection()
                                withAnimation { step += 1 }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(step == 2 ? "Preview" : "Next")
                                        .font(.subheadline.weight(.semibold))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(nextEnabled ? Color.dinkrGreen : Color.secondary.opacity(0.4))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                            .disabled(!nextEnabled)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.dinkrCoral)
                }
            }
        }
    }

    private var stepTitle: String {
        switch step {
        case 0: return "Choose Opponent"
        case 1: return "Choose Type"
        case 2: return "Set Terms"
        default: return "Preview"
        }
    }

    private var nextEnabled: Bool {
        switch step {
        case 0: return selectedOpponent != nil
        case 1: return selectedType != nil
        case 2: return true
        default: return true
        }
    }
}

// MARK: - Step Indicator

private struct StepIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i <= current ? Color.dinkrGreen : Color.secondary.opacity(0.2))
                    .frame(height: 4)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: current)
            }
        }
    }
}

// MARK: - Step 0: Choose Opponent

private struct ChooseOpponentStep: View {
    @Binding var selected: User?
    @State private var searchText = ""

    private var candidates: [User] { User.mockPlayers }
    private var filtered: [User] {
        if searchText.isEmpty { return candidates }
        return candidates.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Who do you want to challenge?")
                .font(.headline)
                .padding(.horizontal, 20)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search friends...", text: $searchText)
                    .font(.subheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filtered) { user in
                        Button {
                            HapticManager.selection()
                            selected = user
                        } label: {
                            HStack(spacing: 12) {
                                AvatarView(urlString: user.avatarURL, displayName: user.displayName, size: 44)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.displayName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.dinkrNavy)
                                    Text("@\(user.username)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if selected?.id == user.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(Color.dinkrGreen)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.horizontal, 20)
                    }
                }
            }
        }
    }
}

// MARK: - Step 1: Choose Challenge Type

private struct ChooseChallengeTypeStep: View {
    @Binding var selected: ChallengeType?

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What kind of challenge?")
                .font(.headline)
                .padding(.horizontal, 20)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(ChallengeType.allCases, id: \.self) { type in
                        ChallengeTypeCard(type: type, isSelected: selected == type) {
                            HapticManager.selection()
                            selected = type
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

private struct ChallengeTypeCard: View {
    let type: ChallengeType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(type.brandColor.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: type.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(type.brandColor)
                }

                Text(type.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dinkrNavy)

                Text(type.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? type.brandColor : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? type.brandColor.opacity(0.2) : .black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
    }
}

// MARK: - Step 2: Set Terms

private struct SetTermsStep: View {
    let type: ChallengeType
    @Binding var goalValue: Double
    @Binding var durationIndex: Int
    @Binding var isPublic: Bool
    @Binding var trashTalk: String
    let durations: [(String, Int)]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Goal value
                VStack(alignment: .leading, spacing: 12) {
                    Text("GOAL")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .tracking(1)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Target value")
                                .font(.subheadline)
                            Text(type.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(Int(goalValue))")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(type.brandColor)
                            .frame(minWidth: 40)
                        Stepper("", value: $goalValue, in: 1...1000, step: 1)
                            .labelsHidden()
                    }
                    .padding(14)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)

                // Duration
                VStack(alignment: .leading, spacing: 12) {
                    Text("DURATION")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .tracking(1)

                    HStack(spacing: 8) {
                        ForEach(durations.indices, id: \.self) { i in
                            Button {
                                HapticManager.selection()
                                durationIndex = i
                            } label: {
                                Text(durations[i].0)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(durationIndex == i ? .white : Color.dinkrNavy)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(durationIndex == i ? Color.dinkrGreen : Color.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: durationIndex)
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Public / Private
                VStack(alignment: .leading, spacing: 12) {
                    Text("VISIBILITY")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .tracking(1)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Public Challenge")
                                .font(.subheadline.weight(.semibold))
                            Text("Visible in activity feed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $isPublic)
                            .tint(Color.dinkrGreen)
                            .labelsHidden()
                    }
                    .padding(14)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)

                // Trash talk
                VStack(alignment: .leading, spacing: 12) {
                    Text("TRASH TALK (OPTIONAL)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .tracking(1)

                    TextField("Say something spicy...", text: $trashTalk, axis: .vertical)
                        .font(.subheadline)
                        .lineLimit(3, reservesSpace: true)
                        .padding(14)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Step 3: Preview & Send

private struct PreviewSendStep: View {
    let opponent: User
    let type: ChallengeType
    let goalValue: Double
    let duration: (String, Int)
    let isPublic: Bool
    let trashTalk: String
    let onSend: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Challenge Preview")
                    .font(.headline)
                    .padding(.horizontal, 20)

                // Preview card
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(type.brandColor.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: type.icon)
                                .font(.system(size: 20))
                                .foregroundStyle(type.brandColor)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.rawValue)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.dinkrNavy)
                            Text(type.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    HStack {
                        Label("\(Int(goalValue)) goal", systemImage: "target")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Label(duration.0, systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Label(isPublic ? "Public" : "Private", systemImage: isPublic ? "globe" : "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !trashTalk.isEmpty {
                        Text("\"\(trashTalk)\"")
                            .font(.subheadline.italic())
                            .foregroundStyle(Color.dinkrAmber)
                            .padding(10)
                            .background(Color.dinkrAmber.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    HStack(spacing: 12) {
                        AvatarView(urlString: nil, displayName: "Alex Rivera", size: 38)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("You")
                                .font(.subheadline.weight(.semibold))
                            Text("@pickleking")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.left.arrow.right")
                            .foregroundStyle(type.brandColor)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(opponent.displayName)
                                .font(.subheadline.weight(.semibold))
                            Text("@\(opponent.username)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        AvatarView(urlString: opponent.avatarURL, displayName: opponent.displayName, size: 38)
                    }
                }
                .padding(16)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(type.brandColor.opacity(0.18), lineWidth: 1))
                .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)
                .padding(.horizontal, 20)

                // Send button
                Button(action: onSend) {
                    HStack(spacing: 10) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18))
                        Text("Send Challenge")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [type.brandColor, type.brandColor.opacity(0.82)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: type.brandColor.opacity(0.4), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    NewChallengeView()
        .environment(AuthService())
}

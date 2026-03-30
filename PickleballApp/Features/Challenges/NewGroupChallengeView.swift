import SwiftUI

// MARK: - NewGroupChallengeView

struct NewGroupChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0

    @State private var selectedGroup: Group? = nil
    @State private var selectedMetric: GroupChallengeMetric? = nil
    @State private var durationIndex = 1    // 0=1 week, 1=2 weeks, 2=1 month
    @State private var stakes = ""

    private let durations: [(String, Int)] = [
        ("1 Week", 7), ("2 Weeks", 14), ("1 Month", 30)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Step indicator
                    GroupChallengeStepIndicator(current: step, total: 3)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 20)

                    // Step content
                    ZStack {
                        if step == 0 {
                            PickOpponentGroupStep(selected: $selectedGroup)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        } else if step == 1 {
                            PickMetricAndTermsStep(
                                selectedMetric: $selectedMetric,
                                durationIndex: $durationIndex,
                                stakes: $stakes,
                                durations: durations
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        } else {
                            if let group = selectedGroup, let metric = selectedMetric {
                                GroupChallengePreviewStep(
                                    opponentGroup: group,
                                    metric: metric,
                                    duration: durations[durationIndex],
                                    stakes: stakes,
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

                        if step < 2 {
                            Button {
                                HapticManager.selection()
                                withAnimation { step += 1 }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(step == 1 ? "Preview" : "Next")
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
        case 0: return "Pick Opponent Group"
        case 1: return "Set Challenge Terms"
        default: return "Preview"
        }
    }

    private var nextEnabled: Bool {
        switch step {
        case 0: return selectedGroup != nil
        case 1: return selectedMetric != nil
        default: return true
        }
    }
}

// MARK: - Step Indicator

private struct GroupChallengeStepIndicator: View {
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

// MARK: - Step 1: Pick Opponent Group

private struct PickOpponentGroupStep: View {
    @Binding var selected: Group?
    @State private var searchText = ""

    private var filtered: [Group] {
        if searchText.isEmpty { return Group.mockGroups }
        return Group.mockGroups.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Which group do you want to challenge?")
                .font(.headline)
                .padding(.horizontal, 20)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search groups...", text: $searchText)
                    .font(.subheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filtered) { group in
                        Button {
                            HapticManager.selection()
                            selected = group
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.dinkrGreen.opacity(0.12))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "person.3.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Color.dinkrGreen)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(group.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.dinkrNavy)
                                    Text("\(group.memberCount) members · \(group.isPrivate ? "Private" : "Public")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if selected?.id == group.id {
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

// MARK: - Step 2: Pick Metric + Terms

private struct PickMetricAndTermsStep: View {
    @Binding var selectedMetric: GroupChallengeMetric?
    @Binding var durationIndex: Int
    @Binding var stakes: String
    let durations: [(String, Int)]

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Metric grid
                VStack(alignment: .leading, spacing: 12) {
                    Text("WHAT ARE YOU COMPETING ON?")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .tracking(1)
                        .padding(.horizontal, 20)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(GroupChallengeMetric.allCases, id: \.self) { metric in
                            GroupMetricCard(metric: metric, isSelected: selectedMetric == metric) {
                                HapticManager.selection()
                                selectedMetric = metric
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Duration
                VStack(alignment: .leading, spacing: 12) {
                    Text("DURATION")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .tracking(1)
                        .padding(.horizontal, 20)

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
                    .padding(.horizontal, 20)
                }

                // Stakes
                VStack(alignment: .leading, spacing: 12) {
                    Text("STAKES (OPTIONAL)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .tracking(1)
                        .padding(.horizontal, 20)

                    TextField("e.g. Winning group gets bragging rights 🏆", text: $stakes, axis: .vertical)
                        .font(.subheadline)
                        .lineLimit(3, reservesSpace: true)
                        .padding(14)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 20)
        }
    }
}

private struct GroupMetricCard: View {
    let metric: GroupChallengeMetric
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.dinkrGreen.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: metric.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.dinkrGreen)
                }

                Text(metric.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dinkrNavy)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.dinkrGreen : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? Color.dinkrGreen.opacity(0.2) : .black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
    }
}

// MARK: - Step 3: Preview & Send

private struct GroupChallengePreviewStep: View {
    let opponentGroup: Group
    let metric: GroupChallengeMetric
    let duration: (String, Int)
    let stakes: String
    let onSend: () -> Void

    // Current user's group (stubbed as South Austin Dinkers)
    private let myGroup = Group.mockGroups[0]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Challenge Preview")
                    .font(.headline)
                    .padding(.horizontal, 20)

                // Preview card
                VStack(alignment: .leading, spacing: 16) {

                    // Metric header
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.dinkrGreen.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: metric.icon)
                                .font(.system(size: 20))
                                .foregroundStyle(Color.dinkrGreen)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Group Challenge")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.dinkrNavy)
                            Text(metric.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    // Meta row
                    HStack {
                        Label(duration.0, systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Label("Aggregate Score", systemImage: "chart.bar.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Stakes
                    if !stakes.isEmpty {
                        Text("\"\(stakes)\"")
                            .font(.subheadline.italic())
                            .foregroundStyle(Color.dinkrAmber)
                            .padding(10)
                            .background(Color.dinkrAmber.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Groups vs row
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(myGroup.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.dinkrNavy)
                                .lineLimit(2)
                            Text("\(myGroup.memberCount) members")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "arrow.left.arrow.right")
                            .foregroundStyle(Color.dinkrGreen)
                            .font(.system(size: 16))

                        VStack(alignment: .trailing, spacing: 3) {
                            Text(opponentGroup.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.dinkrNavy)
                                .multilineTextAlignment(.trailing)
                                .lineLimit(2)
                            Text("\(opponentGroup.memberCount) members")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(16)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.dinkrGreen.opacity(0.18), lineWidth: 1))
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
                            colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.82)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.dinkrGreen.opacity(0.4), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    NewGroupChallengeView()
        .environment(AuthService())
}

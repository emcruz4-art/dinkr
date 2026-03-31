import SwiftUI

// MARK: - TournamentRegistrationView

struct TournamentRegistrationView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0

    // Step 1 — Division
    @State private var selectedDivision: TournamentDivision? = nil
    @State private var selectedAgeBracket: AgeBracket = .open

    // Step 2 — Skill Bracket
    @State private var selectedSkillBracket: SkillBracket? = nil

    // Step 3 — Partner
    @State private var partnerSearch = ""
    @State private var selectedPartner: User? = nil

    // Step 4 — Confirm
    @State private var waiverAccepted = false
    @State private var registrationComplete = false

    private var isDoublesSelected: Bool {
        guard let div = selectedDivision else { return false }
        return div.isDoubles
    }

    private var totalSteps: Int { isDoublesSelected ? 4 : 4 }

    private var filteredPartners: [User] {
        if partnerSearch.isEmpty { return User.mockPlayers }
        return User.mockPlayers.filter {
            $0.displayName.localizedCaseInsensitiveContains(partnerSearch)
            || $0.username.localizedCaseInsensitiveContains(partnerSearch)
        }
    }

    private var canProceedStep1: Bool { selectedDivision != nil }
    private var canProceedStep2: Bool { selectedSkillBracket != nil }
    private var canProceedStep3: Bool { !isDoublesSelected || selectedPartner != nil }

    private var entryFeeFormatted: String {
        guard let fee = event.entryFee else { return "Free" }
        return String(format: "$%.0f", fee)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if registrationComplete {
                    successView
                        .transition(.scale.combined(with: .opacity))
                } else {
                    VStack(spacing: 0) {
                        stepIndicator
                            .padding(.top, 8)
                            .padding(.bottom, 20)

                        TabView(selection: $currentStep) {
                            step1Division.tag(0)
                            step2Skill.tag(1)
                            step3Partner.tag(2)
                            step4Confirm.tag(3)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .animation(.spring(response: 0.38, dampingFraction: 0.8), value: currentStep)
                    }
                }
            }
            .navigationTitle("Tournament Registration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if currentStep == 0 && !registrationComplete {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(Color.dinkrGreen)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentStep > 0 && !registrationComplete {
                        Button {
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                                currentStep -= 1
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.subheadline.weight(.semibold))
                                Text("Back")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(Color.dinkrGreen)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(i == currentStep ? Color.dinkrGreen : Color.secondary.opacity(0.25))
                    .frame(width: i == currentStep ? 28 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
            }
        }
    }

    // MARK: - Step 1: Division

    private var step1Division: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("Choose\nYour Division")
                    .font(.system(size: 28, weight: .black, design: .rounded))

                // Event Header Card
                eventHeaderCard

                // Division Grid
                VStack(alignment: .leading, spacing: 12) {
                    Text("Division")
                        .font(.headline)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(TournamentDivision.allCases, id: \.self) { division in
                            DivisionCard(
                                division: division,
                                isSelected: selectedDivision == division
                            ) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    selectedDivision = division
                                    // Reset partner if switching to singles
                                    if !division.isDoubles {
                                        selectedPartner = nil
                                    }
                                }
                            }
                        }
                    }
                }

                // Age Bracket
                VStack(alignment: .leading, spacing: 12) {
                    Text("Age Bracket")
                        .font(.headline)
                    Text("Optional — leave at Open if unsure")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        ForEach(AgeBracket.allCases, id: \.self) { bracket in
                            Button {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    selectedAgeBracket = bracket
                                }
                            } label: {
                                Text(bracket.label)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(selectedAgeBracket == bracket ? .white : Color.primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedAgeBracket == bracket
                                        ? Color.dinkrGreen
                                        : Color.cardBackground,
                                        in: RoundedRectangle(cornerRadius: 10)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(
                                                selectedAgeBracket == bracket ? Color.clear : Color.secondary.opacity(0.2),
                                                lineWidth: 1
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                }

                nextButton(label: "Next →", enabled: canProceedStep1) {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                        currentStep = 1
                    }
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Step 2: Skill Bracket

    private var step2Skill: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Select Your\nSkill Bracket")
                    .font(.system(size: 28, weight: .black, design: .rounded))

                // DUPR chip
                if let dupr = User.mockCurrentUser.duprRating {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.dinkrAmber)
                        Text("Your DUPR Rating")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.2f", dupr))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.dinkrAmber)
                    }
                    .padding(14)
                    .background(Color.dinkrAmber.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }

                // Recommendation banner
                HStack(spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(Color.dinkrSky)
                    Text("We recommend **3.5–4.0** based on your DUPR")
                        .font(.subheadline)
                        .foregroundStyle(Color.primary)
                }
                .padding(14)
                .background(Color.dinkrSky.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

                // Skill bracket cards
                VStack(spacing: 12) {
                    ForEach(SkillBracket.allCases, id: \.self) { bracket in
                        SkillBracketCard(
                            bracket: bracket,
                            isSelected: selectedSkillBracket == bracket
                        ) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                selectedSkillBracket = bracket
                            }
                        }
                    }
                }

                nextButton(label: "Next →", enabled: canProceedStep2) {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                        currentStep = 2
                    }
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Step 3: Partner

    private var step3Partner: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if isDoublesSelected {
                    Text("Find Your\nPartner")
                        .font(.system(size: 28, weight: .black, design: .rounded))

                    // Selected partner confirmation row
                    if let partner = selectedPartner {
                        PartnerConfirmationRow(partner: partner) {
                            withAnimation { selectedPartner = nil }
                        }
                    }

                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search players...", text: $partnerSearch)
                    }
                    .padding(12)
                    .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))

                    // Player list
                    VStack(spacing: 8) {
                        ForEach(filteredPartners) { player in
                            PartnerPickerRow(
                                player: player,
                                isSelected: selectedPartner?.id == player.id
                            ) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    selectedPartner = player
                                }
                            }
                        }
                    }

                    // Next / Skip buttons
                    VStack(spacing: 10) {
                        nextButton(label: "Next →", enabled: canProceedStep3) {
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                                currentStep = 3
                            }
                        }
                    }
                    .padding(.bottom, 32)
                } else {
                    // Singles — skip partner step
                    VStack(spacing: 20) {
                        Spacer(minLength: 40)
                        Image(systemName: "person.fill.checkmark")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.dinkrGreen)
                        Text("Singles Division")
                            .font(.title2.weight(.bold))
                        Text("No partner needed for singles events.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer(minLength: 20)
                        nextButton(label: "Continue to Review →", enabled: true) {
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                                currentStep = 3
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Step 4: Confirm & Pay

    private var step4Confirm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Review &\nComplete")
                    .font(.system(size: 28, weight: .black, design: .rounded))

                // Registration summary card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Registration Summary")
                        .font(.headline)

                    Divider()

                    summaryRow(label: "Event", value: event.title)
                    summaryRow(label: "Division", value: selectedDivision?.label ?? "—")
                    summaryRow(label: "Age Bracket", value: selectedAgeBracket.label)
                    summaryRow(label: "Skill Bracket", value: selectedSkillBracket?.label ?? "—")

                    if isDoublesSelected {
                        summaryRow(label: "Partner", value: selectedPartner?.displayName ?? "TBD")
                    }

                    Divider()

                    HStack {
                        Text("Entry Fee")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(entryFeeFormatted)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.dinkrAmber)
                    }
                }
                .padding(16)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)

                // Waiver checkbox
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        waiverAccepted.toggle()
                    }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(
                                    waiverAccepted ? Color.dinkrGreen : Color.secondary.opacity(0.4),
                                    lineWidth: 1.5
                                )
                                .frame(width: 22, height: 22)
                            if waiverAccepted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.dinkrGreen)
                            }
                        }
                        Text("I agree to the event waiver and code of conduct")
                            .font(.subheadline)
                            .foregroundStyle(Color.primary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .buttonStyle(.plain)

                // Complete Registration button
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        registrationComplete = true
                    }
                } label: {
                    Text("Complete Registration")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            waiverAccepted
                            ? LinearGradient(
                                colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.75)],
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                            : LinearGradient(
                                colors: [Color.secondary.opacity(0.3), Color.secondary.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                              ),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                }
                .disabled(!waiverAccepted)
                .animation(.easeInOut(duration: 0.2), value: waiverAccepted)
                .padding(.bottom, 32)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.dinkrGreen)
            }

            VStack(spacing: 10) {
                Text("You're Registered!")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                Text("Good luck at **\(event.title)**.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 10) {
                successDetail(icon: "flag.checkered", label: selectedDivision?.label ?? "—")
                successDetail(icon: "chart.bar", label: selectedSkillBracket?.label ?? "—")
                if isDoublesSelected, let partner = selectedPartner {
                    successDetail(icon: "person.2.fill", label: "With \(partner.displayName)")
                }
                successDetail(icon: "dollarsign.circle", label: entryFeeFormatted)
            }
            .padding(16)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding(.horizontal)

            Spacer()

            Button("Done") { dismiss() }
                .primaryButton()
                .padding(.horizontal)
                .padding(.bottom, 32)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private var eventHeaderCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(event.title)
                .font(.headline)
                .lineLimit(2)
            HStack(spacing: 12) {
                Label(event.dateTime.shortDateString, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label(event.dateTime.timeString, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Label(event.location, systemImage: "mappin.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if let fee = event.entryFee {
                Label(String(format: "Entry: $%.0f", fee), systemImage: "dollarsign.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dinkrAmber)
            }
        }
        .padding(14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
    }

    private func successDetail(icon: String, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.dinkrGreen)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
        }
    }

    private func nextButton(label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    enabled ? Color.dinkrGreen : Color.secondary.opacity(0.3),
                    in: RoundedRectangle(cornerRadius: 12)
                )
        }
        .disabled(!enabled)
        .animation(.easeInOut(duration: 0.15), value: enabled)
    }
}

// MARK: - Division Card

private struct DivisionCard: View {
    let division: TournamentDivision
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: division.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.dinkrGreen : Color.secondary)
                Text(division.label)
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected ? Color.dinkrGreen.opacity(0.08) : Color.cardBackground,
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isSelected ? Color.dinkrGreen : Color.secondary.opacity(0.15),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Skill Bracket Card

private struct SkillBracketCard: View {
    let bracket: SkillBracket
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bracket.label)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(isSelected ? Color.dinkrGreen : Color.primary)
                    Text(bracket.competitionLevel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
            .padding(14)
            .background(
                isSelected ? Color.dinkrGreen.opacity(0.08) : Color.cardBackground,
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isSelected ? Color.dinkrGreen : Color.secondary.opacity(0.15),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Partner Picker Row

private struct PartnerPickerRow: View {
    let player: User
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Text(player.displayName.prefix(1))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.dinkrGreen)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.displayName)
                        .font(.subheadline.weight(.semibold))
                    Text("@\(player.username)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                SkillBadge(level: player.skillLevel, compact: true)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
            .padding(12)
            .background(
                isSelected ? Color.dinkrGreen.opacity(0.06) : Color.cardBackground,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? Color.dinkrGreen : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Partner Confirmation Row

private struct PartnerConfirmationRow: View {
    let partner: User
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.subheadline)
                .foregroundStyle(Color.dinkrGreen)
            VStack(alignment: .leading, spacing: 2) {
                Text(partner.displayName)
                    .font(.subheadline.weight(.semibold))
                Text("Partner confirmed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            SkillBadge(level: partner.skillLevel, compact: true)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.dinkrGreen.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.dinkrGreen.opacity(0.4), lineWidth: 1.5)
        )
    }
}

// MARK: - Supporting Models

enum TournamentDivision: String, CaseIterable, Hashable {
    case mensSingles    = "Men's Singles"
    case womensSingles  = "Women's Singles"
    case mensDoubles    = "Men's Doubles"
    case womensDoubles  = "Women's Doubles"
    case mixedDoubles   = "Mixed Doubles"

    var label: String { rawValue }

    var icon: String {
        switch self {
        case .mensSingles:   return "person.fill"
        case .womensSingles: return "person.fill"
        case .mensDoubles:   return "person.2.fill"
        case .womensDoubles: return "person.2.fill"
        case .mixedDoubles:  return "person.2.wave.2.fill"
        }
    }

    var isDoubles: Bool {
        switch self {
        case .mensSingles, .womensSingles: return false
        default: return true
        }
    }
}

enum AgeBracket: String, CaseIterable, Hashable {
    case open   = "Open"
    case senior = "35+"
    case masters = "50+"

    var label: String { rawValue }
}

enum SkillBracket: String, CaseIterable, Hashable {
    case threeToThreeHalf   = "3.0–3.5"
    case threeHalfToFour    = "3.5–4.0"
    case fourToFourHalf     = "4.0–4.5"
    case fourHalfPlus       = "4.5+"

    var label: String { rawValue }

    var competitionLevel: String {
        switch self {
        case .threeToThreeHalf:  return "Intermediate"
        case .threeHalfToFour:   return "Intermediate–Advanced"
        case .fourToFourHalf:    return "Advanced"
        case .fourHalfPlus:      return "Elite"
        }
    }
}

// MARK: - Preview

#Preview {
    TournamentRegistrationView(event: Event.mockEvents[0])
}

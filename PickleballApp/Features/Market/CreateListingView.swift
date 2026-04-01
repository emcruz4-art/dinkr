import SwiftUI

// MARK: - Step enum

private enum ListingStep: Int, CaseIterable {
    case details = 0
    case photos  = 1
    case review  = 2

    var title: String {
        switch self {
        case .details: return "Item Details"
        case .photos:  return "Photos & Price"
        case .review:  return "Review & Publish"
        }
    }
}

// MARK: - Draft model (no Firebase)

private struct ListingDraft {
    var category: MarketCategory   = .paddles
    var title: String              = ""
    var description: String        = ""
    var condition: ListingCondition = .good
    var price: String              = ""
    var acceptsOffers: Bool        = false
    var location: String           = "Austin, TX"
    // 0 = not selected, 1 = selected
    var photoSlots: [Bool]         = [false, false, false]
}

// MARK: - CreateListingView

struct CreateListingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService

    @State private var step: ListingStep = .details
    @State private var draft = ListingDraft()
    @State private var isPublished = false
    @State private var isPublishing = false
    @State private var publishError: String? = nil
    @State private var confettiTrigger: Int = 0

    // Which step "Edit" jumps back to
    @State private var editTarget: ListingStep? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Capsule step indicator ─────────────────────────────
                    StepIndicator(current: step)
                        .padding(.top, 14)
                        .padding(.bottom, 6)

                    if isPublished {
                        SuccessView(confettiTrigger: confettiTrigger) {
                            dismiss()
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
                        stepContent
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal:   .move(edge: .leading).combined(with: .opacity)
                                )
                            )
                    }
                }
            }
            .navigationTitle(step.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Step routing

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .details:
            Step1DetailsView(draft: $draft) {
                withAnimation(.easeInOut(duration: 0.3)) { step = .photos }
            }
        case .photos:
            Step2PhotosPriceView(draft: $draft) {
                withAnimation(.easeInOut(duration: 0.3)) { step = .review }
            }
        case .review:
            Step3ReviewView(
                draft: draft,
                onEdit: { target in
                    withAnimation(.easeInOut(duration: 0.3)) { step = target }
                },
                onPublish: {
                    Task { await publishListing() }
                }
            )
        }
    }

    // MARK: - Publish to Firestore

    @MainActor
    private func publishListing() async {
        guard let seller = authService.currentUser else { return }
        isPublishing = true
        defer { isPublishing = false }
        let id = UUID().uuidString
        let listing = MarketListing(
            id: id,
            sellerId: seller.id,
            sellerName: seller.displayName,
            category: draft.category,
            brand: "",
            model: draft.title.isEmpty ? "Item" : draft.title,
            condition: draft.condition,
            price: Double(draft.price) ?? 0,
            description: draft.description,
            photos: [],
            status: .active,
            location: draft.location.isEmpty ? seller.city : draft.location,
            createdAt: Date(),
            isFeatured: false,
            viewCount: 0
        )
        do {
            try await FirestoreService.shared.setDocument(
                listing,
                collection: FirestoreCollections.marketListings,
                documentId: id
            )
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isPublished = true
                confettiTrigger += 1
            }
            HapticManager.success()
        } catch {
            publishError = error.localizedDescription
        }
    }
}

// MARK: - Step Indicator

private struct StepIndicator: View {
    let current: ListingStep

    var body: some View {
        HStack(spacing: 6) {
            ForEach(ListingStep.allCases, id: \.rawValue) { s in
                let isActive  = s == current
                let isPast    = s.rawValue < current.rawValue

                Capsule()
                    .fill(
                        isActive || isPast
                            ? Color.dinkrGreen
                            : Color.secondary.opacity(0.2)
                    )
                    .frame(width: isActive ? 32 : 10, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: current)
            }
        }
    }
}

// MARK: - Step 1: Item Details

private struct Step1DetailsView: View {
    @Binding var draft: ListingDraft
    let onNext: () -> Void

    var canProceed: Bool {
        !draft.title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private let categoryItems: [(cat: MarketCategory, icon: String, label: String, color: Color)] = [
        (.paddles,     "sportscourt",    "Paddles",     Color.dinkrCoral),
        (.balls,       "circle.circle",  "Balls",       Color.dinkrAmber),
        (.bags,        "bag",            "Bags",        Color.dinkrSky),
        (.apparel,     "tshirt",         "Apparel",     .purple),
        (.shoes,       "boot",           "Shoes",       .teal),
        (.accessories, "sparkles",       "Accessories", .pink),
        (.other,       "square.grid.2x2","Other",       Color.dinkrNavy),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Category 2-col grid
                CLSectionCard(label: "Category", icon: "square.grid.2x2.fill", iconColor: Color.dinkrGreen) {
                    let columns = [GridItem(.flexible()), GridItem(.flexible())]
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(categoryItems, id: \.label) { item in
                            let isSelected = draft.category == item.cat
                            Button {
                                HapticManager.selection()
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    draft.category = item.cat
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isSelected ? item.color : item.color.opacity(0.12))
                                            .frame(width: 38, height: 38)
                                        Image(systemName: item.icon)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(isSelected ? .white : item.color)
                                    }
                                    Text(item.label)
                                        .font(.subheadline.weight(isSelected ? .bold : .medium))
                                        .foregroundStyle(isSelected ? item.color : .primary)
                                    Spacer()
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(item.color)
                                            .font(.system(size: 14))
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isSelected ? item.color.opacity(0.08) : Color.appBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isSelected ? item.color.opacity(0.5) : Color.secondary.opacity(0.15), lineWidth: 1.5)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.15), value: isSelected)
                        }
                    }
                }

                // Title
                CLSectionCard(label: "Title", icon: "tag.fill", iconColor: Color.dinkrAmber) {
                    TextField("e.g. Selkirk Vanguard 6.0", text: $draft.title)
                        .font(.body)
                }

                // Description
                CLSectionCard(label: "Description", icon: "text.alignleft", iconColor: Color.dinkrSky) {
                    ZStack(alignment: .topLeading) {
                        if draft.description.isEmpty {
                            Text("Describe the item, any wear or damage…")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 1)
                        }
                        TextEditor(text: $draft.description)
                            .font(.body)
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                    }
                }

                // Condition chips
                CLSectionCard(label: "Condition", icon: "sparkle", iconColor: Color.dinkrCoral) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ListingCondition.allCases, id: \.self) { cond in
                                let isSelected = draft.condition == cond
                                Button {
                                    HapticManager.selection()
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        draft.condition = cond
                                    }
                                } label: {
                                    HStack(spacing: 5) {
                                        Circle()
                                            .fill(conditionColor(cond))
                                            .frame(width: 8, height: 8)
                                        Text(cond.rawValue)
                                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                            .foregroundStyle(isSelected ? conditionColor(cond) : .primary)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        isSelected
                                            ? conditionColor(cond).opacity(0.13)
                                            : Color.appBackground
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                isSelected ? conditionColor(cond) : Color.secondary.opacity(0.25),
                                                lineWidth: isSelected ? 1.5 : 1
                                            )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Next button
                CLNextButton(label: "Next →", enabled: canProceed, action: onNext)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 32)
        }
    }

    private func conditionColor(_ c: ListingCondition) -> Color {
        switch c {
        case .brandNew:  return Color.dinkrGreen
        case .likeNew:   return Color.dinkrSky
        case .good:      return Color.dinkrAmber
        case .fair:      return Color.dinkrCoral
        case .forParts:  return .secondary
        }
    }
}

// MARK: - Step 2: Photos & Price

private struct Step2PhotosPriceView: View {
    @Binding var draft: ListingDraft
    let onNext: () -> Void

    var canProceed: Bool {
        guard let val = Double(draft.price), val > 0 else { return false }
        return true
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Photo placeholders
                CLSectionCard(label: "Photos", icon: "photo.stack.fill", iconColor: Color.dinkrSky) {
                    HStack(spacing: 10) {
                        ForEach(draft.photoSlots.indices, id: \.self) { idx in
                            let isSelected = draft.photoSlots[idx]
                            Button {
                                HapticManager.selection()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    draft.photoSlots[idx].toggle()
                                }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isSelected ? Color.dinkrGreen.opacity(0.08) : Color.secondary.opacity(0.10))
                                        .frame(height: 90)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    isSelected ? Color.dinkrGreen : Color.secondary.opacity(0.25),
                                                    lineWidth: isSelected ? 2 : 1
                                                )
                                        )

                                    if isSelected {
                                        VStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundStyle(Color.dinkrGreen)
                                            Text("Selected")
                                                .font(.caption2.weight(.semibold))
                                                .foregroundStyle(Color.dinkrGreen)
                                        }
                                    } else {
                                        VStack(spacing: 4) {
                                            Image(systemName: "plus.circle")
                                                .font(.system(size: 22))
                                                .foregroundStyle(.secondary)
                                            Text("Add Photo")
                                                .font(.caption2.weight(.medium))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Text("\(draft.photoSlots.filter { $0 }.count)/\(draft.photoSlots.count) selected")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.top, 4)
                }

                // Price
                CLSectionCard(label: "Price", icon: "dollarsign.circle.fill", iconColor: Color.dinkrGreen) {
                    HStack(spacing: 8) {
                        Text("$")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.dinkrGreen)
                        TextField("0.00", text: $draft.price)
                            .keyboardType(.decimalPad)
                            .font(.title2.weight(.semibold))
                    }
                }

                // Accept Offers toggle
                CLSectionCard(label: "Offers", icon: "hand.raised.fill", iconColor: Color.dinkrAmber) {
                    Toggle(isOn: $draft.acceptsOffers) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Accept Offers")
                                .font(.body.weight(.medium))
                            Text("Buyers can send you a counter-offer")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(Color.dinkrGreen)
                }

                // Location chip
                CLSectionCard(label: "Location", icon: "mappin.circle.fill", iconColor: Color.dinkrCoral) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.dinkrCoral)
                        Text(draft.location)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("Change")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.dinkrCoral.opacity(0.07))
                    .clipShape(Capsule())
                }

                CLNextButton(label: "Next →", enabled: canProceed, action: onNext)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Step 3: Review & Publish

private struct Step3ReviewView: View {
    let draft: ListingDraft
    let onEdit: (ListingStep) -> Void
    let onPublish: () -> Void

    private var previewListing: MarketListing {
        MarketListing(
            id: "preview",
            sellerId: User.mockCurrentUser.id,
            sellerName: User.mockCurrentUser.displayName,
            category: draft.category,
            brand: "",
            model: draft.title.isEmpty ? "Your Item" : draft.title,
            condition: draft.condition,
            price: Double(draft.price) ?? 0,
            description: draft.description,
            photos: [],
            status: .active,
            location: draft.location,
            createdAt: Date(),
            isFeatured: false,
            viewCount: 0
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Preview card
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "eye.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dinkrSky)
                        Text("PREVIEW")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(.secondary)
                    }
                    ListingCardView(listing: previewListing)
                        .frame(maxWidth: 200)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)

                Divider().padding(.horizontal, 20)

                // Details summary row
                ReviewRow(
                    icon: "tag.fill",
                    iconColor: Color.dinkrAmber,
                    title: "Item Details"
                ) {
                    onEdit(.details)
                } content: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(draft.title.isEmpty ? "—" : draft.title)
                            .font(.subheadline.weight(.semibold))
                        Text(draft.condition.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if !draft.description.isEmpty {
                            Text(draft.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }

                // Photos & price summary row
                ReviewRow(
                    icon: "photo.stack.fill",
                    iconColor: Color.dinkrSky,
                    title: "Photos & Price"
                ) {
                    onEdit(.photos)
                } content: {
                    VStack(alignment: .leading, spacing: 4) {
                        let photoCount = draft.photoSlots.filter { $0 }.count
                        Label("\(photoCount) photo\(photoCount == 1 ? "" : "s") attached", systemImage: "photo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Text("$\(draft.price.isEmpty ? "0" : draft.price)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.dinkrGreen)
                            if draft.acceptsOffers {
                                Text("· Accepting Offers")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Label(draft.location, systemImage: "mappin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Publish button
                Button(action: onPublish) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Publish Listing")
                            .font(.headline.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.75)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .padding(.top, 10)
        }
    }
}

// MARK: - ReviewRow

private struct ReviewRow<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let onEdit: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(iconColor)
                    Text(title)
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
                Spacer()
                Button("Edit") { onEdit() }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dinkrGreen)
            }
            content()
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Success View

private struct SuccessView: View {
    let confettiTrigger: Int
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.12))
                    .frame(width: 110, height: 110)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.dinkrGreen)
                    .symbolEffect(.bounce, value: confettiTrigger)
            }

            VStack(spacing: 8) {
                Text("Your item is live!")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(.primary)
                Text("Buyers can now find and message you about your listing.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Confetti dots row
            ConfettiRow(trigger: confettiTrigger)
                .padding(.horizontal, 40)

            Button(action: onDone) {
                Text("Done")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.75)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}

// MARK: - Confetti Row (simple animated dots)

private struct ConfettiRow: View {
    let trigger: Int
    @State private var offsets: [CGFloat] = Array(repeating: 0, count: 12)
    @State private var opacities: [Double] = Array(repeating: 0, count: 12)

    private let colors: [Color] = [
        Color.dinkrGreen, Color.dinkrCoral, Color.dinkrAmber,
        Color.dinkrSky, .purple, .pink, Color.dinkrNavy, .teal
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(colors[i % colors.count])
                    .frame(width: 8, height: 8)
                    .offset(y: offsets[i])
                    .opacity(opacities[i])
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 40)
        .onChange(of: trigger) { _, _ in animate() }
        .onAppear { animate() }
    }

    private func animate() {
        for i in 0..<12 {
            let delay = Double(i) * 0.04
            withAnimation(.easeOut(duration: 0.5).delay(delay)) {
                offsets[i] = CGFloat.random(in: -20 ... -4)
                opacities[i] = 1
            }
            withAnimation(.easeIn(duration: 0.35).delay(delay + 0.45)) {
                offsets[i] = CGFloat.random(in: 4 ... 20)
                opacities[i] = 0
            }
        }
    }
}

// MARK: - Shared subviews

private struct CLSectionCard<Content: View>: View {
    let label: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(iconColor)
                Text(label)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            content()
                .padding(14)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

private struct CLNextButton: View {
    let label: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: enabled
                            ? [Color.dinkrGreen, Color.dinkrGreen.opacity(0.75)]
                            : [Color.secondary.opacity(0.3), Color.secondary.opacity(0.25)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(
                    color: enabled ? Color.dinkrGreen.opacity(0.3) : .clear,
                    radius: 8, x: 0, y: 4
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .animation(.easeInOut(duration: 0.2), value: enabled)
    }
}

// MARK: - Preview

#Preview {
    CreateListingView()
}

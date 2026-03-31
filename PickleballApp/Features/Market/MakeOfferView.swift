import SwiftUI

struct MakeOfferView: View {
    let listing: MarketListing
    @Environment(\.dismiss) private var dismiss

    @State private var offerAmount: String = ""
    @State private var noteText: String = ""
    @State private var isSubmitting: Bool = false
    @State private var didSend: Bool = false

    private let noteCharLimit = 100

    // Quick-offer percentages
    private struct QuickChip {
        let label: String
        let pct: Double
    }
    private var quickChips: [QuickChip] {
        [
            QuickChip(label: "90%", pct: 0.90),
            QuickChip(label: "80%", pct: 0.80),
            QuickChip(label: "70%", pct: 0.70),
        ]
    }

    private var parsedAmount: Double? {
        guard let v = Double(offerAmount), v > 0 else { return nil }
        return v
    }

    private var canSend: Bool {
        parsedAmount != nil && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if didSend {
                    successView
                } else {
                    formView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .presentationDetents([.height(460)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Form

    private var formView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Mini listing card
                listingMiniCard
                    .padding(.horizontal)
                    .padding(.top, 4)

                Divider()

                // Your Offer input
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your Offer")
                        .font(.headline)

                    HStack(alignment: .center, spacing: 4) {
                        Text("$")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Color.dinkrCoral)
                        TextField("0", text: $offerAmount)
                            .font(.system(size: 32, weight: .bold))
                            .keyboardType(.numberPad)
                            .foregroundStyle(Color.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Quick offer chips
                    HStack(spacing: 8) {
                        ForEach(quickChips, id: \.label) { chip in
                            let amount = Int(listing.price * chip.pct)
                            Button {
                                offerAmount = "\(amount)"
                            } label: {
                                Text("\(chip.label) ($\(amount))")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.dinkrGreen)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.dinkrGreen.opacity(0.10))
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.dinkrGreen.opacity(0.35), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal)

                // Optional note
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Message")
                            .font(.headline)
                        Text("(optional)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(noteText.count)/\(noteCharLimit)")
                            .font(.caption2)
                            .foregroundStyle(noteText.count >= noteCharLimit ? Color.dinkrCoral : Color.secondary)
                    }

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $noteText)
                            .frame(height: 72)
                            .padding(8)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onChange(of: noteText) { _, newVal in
                                if newVal.count > noteCharLimit {
                                    noteText = String(newVal.prefix(noteCharLimit))
                                }
                            }

                        if noteText.isEmpty {
                            Text("Add a note to the seller...")
                                .foregroundStyle(.tertiary)
                                .font(.subheadline)
                                .padding(.top, 16)
                                .padding(.leading, 12)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .padding(.horizontal)

                // Active offers info
                HStack(spacing: 6) {
                    Image(systemName: "tag")
                        .font(.caption)
                        .foregroundStyle(Color.dinkrAmber)
                    Text("Your offers: 0 active")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // Send button
                Button {
                    Task { await submitOffer() }
                } label: {
                    ZStack {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Send Offer")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(canSend ? Color.dinkrGreen : Color.dinkrGreen.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Listing mini-card

    private var listingMiniCard: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: .secondarySystemBackground))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: categoryIcon(for: listing.category))
                        .font(.title3)
                        .foregroundStyle(Color.dinkrCoral.opacity(0.5))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("\(listing.brand) \(listing.model)")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text("Asking price")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("$\(Int(listing.price))")
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.dinkrCoral)
                .clipShape(Capsule())
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Success state

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.dinkrGreen)
                    .symbolRenderingMode(.hierarchical)
                    .symbolEffect(.bounce, options: .nonRepeating)
            }

            VStack(spacing: 6) {
                Text("Offer Sent!")
                    .font(.title2.weight(.bold))
                Text("The seller will be notified")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func submitOffer() async {
        guard let amount = parsedAmount else { return }
        isSubmitting = true
        let offer = MarketOffer(
            id: UUID().uuidString,
            listingId: listing.id,
            listingTitle: "\(listing.brand) \(listing.model)",
            buyerId: User.mockCurrentUser.id,
            buyerName: User.mockCurrentUser.displayName,
            sellerId: listing.sellerId,
            sellerName: listing.sellerName,
            amount: amount,
            message: noteText.isEmpty ? "Hi, I'd like to make an offer on your item." : noteText,
            status: .pending,
            createdAt: Date(),
            respondedAt: nil
        )
        try? await OfferService.shared.submitOffer(offer)
        isSubmitting = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            didSend = true
        }
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        dismiss()
    }

    // MARK: - Helpers

    private func categoryIcon(for category: MarketCategory) -> String {
        switch category {
        case .paddles:     return "figure.pickleball"
        case .balls:       return "circle.fill"
        case .bags:        return "bag.fill"
        case .apparel:     return "tshirt.fill"
        case .shoes:       return "shoeprints.fill"
        case .accessories: return "sparkles"
        case .courts:      return "sportscourt"
        case .other:       return "ellipsis.circle"
        }
    }
}

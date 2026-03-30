import SwiftUI

struct ListingDetailView: View {
    let listing: MarketListing
    @State private var showMakeOffer = false
    @State private var messageSent = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Photo placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.cardBackground)
                        .frame(height: 280)
                    Image(systemName: categoryIcon)
                        .font(.system(size: 80))
                        .foregroundStyle(Color.dinkrCoral.opacity(0.3))
                }

                VStack(alignment: .leading, spacing: 16) {
                    // Title + price
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(listing.brand + " " + listing.model)
                                .font(.title2.weight(.bold))
                            Text(listing.category.rawValue.capitalized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("$\(Int(listing.price))")
                                .font(.title.weight(.heavy))
                                .foregroundStyle(Color.dinkrCoral)
                            Text(listing.condition.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Stats row
                    HStack(spacing: 16) {
                        Label(listing.location, systemImage: "mappin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Label("\(listing.viewCount) views", systemImage: "eye")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if listing.isFeatured {
                            Label("Featured", systemImage: "star.fill")
                                .font(.caption)
                                .foregroundStyle(Color.dinkrAmber)
                        }
                    }

                    Divider()

                    // Description
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Description")
                            .font(.headline)
                        Text(listing.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Seller card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Seller")
                            .font(.headline)

                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.dinkrGreen.opacity(0.15))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Text(String(listing.sellerName.prefix(1)))
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(Color.dinkrGreen)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(listing.sellerName)
                                    .font(.subheadline.weight(.semibold))
                                HStack(spacing: 4) {
                                    HStack(spacing: 2) {
                                        ForEach(0..<5) { i in
                                            Image(systemName: i < 4 ? "star.fill" : "star.leadinghalf.filled")
                                                .font(.caption2)
                                                .foregroundStyle(Color.dinkrAmber)
                                        }
                                    }
                                    Text("4.8 · Verified Seller")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text("Member since 2023 · 12 sales")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Divider()

                    // CTA buttons
                    VStack(spacing: 10) {
                        Button {
                            Task {
                                _ = await DMService.shared.startConversation(
                                    currentUserId: User.mockCurrentUser.id,
                                    currentUserName: User.mockCurrentUser.displayName,
                                    targetUserId: listing.sellerId,
                                    targetUserName: listing.sellerName
                                )
                                messageSent = true
                                try? await Task.sleep(nanoseconds: 2_000_000_000)
                                messageSent = false
                            }
                        } label: {
                            Text(messageSent ? "Message Sent ✓" : "Message Seller")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(messageSent ? Color.dinkrSky : Color.dinkrGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)

                        Button {
                            showMakeOffer = true
                        } label: {
                            Text("Make Offer")
                                .font(.headline)
                                .foregroundStyle(Color.dinkrCoral)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.dinkrCoral.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.dinkrCoral.opacity(0.4), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(listing.model)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMakeOffer) {
            MakeOfferSheet(listing: listing)
        }
    }

    var categoryIcon: String {
        switch listing.category {
        case .paddles: return "figure.pickleball"
        case .balls: return "circle.fill"
        case .bags: return "bag.fill"
        case .apparel: return "tshirt.fill"
        case .shoes: return "shoeprints.fill"
        case .accessories: return "sparkles"
        case .courts: return "sportscourt"
        case .other: return "ellipsis.circle"
        }
    }
}

struct MakeOfferSheet: View {
    let listing: MarketListing
    @State private var offerAmount = ""
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var didSubmit = false
    @Environment(\.dismiss) private var dismiss

    var suggestedOffer: Int { Int(listing.price * 0.85) }
    var parsedAmount: Double? { Double(offerAmount) }

    var body: some View {
        NavigationStack {
            if didSubmit {
                // Success state
                VStack(spacing: 20) {
                    Spacer()
                    ZStack {
                        Circle().fill(Color.dinkrGreen.opacity(0.15)).frame(width: 88, height: 88)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                    Text("Offer Sent!")
                        .font(.title2.weight(.bold))
                    Text("Your offer of $\(offerAmount) has been sent to \(listing.sellerName). They'll respond shortly.")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Item summary
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.cardBackground)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "figure.pickleball")
                                        .foregroundStyle(Color.dinkrCoral.opacity(0.4))
                                )
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(listing.brand) \(listing.model)")
                                    .font(.subheadline.weight(.semibold))
                                Text("Listed at $\(Int(listing.price))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)

                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Offer")
                                .font(.headline)

                            HStack {
                                Text("$")
                                    .font(.title.weight(.bold))
                                    .foregroundStyle(Color.dinkrCoral)
                                TextField("0", text: $offerAmount)
                                    .font(.title.weight(.bold))
                                    .keyboardType(.numberPad)
                            }
                            .padding(14)
                            .background(Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            Button {
                                offerAmount = "\(suggestedOffer)"
                            } label: {
                                Text("Use suggested offer: $\(suggestedOffer)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.dinkrGreen)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message (optional)")
                                .font(.headline)
                            TextEditor(text: $message)
                                .frame(height: 100)
                                .padding(10)
                                .background(Color.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(alignment: .topLeading) {
                                    if message.isEmpty {
                                        Text("Hi! I'd like to make an offer on your item...")
                                            .foregroundStyle(.secondary)
                                            .padding(14)
                                            .allowsHitTesting(false)
                                    }
                                }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
                .navigationTitle("Make an Offer")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { dismiss() }
                            .disabled(isSubmitting)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task { await sendOffer() }
                        } label: {
                            if isSubmitting {
                                ProgressView()
                                    .tint(Color.dinkrCoral)
                            } else {
                                Text("Send Offer")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(offerAmount.isEmpty ? Color.secondary : Color.dinkrCoral)
                            }
                        }
                        .disabled(offerAmount.isEmpty || isSubmitting)
                    }
                }
            }
        }
    }

    private func sendOffer() async {
        guard let amount = parsedAmount, amount > 0 else { return }
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
            message: message.isEmpty ? "Hi! I'd like to make an offer on your item." : message,
            status: .pending,
            createdAt: Date(),
            respondedAt: nil
        )
        try? await OfferService.shared.submitOffer(offer)
        isSubmitting = false
        withAnimation { didSubmit = true }
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        dismiss()
    }
}

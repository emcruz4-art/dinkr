import SwiftUI

// MARK: - Price Alert Model

struct PriceAlert: Equatable {
    var targetPrice: Double
    var notifySimilar: Bool
}

// MARK: - PriceDropAlertView

struct PriceDropAlertView: View {
    let listing: MarketListing

    // External binding so parent can persist the alert
    @Binding var currentAlert: PriceAlert?

    @Environment(\.dismiss) private var dismiss

    @State private var targetPriceText: String = ""
    @State private var notifySimilar: Bool = false
    @State private var didSetAlert: Bool = false
    @State private var isEditing: Bool = false

    private var currentPrice: Double { listing.price }
    private var listingTitle: String { "\(listing.brand) \(listing.model)" }

    private var parsedTargetPrice: Double? {
        Double(targetPriceText.replacingOccurrences(of: ",", with: ""))
    }

    private var canSetAlert: Bool {
        guard let price = parsedTargetPrice else { return false }
        return price > 0 && price < currentPrice
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Handle ────────────────────────────────────────────────────
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 16)

            // ── Header: listing info ───────────────────────────────────────
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.dinkrAmber.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "bell.badge")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.dinkrAmber)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(listingTitle)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text("Current price: \(currentPrice, format: .currency(code: "USD").precision(.fractionLength(0)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 16)

            Divider()
                .padding(.bottom, 16)

            // ── Main content ──────────────────────────────────────────────
            if didSetAlert && !isEditing {
                alertConfirmationView
            } else if let alert = currentAlert, !isEditing {
                existingAlertView(alert: alert)
            } else {
                setAlertForm
            }
        }
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.hidden)
        .onAppear {
            if let alert = currentAlert {
                targetPriceText = String(Int(alert.targetPrice))
                notifySimilar = alert.notifySimilar
            }
        }
    }

    // MARK: - Set Alert Form

    private var setAlertForm: some View {
        VStack(spacing: 16) {

            // Label
            Text("Alert me when price drops below:")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            // Price input
            HStack(spacing: 0) {
                Text("$")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.dinkrGreen)
                    .padding(.leading, 14)
                TextField("0", text: $targetPriceText)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.dinkrGreen)
                    .keyboardType(.numberPad)
                    .padding(.vertical, 12)
                    .padding(.trailing, 14)
            }
            .background(Color.dinkrGreen.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.dinkrGreen.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)

            // Quick percentage buttons
            HStack(spacing: 8) {
                ForEach([10, 20, 30], id: \.self) { pct in
                    let target = currentPrice * (1.0 - Double(pct) / 100.0)
                    Button {
                        targetPriceText = String(Int(target))
                    } label: {
                        VStack(spacing: 1) {
                            Text("\(pct)% off")
                                .font(.system(size: 11, weight: .bold))
                            Text("$\(Int(target))")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(Color.dinkrNavy)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.dinkrNavy.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.dinkrNavy.opacity(0.18), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal)

            // Similar items toggle
            Toggle(isOn: $notifySimilar) {
                Text("Also notify when similar items are listed for less")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .tint(Color.dinkrGreen)
            .padding(.horizontal)

            // Set Alert button
            Button {
                guard canSetAlert, let price = parsedTargetPrice else { return }
                currentAlert = PriceAlert(targetPrice: price, notifySimilar: notifySimilar)
                isEditing = false
                withAnimation { didSetAlert = true }
            } label: {
                Text("Set Alert")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(canSetAlert ? Color.dinkrGreen : Color.secondary.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(!canSetAlert)
            .padding(.horizontal)
            .padding(.bottom, 4)
        }
    }

    // MARK: - Confirmation after setting

    private var alertConfirmationView: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.dinkrGreen)
            }
            Text("Alert set! We'll notify you 🔔")
                .font(.headline.weight(.semibold))
            if let alert = currentAlert {
                Text("You'll be alerted when the price drops below \(alert.targetPrice, format: .currency(code: "USD").precision(.fractionLength(0)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.dinkrGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.bottom, 4)
            Spacer()
        }
    }

    // MARK: - Existing alert view

    private func existingAlertView(alert: PriceAlert) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active price alert")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                    HStack(spacing: 4) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.dinkrAmber)
                        Text("Below \(alert.targetPrice, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            .font(.title3.weight(.bold))
                    }
                    if alert.notifySimilar {
                        Text("Also watching for similar items")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.dinkrGreen)
            }
            .padding()
            .background(Color.dinkrGreen.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.dinkrGreen.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal)

            HStack(spacing: 12) {
                Button {
                    isEditing = true
                    didSetAlert = false
                } label: {
                    Text("Edit")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.dinkrNavy.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button {
                    currentAlert = nil
                    dismiss()
                } label: {
                    Text("Remove")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrCoral)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.dinkrCoral.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.dinkrCoral.opacity(0.25), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    PriceDropAlertView(
        listing: MarketListing.mockListings[0],
        currentAlert: .constant(nil)
    )
}

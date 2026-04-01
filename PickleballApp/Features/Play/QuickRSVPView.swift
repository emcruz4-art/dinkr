import SwiftUI

// MARK: - QuickRSVPView

struct QuickRSVPView: View {
    let session: GameSession
    let viewModel: PlayViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService

    private var currentUserId: String { authService.currentUser?.id ?? "" }

    // Success state
    @State private var showSuccess = false

    // MARK: - Derived state

    private var isRSVPd: Bool {
        // Check both the viewModel's live copy and the passed session
        let live = viewModel.nearbySessions.first(where: { $0.id == session.id }) ?? session
        return live.rsvps.contains(currentUserId)
    }

    private var liveSession: GameSession {
        viewModel.nearbySessions.first(where: { $0.id == session.id }) ?? session
    }

    private var isFull: Bool { liveSession.isFull }
    private var spotsRemaining: Int { liveSession.spotsRemaining }
    private var fillRatio: Double {
        guard liveSession.totalSpots > 0 else { return 0 }
        return Double(liveSession.rsvps.count) / Double(liveSession.totalSpots)
    }

    // MARK: - Formatters

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: session.dateTime)
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: session.dateTime)
    }

    private var formatLabel: String {
        switch session.format {
        case .singles:     return "Singles"
        case .doubles:     return "Doubles"
        case .mixed:       return "Mixed"
        case .openPlay:    return "Open Play"
        case .round_robin: return "Round Robin"
        }
    }

    private var formatColor: Color {
        switch session.format {
        case .singles:     return Color.dinkrCoral
        case .doubles:     return Color.dinkrGreen
        case .mixed:       return Color.dinkrSky
        case .openPlay:    return Color.dinkrAmber
        case .round_robin: return Color.dinkrNavy
        }
    }

    private var skillRangeLabel: String {
        let lo = session.skillRange.lowerBound.label
        let hi = session.skillRange.upperBound.label
        return lo == hi ? lo : "\(lo)–\(hi)"
    }

    private var feeLabel: String {
        guard let fee = session.fee, fee > 0 else { return "Free" }
        return String(format: "$%.0f", fee)
    }

    private var isFree: Bool {
        guard let fee = session.fee else { return true }
        return fee == 0
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if showSuccess {
                successOverlay
            } else {
                mainContent
            }
        }
        .presentationDetents([.height(380)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }

    // MARK: - Main content

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Drag handle area is handled by presentationDragIndicator
            // Top content
            VStack(alignment: .leading, spacing: 14) {
                // Court name + date/time
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.courtName)
                        .font(.title3.bold())
                        .foregroundStyle(Color.dinkrNavy)
                        .lineLimit(1)
                    Text("\(formattedDate)  ·  \(formattedTime)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Pills row: format + skill range + fee badge
                HStack(spacing: 8) {
                    // Format pill
                    Text(formatLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(formatColor)
                        .clipShape(Capsule())

                    // Skill range pill
                    Text(skillRangeLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrNavy)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.dinkrNavy.opacity(0.10))
                        .clipShape(Capsule())

                    Spacer()

                    // Fee badge
                    Text(feeLabel)
                        .font(.caption.bold())
                        .foregroundStyle(isFree ? Color.dinkrGreen : Color.dinkrAmber)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            isFree
                                ? Color.dinkrGreen.opacity(0.12)
                                : Color.dinkrAmber.opacity(0.15)
                        )
                        .clipShape(Capsule())
                }

                // Host row
                HStack(spacing: 8) {
                    AvatarView(urlString: nil, displayName: session.hostName, size: 32)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(session.hostName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrNavy)
                        // Star rating stub (hosts don't carry a rating on GameSession)
                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { i in
                                Image(systemName: i < 4 ? "star.fill" : "star.leadinghalf.filled")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.dinkrAmber)
                            }
                            Text("4.8")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }

                // Spots progress bar
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(liveSession.rsvps.count) / \(liveSession.totalSpots) spots filled")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(isFull ? "Full" : "\(spotsRemaining) left")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isFull ? Color.dinkrCoral : Color.dinkrGreen)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.dinkrGreen.opacity(0.15))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(isFull ? Color.dinkrCoral : Color.dinkrGreen)
                                .frame(width: geo.size.width * fillRatio)
                        }
                    }
                    .frame(height: 5)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Spacer(minLength: 16)

            // Action area
            VStack(spacing: 10) {
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Action buttons

    @ViewBuilder
    private var actionButtons: some View {
        if isRSVPd {
            // Already RSVPd state
            HStack(spacing: 12) {
                Label("You're In! ✓", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.dinkrGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.dinkrGreen.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button(role: .destructive) {
                HapticManager.medium()
                viewModel.rsvp(to: liveSession)
                dismiss()
            } label: {
                Text("Cancel RSVP")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.dinkrCoral)
                    .frame(maxWidth: .infinity)
            }
        } else if isFull {
            // Full + not RSVPd — waitlist
            Button {
                HapticManager.medium()
                // Waitlist action placeholder (extend viewModel as needed)
                dismiss()
            } label: {
                Label("Join Waitlist", systemImage: "clock.badge.plus")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.dinkrAmber)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Button {
                dismiss()
            } label: {
                Text("Maybe Later")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        } else {
            // Default: not RSVPd and spots available
            Button {
                HapticManager.medium()
                viewModel.rsvp(to: liveSession)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showSuccess = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            } label: {
                Text("RSVP Now")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.dinkrGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Button {
                dismiss()
            } label: {
                Text("Maybe Later")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Success overlay

    private var successOverlay: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.dinkrGreen)
                    .transition(.scale.combined(with: .opacity))
            }
            Text("See you there!")
                .font(.title3.bold())
                .foregroundStyle(Color.dinkrNavy)
            Text("You're on the list for \(session.courtName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .transition(.opacity)
    }
}

// MARK: - Preview

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            QuickRSVPView(
                session: GameSession.mockSessions[0],
                viewModel: {
                    let vm = PlayViewModel()
                    vm.nearbySessions = GameSession.mockSessions
                    return vm
                }()
            )
        }
}

import SwiftUI

// MARK: - EventCheckInView

struct EventCheckInView: View {
    let event: Event

    @Environment(\.dismiss) private var dismiss

    // PIN state
    @State private var pin: String = ""
    @State private var pinShake: Bool = false
    @State private var isCheckedIn: Bool = false
    @State private var showSuccess: Bool = false
    @State private var checkmarkScale: CGFloat = 0.3
    @State private var checkmarkOpacity: Double = 0

    private let correctPIN = "4829"
    private let registrationCode = "DINKR-4829"
    private let assignedCourt = "Court 3"

    var body: some View {
        ZStack {
            // Full-screen navy background
            Color.dinkrNavy.ignoresSafeArea()

            if showSuccess {
                successOverlay
            } else {
                mainContent
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.dinkrNavy, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.top, 24)
                    .padding(.bottom, 32)

                // QR Section
                qrSection
                    .padding(.horizontal, 24)

                // OR Divider
                orDivider
                    .padding(.vertical, 28)
                    .padding(.horizontal, 24)

                // PIN Section
                pinSection
                    .padding(.horizontal, 24)

                // Check In Button
                checkInButton
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                // Event Summary
                eventSummaryCard
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 40)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("Check In")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.white)

            Text(event.title)
                .font(.subheadline)
                .foregroundStyle(Color.dinkrGreen)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - QR Section

    private var qrSection: some View {
        VStack(spacing: 16) {
            // QR placeholder with dashed border
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        style: StrokeStyle(lineWidth: 2, dash: [8, 5])
                    )
                    .foregroundStyle(Color.dinkrGreen.opacity(0.6))
                    .frame(width: 220, height: 220)

                // Simulated 7×7 QR grid drawn with Path
                QRGridPattern()
                    .fill(Color.white)
                    .frame(width: 180, height: 180)
            }
            .frame(width: 220, height: 220)

            // Registration code
            Text(registrationCode)
                .font(.system(.title3, design: .monospaced).weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.1))
                )

            Text("Scan at the venue")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - OR Divider

    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)

            Text("OR")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.white.opacity(0.5))
                .padding(.horizontal, 4)

            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
        }
    }

    // MARK: - PIN Section

    private var pinSection: some View {
        VStack(spacing: 16) {
            Text("Enter 4-Digit PIN")
                .font(.headline)
                .foregroundStyle(.white)

            // PIN display boxes
            HStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { index in
                    PINBox(
                        character: pin.count > index ? String(Array(pin)[index]) : nil,
                        isFocused: pin.count == index
                    )
                }
            }
            .modifier(ShakeEffect(trigger: pinShake))

            // Numpad
            numpad
        }
    }

    // MARK: - Numpad

    private var numpad: some View {
        VStack(spacing: 10) {
            ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { digit in
                        NumpadButton(label: "\(digit)") {
                            addDigit("\(digit)")
                        }
                    }
                }
            }
            HStack(spacing: 10) {
                // Empty placeholder to keep layout aligned
                Color.clear.frame(width: 80, height: 56)

                NumpadButton(label: "0") {
                    addDigit("0")
                }

                // Backspace
                Button {
                    deleteDigit()
                } label: {
                    Image(systemName: "delete.left")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 56)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Check In Button

    private var checkInButton: some View {
        Button {
            attemptCheckIn()
        } label: {
            Text("Check In with PIN")
                .font(.headline)
                .foregroundStyle(pin.count == 4 ? Color.dinkrNavy : Color.white.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(pin.count == 4 ? Color.dinkrGreen : Color.white.opacity(0.1))
                )
        }
        .disabled(pin.count != 4)
        .animation(.easeInOut(duration: 0.2), value: pin.count)
    }

    // MARK: - Event Summary Card

    private var eventSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Details")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 14) {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.dinkrGreen)
                    .frame(width: 20)
                Text(event.dateTime.formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }

            HStack(spacing: 14) {
                Image(systemName: "clock")
                    .foregroundStyle(Color.dinkrGreen)
                    .frame(width: 20)
                Text(event.dateTime.formatted(.dateTime.hour().minute()))
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }

            HStack(spacing: 14) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Color.dinkrCoral)
                    .frame(width: 20)
                Text(event.location)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }

            HStack(spacing: 14) {
                Image(systemName: "sportscourt.fill")
                    .foregroundStyle(Color.dinkrAmber)
                    .frame(width: 20)
                Text("\(assignedCourt) assigned")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dinkrAmber)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.2))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(Color.dinkrGreen.opacity(0.35))
                    .frame(width: 110, height: 110)

                Image(systemName: "checkmark")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(Color.dinkrGreen)
                    .scaleEffect(checkmarkScale)
                    .opacity(checkmarkOpacity)
            }

            VStack(spacing: 8) {
                Text("You're checked in! 🎉")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text("\(assignedCourt) assigned")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.dinkrAmber)
            }

            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "sportscourt.fill")
                        .foregroundStyle(Color.dinkrGreen)
                    Text(event.title)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
                HStack(spacing: 10) {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(Color.dinkrSky)
                    Text(event.dateTime.formatted(.dateTime.weekday(.abbreviated).month().day().hour().minute()))
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.75))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
            )
            .padding(.horizontal, 32)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(Color.dinkrNavy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                checkmarkScale = 1.0
                checkmarkOpacity = 1.0
            }
        }
    }

    // MARK: - Actions

    private func addDigit(_ digit: String) {
        guard pin.count < 4 else { return }
        pin += digit
    }

    private func deleteDigit() {
        guard !pin.isEmpty else { return }
        pin.removeLast()
    }

    private func attemptCheckIn() {
        guard pin == correctPIN else {
            withAnimation(.default) { pinShake = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pinShake = false
                pin = ""
            }
            return
        }
        isCheckedIn = true
        withAnimation(.easeInOut(duration: 0.4)) {
            showSuccess = true
        }
    }
}

// MARK: - QRGridPattern (7x7 simulated QR)

struct QRGridPattern: Shape {
    // Predefined "on" cells for a plausible QR-like grid
    private static let filledCells: Set<[Int]> = [
        // Top-left finder
        [0,0],[0,1],[0,2],[0,3],[0,4],[0,5],[0,6],
        [1,0],[1,6],
        [2,0],[2,2],[2,3],[2,4],[2,6],
        [3,0],[3,2],[3,4],[3,6],
        [4,0],[4,2],[4,3],[4,4],[4,6],
        [5,0],[5,6],
        [6,0],[6,1],[6,2],[6,3],[6,4],[6,5],[6,6],
        // Top-right finder
        [0,14],[0,15],[0,16],[0,17],[0,18],[0,19],[0,20],
        [1,14],[1,20],
        [2,14],[2,16],[2,17],[2,18],[2,20],
        [3,14],[3,16],[3,18],[3,20],
        [4,14],[4,16],[4,17],[4,18],[4,20],
        [5,14],[5,20],
        [6,14],[6,15],[6,16],[6,17],[6,18],[6,19],[6,20],
        // Bottom-left finder
        [14,0],[14,1],[14,2],[14,3],[14,4],[14,5],[14,6],
        [15,0],[15,6],
        [16,0],[16,2],[16,3],[16,4],[16,6],
        [17,0],[17,2],[17,4],[17,6],
        [18,0],[18,2],[18,3],[18,4],[18,6],
        [19,0],[19,6],
        [20,0],[20,1],[20,2],[20,3],[20,4],[20,5],[20,6],
        // Data modules (scattered for visual authenticity)
        [8,2],[8,5],[8,8],[8,11],[8,14],[8,17],
        [9,1],[9,4],[9,7],[9,10],[9,13],[9,16],[9,19],
        [10,3],[10,6],[10,9],[10,12],[10,15],[10,18],
        [11,2],[11,5],[11,8],[11,11],[11,14],[11,17],[11,20],
        [12,1],[12,4],[12,7],[12,10],[12,13],[12,16],
        [13,3],[13,6],[13,9],[13,12],[13,15],[13,18],
    ]

    func path(in rect: CGRect) -> Path {
        let cols = 21
        let rows = 21
        let cellW = rect.width / CGFloat(cols)
        let cellH = rect.height / CGFloat(rows)
        let padding: CGFloat = 1.5

        var path = Path()
        for cell in Self.filledCells {
            let row = cell[0]
            let col = cell[1]
            let x = rect.minX + CGFloat(col) * cellW + padding
            let y = rect.minY + CGFloat(row) * cellH + padding
            let w = cellW - padding * 2
            let h = cellH - padding * 2
            path.addRoundedRect(
                in: CGRect(x: x, y: y, width: w, height: h),
                cornerSize: CGSize(width: 1.5, height: 1.5)
            )
        }
        return path
    }
}

// MARK: - PINBox

private struct PINBox: View {
    let character: String?
    let isFocused: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isFocused ? Color.dinkrGreen : Color.white.opacity(0.2),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .frame(width: 62, height: 72)

            if let char = character {
                Text(char)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .transition(.scale.combined(with: .opacity))
            } else if isFocused {
                // Blinking cursor indicator
                Rectangle()
                    .fill(Color.dinkrGreen)
                    .frame(width: 2, height: 28)
                    .opacity(0.8)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: character)
    }
}

// MARK: - NumpadButton

private struct NumpadButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.title2.weight(.medium))
                .foregroundStyle(.white)
                .frame(width: 80, height: 56)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ShakeEffect

struct ShakeEffect: AnimatableModifier {
    var trigger: Bool
    @State private var offset: CGFloat = 0

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: trigger) { _, newValue in
                guard newValue else { return }
                withAnimation(
                    Animation.timingCurve(0.36, 0.07, 0.19, 0.97, duration: 0.4)
                ) {
                    offset = -10
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(Animation.timingCurve(0.36, 0.07, 0.19, 0.97, duration: 0.4)) {
                        offset = 10
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(Animation.timingCurve(0.36, 0.07, 0.19, 0.97, duration: 0.4)) {
                        offset = -6
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(Animation.timingCurve(0.36, 0.07, 0.19, 0.97, duration: 0.4)) {
                        offset = 0
                    }
                }
            }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EventCheckInView(event: Event.mockEvents[0])
    }
}

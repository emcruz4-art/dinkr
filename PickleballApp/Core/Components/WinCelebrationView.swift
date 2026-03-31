import SwiftUI

// MARK: - ConfettiShape

enum ConfettiShape {
    case circle
    case rectangle
    case triangle
}

// MARK: - ConfettiPiece

struct ConfettiPiece: Identifiable {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    var rotation: Double
    var color: Color
    var size: CGFloat
    var shape: ConfettiShape
}

// MARK: - ConfettiView

struct ConfettiView: View {
    @State private var pieces: [ConfettiPiece] = []
    @State private var animating = false
    @State private var visible = true

    private let confettiColors: [Color] = [
        Color.dinkrGreen,
        Color.dinkrAmber,
        Color.dinkrCoral,
        Color.dinkrSky,
        .white
    ]
    private let screenHeight = UIScreen.main.bounds.height
    private let screenWidth  = UIScreen.main.bounds.width

    var body: some View {
        ZStack {
            if visible {
                ForEach(pieces) { piece in
                    ConfettiPieceView(piece: piece, animating: animating, screenHeight: screenHeight)
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            spawnPieces()
            withAnimation(.linear(duration: 2.8)) {
                animating = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                visible = false
            }
        }
    }

    private func spawnPieces() {
        let shapes: [ConfettiShape] = [.circle, .rectangle, .triangle]
        pieces = (0..<60).map { _ in
            ConfettiPiece(
                id: UUID(),
                x: CGFloat.random(in: 0...screenWidth),
                y: -20,
                rotation: Double.random(in: 0...360),
                color: confettiColors.randomElement()!,
                size: CGFloat.random(in: 7...14),
                shape: shapes.randomElement()!
            )
        }
    }
}

// MARK: - ConfettiPieceView

private struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    let animating: Bool
    let screenHeight: CGFloat

    private var targetY: CGFloat { screenHeight + 50 }
    private var xDrift: CGFloat { CGFloat.random(in: -60...60) }

    var body: some View {
        pieceShape
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size)
            .rotationEffect(.degrees(animating ? piece.rotation + 360 : piece.rotation))
            .position(
                x: animating ? piece.x + xDrift : piece.x,
                y: animating ? targetY : piece.y
            )
            .animation(
                .linear(duration: Double.random(in: 2.2...2.8))
                    .delay(Double.random(in: 0...0.4)),
                value: animating
            )
    }

    private var pieceShape: AnyShape {
        switch piece.shape {
        case .circle:
            AnyShape(Circle())
        case .rectangle:
            AnyShape(Rectangle())
        case .triangle:
            AnyShape(ConfettiTriangle())
        }
    }
}

// MARK: - ConfettiTriangle Shape

private struct ConfettiTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - WinCelebrationView

struct WinCelebrationView: View {
    let score: String
    let opponentName: String
    let duprChange: Double

    var onLogFullResult: (() -> Void)?
    var onDone: (() -> Void)?

    private var duprChangeFormatted: String {
        let sign = duprChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", duprChange)) DUPR"
    }

    private var shareText: String {
        "I won \(score) against \(opponentName) on Dinkr! \(duprChangeFormatted)"
    }

    var body: some View {
        ZStack {
            // Background
            Color.appBackground
                .ignoresSafeArea()

            // Confetti overlay
            ConfettiView()
                .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                Spacer()

                // Trophy
                Text("🏆")
                    .font(.system(size: 80))
                    .padding(.bottom, 12)

                // Headline
                Text("You Won! 🏆")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(Color.dinkrAmber)
                    .padding(.bottom, 16)

                // Score
                Text(score)
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .padding(.bottom, 16)

                // Opponent chip
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("vs \(opponentName)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.cardBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.secondary.opacity(0.18), lineWidth: 1)
                )
                .padding(.bottom, 14)

                // DUPR badge
                HStack(spacing: 5) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                    Text(duprChangeFormatted)
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.dinkrGreen)
                .clipShape(Capsule())
                .padding(.bottom, 36)

                // Action buttons
                VStack(spacing: 12) {
                    ShareLink(
                        item: shareText,
                        preview: SharePreview("Dinkr Win", image: Image(systemName: "trophy.fill"))
                    ) {
                        Label("Share Result", systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        onLogFullResult?()
                    } label: {
                        Text("Log Full Result")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Color.dinkrGreen, lineWidth: 1.5)
                            )
                    }

                    Button("Done") {
                        onDone?()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
    }
}

// MARK: - WinCelebration View Modifier

private struct WinCelebrationModifier: ViewModifier {
    @Binding var isPresented: Bool
    let score: String
    let opponent: String
    let duprChange: Double

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                WinCelebrationView(
                    score: score,
                    opponentName: opponent,
                    duprChange: duprChange,
                    onDone: { isPresented = false }
                )
            }
    }
}

extension View {
    func winCelebration(
        isPresented: Binding<Bool>,
        score: String,
        opponent: String,
        duprChange: Double
    ) -> some View {
        modifier(WinCelebrationModifier(
            isPresented: isPresented,
            score: score,
            opponent: opponent,
            duprChange: duprChange
        ))
    }
}

// MARK: - Preview

#Preview("Win Celebration") {
    WinCelebrationView(
        score: "11 – 7",
        opponentName: "Alex Rivera",
        duprChange: 0.08,
        onDone: {}
    )
}

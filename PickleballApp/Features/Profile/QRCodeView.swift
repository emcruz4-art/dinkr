import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

// MARK: - QR Code Generation

func generateQRCode(from string: String) -> UIImage? {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    guard let data = string.data(using: .utf8) else { return nil }
    filter.setValue(data, forKey: "inputMessage")
    filter.setValue("M", forKey: "inputCorrectionLevel")

    guard let ciImage = filter.outputImage else { return nil }

    // Scale up for crisp rendering at display size
    let scale: CGFloat = 10.0
    let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

    guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
    return UIImage(cgImage: cgImage)
}

// MARK: - QR Code Image View

private struct QRCodeImageView: View {
    let content: String

    var body: some View {
        if let uiImage = generateQRCode(from: content) {
            Image(uiImage: uiImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .colorInvert()          // makes modules white
                .colorMultiply(.white)  // ensures white on transparent
        } else {
            Image(systemName: "qrcode")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
        }
    }
}

// MARK: - QRCodeView (full card)

struct QRCodeView: View {
    let user: User

    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var renderedCardImage: UIImage?

    private var deepLink: DinkrDeepLink { .profile(userId: user.id) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dinkrNavy.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Card
                        qrCard
                            .shadow(color: Color.dinkrNavy.opacity(0.6), radius: 24, x: 0, y: 12)

                        // Share button
                        Button {
                            renderCardToImage()
                        } label: {
                            Label("Share My QR Code", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 32)

                        Text("Anyone who scans this code will be taken\ndirectly to your Dinkr profile.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 32)
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("My QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.dinkrGreen)
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let img = renderedCardImage {
                    ActivityShareSheet(items: [
                        "Connect with me on Dinkr!",
                        deepLink.webURL,
                        img
                    ])
                    .presentationDetents([.medium, .large])
                } else {
                    ActivityShareSheet(items: [
                        deepLink.shareText,
                        deepLink.webURL
                    ])
                    .presentationDetents([.medium, .large])
                }
            }
        }
    }

    // MARK: - QR Card

    @ViewBuilder
    private var qrCard: some View {
        VStack(spacing: 24) {
            // Logo
            DinkrLogoView(size: 36, showWordmark: true, tintColor: .white)
                .padding(.top, 28)

            // QR code
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 220, height: 220)

                QRCodeImageView(content: deepLink.url.absoluteString)
                    .frame(width: 190, height: 190)
            }

            // Name + username
            VStack(spacing: 4) {
                Text(user.displayName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }

            // Skill badge
            SkillBadge(level: user.skillLevel)

            // Caption
            Text("Scan to connect on Dinkr")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.45))
                .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.dinkrNavy,
                            Color(red: 0.06, green: 0.26, blue: 0.42)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .id("qrCard")
    }

    // MARK: - Render card to UIImage for sharing

    private func renderCardToImage() {
        let renderer = ImageRenderer(content:
            qrCard
                .frame(width: 340)
                .environment(\.colorScheme, .dark)
        )
        renderer.scale = 3.0
        renderedCardImage = renderer.uiImage
        showShareSheet = true
    }
}

// MARK: - QRCodeButton (compact presenter)

struct QRCodeButton: View {
    let user: User
    @State private var showQRCode = false

    var body: some View {
        Button {
            showQRCode = true
        } label: {
            Image(systemName: "qrcode")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.dinkrGreen)
                .frame(width: 44, height: 44)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 10))
        }
        .sheet(isPresented: $showQRCode) {
            QRCodeView(user: user)
        }
    }
}

// MARK: - Preview

#Preview {
    QRCodeView(user: .mockCurrentUser)
}

import SwiftUI

/// Developer utility: previews DinkrIconView at all App Store–required sizes
/// and provides a 1024pt PNG export via ImageRenderer.
struct IconPreviewView: View {

    // All sizes required by the App Store / iOS icon spec
    private let iconSizes: [CGFloat] = [
        20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024
    ]

    // Sizes shown in the scrollable grid (1024 is shown separately due to its size)
    private let gridSizes: [CGFloat] = [
        20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180
    ]

    @State private var isExporting = false
    @State private var exportedImage: Image?
    @State private var showExportConfirmation = false

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 200), spacing: 20)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {

                    // — Grid of standard sizes
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(gridSizes, id: \.self) { size in
                            iconCell(size: size)
                        }
                    }
                    .padding(.horizontal)

                    Divider()

                    // — 1024pt hero (App Store marketing icon)
                    VStack(spacing: 12) {
                        Text("1024pt — App Store")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        DinkrIconView(size: 160)  // displayed at 160, represents 1024

                        Text("Displayed at 160pt; renders at 1024pt for export")
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    Divider()

                    // — Export button
                    exportSection
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("App Icon Preview")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(UIColor.systemGroupedBackground))
        }
    }

    // MARK: - Icon cell

    private func iconCell(size: CGFloat) -> some View {
        VStack(spacing: 8) {
            DinkrIconView(size: min(size, 100))  // cap display size so grid stays readable
                .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)

            Text("\(Int(size))pt")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Export section

    private var exportSection: some View {
        VStack(spacing: 16) {
            Text("Export")
                .font(.headline)

            Button {
                exportIcon()
            } label: {
                HStack(spacing: 10) {
                    if isExporting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Text(isExporting ? "Rendering…" : "Export 1024pt PNG")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.dinkrGreen)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isExporting)
            .padding(.horizontal, 24)

            if showExportConfirmation {
                Label("Icon rendered and shared", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.dinkrGreen)
                    .font(.subheadline)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: - Export logic

    @MainActor
    private func exportIcon() {
        isExporting = true
        showExportConfirmation = false

        // Render DinkrIconView at the full 1024pt resolution
        let renderer = ImageRenderer(content:
            DinkrIconView(size: 1024)
                .frame(width: 1024, height: 1024)
        )
        renderer.scale = 1.0  // 1:1 — we want 1024 actual pixels

        guard let uiImage = renderer.uiImage else {
            isExporting = false
            return
        }

        // Share via UIActivityViewController
        let activityVC = UIActivityViewController(
            activityItems: [uiImage],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            // Present from the topmost presented controller
            var presentingVC = rootVC
            while let presented = presentingVC.presentedViewController {
                presentingVC = presented
            }
            activityVC.completionWithItemsHandler = { _, completed, _, _ in
                DispatchQueue.main.async {
                    isExporting = false
                    if completed {
                        withAnimation { showExportConfirmation = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { showExportConfirmation = false }
                        }
                    }
                }
            }
            presentingVC.present(activityVC, animated: true)
        } else {
            isExporting = false
        }
    }
}

// MARK: - Preview

#Preview {
    IconPreviewView()
}

import SwiftUI

// MARK: - Profile Share Card (rendered to UIImage via ImageRenderer)

struct ProfileShareCard: View {
    let user: User
    /// Optional group names for display; first 3 are shown.
    var groupNames: [String] = []

    private var initials: String {
        let parts = user.displayName.split(separator: " ")
        let letters = parts.compactMap { $0.first.map(String.init) }
        return letters.prefix(2).joined().uppercased()
    }

    private var levelTitle: String {
        switch user.gamesPlayed {
        case 0..<10: return "Newbie"
        case 10..<25: return "Rookie"
        case 25..<50: return "Player"
        case 50..<75: return "Regular"
        case 75..<100: return "Competitor"
        case 100..<125: return "Veteran"
        case 125..<150: return "Dinkmaster"
        case 150..<200: return "Court Legend"
        case 200..<300: return "Pro Circuit"
        default: return "Hall of Fame"
        }
    }

    private var levelNumber: Int {
        switch user.gamesPlayed {
        case 0..<10: return 1
        case 10..<25: return 2
        case 25..<50: return 3
        case 50..<75: return 4
        case 75..<100: return 5
        case 100..<125: return 6
        case 125..<150: return 7
        case 150..<200: return 8
        case 200..<300: return 9
        default: return 10
        }
    }

    var body: some View {
        ZStack {
            // Diagonal gradient background: dinkrNavy → dinkrGreen
            LinearGradient(
                colors: [Color.dinkrNavy, Color(red: 0.06, green: 0.30, blue: 0.17)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle court lines canvas
            ShareCardCourtLines()
                .opacity(0.07)

            // Card content
            VStack(spacing: 0) {
                // Top: wordmark + tagline
                HStack(alignment: .center) {
                    DinkrLogoView(size: 22, tintColor: .white)
                    Spacer()
                    Text("Play with me on Dinkr")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)

                // Avatar
                ZStack {
                    // Glow halo
                    Circle()
                        .fill(Color.dinkrGreen.opacity(0.28))
                        .frame(width: 106, height: 106)
                        .blur(radius: 10)

                    // Ring
                    Circle()
                        .stroke(Color.dinkrGreen, lineWidth: 3)
                        .frame(width: 90, height: 90)

                    // Avatar or initials
                    Circle()
                        .fill(Color.dinkrNavy)
                        .frame(width: 84, height: 84)

                    Text(initials)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.dinkrGreen)
                }
                .padding(.top, 20)

                // Player name
                Text(user.displayName)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 14)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                // @username
                Text("@\(user.username)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 3)

                // Skill level + play style badges
                HStack(spacing: 8) {
                    SkillBadge(level: user.skillLevel)

                    if let style = user.playStyle {
                        HStack(spacing: 4) {
                            Image(systemName: style.icon)
                                .font(.system(size: 9, weight: .semibold))
                            Text(style.rawValue)
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.12), in: Capsule())
                        .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
                    }
                }
                .padding(.top, 10)

                // Stats row: DUPR / Games / Win Rate / Level
                HStack(spacing: 0) {
                    ShareStatColumn(
                        value: user.duprRating.map { String(format: "%.2f", $0) } ?? "—",
                        label: "DUPR",
                        accentColor: Color.dinkrAmber
                    )
                    shareStatDivider
                    ShareStatColumn(
                        value: "\(user.gamesPlayed)",
                        label: "Games",
                        accentColor: .white
                    )
                    shareStatDivider
                    ShareStatColumn(
                        value: "\(Int(user.winRate * 100))%",
                        label: "Win Rate",
                        accentColor: Color.dinkrGreen
                    )
                    shareStatDivider
                    ShareStatColumn(
                        value: "Lv.\(levelNumber)",
                        label: levelTitle,
                        accentColor: Color.dinkrSky
                    )
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.top, 14)

                // DinkrGroup membership pills (first 3)
                let displayGroups = Array(groupNames.prefix(3))
                if !displayGroups.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(displayGroups, id: \.self) { name in
                            Text(name)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineLimit(1)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.white.opacity(0.12), in: Capsule())
                                .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }

                Spacer(minLength: 0)

                // Bottom: QR code + watermark
                HStack(alignment: .bottom, spacing: 14) {
                    // QR placeholder drawn with Canvas
                    ShareQRPlaceholder(content: "dinkr.app/player/\(user.username)")
                        .frame(width: 56, height: 56)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scan to connect")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                        Text("dinkr.app/player/\(user.username)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    }

                    Spacer()

                    Text("dinkr.app")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .padding(.top, 10)
            }
        }
        .frame(width: 360, height: 500)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var shareStatDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.12))
            .frame(width: 1, height: 30)
    }
}

// MARK: - Share Stat Column

private struct ShareStatColumn: View {
    let value: String
    let label: String
    let accentColor: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
                .textCase(.uppercase)
                .tracking(0.3)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Court Lines for Share Card

private struct ShareCardCourtLines: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            var path = Path()
            // NVZ kitchen lines
            path.move(to: CGPoint(x: 0, y: h * 0.38))
            path.addLine(to: CGPoint(x: w, y: h * 0.38))
            path.move(to: CGPoint(x: 0, y: h * 0.62))
            path.addLine(to: CGPoint(x: w, y: h * 0.62))
            // Center line
            path.move(to: CGPoint(x: w * 0.5, y: 0))
            path.addLine(to: CGPoint(x: w * 0.5, y: h))
            // Baselines
            path.move(to: CGPoint(x: 0, y: h * 0.04))
            path.addLine(to: CGPoint(x: w, y: h * 0.04))
            path.move(to: CGPoint(x: 0, y: h * 0.96))
            path.addLine(to: CGPoint(x: w, y: h * 0.96))
            // Sidelines
            path.move(to: CGPoint(x: w * 0.04, y: 0))
            path.addLine(to: CGPoint(x: w * 0.04, y: h))
            path.move(to: CGPoint(x: w * 0.96, y: 0))
            path.addLine(to: CGPoint(x: w * 0.96, y: h))
            ctx.stroke(path, with: .color(.white), lineWidth: 1.2)
        }
    }
}

// MARK: - QR Placeholder (Canvas grid of squares)

private struct ShareQRPlaceholder: View {
    let content: String

    var body: some View {
        Canvas { ctx, size in
            let moduleSize: CGFloat = size.width / 9.0
            // Deterministic "QR-like" pattern from content hash
            var seed = content.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }

            let outerRect = CGRect(origin: .zero, size: size)
            ctx.fill(Path(outerRect), with: .color(.white.opacity(0.9)))

            // Draw modules
            for row in 0..<9 {
                for col in 0..<9 {
                    // Always fill corner finder squares
                    let isFinder = isFinderPattern(row: row, col: col)
                    let isFilled: Bool
                    if isFinder {
                        isFilled = true
                    } else {
                        seed = (seed &* 1664525 &+ 1013904223) & 0x7FFFFFFF
                        isFilled = (seed % 3) != 0
                    }

                    if isFilled {
                        let rect = CGRect(
                            x: CGFloat(col) * moduleSize + 1,
                            y: CGFloat(row) * moduleSize + 1,
                            width: moduleSize - 1,
                            height: moduleSize - 1
                        )
                        let path = Path(roundedRect: rect, cornerRadius: 1)
                        ctx.fill(path, with: .color(Color.dinkrNavy))
                    }
                }
            }
        }
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(3)
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
    }

    private func isFinderPattern(row: Int, col: Int) -> Bool {
        // Top-left 3x3
        if row < 3 && col < 3 { return true }
        // Top-right 3x3
        if row < 3 && col >= 6 { return true }
        // Bottom-left 3x3
        if row >= 6 && col < 3 { return true }
        return false
    }
}

// MARK: - Share Profile Sheet

struct ShareProfileSheet: View {
    let user: User
    var groupNames: [String] = []

    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage?
    @State private var isRendering = true
    @State private var copyLinkToast = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Card preview
                        ZStack {
                            if isRendering {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.dinkrNavy.opacity(0.15))
                                    .frame(width: 360, height: 500)
                                    .overlay {
                                        ProgressView()
                                            .tint(Color.dinkrGreen)
                                    }
                            } else {
                                ProfileShareCard(user: user, groupNames: groupNames)
                                    .shadow(color: .black.opacity(0.28), radius: 24, x: 0, y: 10)
                            }
                        }
                        .padding(.top, 16)

                        // Action buttons
                        VStack(spacing: 12) {
                            // Share Profile (ShareLink)
                            if let img = shareImage {
                                ShareLink(
                                    item: Image(uiImage: img),
                                    preview: SharePreview(
                                        "Play pickleball with \(user.displayName) on Dinkr",
                                        image: Image(uiImage: img)
                                    )
                                ) {
                                    Label("Share Profile", systemImage: "square.and.arrow.up")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 15)
                                        .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 14))
                                }
                                .padding(.horizontal, 24)
                            } else {
                                Label("Share Profile", systemImage: "square.and.arrow.up")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .background(Color.dinkrGreen.opacity(0.4), in: RoundedRectangle(cornerRadius: 14))
                                    .padding(.horizontal, 24)
                            }

                            // Copy Link
                            Button {
                                UIPasteboard.general.string = "dinkr.app/player/\(user.username)"
                                HapticManager.success()
                                withAnimation { copyLinkToast = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { copyLinkToast = false }
                                }
                            } label: {
                                Label(
                                    copyLinkToast ? "Link Copied!" : "Copy Link",
                                    systemImage: copyLinkToast ? "checkmark" : "link"
                                )
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.dinkrGreen)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.dinkrGreen.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.dinkrGreen.opacity(0.35), lineWidth: 1)
                                )
                            }
                            .animation(.easeInOut(duration: 0.2), value: copyLinkToast)
                            .padding(.horizontal, 24)

                            // Download to Photos
                            Button {
                                guard let img = shareImage else { return }
                                UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                                HapticManager.success()
                                dismiss()
                            } label: {
                                Label("Download", systemImage: "arrow.down.to.line")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            .disabled(shareImage == nil)
                        }

                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationTitle("Share Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task {
            await renderCard()
        }
    }

    // MARK: - Render

    @MainActor
    private func renderCard() async {
        isRendering = true
        let renderer = ImageRenderer(content:
            ProfileShareCard(user: user, groupNames: groupNames)
                .environment(\.colorScheme, .dark)
        )
        renderer.scale = 3.0
        shareImage = renderer.uiImage
        isRendering = false
    }
}

// MARK: - Previews

#Preview("Share Card") {
    ProfileShareCard(
        user: User.mockCurrentUser,
        groupNames: ["South Austin Dinkers", "4.0+ Competitive Pool", "Mueller Morning Crew"]
    )
    .padding()
    .background(Color.gray)
}

#Preview("Share Sheet") {
    ShareProfileSheet(
        user: User.mockCurrentUser,
        groupNames: ["South Austin Dinkers", "4.0+ Competitive Pool", "Mueller Morning Crew"]
    )
}

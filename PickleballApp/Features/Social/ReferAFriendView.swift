import SwiftUI

// MARK: - Models

private struct ReferralEntry: Identifiable {
    let id = UUID()
    let name: String
    let avatarInitials: String
    let avatarColor: Color
    let joinDate: Date
    let rewardEarned: Bool
}

private struct TopReferrer: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let avatarInitials: String
    let referralCount: Int
    let isCurrentUser: Bool
}

// MARK: - Share Platform Model

private struct SharePlatform: Identifiable {
    let id = UUID()
    let label: String
    let systemIcon: String
    let color: Color
    let action: (String) -> Void
}

// MARK: - QR Code Placeholder

private struct QRCodePlaceholderView: View {
    let size: CGFloat

    private let gridSize = 7
    // A fixed pattern that looks like a real QR code structure
    private let pattern: [Int: Bool] = [
        0: true, 1: true, 2: true, 3: true, 4: true, 5: true, 6: true,
        7: false,
        8: true, 9: false, 10: false, 11: false, 12: false, 13: false, 14: true,
        15: false,
        16: true, 17: false, 18: true, 19: true, 20: true, 21: false, 22: true,
        23: false,
        24: true, 25: false, 26: true, 27: false, 28: true, 29: false, 30: true,
        31: false,
        32: true, 33: false, 34: true, 35: true, 36: true, 37: false, 38: true,
        39: false,
        40: true, 41: false, 42: false, 43: false, 44: false, 45: false, 46: true,
        47: false,
        48: true, 49: true, 50: true, 51: true, 52: true, 53: true, 54: true,
        // interior fill pattern
        56: true, 58: true, 60: true,
        64: true, 66: true,
        70: true, 72: true, 74: true, 76: true,
        80: true, 83: true, 85: true,
        // bottom-left finder
        84: true, 85: true, 86: true, 87: true, 88: true, 89: true, 90: true,
        91: false,
        92: true, 93: false, 94: false, 95: false, 96: false, 97: false, 98: true,
        99: false,
        100: true, 101: false, 102: true, 103: true, 104: true, 105: false, 106: true,
        107: false,
        108: true, 109: false, 110: true, 111: false, 112: true, 113: false, 114: true,
        115: false,
        116: true, 117: false, 118: true, 119: true, 120: true, 121: false, 122: true,
        123: false,
        124: true, 125: false, 126: false, 127: false, 128: false, 129: false, 130: true,
        131: false,
        132: true, 133: true, 134: true, 135: true, 136: true, 137: true, 138: true,
    ]

    var body: some View {
        let cellSize = size / CGFloat(gridSize)
        Canvas { ctx, _ in
            for row in 0..<gridSize {
                for col in 0..<gridSize {
                    let idx = row * gridSize + col
                    let filled: Bool
                    // Finder patterns (top-left, top-right, bottom-left)
                    let inTopLeft    = row < 3 && col < 3
                    let inTopRight   = row < 3 && col >= (gridSize - 3)
                    let inBottomLeft = row >= (gridSize - 3) && col < 3
                    if inTopLeft || inTopRight || inBottomLeft {
                        // border of finder = filled, interior alternates
                        let lr = inTopLeft ? row : (inTopRight ? row : row - (gridSize - 3))
                        let lc = inTopLeft ? col : (inTopRight ? col - (gridSize - 3) : col)
                        filled = (lr == 0 || lr == 2 || lc == 0 || lc == 2) || (lr == 1 && lc == 1)
                    } else {
                        filled = pattern[idx] ?? ((row + col) % 3 == 0)
                    }
                    if filled {
                        let rect = CGRect(
                            x: CGFloat(col) * cellSize + 1,
                            y: CGFloat(row) * cellSize + 1,
                            width: cellSize - 2,
                            height: cellSize - 2
                        )
                        ctx.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(Color.dinkrNavy))
                    }
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Avatar Stack

private struct AvatarStackView: View {
    let initials: [String]
    let colors: [Color]
    let size: CGFloat

    var body: some View {
        HStack(spacing: -(size * 0.3)) {
            ForEach(Array(zip(initials.indices, initials)), id: \.0) { idx, initial in
                ZStack {
                    Circle()
                        .fill(colors[idx % colors.count])
                        .frame(width: size, height: size)
                    Text(initial)
                        .font(.system(size: size * 0.36, weight: .bold))
                        .foregroundStyle(.white)
                }
                .overlay(Circle().strokeBorder(Color.appBackground, lineWidth: 2))
                .zIndex(Double(initials.count - idx))
            }
        }
    }
}

// MARK: - ReferAFriendView

struct ReferAFriendView: View {

    // MARK: State
    @State private var codeCopied = false
    @State private var showQRSheet = false

    // MARK: Constants
    private let referralCode  = "EVAN2026"
    private let referralURL   = "https://dinkr.app/join/EVAN2026"

    // MARK: Mock data
    private let recentReferrals: [ReferralEntry] = [
        ReferralEntry(
            name: "Jordan Smith",
            avatarInitials: "JS",
            avatarColor: Color.dinkrSky,
            joinDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            rewardEarned: true
        ),
        ReferralEntry(
            name: "Taylor Kim",
            avatarInitials: "TK",
            avatarColor: Color.dinkrAmber,
            joinDate: Calendar.current.date(byAdding: .day, value: -12, to: Date()) ?? Date(),
            rewardEarned: true
        ),
        ReferralEntry(
            name: "Sam Rivera",
            avatarInitials: "SR",
            avatarColor: Color.dinkrCoral,
            joinDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            rewardEarned: false
        ),
    ]

    private let topReferrers: [TopReferrer] = [
        TopReferrer(rank: 1, name: "ChrisP",  avatarInitials: "CP", referralCount: 18, isCurrentUser: false),
        TopReferrer(rank: 2, name: "MariaPB", avatarInitials: "MP", referralCount: 14, isCurrentUser: false),
        TopReferrer(rank: 3, name: "You",     avatarInitials: "EC", referralCount: 3,  isCurrentUser: true),
        TopReferrer(rank: 4, name: "Priya_D", avatarInitials: "PD", referralCount: 2,  isCurrentUser: false),
    ]

    private var friendsJoined: Int { recentReferrals.filter { $0.rewardEarned }.count }
    private var joinedInitials: [String] { recentReferrals.map { $0.avatarInitials } }
    private var joinedColors: [Color]   { recentReferrals.map { $0.avatarColor } }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    headerSection
                    statsRow
                    rewardBanner
                    referralCodeCard
                    shareMethodsGrid
                    qrSection
                    recentReferralsList
                    leaderboardSection
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Invite Friends")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showQRSheet) { qrFullSheet }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.dinkrGreen.opacity(0.25), Color.dinkrSky.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                Text("🏓")
                    .font(.system(size: 38))
            }
            Text("Invite Friends to Dinkr 🏓")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            Text("Grow the community. Earn rewards together.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(value: "\(friendsJoined)", label: "Joined", color: Color.dinkrGreen)
            Divider().frame(height: 36)
            statCell(value: "\(friendsJoined)", label: "Weeks Earned", color: Color.dinkrAmber)
            Divider().frame(height: 36)
            statCell(value: "\(recentReferrals.count)", label: "Pending", color: Color.dinkrCoral)
        }
        .padding(.vertical, 16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private func statCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Reward Banner

    private var rewardBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.dinkrAmber.opacity(0.18))
                    .frame(width: 46, height: 46)
                Image(systemName: "gift.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.dinkrAmber)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Earn 1 week Premium for each friend who joins")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.dinkrNavy)
                HStack(spacing: 6) {
                    AvatarStackView(
                        initials: joinedInitials,
                        colors: joinedColors,
                        size: 22
                    )
                    Text("\(friendsJoined) friend\(friendsJoined == 1 ? "" : "s") joined")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(Color.dinkrAmber.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.dinkrAmber.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Referral Code Card

    private var referralCodeCard: some View {
        VStack(spacing: 14) {
            HStack {
                Label("Your Referral Code", systemImage: "tag.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            // Large code display
            Text(referralCode)
                .font(.system(size: 36, weight: .heavy, design: .monospaced))
                .foregroundStyle(Color.dinkrNavy)
                .tracking(6)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    LinearGradient(
                        colors: [Color.dinkrGreen.opacity(0.08), Color.dinkrSky.opacity(0.06)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.dinkrGreen.opacity(0.25), lineWidth: 1.5)
                )

            // Copy button row
            HStack(spacing: 12) {
                // Link display
                HStack(spacing: 6) {
                    Image(systemName: "link")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.dinkrSky)
                    Text("dinkr.app/join/\(referralCode.lowercased())")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.dinkrNavy.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    UIPasteboard.general.string = referralURL
                    HapticManager.light()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        codeCopied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { codeCopied = false }
                    }
                } label: {
                    Label(
                        codeCopied ? "Copied!" : "Copy Link",
                        systemImage: codeCopied ? "checkmark" : "doc.on.doc"
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(codeCopied ? .white : Color.dinkrGreen)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        codeCopied ? Color.dinkrGreen : Color.dinkrGreen.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
                .animation(.easeInOut(duration: 0.2), value: codeCopied)
            }
        }
        .padding(20)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    // MARK: - Share Methods Grid

    private var shareMethodsGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Share via")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            let message = "Join me on Dinkr — the best app for finding pickleball games! Use code \(referralCode) or tap: \(referralURL)"

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {

                // Messages (ShareLink with custom message)
                ShareLink(
                    item: URL(string: referralURL)!,
                    subject: Text("Join me on Dinkr 🏓"),
                    message: Text(message)
                ) {
                    ShareMethodCell(
                        icon: "message.fill",
                        label: "Messages",
                        color: Color.dinkrGreen
                    )
                }
                .buttonStyle(.plain)

                // WhatsApp
                Button {
                    let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    if let url = URL(string: "https://wa.me/?text=\(encoded)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    ShareMethodCell(
                        icon: "bubble.left.and.bubble.right.fill",
                        label: "WhatsApp",
                        color: Color(red: 0.16, green: 0.65, blue: 0.34)
                    )
                }
                .buttonStyle(.plain)

                // Instagram Story (placeholder — deep link)
                Button {
                    // Instagram custom URL schemes require the app; gracefully fall through
                    if let url = URL(string: "instagram://"), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(URL(string: "instagram://story-camera")!)
                    } else {
                        // Fallback: copy link so user can paste into IG story
                        UIPasteboard.general.string = referralURL
                    }
                } label: {
                    ShareMethodCell(
                        icon: "camera.fill",
                        label: "Instagram Story",
                        color: Color.dinkrCoral
                    )
                }
                .buttonStyle(.plain)

                // Email
                Button {
                    let subject = "Join me on Dinkr 🏓".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    let body    = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    if let url = URL(string: "mailto:?subject=\(subject)&body=\(body)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    ShareMethodCell(
                        icon: "envelope.fill",
                        label: "Send Email",
                        color: Color.dinkrSky
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - QR Code Section

    private var qrSection: some View {
        Button {
            showQRSheet = true
        } label: {
            HStack(spacing: 16) {
                QRCodePlaceholderView(size: 58)
                    .padding(8)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Show QR Code")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.dinkrNavy)
                    Text("Let nearby friends scan to join instantly")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "qrcode")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.dinkrGreen)
            }
            .padding(16)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.dinkrGreen.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - QR Full Sheet

    private var qrFullSheet: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Text("Scan to Join Dinkr")
                    .font(.title2.weight(.bold))
                Text("Point your camera at this code")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                QRCodePlaceholderView(size: 220)
                    .padding(20)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)

                VStack(spacing: 4) {
                    Text(referralCode)
                        .font(.system(size: 22, weight: .heavy, design: .monospaced))
                        .tracking(4)
                        .foregroundStyle(Color.dinkrNavy)
                    Text(referralURL)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.top, 32)
            .padding(.horizontal, 32)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showQRSheet = false }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
    }

    // MARK: - Recent Referrals

    private var recentReferralsList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Referrals")
                .font(.headline)

            VStack(spacing: 10) {
                ForEach(recentReferrals) { entry in
                    HStack(spacing: 12) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(entry.avatarColor.opacity(0.2))
                                .frame(width: 40, height: 40)
                            Text(entry.avatarInitials)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(entry.avatarColor)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name)
                                .font(.subheadline.weight(.semibold))
                            Text("Joined \(entry.joinDate.formatted(.relative(presentation: .named)))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if entry.rewardEarned {
                            Label("Reward earned", systemImage: "checkmark.seal.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.dinkrGreen)
                                .labelStyle(.titleAndIcon)
                        } else {
                            Text("Pending")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.dinkrAmber)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.dinkrAmber.opacity(0.12), in: Capsule())
                        }
                    }
                    .padding(14)
                    .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Leaderboard

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Top Referrers This Month", systemImage: "trophy.fill")
                    .font(.headline)
                    .foregroundStyle(Color.dinkrNavy)
                Spacer()
                Text("March 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                ForEach(topReferrers) { referrer in
                    HStack(spacing: 12) {
                        // Rank badge
                        ZStack {
                            Circle()
                                .fill(rankColor(referrer.rank).opacity(0.15))
                                .frame(width: 30, height: 30)
                            Text("#\(referrer.rank)")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(rankColor(referrer.rank))
                        }

                        // Avatar
                        ZStack {
                            Circle()
                                .fill(referrer.isCurrentUser ? Color.dinkrGreen.opacity(0.2) : Color.secondary.opacity(0.12))
                                .frame(width: 34, height: 34)
                            Text(referrer.avatarInitials)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(referrer.isCurrentUser ? Color.dinkrGreen : .secondary)
                        }

                        Text(referrer.isCurrentUser ? "You" : referrer.name)
                            .font(.subheadline.weight(referrer.isCurrentUser ? .bold : .regular))
                            .foregroundStyle(referrer.isCurrentUser ? Color.dinkrGreen : .primary)

                        Spacer()

                        HStack(spacing: 4) {
                            Text("\(referrer.referralCount)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.dinkrNavy)
                            Text("referrals")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        referrer.isCurrentUser
                            ? Color.dinkrGreen.opacity(0.06)
                            : Color.cardBackground,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                referrer.isCurrentUser ? Color.dinkrGreen.opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    )
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color.dinkrAmber
        case 2: return Color(red: 0.6, green: 0.6, blue: 0.65)
        case 3: return Color(red: 0.72, green: 0.45, blue: 0.2)
        default: return Color.secondary
        }
    }
}

// MARK: - Share Method Cell

private struct ShareMethodCell: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    ReferAFriendView()
}

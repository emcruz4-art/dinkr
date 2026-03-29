import SwiftUI

struct LiveSessionDraftView: View {
    @State private var countdown = 45  // seconds to start
    @State private var timerActive = true
    @State private var players: [DraftPlayer] = DraftPlayer.mockDraftPlayers

    struct DraftPlayer: Identifiable {
        let id: String
        let name: String
        let skill: String
        let distance: String
        let status: Status
        enum Status { case confirmed, pending, open }
    }

    // 4-player doubles draft
    var confirmedPlayers: [DraftPlayer] { players.filter { $0.status == .confirmed } }
    var pendingPlayers: [DraftPlayer] { players.filter { $0.status == .pending } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Live countdown card
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color.dinkrNavy, Color.dinkrGreen.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                Text("LIVE SESSION")
                                    .font(.system(size: 11, weight: .heavy))
                                    .foregroundStyle(.white.opacity(0.9))
                            }

                            Text("Westside Pickleball Complex")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)

                            Text("Court 3 · Doubles · 3.5+")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))

                            // Countdown
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .foregroundStyle(Color.dinkrAmber)
                                    .font(.caption)
                                Text("Starts in \(countdown)s")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Color.dinkrAmber)
                            }
                        }
                        .padding(20)
                    }
                    .frame(height: 150)
                    .padding(.horizontal)

                    // Draft board
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DRAFT BOARD")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        // 4 slots grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(0..<4, id: \.self) { slot in
                                let player = slot < confirmedPlayers.count ? confirmedPlayers[slot] : nil
                                DraftSlotCard(slot: slot + 1, player: player)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // You're #3 in queue
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.dinkrSky.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Text("3")
                                .font(.title3.weight(.heavy))
                                .foregroundStyle(Color.dinkrSky)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("You're #3 in the queue")
                                .font(.subheadline.weight(.bold))
                            Text("1 player ahead of you. Standby for a spot!")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(Color.dinkrSky.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Action
                    Button {} label: {
                        Text("Confirm Spot  →")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.dinkrGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
                .padding(.top)
            }
            .navigationTitle("Live Draft")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct DraftSlotCard: View {
    let slot: Int
    let player: LiveSessionDraftView.DraftPlayer?

    var body: some View {
        VStack(spacing: 10) {
            if let player = player {
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Text(String(player.name.prefix(1)))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.dinkrGreen)
                    Circle()
                        .fill(Color.dinkrGreen)
                        .frame(width: 14, height: 14)
                        .overlay(Image(systemName: "checkmark").font(.system(size: 7, weight: .heavy)).foregroundStyle(.white))
                        .offset(x: 18, y: 18)
                }
                Text(player.name.components(separatedBy: " ").first ?? "")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text(player.skill)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                Text("✓ Confirmed")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.dinkrGreen)
            } else {
                ZStack {
                    Circle()
                        .stroke(Color.dinkrGreen.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .frame(width: 52, height: 52)
                    Image(systemName: "plus")
                        .foregroundStyle(Color.dinkrGreen.opacity(0.5))
                        .font(.title3)
                }
                Text("Slot \(slot)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("")
                    .font(.system(size: 9))
                Text("Open")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(player != nil ? Color.dinkrGreen.opacity(0.04) : Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension LiveSessionDraftView {
    static let mockDraftPlayers: [DraftPlayer] = []
}

extension LiveSessionDraftView.DraftPlayer {
    static let mockDraftPlayers: [LiveSessionDraftView.DraftPlayer] = [
        .init(id: "dp1", name: "Maria Chen", skill: "3.5", distance: "0.4 mi", status: .confirmed),
        .init(id: "dp2", name: "Jordan Smith", skill: "4.0", distance: "0.8 mi", status: .confirmed),
        .init(id: "dp3", name: "Open Slot", skill: "", distance: "", status: .open),
        .init(id: "dp4", name: "Open Slot", skill: "", distance: "", status: .open),
    ]
}

import SwiftUI

struct CourtCheckIn: Identifiable {
    let id: String
    let userId: String
    let userName: String
    let courtName: String
    let emoji: String
    let minutesAgo: Int
    let isYours: Bool
}

struct CheckInStoriesBar: View {
    let checkIns: [CourtCheckIn]
    @State private var showAddCheckIn = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                // "You" add button
                AddCheckInButton(action: { showAddCheckIn = true })

                ForEach(checkIns) { checkIn in
                    CheckInBubble(checkIn: checkIn)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $showAddCheckIn) {
            AddCheckInSheet()
        }
    }

    static let mockCheckIns: [CourtCheckIn] = [
        CourtCheckIn(id: "ci1", userId: "user_002", userName: "Maria", courtName: "Westside Courts", emoji: "🏓", minutesAgo: 5, isYours: false),
        CourtCheckIn(id: "ci2", userId: "user_003", userName: "Jordan", courtName: "Mueller Park", emoji: "🎯", minutesAgo: 12, isYours: false),
        CourtCheckIn(id: "ci3", userId: "user_007", userName: "Jamie", courtName: "Barton Springs", emoji: "🔥", minutesAgo: 28, isYours: false),
        CourtCheckIn(id: "ci4", userId: "user_004", userName: "Sarah", courtName: "South Lamar", emoji: "💪", minutesAgo: 45, isYours: false),
        CourtCheckIn(id: "ci5", userId: "user_009", userName: "Riley", courtName: "Zilker Park", emoji: "🌟", minutesAgo: 67, isYours: false),
    ]
}

struct CheckInBubble: View {
    let checkIn: CourtCheckIn
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    // Gradient ring (like Instagram unread story)
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.dinkrGreen, Color.dinkrAmber],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: 62, height: 62)

                    Circle()
                        .fill(Color.appBackground)
                        .frame(width: 56, height: 56)

                    AvatarView(displayName: checkIn.userName, size: 52)

                    // Emoji badge
                    Text(checkIn.emoji)
                        .font(.system(size: 14))
                        .frame(width: 22, height: 22)
                        .background(Color.appBackground)
                        .clipShape(Circle())
                        .offset(x: 18, y: 18)
                }
                .frame(width: 64, height: 64)

                Text(checkIn.userName)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)

                Text(checkIn.minutesAgo < 60 ? "\(checkIn.minutesAgo)m" : "\(checkIn.minutesAgo / 60)h")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            CheckInDetailSheet(checkIn: checkIn)
        }
    }
}

struct AddCheckInButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(Color.dinkrGreen.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                        .frame(width: 62, height: 62)
                    ZStack {
                        Circle()
                            .fill(Color.dinkrGreen.opacity(0.10))
                            .frame(width: 52, height: 52)
                        Image(systemName: "plus")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color.dinkrGreen)
                    }
                }
                .frame(width: 64, height: 64)

                Text("Check In")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color.dinkrGreen)

                Text("now")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct CheckInDetailSheet: View {
    let checkIn: CourtCheckIn
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                AvatarView(displayName: checkIn.userName, size: 80)

                VStack(spacing: 6) {
                    Text(checkIn.userName)
                        .font(.title2.weight(.bold))
                    Text("is playing at")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(checkIn.courtName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                    Text("\(checkIn.emoji) \(checkIn.minutesAgo)m ago")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Button {} label: {
                        Text("Join Session")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.dinkrGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    Button {} label: {
                        Text("Message")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.dinkrSky)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.dinkrSky.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .padding(.top, 32)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct AddCheckInSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCourt = 0
    @State private var selectedEmoji = "🏓"
    let courts = ["Westside Pickleball Complex", "Mueller Recreation Center", "South Lamar Sports Club", "Barton Springs Tennis Center", "Zilker Park Courts"]
    let emojis = ["🏓", "🔥", "💪", "🎯", "🌟", "😤", "🏆", "⚡"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Where are you playing?")
                    .font(.title3.weight(.bold))
                    .padding(.top)

                // Court picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Court")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Picker("Court", selection: $selectedCourt) {
                        ForEach(courts.indices, id: \.self) { i in
                            Text(courts[i]).tag(i)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(12)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                // Emoji picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vibe")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(emojis, id: \.self) { emoji in
                                Button {
                                    selectedEmoji = emoji
                                } label: {
                                    Text(emoji)
                                        .font(.title2)
                                        .frame(width: 52, height: 52)
                                        .background(selectedEmoji == emoji ? Color.dinkrGreen.opacity(0.15) : Color.cardBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedEmoji == emoji ? Color.dinkrGreen : Color.clear, lineWidth: 2)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Button {
                    dismiss()
                } label: {
                    Text("Check In \(selectedEmoji)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.dinkrGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Court Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

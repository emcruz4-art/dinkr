import SwiftUI

// MARK: - Activity Type

enum ActivityType: String, CaseIterable {
    case all = "All"
    case games = "Games"
    case social = "Social"
    case achievements = "Achievements"
    case market = "Market"

    var dotColor: Color {
        switch self {
        case .all: return Color.dinkrGreen
        case .games: return Color.dinkrGreen
        case .social: return Color.dinkrSky
        case .achievements: return Color.dinkrCoral
        case .market: return Color.dinkrAmber
        }
    }

    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .games: return "figure.pickleball"
        case .social: return "person.2.fill"
        case .achievements: return "trophy.fill"
        case .market: return "bag.fill"
        }
    }
}

// MARK: - Activity Item Model

struct ActivityItem: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let timeAgo: String
    let type: ActivityType
    let systemIcon: String

    init(id: UUID = UUID(), title: String, subtitle: String, timeAgo: String, type: ActivityType, systemIcon: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.timeAgo = timeAgo
        self.type = type
        self.systemIcon = systemIcon
    }

    static let mockItems: [ActivityItem] = [
        ActivityItem(
            title: "Joined game at Westside",
            subtitle: "Open play · 4 players confirmed",
            timeAgo: "2h ago",
            type: .games,
            systemIcon: "figure.pickleball"
        ),
        ActivityItem(
            title: "Won 11–7 against Maria",
            subtitle: "Singles · Westside Pickleball Complex",
            timeAgo: "Yesterday",
            type: .games,
            systemIcon: "trophy.fill"
        ),
        ActivityItem(
            title: "New achievement: Centurion 🏆",
            subtitle: "Played 100 games total",
            timeAgo: "2d ago",
            type: .achievements,
            systemIcon: "medal.fill"
        ),
        ActivityItem(
            title: "Posted a highlight",
            subtitle: "\"That cross-court dink though...\"",
            timeAgo: "3d ago",
            type: .social,
            systemIcon: "play.circle.fill"
        ),
        ActivityItem(
            title: "Joined South Austin DinkrGroup",
            subtitle: "248 members · Public group",
            timeAgo: "4d ago",
            type: .social,
            systemIcon: "person.3.fill"
        ),
        ActivityItem(
            title: "Lost 9–11 to Carlos R.",
            subtitle: "Doubles · Barton Creek Courts",
            timeAgo: "4d ago",
            type: .games,
            systemIcon: "figure.pickleball"
        ),
        ActivityItem(
            title: "Listed paddle for sale",
            subtitle: "Joola Perseus · $89",
            timeAgo: "5d ago",
            type: .market,
            systemIcon: "tag.fill"
        ),
        ActivityItem(
            title: "New achievement: Hot Streak 🔥",
            subtitle: "Won 5 games in a row",
            timeAgo: "5d ago",
            type: .achievements,
            systemIcon: "flame.fill"
        ),
        ActivityItem(
            title: "Followed Jamie Nguyen",
            subtitle: "4.2 DUPR · Austin, TX",
            timeAgo: "6d ago",
            type: .social,
            systemIcon: "person.badge.plus"
        ),
        ActivityItem(
            title: "Won 11–3 against Sam T.",
            subtitle: "Singles · Mueller Recreation Center",
            timeAgo: "6d ago",
            type: .games,
            systemIcon: "trophy.fill"
        ),
        ActivityItem(
            title: "Purchased new grip tape",
            subtitle: "Wilson Pro Overgrip 3-pack",
            timeAgo: "1w ago",
            type: .market,
            systemIcon: "bag.fill"
        ),
        ActivityItem(
            title: "New achievement: Social Butterfly",
            subtitle: "Played with 10 different opponents",
            timeAgo: "1w ago",
            type: .achievements,
            systemIcon: "star.fill"
        ),
        ActivityItem(
            title: "Created event: Saturday Drills",
            subtitle: "Westside · Mar 29 · 8 AM",
            timeAgo: "1w ago",
            type: .social,
            systemIcon: "calendar.badge.plus"
        ),
        ActivityItem(
            title: "Won 11–6 against Alex P.",
            subtitle: "Mixed doubles · Barton Creek Courts",
            timeAgo: "1w ago",
            type: .games,
            systemIcon: "figure.pickleball"
        ),
    ]
}

// MARK: - RecentActivityView

struct RecentActivityView: View {
    @State private var selectedFilter: ActivityType = .all
    @State private var displayCount = 8

    private var filtered: [ActivityItem] {
        if selectedFilter == .all {
            return ActivityItem.mockItems
        }
        return ActivityItem.mockItems.filter { $0.type == selectedFilter }
    }

    private var displayed: [ActivityItem] {
        Array(filtered.prefix(displayCount))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(ActivityType.allCases, id: \.self) { filter in
                            ActivityFilterChip(
                                label: filter.rawValue,
                                icon: filter.icon,
                                isSelected: selectedFilter == filter,
                                color: filter.dotColor
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedFilter = filter
                                    displayCount = 8
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }

                // Timeline
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(displayed.enumerated()), id: \.element.id) { index, item in
                        ActivityTimelineRow(
                            item: item,
                            isLast: index == displayed.count - 1
                        )
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 8)),
                            removal: .opacity
                        ))
                    }
                }
                .padding(.horizontal, 20)
                .animation(.easeInOut(duration: 0.25), value: selectedFilter)
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: displayCount)

                // Load more button
                if displayCount < filtered.count {
                    Button {
                        withAnimation {
                            displayCount += 6
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Load more")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(Color.dinkrGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.dinkrGreen.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.dinkrGreen.opacity(0.22), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                } else {
                    Text("You're all caught up!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 24)
                }
            }
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Filter Chip

private struct ActivityFilterChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(label)
                    .font(.subheadline.weight(isSelected ? .bold : .regular))
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? AnyShapeStyle(color)
                    : AnyShapeStyle(Color.secondary.opacity(0.1))
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Activity Timeline Row

private struct ActivityTimelineRow: View {
    let item: ActivityItem
    let isLast: Bool

    private var dotColor: Color {
        switch item.type {
        case .games:        return Color.dinkrGreen
        case .achievements: return Color.dinkrCoral
        case .social:       return Color.dinkrSky
        case .market:       return Color.dinkrAmber
        case .all:          return Color.dinkrNavy
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left timeline column
            VStack(spacing: 0) {
                // Circle dot
                ZStack {
                    Circle()
                        .fill(dotColor.opacity(0.18))
                        .frame(width: 32, height: 32)
                    Circle()
                        .stroke(dotColor, lineWidth: 2)
                        .frame(width: 32, height: 32)
                    Image(systemName: item.systemIcon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(dotColor)
                }

                // Vertical line
                if !isLast {
                    Rectangle()
                        .fill(dotColor.opacity(0.2))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .frame(width: 32)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Text(item.timeAgo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(.leading, 12)
            .padding(.bottom, isLast ? 0 : 20)
            .padding(.top, 6)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RecentActivityView()
    }
}

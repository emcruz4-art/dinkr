import SwiftUI

// MARK: - PaginatedListView

/// A reusable paginated list wrapper backed by a LazyVStack.
/// When the user scrolls to the last item, `onLoadMore` is triggered automatically.
/// Shows skeleton placeholders while loading and a "caught up" footer when exhausted.
struct PaginatedListView<Item: Identifiable, ItemView: View>: View {
    let items: [Item]
    let isLoading: Bool
    let hasMore: Bool
    let onLoadMore: () async -> Void
    @ViewBuilder let itemView: (Item) -> ItemView

    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(items) { item in
                itemView(item)
            }

            if hasMore {
                // Invisible trigger at the bottom of the list; fires onLoadMore when visible
                LoadMoreTrigger(action: onLoadMore)

                if isLoading {
                    // Show skeleton cards while the next page loads
                    ForEach(0..<3, id: \.self) { _ in
                        GameCardSkeleton()
                            .padding(.horizontal, 16)
                    }
                }
            } else if !items.isEmpty {
                // All pages exhausted
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.dinkrGreen)
                    Text("You're all caught up")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 20)
            }
        }
    }
}

// MARK: - LoadMoreTrigger

/// An invisible 1-pt view that fires `action` once when it first appears in the viewport.
/// Subsequent appearances (e.g. layout recalculations) are ignored until the view is
/// reset by the parent replacing `items`.
struct LoadMoreTrigger: View {
    let action: () async -> Void

    @State private var isTriggering = false

    var body: some View {
        Color.clear
            .frame(height: 1)
            .onAppear {
                guard !isTriggering else { return }
                isTriggering = true
                Task {
                    await action()
                    // Allow re-triggering once the task finishes (next page boundary)
                    isTriggering = false
                }
            }
    }
}

import SwiftUI

// MARK: - BookmarkButton
//
// A reusable bookmark toggle button wired to BookmarkService.
// Displays bookmark.fill when saved, bookmark when not.
// Fires HapticManager.selection() on each tap and animates
// with a spring scale to give a satisfying snap.

struct BookmarkButton: View {
    let id: String
    let type: BookmarkType

    @State private var service = BookmarkService.shared
    @State private var scale: CGFloat = 1.0

    private var isSaved: Bool {
        switch type {
        case .game:    return service.isSaved(gameId: id)
        case .event:   return service.isSaved(eventId: id)
        case .listing: return service.isSaved(listingId: id)
        case .post:    return service.isSaved(postId: id)
        }
    }

    var body: some View {
        Button {
            HapticManager.selection()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                scale = 1.25
            }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5).delay(0.1)) {
                scale = 1.0
            }
            switch type {
            case .game:    service.toggle(gameId: id)
            case .event:   service.toggle(eventId: id)
            case .listing: service.toggle(listingId: id)
            case .post:    service.toggle(postId: id)
            }
        } label: {
            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSaved ? Color.dinkrGreen : .secondary)
                .scaleEffect(scale)
                .padding(7)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: 20) {
        BookmarkButton(id: "preview_game", type: .game)
        BookmarkButton(id: "preview_event", type: .event)
        BookmarkButton(id: "preview_listing", type: .listing)
    }
    .padding()
}

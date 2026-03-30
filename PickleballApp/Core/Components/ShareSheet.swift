import SwiftUI
import UIKit

// MARK: - UIActivityViewController Wrapper

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Dinkr Deep Link Builder

enum DinkrDeepLink {
    case profile(userId: String)
    case event(eventId: String)
    case listing(listingId: String)
    case session(sessionId: String)

    private var scheme: String { "dinkr" }
    private var webBase: String { "https://dinkr.app" }

    private var path: String {
        switch self {
        case .profile(let id):  return "/profile/\(id)"
        case .event(let id):    return "/event/\(id)"
        case .listing(let id):  return "/listing/\(id)"
        case .session(let id):  return "/session/\(id)"
        }
    }

    var url: URL {
        // dinkr://profile/user_001
        let raw = "\(scheme):/\(path)"
        return URL(string: raw) ?? URL(string: "dinkr://")!
    }

    var webURL: URL {
        // https://dinkr.app/profile/user_001
        return URL(string: "\(webBase)\(path)") ?? URL(string: webBase)!
    }

    var shareText: String {
        switch self {
        case .profile:  return "Check out this player on Dinkr!"
        case .event:    return "Join me at this pickleball event on Dinkr!"
        case .listing:  return "Check out this listing on Dinkr Marketplace!"
        case .session:  return "Come play pickleball with me — join this session on Dinkr!"
        }
    }
}

// MARK: - Dinkr Share Button

struct DinkrShareButton: View {
    let link: DinkrDeepLink

    @State private var showShareSheet = false

    var body: some View {
        Button {
            showShareSheet = true
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.dinkrGreen)
                .frame(width: 44, height: 44)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 10))
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityShareSheet(items: [link.shareText, link.webURL])
                .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        DinkrShareButton(link: .profile(userId: "user_001"))
        DinkrShareButton(link: .event(eventId: "evt_001"))
        DinkrShareButton(link: .listing(listingId: "listing_001"))
    }
    .padding()
}

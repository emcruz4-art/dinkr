import Foundation

@Observable
final class TabRouter {
    static let shared = TabRouter()
    var selectedTab: AppTab = .home
    var showSearch: Bool = false

    private init() {}
}

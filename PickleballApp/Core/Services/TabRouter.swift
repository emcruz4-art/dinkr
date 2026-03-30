import Foundation

@Observable
final class TabRouter {
    static let shared = TabRouter()
    var selectedTab: AppTab = .home

    private init() {}
}

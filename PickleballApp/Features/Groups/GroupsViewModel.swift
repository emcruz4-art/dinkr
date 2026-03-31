import Foundation
import Observation

@Observable
final class GroupsViewModel {
    var myGroups: [DinkrGroup] = []
    var discoverGroups: [DinkrGroup] = []
    var isLoading = false
    var showCreateGroup = false

    private let firestoreService = FirestoreService.shared

    func load(currentUserId: String? = nil) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let allGroups: [DinkrGroup] = try await firestoreService.queryCollectionOrdered(
                collection: FirestoreCollections.groups,
                orderBy: "name"
            )
            if let uid = currentUserId {
                myGroups = allGroups.filter { $0.memberIds.contains(uid) }
            } else {
                myGroups = []
            }
            discoverGroups = allGroups
        } catch {
            print("[GroupsViewModel] load error: \(error)")
            #if DEBUG
            let all = DinkrGroup.mockGroups
            myGroups = currentUserId != nil ? Array(all.prefix(2)) : []
            discoverGroups = all
            #endif
        }
    }
}

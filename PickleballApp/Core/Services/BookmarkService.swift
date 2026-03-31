import Foundation
import Observation

// MARK: - BookmarkType

enum BookmarkType {
    case game, event, listing, post
}

// MARK: - BookmarkService

@Observable
final class BookmarkService {

    static let shared = BookmarkService()

    // MARK: Stored properties (backed by UserDefaults)

    var savedGameIds: Set<String> = [] {
        didSet { persist(savedGameIds, key: Keys.games) }
    }
    var savedEventIds: Set<String> = [] {
        didSet { persist(savedEventIds, key: Keys.events) }
    }
    var savedListingIds: Set<String> = [] {
        didSet { persist(savedListingIds, key: Keys.listings) }
    }
    var savedPostIds: Set<String> = [] {
        didSet { persist(savedPostIds, key: Keys.posts) }
    }

    // MARK: Init

    private init() {
        savedGameIds    = load(key: Keys.games)
        savedEventIds   = load(key: Keys.events)
        savedListingIds = load(key: Keys.listings)
        savedPostIds    = load(key: Keys.posts)
    }

    // MARK: Toggle

    func toggle(gameId: String) {
        if savedGameIds.contains(gameId) {
            savedGameIds.remove(gameId)
        } else {
            savedGameIds.insert(gameId)
        }
    }

    func toggle(eventId: String) {
        if savedEventIds.contains(eventId) {
            savedEventIds.remove(eventId)
        } else {
            savedEventIds.insert(eventId)
        }
    }

    func toggle(listingId: String) {
        if savedListingIds.contains(listingId) {
            savedListingIds.remove(listingId)
        } else {
            savedListingIds.insert(listingId)
        }
    }

    func toggle(postId: String) {
        if savedPostIds.contains(postId) {
            savedPostIds.remove(postId)
        } else {
            savedPostIds.insert(postId)
        }
    }

    // MARK: Query

    func isSaved(gameId: String) -> Bool     { savedGameIds.contains(gameId) }
    func isSaved(eventId: String) -> Bool    { savedEventIds.contains(eventId) }
    func isSaved(listingId: String) -> Bool  { savedListingIds.contains(listingId) }
    func isSaved(postId: String) -> Bool     { savedPostIds.contains(postId) }

    // MARK: Private helpers

    private enum Keys {
        static let games    = "dinkr.bookmarks.games"
        static let events   = "dinkr.bookmarks.events"
        static let listings = "dinkr.bookmarks.listings"
        static let posts    = "dinkr.bookmarks.posts"
    }

    private func persist(_ set: Set<String>, key: String) {
        UserDefaults.standard.set(Array(set), forKey: key)
    }

    private func load(key: String) -> Set<String> {
        let array = UserDefaults.standard.stringArray(forKey: key) ?? []
        return Set(array)
    }
}

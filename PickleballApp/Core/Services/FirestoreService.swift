import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    private init() {}

    // MARK: - Get single document

    func getDocument<T: Decodable>(collection: String, documentId: String) async throws -> T {
        try await db.collection(collection).document(documentId).getDocument(as: T.self)
    }

    // MARK: - Set (overwrite) document

    func setDocument<T: Encodable>(_ value: T, collection: String, documentId: String) async throws {
        try db.collection(collection).document(documentId).setData(from: value)
    }

    // MARK: - Delete document

    func deleteDocument(collection: String, documentId: String) async throws {
        try await db.collection(collection).document(documentId).delete()
    }

    // MARK: - Add document (auto-generated ID)

    func addDocument<T: Encodable>(_ value: T, collection: String) async throws -> String {
        let ref = try db.collection(collection).addDocument(from: value)
        return ref.documentID
    }

    // MARK: - Query by equality

    func queryCollection<T: Decodable>(collection: String,
                                        field: String,
                                        isEqualTo value: Any) async throws -> [T] {
        let snapshot = try await db.collection(collection)
            .whereField(field, isEqualTo: value)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: T.self) }
    }

    // MARK: - Query ordered with optional limit

    func queryCollectionOrdered<T: Decodable>(collection: String,
                                               orderBy field: String,
                                               descending: Bool = false,
                                               limit: Int? = nil) async throws -> [T] {
        var query: Query = db.collection(collection).order(by: field, descending: descending)
        if let limit { query = query.limit(to: limit) }
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.map { try $0.data(as: T.self) }
    }

    // MARK: - Query where field >= value, ordered

    func queryCollectionWhere<T: Decodable>(collection: String,
                                             whereField: String,
                                             isGreaterThanOrEqualTo value: Any,
                                             orderBy orderField: String,
                                             descending: Bool = false) async throws -> [T] {
        let snapshot = try await db.collection(collection)
            .whereField(whereField, isGreaterThanOrEqualTo: value)
            .order(by: orderField, descending: descending)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: T.self) }
    }

    // MARK: - Query where field in array

    func queryCollectionWhereIn<T: Decodable>(collection: String,
                                               field: String,
                                               arrayContains value: Any) async throws -> [T] {
        let snapshot = try await db.collection(collection)
            .whereField(field, arrayContains: value)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: T.self) }
    }

    // MARK: - Update specific fields (for FieldValue operations)

    func updateDocument(collection: String, documentId: String, data: [String: Any]) async throws {
        try await db.collection(collection).document(documentId).updateData(data)
    }

    // MARK: - Listen to collection

    func listenToCollection<T: Decodable>(collection: String,
                                           onChange: @escaping ([T]) -> Void) -> ListenerRegistration {
        db.collection(collection).addSnapshotListener { snapshot, _ in
            guard let snapshot else { return }
            let items = snapshot.documents.compactMap { try? $0.data(as: T.self) }
            onChange(items)
        }
    }
}

enum FirestoreError: LocalizedError {
    case decodingFailed
    case notFound

    var errorDescription: String? {
        switch self {
        case .decodingFailed: return "Failed to decode Firestore document."
        case .notFound: return "Document not found."
        }
    }
}

import StoreKit
import Observation

@Observable
final class StoreService {
    static let shared = StoreService()

    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading: Bool = false

    #if DEBUG
    var debugIsPro: Bool = false
    #endif

    var isPro: Bool {
        #if DEBUG
        if debugIsPro { return true }
        #endif
        return purchasedProductIDs.contains(ProductID.monthlyPro)
            || purchasedProductIDs.contains(ProductID.yearlyPro)
    }

    // MARK: - Product IDs

    enum ProductID {
        static let monthlyPro = "com.dinkr.ios.pro.monthly"
        static let yearlyPro  = "com.dinkr.ios.pro.yearly"
    }

    // MARK: - Init

    private init() {
        // Start listening for transactions immediately
        let _ = listenForTransactions()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let ids: [String] = [ProductID.monthlyPro, ProductID.yearlyPro]
            let fetched = try await Product.products(for: ids)
            // Sort: monthly first, then yearly
            products = fetched.sorted { lhs, rhs in
                lhs.id == ProductID.monthlyPro
            }
        } catch {
            // In dev builds App Store products won't exist — fail silently
            products = []
        }

        await updatePurchasedProducts()
    }

    // MARK: - Purchase

    /// Returns `true` if purchase completed successfully.
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return true

        case .userCancelled:
            return false

        case .pending:
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            // Restore failure is non-fatal in dev builds
        }
    }

    // MARK: - Private Helpers

    private func updatePurchasedProducts() async {
        var validIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.revocationDate == nil {
                    validIDs.insert(transaction.productID)
                }
            }
        }

        purchasedProductIDs = validIDs
    }

    @discardableResult
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }

            for await result in Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}

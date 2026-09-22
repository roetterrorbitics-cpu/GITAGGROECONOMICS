import Foundation
import StoreKit

@MainActor
final class SubscriptionStore: ObservableObject {
    @Published private(set) var products: [Product] = []

    private let productIDs = [
        "com.roetterrorbitics.rendert.creator",
        "com.roetterrorbitics.rendert.pro"
    ]

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            products = []
        }
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            guard case .success(let verification) = result else { return }

            switch verification {
            case .verified(let transaction):
                await transaction.finish()
            case .unverified:
                break
            }
        } catch {
            // The UI stays usable; production will surface a user-facing error state here.
        }
    }
}

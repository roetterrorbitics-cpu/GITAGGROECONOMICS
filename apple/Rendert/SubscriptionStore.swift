import Foundation
import Combine
import StoreKit

@MainActor
final class SubscriptionStore: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var activeProductIDs = Set<String>()
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let productIDs = [
        "com.roetterrorbitics.rendert.creator",
        "com.roetterrorbitics.rendert.pro"
    ]

    private var updatesTask: Task<Void, Never>?
    weak var authStore: AuthStore?

    init() { updatesTask = listenForTransactions() }
    deinit { updatesTask?.cancel() }

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs).sorted { $0.price < $1.price }
            await refreshEntitlements()
        } catch {
            products = []
            errorMessage = "Die Apple-Abo-Produkte konnten noch nicht geladen werden."
        }
    }

    func purchase(_ product: Product) async {
        guard authStore?.isAuthenticated == true else {
            errorMessage = "Bitte zuerst anmelden, damit das Abo deinem Rendert-Konto zugeordnet werden kann."
            return
        }
        isLoading = true
        defer { isLoading = false }

        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    errorMessage = "Apple konnte die Transaktion nicht verifizieren."
                    return
                }
                await syncTransaction(transaction)
                await transaction.finish()
                await refreshEntitlements()
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Die Zahlung wartet noch auf Bestätigung."
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            guard let self else { return }
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await syncTransaction(transaction)
                await transaction.finish()
                await refreshEntitlements()
            }
        }
    }

    private func refreshEntitlements() async {
        var active = Set<String>()
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            active.insert(transaction.productID)
            await syncTransaction(transaction)
        }
        activeProductIDs = active
    }

    private func syncTransaction(_ transaction: Transaction) async {
        guard let authStore else { return }
        do {
            let body = try JSONEncoder().encode(AppleSyncRequest(
                transactionJWS: transaction.jwsRepresentation,
                productID: transaction.productID
            ))
            let request = try await authStore.authorizedRequest(
                path: "api/apple/sync-subscription",
                body: body
            )
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                let message = (try? JSONDecoder().decode(AppleSyncError.self, from: data).message)
                    ?? "Abo konnte nicht mit Rendert synchronisiert werden."
                throw NSError(
                    domain: "Rendert",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: message]
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct AppleSyncRequest: Encodable {
    let transactionJWS: String
    let productID: String
}

private struct AppleSyncError: Decodable {
    let message: String
}

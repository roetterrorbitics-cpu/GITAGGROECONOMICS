import SwiftUI

@main
struct RendertApp: App {
    @StateObject private var store = SubscriptionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}

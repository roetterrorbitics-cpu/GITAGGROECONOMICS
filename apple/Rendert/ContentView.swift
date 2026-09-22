import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @Environment(\\.openURL) private var openURL
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            home
                .tabItem { Label("Start", systemImage: "sparkles") }
                .tag(0)

            workspace
                .tabItem { Label("Workspace", systemImage: "rectangle.3.group") }
                .tag(1)

            account
                .tabItem { Label("Konto", systemImage: "person.crop.circle") }
                .tag(2)
        }
        .task {
            await store.loadProducts()
        }
    }

    private var home: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Rendert")
                        .font(.largeTitle.bold())

                    Text("KI, die für Menschen arbeitet.")
                        .font(.title2.weight(.semibold))

                    Text("Eine native Apple-Oberfläche für den Rendert Workspace – klar, schnell und auf mehreren Apple-Plattformen nutzbar.")
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        stat(title: "Auth", value: "Supabase")
                        stat(title: "Web", value: "Live-ready")
                        stat(title: "Apple", value: "SwiftUI")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Apple-Abo")
                            .font(.headline)

                        Text("Creator und Pro werden in der Apple-App über StoreKit eingebunden. Die bestehende PayPal-Abrechnung bleibt für die Web-App getrennt.")
                            .foregroundStyle(.secondary)

                        if store.products.isEmpty {
                            Text("StoreKit-Produkte sind noch nicht in App Store Connect verbunden.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(store.products, id: \.id) { product in
                                Button {
                                    Task { await store.purchase(product) }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(product.displayName)
                                            Text(product.displayPrice)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                }
                .padding()
            }
            .navigationTitle("Rendert")
        }
    }

    private var workspace: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "rectangle.3.group")
                    .font(.system(size: 52))
                    .foregroundStyle(.secondary)
                Text("Dein Workspace")
                    .font(.title.bold())
                Text("Der native Apple-Workspace ist vorbereitet. Als Nächstes verbinden wir hier Auth, KI-Workflows und deine Backend-Daten.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 520)
            }
            .padding()
            .navigationTitle("Workspace")
        }
    }

    private var account: some View {
        NavigationStack {
            Form {
                Section("Konto") {
                    Label("Supabase Auth", systemImage: "person.badge.key")
                    Text("Web-Login und native Session-Verknüpfung werden im nächsten Integrationsschritt gekoppelt.")
                        .foregroundStyle(.secondary)
                }

                Section("Web-App") {
                    Button("Rendert im Browser öffnen") {
                        openURL(URL(string: "https://your-production-domain.example/")!)
                    }
                }
            }
            .navigationTitle("Konto")
        }
    }

    private func stat(title: String, value: String) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
    }
}

import SwiftUI

struct ContentView: View {
    @StateObject private var auth = AuthStore()
    @EnvironmentObject private var store: SubscriptionStore
    @Environment(\.openURL) private var openURL
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            home.tabItem { Label("Start", systemImage: "sparkles") }.tag(0)
            workspace.tabItem { Label("Workspace", systemImage: "rectangle.3.group") }.tag(1)
            account.tabItem { Label("Konto", systemImage: "person.crop.circle") }.tag(2)
        }
        .task {
            store.authStore = auth
            await auth.bootstrap()
            await store.loadProducts()
        }
    }

    private var home: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Rendert").font(.largeTitle.bold())
                    Text("KI, die für Menschen arbeitet.").font(.title2.weight(.semibold))
                    Text("Native Apple-App für deinen Rendert Workspace.")
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        stat(title: "Auth", value: auth.isAuthenticated ? "Angemeldet" : "Gast")
                        stat(title: "Apple", value: "StoreKit 2")
                    }

                    paywall
                }
                .padding()
            }
            .navigationTitle("Rendert")
        }
    }

    private var paywall: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rendert Pro").font(.headline)
            Text("Creator und Pro werden auf Apple-Plattformen als auto-renewable subscriptions über StoreKit verkauft.")
                .foregroundStyle(.secondary)

            if !auth.isAuthenticated {
                Button("Anmelden / Account erstellen") { selection = 2 }
                    .buttonStyle(.borderedProminent)
            }

            if store.products.isEmpty {
                Text("StoreKit-Produkte sind noch nicht in App Store Connect verbunden.")
                    .font(.footnote).foregroundStyle(.secondary)
            } else {
                ForEach(store.products, id: \.id) { product in
                    let active = store.activeProductIDs.contains(product.id)
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
                            Text(active ? "Aktiv" : "Abonnieren")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(active || !auth.isAuthenticated)
                }
            }

            Button("Käufe wiederherstellen") {
                Task { await store.restorePurchases() }
            }
            .buttonStyle(.bordered)

            if let error = store.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var workspace: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "rectangle.3.group")
                    .font(.system(size: 52))
                    .foregroundStyle(.secondary)
                Text(auth.isAuthenticated ? "Dein Workspace" : "Workspace gesperrt")
                    .font(.title.bold())
                Text(auth.isAuthenticated
                     ? "Hier hängen wir die eigentlichen Rendert-KI-Workflows und deine Daten an."
                     : "Melde dich an, um den Workspace zu öffnen.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                if !auth.isAuthenticated {
                    Button("Anmelden") { selection = 2 }
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Workspace")
        }
    }

    private var account: some View {
        NavigationStack {
            Form {
                Section("Konto") {
                    if auth.isAuthenticated {
                        Label(auth.email.isEmpty ? "Angemeldet" : auth.email, systemImage: "checkmark.seal")
                        Button("Abmelden", role: .destructive) { auth.signOut() }
                    } else {
                        LoginForm(auth: auth)
                    }
                }

                Section("Web-App") {
                    Button("Rendert im Browser öffnen") {
                        guard let url = URL(string: "https://your-production-domain.example") else { return }
                        openURL(url)
                    }
                    Text("Die finale Produktions-Domain wird nach dem Vercel-Deployment eingesetzt.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Konto")
        }
    }

    private func stat(title: String, value: String) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct LoginForm: View {
    @ObservedObject var auth: AuthStore
    @State private var email = ""
    @State private var password = ""
    @State private var register = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Modus", selection: $register) {
                Text("Anmelden").tag(false)
                Text("Registrieren").tag(true)
            }
            .pickerStyle(.segmented)

            TextField("E-Mail", text: $email)
                .textInputAutocapitalization(.never)
                .textContentType(.username)

            SecureField("Passwort", text: $password)

            Button(register ? "Account erstellen" : "Anmelden") {
                Task {
                    if register {
                        await auth.signUp(email: email, password: password)
                    } else {
                        await auth.signIn(email: email, password: password)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(email.isEmpty || password.count < 8 || auth.isLoading)

            Button("Passwort zurücksetzen") {
                Task { await auth.sendPasswordReset(email: email) }
            }
            .font(.footnote)

            if let error = auth.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}

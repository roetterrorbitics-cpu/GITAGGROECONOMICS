import Foundation
import Combine

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var isAuthenticated = false
    @Published private(set) var email = ""
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private(set) var config: AppConfig?

    init() {
        isAuthenticated = KeychainStore.loadSession() != nil
    }

    func bootstrap() async {
        do {
            if config == nil { config = try await AppConfig.load() }
            guard let session = KeychainStore.loadSession() else { return }
            let user = try await requestUser(accessToken: session.accessToken)
            email = user.email ?? ""
            isAuthenticated = true
        } catch {
            signOut()
        }
    }

    func signUp(email: String, password: String) async {
        await authenticate(endpoint: "/auth/v1/signup", email: email, password: password, allowEmptySession: true)
    }

    func signIn(email: String, password: String) async {
        await authenticate(endpoint: "/auth/v1/token?grant_type=password", email: email, password: password, allowEmptySession: false)
    }

    func signOut() {
        KeychainStore.clearSession()
        isAuthenticated = false
        email = ""
    }

    func sendPasswordReset(email: String) async {
        do {
            let config = try await ensureConfig()
            var request = URLRequest(url: config.supabaseURL.appendingPathComponent("auth/v1/recover"))
            request.httpMethod = "POST"
            request.setValue(config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(["email": email])
            _ = try await perform(request)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func authorizedRequest(path: String, method: String = "POST", body: Data? = nil) async throws -> URLRequest {
        let config = try await ensureConfig()
        guard let session = KeychainStore.loadSession() else { throw AuthError.notAuthenticated }

        var request = URLRequest(url: config.backendBaseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    private func authenticate(endpoint: String, email: String, password: String, allowEmptySession: Bool) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let config = try await ensureConfig()
            guard let url = URL(string: endpoint, relativeTo: config.supabaseURL) else { throw AuthError.invalidURL }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(AuthRequest(email: email, password: password))

            let data = try await perform(request)
            let response = try JSONDecoder().decode(AuthResponse.self, from: data)

            guard !response.accessToken.isEmpty, !response.refreshToken.isEmpty else {
                if allowEmptySession {
                    self.email = email
                    errorMessage = "Account erstellt. Bitte bestätige deine E-Mail, falls dies im Supabase-Projekt aktiviert ist."
                    return
                }
                throw AuthError.invalidSession
            }

            KeychainStore.saveSession(accessToken: response.accessToken, refreshToken: response.refreshToken)
            self.email = response.user?.email ?? email
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func ensureConfig() async throws -> AppConfig {
        if let config { return config }
        let loaded = try await AppConfig.load()
        config = loaded
        return loaded
    }

    private func requestUser(accessToken: String) async throws -> UserResponse {
        let config = try await ensureConfig()
        var request = URLRequest(url: config.supabaseURL.appendingPathComponent("auth/v1/user"))
        request.httpMethod = "GET"
        request.setValue(config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try JSONDecoder().decode(UserResponse.self, from: try await perform(request))
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw AuthError.server(apiError.message ?? apiError.msg ?? "Serverfehler")
            }
            throw AuthError.requestFailed
        }
        return data
    }
}

private struct AuthRequest: Encodable { let email: String; let password: String }

private struct AuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let user: UserResponse?
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

struct UserResponse: Decodable {
    let id: String
    let email: String?
}

private struct APIErrorResponse: Decodable {
    let message: String?
    let msg: String?
}

enum AuthError: LocalizedError {
    case invalidURL, invalidSession, requestFailed, notAuthenticated
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Ungültige Server-URL."
        case .invalidSession: "Die Anmeldung hat keine gültige Sitzung geliefert."
        case .requestFailed: "Die Anfrage konnte nicht abgeschlossen werden."
        case .notAuthenticated: "Bitte melde dich zuerst an."
        case .server(let message): message
        }
    }
}

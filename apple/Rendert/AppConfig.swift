import Foundation

struct AppConfig: Sendable {
    let backendBaseURL: URL
    let supabaseURL: URL
    let supabaseAnonKey: String

    static let fallbackBackendURL = URL(string: "https://your-production-domain.example")!

    static func load() async throws -> AppConfig {
        let backendURL = (Bundle.main.object(forInfoDictionaryKey: "RENDERT_BACKEND_URL") as? String)
            .flatMap(URL.init(string:)) ?? fallbackBackendURL

        let endpoint = backendURL.appendingPathComponent("api/config")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw AppConfigError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(ConfigResponse.self, from: data)
        guard let supabaseURL = URL(string: decoded.supabaseUrl),
              !decoded.supabaseAnonKey.isEmpty else {
            throw AppConfigError.missingEnvironment
        }

        return AppConfig(backendBaseURL: backendURL, supabaseURL: supabaseURL, supabaseAnonKey: decoded.supabaseAnonKey)
    }
}

private struct ConfigResponse: Decodable {
    let supabaseUrl: String
    let supabaseAnonKey: String
}

enum AppConfigError: LocalizedError {
    case invalidResponse
    case missingEnvironment

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "Die Rendert-Serverkonfiguration konnte nicht geladen werden."
        case .missingEnvironment: "Supabase ist auf dem Server noch nicht konfiguriert."
        }
    }
}

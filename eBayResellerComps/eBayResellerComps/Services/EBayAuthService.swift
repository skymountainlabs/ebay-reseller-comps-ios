import Foundation

@MainActor
final class EBayAuthService {
    static let shared = EBayAuthService()

    private var cachedToken: String?
    private var tokenExpiry: Date?

    private let tokenURL = URL(string: "https://api.ebay.com/identity/v1/oauth2/token")!

    private var clientID: String {
        Bundle.main.object(forInfoDictionaryKey: "eBayClientID") as? String ?? ""
    }

    private var clientSecret: String {
        Bundle.main.object(forInfoDictionaryKey: "eBayClientSecret") as? String ?? ""
    }

    func validToken() async throws -> String {
        if let token = cachedToken, let expiry = tokenExpiry, expiry > Date() {
            return token
        }
        return try await fetchToken()
    }

    private func fetchToken() async throws -> String {
        let credentials = "\(clientID):\(clientSecret)"
        guard let credData = credentials.data(using: .utf8) else {
            throw AuthError.invalidCredentials
        }
        let base64 = credData.base64EncodedString()

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "grant_type=client_credentials&scope=https%3A%2F%2Fapi.ebay.com%2Foauth%2Fapi_scope"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AuthError.tokenFetchFailed
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        cachedToken = tokenResponse.accessToken
        // Subtract 60 seconds to refresh before exact expiry
        tokenExpiry = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn - 60))
        return tokenResponse.accessToken
    }

    enum AuthError: Error, LocalizedError {
        case invalidCredentials
        case tokenFetchFailed

        var errorDescription: String? {
            switch self {
            case .invalidCredentials: return "eBay credentials missing in Info.plist."
            case .tokenFetchFailed: return "Failed to fetch eBay application token."
            }
        }
    }

    private struct TokenResponse: Codable {
        let accessToken: String
        let expiresIn: Int

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case expiresIn = "expires_in"
        }
    }
}

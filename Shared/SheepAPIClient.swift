import Foundation

final class SheepAPIClient {
    private let userId: String
    private let systemToken: String

    init(userId: String, systemToken: String) {
        self.userId = userId
        self.systemToken = systemToken
    }

    // MARK: - Private

    private func baseRequest(path: String) -> URLRequest {
        let url = URL(string: Constants.apiBaseURL + path)!
        var request = URLRequest(url: url)
        request.setValue(userId, forHTTPHeaderField: "new-api-user")
        request.setValue(systemToken, forHTTPHeaderField: "Authorization")
        return request
    }

    // MARK: - API Endpoints

    func fetchUserInfo() async throws -> UserInfo? {
        let request = baseRequest(path: "/api/user/self")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        let decoded = try JSONDecoder().decode(UserInfoResponse.self, from: data)
        guard decoded.success else {
            throw APIError.serverError(decoded.message)
        }
        return decoded.data
    }

    func fetchTokens(page: Int = 0, size: Int = 50) async throws -> [Token] {
        let request = baseRequest(path: "/api/token/?p=\(page)&size=\(size)")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        let decoded = try JSONDecoder().decode(TokenListResponse.self, from: data)
        guard decoded.success else {
            throw APIError.serverError(decoded.message)
        }
        return decoded.data?.items ?? []
    }

    func fetchTokenUsage(tokenKey: String) async throws -> TokenUsage? {
        let url = URL(string: Constants.apiBaseURL + "/api/usage/token/")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(tokenKey)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        let decoded = try JSONDecoder().decode(TokenUsageResponse.self, from: data)
        guard decoded.success else {
            throw APIError.serverError(decoded.message)
        }
        return decoded.data
    }

    func refreshAll() async throws -> (UserInfo?, [Token]) {
        async let userInfo = fetchUserInfo()
        async let tokens = fetchTokens()
        return try await (userInfo, tokens)
    }

    // MARK: - Helpers

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(http.statusCode)
        }
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .serverError(let msg):
            return msg.isEmpty ? "Server returned an error" : msg
        }
    }
}

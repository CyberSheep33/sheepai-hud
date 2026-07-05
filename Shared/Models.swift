import Foundation

// MARK: - User Info

struct UserInfoResponse: Codable {
    let data: UserInfo?
    let message: String
    let success: Bool
}

struct UserInfo: Codable {
    let id: Int
    let username: String
    let email: String
    let quota: Int64
    let usedQuota: Int64
    let requestCount: Int

    enum CodingKeys: String, CodingKey {
        case id, username, email, quota
        case usedQuota = "used_quota"
        case requestCount = "request_count"
    }

    var quotaUSD: Double { Double(quota) / Constants.quotaToUSD }
    var usedQuotaUSD: Double { Double(usedQuota) / Constants.quotaToUSD }
}

// MARK: - Token List

struct TokenListResponse: Codable {
    let data: TokenListData?
    let message: String
    let success: Bool
}

struct TokenListData: Codable {
    let total: Int
    let items: [Token]
}

struct Token: Codable, Identifiable {
    let id: Int
    let userId: Int
    let key: String
    let status: Int
    let name: String
    let createdTime: UInt64
    let accessedTime: UInt64
    let expiredTime: Int64
    let remainQuota: Int64
    let unlimitedQuota: Bool
    let usedQuota: Int64
    let group: String

    enum CodingKeys: String, CodingKey {
        case id, key, status, name, group
        case userId = "user_id"
        case createdTime = "created_time"
        case accessedTime = "accessed_time"
        case expiredTime = "expired_time"
        case remainQuota = "remain_quota"
        case unlimitedQuota = "unlimited_quota"
        case usedQuota = "used_quota"
    }

    var isActive: Bool { status == 1 }
    var usedQuotaUSD: Double { Double(usedQuota) / Constants.quotaToUSD }
    var remainQuotaUSD: Double { Double(remainQuota) / Constants.quotaToUSD }

    var accessedDate: Date {
        Date(timeIntervalSince1970: TimeInterval(accessedTime))
    }
}

// MARK: - Token Usage

struct TokenUsageResponse: Codable {
    let data: TokenUsage?
    let message: String
    let success: Bool
}

struct TokenUsage: Codable {
    let name: String
    let totalUsed: Int64
    let totalAvailable: Int64
    let totalGranted: Int64
    let unlimitedQuota: Bool
    let modelLimitsEnabled: Bool
    let expiresAt: Int64

    enum CodingKeys: String, CodingKey {
        case name
        case totalUsed = "total_used"
        case totalAvailable = "total_available"
        case totalGranted = "total_granted"
        case unlimitedQuota = "unlimited_quota"
        case modelLimitsEnabled = "model_limits_enabled"
        case expiresAt = "expires_at"
    }

    var usedUSD: Double { Double(totalUsed) / Constants.quotaToUSD }
    var availableUSD: Double { Double(totalAvailable) / Constants.quotaToUSD }
}

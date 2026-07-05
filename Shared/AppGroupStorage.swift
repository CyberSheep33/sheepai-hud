import Foundation

struct AppGroupStorage {
    private let defaults: UserDefaults?

    init() {
        defaults = UserDefaults(suiteName: Constants.appGroupID)
    }

    var userId: String {
        get { defaults?.string(forKey: Constants.userIdKey) ?? "" }
        set { defaults?.set(newValue, forKey: Constants.userIdKey) }
    }

    var systemToken: String {
        get { defaults?.string(forKey: Constants.systemTokenKey) ?? "" }
        set { defaults?.set(newValue, forKey: Constants.systemTokenKey) }
    }

    var isConfigured: Bool {
        !userId.isEmpty && !systemToken.isEmpty
    }

    var userInfo: UserInfo? {
        get {
            guard let data = defaults?.data(forKey: Constants.userInfoDataKey) else { return nil }
            return try? JSONDecoder().decode(UserInfo.self, from: data)
        }
        set {
            let data = newValue.flatMap { try? JSONEncoder().encode($0) }
            defaults?.set(data, forKey: Constants.userInfoDataKey)
        }
    }

    var tokens: [Token] {
        get {
            guard let data = defaults?.data(forKey: Constants.tokenListDataKey) else { return [] }
            return (try? JSONDecoder().decode([Token].self, from: data)) ?? []
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            defaults?.set(data, forKey: Constants.tokenListDataKey)
        }
    }

    var selectedTokenName: String {
        get { defaults?.string(forKey: Constants.selectedTokenNameKey) ?? "" }
        set { defaults?.set(newValue, forKey: Constants.selectedTokenNameKey) }
    }

    var selectedTokenUsage: TokenUsage? {
        get {
            guard let data = defaults?.data(forKey: Constants.tokenUsageDataKey) else { return nil }
            return try? JSONDecoder().decode(TokenUsage.self, from: data)
        }
        set {
            let data = newValue.flatMap { try? JSONEncoder().encode($0) }
            defaults?.set(data, forKey: Constants.tokenUsageDataKey)
        }
    }

    var lastRefreshTime: Date? {
        get {
            let interval = defaults?.double(forKey: Constants.lastRefreshTimeKey) ?? 0
            return interval > 0 ? Date(timeIntervalSince1970: interval) : nil
        }
        set {
            defaults?.set(newValue?.timeIntervalSince1970 ?? 0,
                         forKey: Constants.lastRefreshTimeKey)
        }
    }
}

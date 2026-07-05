import Foundation

enum Constants {
    static let apiBaseURL = "https://www.sheepai.top"
    static let appGroupID = "group.com.sheepai.hud"
    static let quotaToUSD: Double = 500_000.0

    // UserDefaults keys in App Group suite
    static let userIdKey = "userId"
    static let systemTokenKey = "systemToken"
    static let userInfoDataKey = "userInfoData"
    static let tokenListDataKey = "tokenListData"
    static let tokenUsageDataKey = "tokenUsageData"
    static let selectedTokenNameKey = "selectedTokenName"
    static let lastRefreshTimeKey = "lastRefreshTime"
}

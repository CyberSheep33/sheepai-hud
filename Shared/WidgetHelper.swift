import Foundation

struct WidgetHelper {
    private static let storage = AppGroupStorage()

    static var isConfigured: Bool { storage.isConfigured }

    static func loadUserInfo() -> UserInfo? { storage.userInfo }

    static func loadTokens() -> [Token] {
        storage.tokens
    }

    static func formatUSD(_ value: Double) -> String {
        value.formatted(.currency(code: "USD"))
    }
}

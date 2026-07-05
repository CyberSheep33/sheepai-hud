import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    // MARK: - Published state

    @Published var userInfo: UserInfo?
    @Published var tokens: [Token] = []
    @Published var selectedTokenUsage: TokenUsage?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Computed

    private var storage = AppGroupStorage()

    /// Exposed for SettingsView to pre-fill saved credentials
    var savedUserId: String { storage.userId }
    var savedSystemToken: String { storage.systemToken }

    var isConfigured: Bool { storage.isConfigured }
    var selectedTokenName: String { storage.selectedTokenName }

    var totalTokensUsedUSD: Double {
        tokens.reduce(0) { $0 + $1.usedQuotaUSD }
    }

    var activeTokenCount: Int {
        tokens.filter(\.isActive).count
    }

    var selectedToken: Token? {
        tokens.first { $0.name == storage.selectedTokenName }
    }

    // MARK: - Actions

    func loadCached() {
        userInfo = storage.userInfo
        tokens = storage.tokens
        selectedTokenUsage = storage.selectedTokenUsage
    }

    func refresh() async {
        guard isConfigured else {
            errorMessage = "请先在设置中填写用户 ID 和系统令牌"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let client = SheepAPIClient(
                userId: storage.userId,
                systemToken: storage.systemToken
            )
            let (info, tokenList) = try await client.refreshAll()
            userInfo = info
            tokens = tokenList
            storage.userInfo = info
            storage.tokens = tokenList
            storage.lastRefreshTime = Date()
            await refreshSelectedTokenUsage()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func refreshSelectedTokenUsage() async {
        guard !storage.selectedTokenName.isEmpty else { return }
        guard let token = tokens.first(where: { $0.name == storage.selectedTokenName }) else {
            return
        }
        do {
            let client = SheepAPIClient(
                userId: storage.userId,
                systemToken: storage.systemToken
            )
            let usage = try await client.fetchTokenUsage(tokenKey: token.key)
            selectedTokenUsage = usage
            storage.selectedTokenUsage = usage
        } catch {
            // Silently ignore — the cached value is still displayed
        }
    }

    func updateCredentials(userId: String, systemToken: String) {
        storage.userId = userId
        storage.systemToken = systemToken
    }

    func setSelectedToken(name: String) {
        storage.selectedTokenName = name
        if !name.isEmpty {
            Task { await refreshSelectedTokenUsage() }
        } else {
            selectedTokenUsage = nil
            storage.selectedTokenUsage = nil
        }
    }
}

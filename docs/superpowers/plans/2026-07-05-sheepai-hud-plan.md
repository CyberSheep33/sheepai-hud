
### Task 1: Project scaffolding with XcodeGen

**Files:**
- Create: `project.yml`

**Produces:** Buildable Xcode project with 2 targets (SheepAI app, Widgets extension) sharing `Shared/` sources.

- [ ] **Step 1: Install XcodeGen if needed**

Run: `which xcodegen || brew install xcodegen`
Expected: `xcodegen` is available on PATH

- [ ] **Step 2: Create project.yml**

```yaml
name: SheepAI
options:
  bundleIdPrefix: com.sheepai
  deploymentTarget:
    macOS: "14.0"
  xcodeVersion: "16.0"
  generateEmptyDirectories: true

settings:
  base:
    SWIFT_VERSION: "5.9"

targets:
  SheepAI:
    type: application
    platform: macOS
    deploymentTarget: "14.0"
    sources:
      - path: SheepAI
      - path: Shared
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.sheepai.hud
        INFOPLIST_FILE: ""
        GENERATE_INFOPLIST_FILE: YES
        DEVELOPMENT_TEAM: ""
        MARKETING_VERSION: 1.0.0
        CURRENT_PROJECT_VERSION: 1
    entitlements:
      path: SheepAI.entitlements
      properties:
        com.apple.security.app-sandbox: true
        com.apple.security.network.client: true
        com.apple.security.application-groups:
          - group.com.sheepai.hud
    dependencies:
      - target: Widgets
    preBuildScripts:
      - name: "Generate Entitlements"
        script: |
          cat > "${SRCROOT}/SheepAI.entitlements" << 'ENTEOF'
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
              <key>com.apple.security.app-sandbox</key>
              <true/>
              <key>com.apple.security.network.client</key>
              <true/>
              <key>com.apple.security.application-groups</key>
              <array>
                  <string>group.com.sheepai.hud</string>
              </array>
          </dict>
          </plist>
          ENTEOF
        basedOnDependencyAnalysis: false

  Widgets:
    type: app-extension
    platform: macOS
    deploymentTarget: "14.0"
    sources:
      - path: Widgets
      - path: Shared
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.sheepai.hud.widgets
        INFOPLIST_FILE: Widgets/Info.plist
        GENERATE_INFOPLIST_FILE: NO
        DEVELOPMENT_TEAM: ""
        MARKETING_VERSION: 1.0.0
        CURRENT_PROJECT_VERSION: 1
    entitlements:
      path: Widgets.entitlements
      properties:
        com.apple.security.application-groups:
          - group.com.sheepai.hud
    preBuildScripts:
      - name: "Generate Entitlements & Info.plist"
        script: |
          mkdir -p "${SRCROOT}/Widgets"
          cat > "${SRCROOT}/Widgets.entitlements" << 'ENTEOF'
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
              <key>com.apple.security.application-groups</key>
              <array>
                  <string>group.com.sheepai.hud</string>
              </array>
          </dict>
          </plist>
          ENTEOF
          cat > "${SRCROOT}/Widgets/Info.plist" << 'PLEOF'
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
              <key>CFBundleDevelopmentRegion</key>
              <string>$(DEVELOPMENT_LANGUAGE)</string>
              <key>CFBundleDisplayName</key>
              <string>SheepAI Widgets</string>
              <key>CFBundleExecutable</key>
              <string>$(EXECUTABLE_NAME)</string>
              <key>CFBundleIdentifier</key>
              <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
              <key>CFBundleInfoDictionaryVersion</key>
              <string>6.0</string>
              <key>CFBundleName</key>
              <string>$(PRODUCT_NAME)</string>
              <key>CFBundlePackageType</key>
              <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
              <key>CFBundleShortVersionString</key>
              <string>$(MARKETING_VERSION)</string>
              <key>CFBundleVersion</key>
              <string>$(CURRENT_PROJECT_VERSION)</string>
              <key>LSMinimumSystemVersion</key>
              <string>14.0</string>
              <key>NSExtension</key>
              <dict>
                  <key>NSExtensionPointIdentifier</key>
                  <string>com.apple.widgetkit-extension</string>
              </dict>
          </dict>
          </plist>
          PLEOF
        basedOnDependencyAnalysis: false
```

- [ ] **Step 3: Generate Xcode project**

Run: `xcodegen generate --spec project.yml`
Expected: Creates `SheepAI.xcodeproj`, no errors

- [ ] **Step 4: Verify project opens and builds (empty)**

Run: `xcodebuild -project SheepAI.xcodeproj -scheme SheepAI -configuration Debug build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20`
Expected: Build succeeds with no source files (or minimal placeholder)

---

### Task 2: Shared Constants, Models, and AppGroupStorage

**Files:**
- Create: `Shared/Constants.swift`
- Create: `Shared/Models.swift`
- Create: `Shared/AppGroupStorage.swift`

**Produces:** Data types and storage layer consumed by both App and Widget targets.

- [ ] **Step 1: Create Constants.swift**

```swift
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
```

- [ ] **Step 2: Create Models.swift**

Based on the actual API response JSON fields from `.test/` data. Key mappings use `CodingKeys` since source JSON is snake_case.

```swift
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
```

- [ ] **Step 3: Create AppGroupStorage.swift**

```swift
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
```

- [ ] **Step 4: Verify compilation**

Run: `xcodebuild -project SheepAI.xcodeproj -scheme SheepAI -configuration Debug build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | tail -10`
Expected: Compiles without errors (the Shared files are included in both targets)

---

### Task 3: API Client with URLSession

**Files:**
- Create: `Shared/SheepAPIClient.swift`

**Interfaces:**
- Consumes: `Constants.apiBaseURL`, `UserInfo`, `Token`, `TokenUsage`, response wrapper types from Task 2
- Produces: `SheepAPIClient` class with `fetchUserInfo()`, `fetchTokens(page:size:)`, `fetchTokenUsage(tokenKey:)`, `refreshAll()`

- [ ] **Step 1: Create SheepAPIClient.swift**

```swift
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
            return "无效的服务器响应"
        case .httpError(let code):
            return "HTTP 错误: \(code)"
        case .serverError(let msg):
            return msg.isEmpty ? "服务器返回错误" : msg
        }
    }
}
```

- [ ] **Step 2: Verify compilation**

Run: `xcodebuild -project SheepAI.xcodeproj -scheme SheepAI -configuration Debug build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED"`
Expected: `** BUILD SUCCEEDED **`

---

### Task 4: AppViewModel — ObservableObject state management

**Files:**
- Create: `SheepAI/ViewModels/AppViewModel.swift`

**Interfaces:**
- Consumes: `AppGroupStorage`, `SheepAPIClient`, `UserInfo`, `Token`, `TokenUsage` from Tasks 2-3
- Produces: `AppViewModel` ObservableObject consumed by all host-app Views

- [ ] **Step 1: Create AppViewModel.swift**

```swift
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

    private let storage = AppGroupStorage()

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
```

- [ ] **Step 2: Verify compilation**

Run: `xcodebuild -project SheepAI.xcodeproj -scheme SheepAI -configuration Debug build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED"`
Expected: `** BUILD SUCCEEDED **`

---

### Task 5: Settings View — Credential input form

**Files:**
- Create: `SheepAI/Views/SettingsView.swift`

**Interfaces:**
- Consumes: `AppViewModel.updateCredentials(userId:systemToken:)`, `AppViewModel.isConfigured` from Task 4
- Produces: Self-contained Settings tab view

- [ ] **Step 1: Create SettingsView.swift**

```swift
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var userId: String = ""
    @State private var systemToken: String = ""
    @State private var showSaved: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("设置")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 24)

            // Form
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("用户 ID (new-api-user)")
                            .font(.headline)
                        TextField("输入你的账户 ID", text: $userId)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("系统令牌 (Authorization)")
                            .font(.headline)
                        SecureField("输入你的系统令牌", text: $systemToken)
                            .textFieldStyle(.roundedBorder)
                    }
                } header: {
                    Text("API 凭证")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("凭证安全存储在你的设备 App Group 中，仅用于调用小羊AI API。")
                            .foregroundColor(.secondary)
                        if showSaved {
                            Text("✅ 凭证已保存")
                                .foregroundColor(.green)
                        }
                    }
                }

                Section {
                    Button(action: saveAction) {
                        HStack {
                            Spacer()
                            Text("保存凭证")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(userId.trimmingCharacters(in: .whitespaces).isEmpty ||
                             systemToken.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .formStyle(.grouped)
        }
        .onAppear {
            userId = viewModel.savedUserId
            systemToken = viewModel.savedSystemToken
        }
    }

    private func saveAction() {
        let cleanUserId = userId.trimmingCharacters(in: .whitespaces)
        let cleanToken = systemToken.trimmingCharacters(in: .whitespaces)
        viewModel.updateCredentials(userId: cleanUserId, systemToken: cleanToken)
        withAnimation { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSaved = false }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: AppViewModel())
    }
}
#endif
```

- [ ] **Step 2: Verify compilation**

Run: `xcodebuild -project SheepAI.xcodeproj -scheme SheepAI -configuration Debug build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED"`
Expected: `** BUILD SUCCEEDED **`

---

### Task 6: User Overview View

**Files:**
- Create: `SheepAI/Views/UserOverviewView.swift`

**Interfaces:**
- Consumes: `AppViewModel.userInfo`, `AppViewModel.tokens`, `AppViewModel.isLoading`, `AppViewModel.errorMessage`
- Produces: Self-contained dashboard view

- [ ] **Step 1: Create UserOverviewView.swift**

```swift
import SwiftUI

struct UserOverviewView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("用户总览")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { Task { await viewModel.refresh() } }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 24)

            ScrollView {
                if !viewModel.isConfigured {
                    emptyStateView
                } else if viewModel.isLoading && viewModel.userInfo == nil {
                    loadingView
                } else if let error = viewModel.errorMessage, viewModel.userInfo == nil {
                    errorView(error)
                } else if let user = viewModel.userInfo {
                    userContent(user: user)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - States

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("请先在设置中填写用户 ID 和系统令牌")
                .foregroundColor(.secondary)
        }
        .padding(.top, 80)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("加载中...")
                .foregroundColor(.secondary)
        }
        .padding(.top, 80)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 36))
                .foregroundColor(.red)
            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    // MARK: - Content

    private func userContent(user: UserInfo) -> some View {
        VStack(spacing: 20) {
            // Profile card
            profileCard(user: user)

            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                statCard(
                    title: "💰 余额",
                    value: user.quotaUSD.formatted(.currency(code: "USD")),
                    systemImage: "dollarsign.circle.fill",
                    color: .green
                )
                statCard(
                    title: "📊 已使用",
                    value: user.usedQuotaUSD.formatted(.currency(code: "USD")),
                    systemImage: "chart.line.uptrend.xyaxis.circle.fill",
                    color: .orange
                )
                statCard(
                    title: "🔢 请求次数",
                    value: user.requestCount.formatted(),
                    systemImage: "number.circle.fill",
                    color: .blue
                )
                statCard(
                    title: "🔑 令牌数",
                    value: viewModel.tokens.count.formatted(),
                    systemImage: "key.circle.fill",
                    color: .purple
                )
            }
        }
        .padding(.vertical, 20)
    }

    private func profileCard(user: UserInfo) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(user.username)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        )
    }

    private func statCard(
        title: String,
        value: String,
        systemImage: String,
        color: Color
    ) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
        )
    }
}
```

- [ ] **Step 2: Verify compilation**

Run: `xcodebuild -project SheepAI.xcodeproj -scheme SheepAI -configuration Debug build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED"`
Expected: `** BUILD SUCCEEDED **`

---

### Task 7: Token List View

**Files:**
- Create: `SheepAI/Views/TokenListView.swift`

**Interfaces:**
- Consumes: `AppViewModel.tokens`, `AppViewModel.selectedTokenName`, `AppViewModel.setSelectedToken(name:)`, `AppViewModel.selectedTokenUsage`
- Produces: Two-section view — token table on top, selected token detail panel below

- [ ] **Step 1: Create TokenListView.swift**

```swift
import SwiftUI

struct TokenListView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var selectedTokenName: String = ""
    @State private var sortOrder = [KeyPathComparator(\Token.name)]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("令牌列表")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { Task { await viewModel.refresh() } }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 24)

            if !viewModel.isConfigured {
                emptyStateView
            } else if viewModel.tokens.isEmpty && viewModel.isLoading {
                ProgressView("加载中...")
                    .padding(.top, 80)
            } else {
                tokenContent
            }
        }
        .onAppear {
            selectedTokenName = viewModel.selectedTokenName
        }
    }

    // MARK: - States

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("请先在设置中填写凭证，然后刷新数据")
                .foregroundColor(.secondary)
        }
        .padding(.top, 80)
    }

    // MARK: - Content

    private var tokenContent: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left: table
            Table(viewModel.tokens, selection: $selectedTokenName, sortOrder: $sortOrder) {
                TableColumn("名称", value: \.name) { token in
                    HStack(spacing: 6) {
                        Image(systemName: "key.fill")
                            .font(.caption)
                            .foregroundColor(token.isActive ? .green : .gray)
                        Text(token.name)
                            .fontWeight(.medium)
                    }
                }
                .width(min: 100, ideal: 140)

                TableColumn("状态", value: \.status) { token in
                    Text(token.isActive ? "活跃" : "停用")
                        .font(.caption)
                        .foregroundColor(token.isActive ? .green : .secondary)
                }
                .width(min: 50, ideal: 60)

                TableColumn("已用 (USD)") { token in
                    Text(token.usedQuotaUSD.formatted(.currency(code: "USD")))
                        .font(.caption)
                        .monospacedDigit()
                }
                .width(min: 80, ideal: 100)

                TableColumn("分组", value: \.group) { token in
                    Text(token.group.isEmpty ? "-" : token.group)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .width(min: 100, ideal: 160)
            }
            .onChange(of: selectedTokenName) { _, newName in
                viewModel.setSelectedToken(name: newName)
            }

            Divider()

            // Right: detail panel
            tokenDetailPanel
                .frame(width: 280)
        }
    }

    // MARK: - Detail Panel

    private var tokenDetailPanel: some View {
        Group {
            if let token = viewModel.tokens.first(where: { $0.name == selectedTokenName }) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("令牌详情")
                        .font(.headline)

                    detailRow("名称", token.name)
                    detailRow("状态", token.isActive ? "🟢 活跃" : "⚪ 停用")

                    if token.unlimitedQuota {
                        detailRow("额度", "🟢 无限量")
                    } else {
                        detailRow("额度", "⚠️ 有限额")
                    }

                    detailRow("已使用",
                        token.usedQuotaUSD.formatted(.currency(code: "USD")))

                    if !token.unlimitedQuota {
                        detailRow("剩余",
                            token.remainQuotaUSD.formatted(.currency(code: "USD")))
                    }

                    detailRow("上次访问",
                        token.accessedDate.formatted(date: .numeric, time: .shortened))

                    if !token.group.isEmpty {
                        detailRow("分组", token.group)
                    }

                    Divider()

                    Text("🔑 监视此令牌: 前往桌面添加「令牌监视」小组件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(16)
            } else {
                VStack {
                    Text("选择左侧令牌查看详情")
                        .foregroundColor(.secondary)
                        .padding(.top, 60)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
    }
}
```

- [ ] **Step 2: Verify compilation**

Run: `xcodebuild -project SheepAI.xcodeproj -scheme SheepAI -configuration Debug build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED"`
Expected: `** BUILD SUCCEEDED **`

---

### Task 8: ContentView + App Entry Point

**Files:**
- Create: `SheepAI/SheepAIApp.swift`
- Create: `SheepAI/Views/ContentView.swift`

**Interfaces:**
- Consumes: All views from Tasks 5-7, `AppViewModel` from Task 4
- Produces: Complete runnable app with NavigationSplitView shell

- [ ] **Step 1: Create SheepAIApp.swift**

```swift
import SwiftUI

@main
struct SheepAIApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 800, minHeight: 560)
                .onAppear {
                    viewModel.loadCached()
                    Task { await viewModel.refresh() }
                }
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 900, height: 620)
    }
}
```

- [ ] **Step 2: Create ContentView.swift**

```swift
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var selectedTab: Tab = .overview

    enum Tab: String, CaseIterable, Identifiable {
        case overview = "用户总览"
        case tokens = "令牌列表"
        case settings = "设置"

        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .overview: return "person.fill"
            case .tokens:   return "key.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(Tab.allCases, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.systemImage)
                    .font(.body)
                    .padding(.vertical, 4)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200)
            .listStyle(.sidebar)
        } detail: {
            // Content
            switch selectedTab {
            case .overview:
                UserOverviewView(viewModel: viewModel)
            case .tokens:
                TokenListView(viewModel: viewModel)
            case .settings:
                SettingsView(viewModel: viewModel)
            }
        }
    }
}
```

- [ ] **Step 3: Verify build**

Run: `xcodebuild -project SheepAI.xcodeproj -scheme SheepAI -configuration Debug build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED"`
Expected: `** BUILD SUCCEEDED **`

---

### Task 9: Widget Bundle + Helper (Timeline Provider base)

**Files:**
- Create: `Widgets/WidgetBundle.swift`

**Interfaces:**
- Produces: WidgetBundle registered by the extension target, plus a shared `WidgetHelper` for reading App Group data

- [ ] **Step 1: Add WidgetHelper to Shared/Models.swift**

Append to `Shared/Models.swift`:

```swift
// MARK: - Widget Helper (shared by widget targets)

enum WidgetHelper {
    static func loadUserInfo() -> UserInfo? {
        guard let data = UserDefaults(suiteName: Constants.appGroupID)?
            .data(forKey: Constants.userInfoDataKey)
        else { return nil }
        return try? JSONDecoder().decode(UserInfo.self, from: data)
    }

    static func loadTokens() -> [Token] {
        guard let data = UserDefaults(suiteName: Constants.appGroupID)?
            .data(forKey: Constants.tokenListDataKey)
        else { return [] }
        return (try? JSONDecoder().decode([Token].self, from: data)) ?? []
    }

    static func loadSelectedTokenUsage() -> TokenUsage? {
        guard let data = UserDefaults(suiteName: Constants.appGroupID)?
            .data(forKey: Constants.tokenUsageDataKey)
        else { return nil }
        return try? JSONDecoder().decode(TokenUsage.self, from: data)
    }

    static func loadSelectedTokenName() -> String {
        UserDefaults(suiteName: Constants.appGroupID)?
            .string(forKey: Constants.selectedTokenNameKey) ?? ""
    }

    static var isConfigured: Bool {
        let store = UserDefaults(suiteName: Constants.appGroupID)
        return !(store?.string(forKey: Constants.userIdKey) ?? "").isEmpty &&
               !(store?.string(forKey: Constants.systemTokenKey) ?? "").isEmpty
    }

    static var lastRefreshTime: Date? {
        let interval = UserDefaults(suiteName: Constants.appGroupID)?
            .double(forKey: Constants.lastRefreshTimeKey) ?? 0
        return interval > 0 ? Date(timeIntervalSince1970: interval) : nil
    }

    static func formatUSD(_ quota: Int64) -> String {
        (Double(quota) / Constants.quotaToUSD).formatted(.currency(code: "USD"))
    }

    static func formatUSD(_ value: Double) -> String {
        value.formatted(.currency(code: "USD"))
    }
}
```

- [ ] **Step 2: Create Widgets/WidgetBundle.swift**

```swift
import SwiftUI
import WidgetKit

@main
struct SheepAIWidgets: WidgetBundle {
    var body: some Widget {
        UserOverviewWidget()
        TokenOverviewWidget()
        TokenMonitorWidget()
    }
}
```

- [ ] **Step 3: Verify compilation**

Run: `xcodebuild -project SheepAI.xcodeproj -scheme Widgets -configuration Debug build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED"`
Expected: Will fail with "Cannot find 'UserOverviewWidget' in scope" — expected, defined in Tasks 10-12

---

### Task 10: User Overview Widget (systemSmall)

**Files:**
- Create: `Widgets/UserOverviewWidget.swift`

**Interfaces:**
- Consumes: `WidgetHelper.loadUserInfo()`, `WidgetHelper.loadTokens()`, `WidgetHelper.isConfigured`

- [ ] **Step 1: Create UserOverviewWidget.swift**

```swift
import SwiftUI
import WidgetKit

struct UserOverviewEntry: TimelineEntry {
    let date: Date
    let userInfo: UserInfo?
    let tokenCount: Int
    let isConfigured: Bool
}

struct UserOverviewProvider: TimelineProvider {
    func placeholder(in context: Context) -> UserOverviewEntry {
        UserOverviewEntry(date: Date(), userInfo: nil, tokenCount: 0, isConfigured: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (UserOverviewEntry) -> Void) {
        let userInfo = WidgetHelper.loadUserInfo()
        let tokens = WidgetHelper.loadTokens()
        let entry = UserOverviewEntry(
            date: Date(),
            userInfo: userInfo,
            tokenCount: tokens.count,
            isConfigured: WidgetHelper.isConfigured
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UserOverviewEntry>) -> Void) {
        let entry = UserOverviewEntry(
            date: Date(),
            userInfo: WidgetHelper.loadUserInfo(),
            tokenCount: WidgetHelper.loadTokens().count,
            isConfigured: WidgetHelper.isConfigured
        )
        let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

struct UserOverviewWidget: Widget {
    let kind = "com.sheepai.hud.user-overview"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UserOverviewProvider()) { entry in
            UserOverviewWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("用户总览")
        .description("显示小羊AI用户信息、余额和用量概览")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - View

struct UserOverviewWidgetView: View {
    let entry: UserOverviewEntry

    var body: some View {
        if !entry.isConfigured {
            notConfiguredView
        } else if let user = entry.userInfo {
            contentView(user: user)
        } else {
            emptyView
        }
    }

    private var notConfiguredView: some View {
        VStack(spacing: 4) {
            Image(systemName: "gearshape.fill")
                .font(.body)
                .foregroundColor(.secondary)
            Text("请先设置凭证")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 4) {
            Image(systemName: "wifi.slash")
                .font(.body)
                .foregroundColor(.secondary)
            Text("暂无数据")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func contentView(user: UserInfo) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            // Top row: username + icon
            HStack(spacing: 3) {
                Text(user.username)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "person.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.accentColor)
            }

            if !user.email.isEmpty {
                Text(user.email)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer().frame(height: 4)

            // Stats in compact rows
            compactRow("💰", "余额", user.quotaUSD.formatted(.currency(code: "USD")))
            compactRow("📊", "已用", user.usedQuotaUSD.formatted(.currency(code: "USD")))
            compactRow("🔢", "请求", user.requestCount.formatted())
            compactRow("🔑", "令牌", entry.tokenCount.formatted())
        }
        .padding(8)
    }

    private func compactRow(_ icon: String, _ label: String, _ value: String) -> some View {
        HStack(spacing: 2) {
            Text(icon)
                .font(.system(size: 8))
                .frame(width: 12, alignment: .center)
            Text(value)
                .font(.system(size: 9, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 7))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}
```

- [ ] **Step 2: Verify compilation**

Run: `xcodebuild -project SheepAI.xcodeproj -scheme Widgets -configuration Debug build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED"`
Expected: Still missing other widget types, but UserOverviewWidget compiles

---

### Task 11: Token Overview Widget (systemSmall)

**Files:**
- Create: `Widgets/TokenOverviewWidget.swift`

**Interfaces:**
- Consumes: `WidgetHelper.loadTokens()`, `WidgetHelper.isConfigured`

- [ ] **Step 1: Create TokenOverviewWidget.swift**

```swift
import SwiftUI
import WidgetKit

struct TokenOverviewEntry: TimelineEntry {
    let date: Date
    let tokenCount: Int
    let activeCount: Int
    let totalUsedUSD: Double
    let isConfigured: Bool
}

struct TokenOverviewProvider: TimelineProvider {
    func placeholder(in context: Context) -> TokenOverviewEntry {
        TokenOverviewEntry(date: Date(), tokenCount: 5, activeCount: 5, totalUsedUSD: 1240, isConfigured: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (TokenOverviewEntry) -> Void) {
        let tokens = WidgetHelper.loadTokens()
        let entry = TokenOverviewEntry(
            date: Date(),
            tokenCount: tokens.count,
            activeCount: tokens.filter(\.isActive).count,
            totalUsedUSD: tokens.reduce(0) { $0 + $1.usedQuotaUSD },
            isConfigured: WidgetHelper.isConfigured
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TokenOverviewEntry>) -> Void) {
        let tokens = WidgetHelper.loadTokens()
        let entry = TokenOverviewEntry(
            date: Date(),
            tokenCount: tokens.count,
            activeCount: tokens.filter(\.isActive).count,
            totalUsedUSD: tokens.reduce(0) { $0 + $1.usedQuotaUSD },
            isConfigured: WidgetHelper.isConfigured
        )
        let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

struct TokenOverviewWidget: Widget {
    let kind = "com.sheepai.hud.token-overview"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TokenOverviewProvider()) { entry in
            TokenOverviewWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("令牌总览")
        .description("显示令牌数量、活跃状态和总用量")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - View

struct TokenOverviewWidgetView: View {
    let entry: TokenOverviewEntry

    var body: some View {
        if !entry.isConfigured {
            VStack(spacing: 4) {
                Image(systemName: "gearshape.fill")
                    .font(.body)
                    .foregroundColor(.secondary)
                Text("请先设置凭证")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        } else if entry.tokenCount == 0 {
            VStack(spacing: 4) {
                Image(systemName: "key.slash")
                    .font(.body)
                    .foregroundColor(.secondary)
                Text("暂无令牌数据")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        } else {
            contentView
        }
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text("🔑")
                    .font(.caption)
                Text("令牌概览")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }

            Spacer().frame(height: 2)

            VStack(alignment: .leading, spacing: 3) {
                statLine("📋", "共 \(entry.tokenCount) 个令牌")
                statLine("⚡", "活跃 \(entry.activeCount) 个")
                statLine("📊", "总用量 \(WidgetHelper.formatUSD(entry.totalUsedUSD))")
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func statLine(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 3) {
            Text(icon)
                .font(.system(size: 8))
            Text(text)
                .font(.system(size: 9))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}
```

- [ ] **Step 2: Verify compilation**

Run: `xcodebuild -project SheepAI.xcodeproj -scheme Widgets -configuration Debug build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED"`
Expected: One more widget type missing — TokenMonitorWidget

---

### Task 12: Token Monitor Widget (systemMedium)

**Files:**
- Create: `Widgets/TokenMonitorWidget.swift`

**Interfaces:**
- Consumes: `WidgetHelper.loadSelectedTokenName()`, `WidgetHelper.loadSelectedTokenUsage()`, `WidgetHelper.loadTokens()`, `WidgetHelper.isConfigured`

- [ ] **Step 1: Create TokenMonitorWidget.swift**

```swift
import SwiftUI
import WidgetKit

struct TokenMonitorEntry: TimelineEntry {
    let date: Date
    let tokenName: String
    let tokenUsage: TokenUsage?
    let token: Token?
    let isConfigured: Bool
}

struct TokenMonitorProvider: TimelineProvider {
    func placeholder(in context: Context) -> TokenMonitorEntry {
        TokenMonitorEntry(
            date: Date(),
            tokenName: "sheeptool",
            tokenUsage: nil,
            token: nil,
            isConfigured: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TokenMonitorEntry) -> Void) {
        let name = WidgetHelper.loadSelectedTokenName()
        let usage = WidgetHelper.loadSelectedTokenUsage()
        let token = WidgetHelper.loadTokens().first { $0.name == name }
        completion(TokenMonitorEntry(
            date: Date(),
            tokenName: name,
            tokenUsage: usage,
            token: token,
            isConfigured: WidgetHelper.isConfigured
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TokenMonitorEntry>) -> Void) {
        let name = WidgetHelper.loadSelectedTokenName()
        let usage = WidgetHelper.loadSelectedTokenUsage()
        let token = WidgetHelper.loadTokens().first { $0.name == name }
        let entry = TokenMonitorEntry(
            date: Date(),
            tokenName: name,
            tokenUsage: usage,
            token: token,
            isConfigured: WidgetHelper.isConfigured
        )
        let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

struct TokenMonitorWidget: Widget {
    let kind = "com.sheepai.hud.token-monitor"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TokenMonitorProvider()) { entry in
            TokenMonitorWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("令牌监视")
        .description("监视指定令牌的用量，在 App 的令牌列表中选择要监视的令牌")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - View

struct TokenMonitorWidgetView: View {
    let entry: TokenMonitorEntry

    var body: some View {
        if !entry.isConfigured {
            notConfiguredView
        } else if entry.tokenName.isEmpty {
            noTokenSelectedView
        } else if let token = entry.token {
            if let usage = entry.tokenUsage {
                detailView(token: token, usage: usage)
            } else {
                basicView(token: token)
            }
        } else {
            notCachedView
        }
    }

    // MARK: - State views

    private var notConfiguredView: some View {
        VStack(spacing: 4) {
            Image(systemName: "gearshape.fill").font(.body).foregroundColor(.secondary)
            Text("请先设置凭证").font(.caption).foregroundColor(.secondary)
        }
    }

    private var noTokenSelectedView: some View {
        VStack(spacing: 6) {
            Image(systemName: "key.fill").font(.title3).foregroundColor(.secondary)
            Text("未选择监视令牌")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("在 App 令牌列表中点击令牌即可选择")
                .font(.caption2)
                .foregroundColor(.tertiary)
                .multilineTextAlignment(.center)
        }
    }

    private var notCachedView: some View {
        VStack(spacing: 4) {
            Image(systemName: "arrow.clockwise").font(.body).foregroundColor(.secondary)
            Text("等待数据...").font(.caption).foregroundColor(.secondary)
        }
    }

    // MARK: - Detail view with usage

    private func detailView(token: Token, usage: TokenUsage) -> some View {
        HStack(spacing: 0) {
            // Left block
            VStack(alignment: .leading, spacing: 6) {
                headerBlock(token: token)

                Spacer().frame(height: 2)

                if token.unlimitedQuota {
                    unlimitedBlock(usage: usage)
                } else {
                    limitedBlock(token: token, usage: usage)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(width: 12)

            // Right block — meta
            VStack(alignment: .leading, spacing: 6) {
                metaBlock(token: token)
            }
            .frame(width: 140, alignment: .leading)
        }
        .padding(12)
    }

    // MARK: - Basic view (token only, no usage)

    private func basicView(token: Token) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            headerBlock(token: token)
            Spacer()
            Text("打开 App 刷新以获取用量详情")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Shared blocks

    private func headerBlock(token: Token) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "key.fill")
                .foregroundColor(token.isActive ? .green : .gray)
            Text(token.name)
                .font(.headline)
                .fontWeight(.bold)
                .lineLimit(1)
        }
    }

    private func unlimitedBlock(usage: TokenUsage) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                Text("无限量")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
            Text("已用 \(usage.usedUSD.formatted(.currency(code: "USD")))")
                .font(.title3)
                .fontWeight(.semibold)
        }
    }

    private func limitedBlock(token: Token, usage: TokenUsage) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(.orange)
                    .frame(width: 6, height: 6)
                Text("有限额")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("已用")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(usage.usedUSD.formatted(.currency(code: "USD")))
                        .font(.body)
                        .fontWeight(.semibold)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("剩余")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(usage.availableUSD.formatted(.currency(code: "USD")))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
        }
    }

    private func metaBlock(token: Token) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            metaItem("上次访问", token.accessedDate.formatted(date: .numeric, time: .shortened))
            if !token.group.isEmpty {
                metaItem("分组", token.group)
            }
        }
    }

    private func metaItem(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 9))
                .lineLimit(2)
        }
    }
}
```

- [ ] **Step 2: Full build verification**

Run: `xcodebuild -project SheepAI.xcodeproj -scheme SheepAI -configuration Debug build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|warning:|BUILD SUCCEEDED"`
Expected: `** BUILD SUCCEEDED **`

---

### Task 13: Run in Xcode and verify

**Files:** None (manual verification)

- [ ] **Step 1: Generate final project and open in Xcode**

Run: `xcodegen generate --spec project.yml && open SheepAI.xcodeproj`

- [ ] **Step 2: Select the SheepAI scheme, build and run (⌘R)**

Expected:
- App launches with sidebar navigation
- Settings tab: enter user ID and system token, hit save
- User Overview tab: shows user info cards after refresh
- Token List tab: shows token table, click a token to see detail and select it for monitoring

- [ ] **Step 3: Add widgets to Notification Center**

- Swipe left from the right edge of the trackpad to reveal Notification Center
- Scroll to bottom, click "Edit Widgets"
- Search for "SheepAI" and add User Overview, Token Overview, and Token Monitor widgets

Expected: All three widgets render with data from the App Group cache

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: complete SheepAI HUD macOS app with 3 widgets"
```

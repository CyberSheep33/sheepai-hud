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
                .containerBackground(.background, for: .widget)
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

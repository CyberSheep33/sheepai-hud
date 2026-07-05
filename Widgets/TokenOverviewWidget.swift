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

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
                .containerBackground(.background, for: .widget)
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
                .foregroundColor(.secondary)
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

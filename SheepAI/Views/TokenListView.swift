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

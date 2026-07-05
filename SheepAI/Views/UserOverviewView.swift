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

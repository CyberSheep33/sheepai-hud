import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var selectedTab: Tab = .settings

    enum Tab: String, CaseIterable {
        case overview = "用户总览"
        case tokens = "令牌列表"
        case settings = "设置"

        var systemImage: String {
            switch self {
            case .overview: return "person.fill"
            case .tokens:   return "key.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar with buttons
            VStack(spacing: 0) {
                Text("SheepAI HUD")
                    .font(.headline)
                    .foregroundColor(.accentColor)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                ForEach(Tab.allCases, id: \.rawValue) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Label(tab.rawValue, systemImage: tab.systemImage)
                            .font(.body)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                selectedTab == tab
                                    ? Color.accentColor.opacity(0.15)
                                    : Color.clear
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 180)

            Divider()

            // Content
            Group {
                switch selectedTab {
                case .overview:
                    UserOverviewView(viewModel: viewModel)
                case .tokens:
                    TokenListView(viewModel: viewModel)
                case .settings:
                    SettingsView(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

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

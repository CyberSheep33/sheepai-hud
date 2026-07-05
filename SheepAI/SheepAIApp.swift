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

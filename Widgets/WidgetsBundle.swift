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

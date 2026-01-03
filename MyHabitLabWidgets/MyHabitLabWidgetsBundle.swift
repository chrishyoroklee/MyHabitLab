import WidgetKit
import SwiftUI

@main
struct MyHabitLabWidgetsBundle: WidgetBundle {
    var body: some Widget {
        SummaryWidget()
        HabitDetailWidget()
    }
}

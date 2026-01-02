import SwiftUI

struct StatsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Stats Coming Soon",
                systemImage: "chart.bar",
                description: Text("Your progress charts will live here.")
            )
            .navigationTitle("Stats")
        }
    }
}

//
//  ContentView.swift
//  MyHabitLab
//
//  Created by 이효록 on 1/2/26.
//

import SwiftUI

struct ContentView: View {
    let dateProvider: DateProvider

    var body: some View {
        TabView {
            DashboardView(dateProvider: dateProvider)
                .tabItem {
                    Label("tab.dashboard", systemImage: "square.grid.2x2")
                }
            StatsView(dateProvider: dateProvider)
                .tabItem {
                    Label("tab.stats", systemImage: "chart.bar")
                }
            SettingsView()
                .tabItem {
                    Label("tab.settings", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView(dateProvider: .live)
}

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
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView(dateProvider: .live)
}

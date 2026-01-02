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

struct DashboardView: View {
    let dateProvider: DateProvider

    var body: some View {
        let today = dateProvider.today()
        return NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("MyHabitLab")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Today is \(today.displayTitle)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Dashboard")
        }
    }
}

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

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Settings Coming Soon",
                systemImage: "gearshape",
                description: Text("Customize reminders and preferences here.")
            )
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView(dateProvider: .live)
}

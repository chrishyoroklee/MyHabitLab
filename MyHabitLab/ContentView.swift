//
//  ContentView.swift
//  MyHabitLab
//
//  Created by 이효록 on 1/2/26.
//

import SwiftUI

struct ContentView: View {
    let dateProvider: DateProvider
    @State private var selectedTab: Tab = .dashboard

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView(dateProvider: dateProvider)
                    .tag(Tab.dashboard)
                    .toolbar(.hidden, for: .tabBar) // Hide system bar
                
                StatsView(dateProvider: dateProvider)
                    .tag(Tab.stats)
                    .toolbar(.hidden, for: .tabBar)
                
                SettingsView()
                    .tag(Tab.settings)
                    .toolbar(.hidden, for: .tabBar)
            }
            .accentColor(AppColors.neonPurple) // Just in case
            
            // Custom Floating Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 20)
        }
        .background(AppColors.primaryBackground)
        .ignoresSafeArea(.keyboard) // Prevent tab bar from moving up with keyboard
    }
}

#Preview {
    ContentView(dateProvider: .live)
}

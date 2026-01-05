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
    @State private var isPresentingNewHabit = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView(dateProvider: dateProvider) {
                    selectedTab = .settings
                }
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
            CustomTabBar(selectedTab: $selectedTab) {
                isPresentingNewHabit = true
            }
                .padding(.bottom, 20)
        }
        .background(AppColors.primaryBackgroundGradient)
        .ignoresSafeArea(.keyboard) // Prevent tab bar from moving up with keyboard
        .sheet(isPresented: $isPresentingNewHabit) {
            HabitFormView()
        }
    }
}

#Preview {
    ContentView(dateProvider: .live)
}

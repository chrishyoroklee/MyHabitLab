//
//  MyHabitLabApp.swift
//  MyHabitLab
//
//  Created by 이효록 on 1/2/26.
//

import SwiftUI
import SwiftData

@main
struct MyHabitLabApp: App {
    private let dateProvider = DateProvider.live
    private let modelContainer: ModelContainer

    init() {
        modelContainer = ModelContainerFactory.makeMainContainer()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(dateProvider: dateProvider)
                .task {
                    await MainActor.run {
                        SampleDataSeeder.seedIfNeeded(context: modelContainer.mainContext)
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}

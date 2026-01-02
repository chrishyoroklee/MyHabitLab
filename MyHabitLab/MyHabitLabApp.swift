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
    @Environment(\.scenePhase) private var scenePhase

    init() {
        modelContainer = ModelContainerFactory.makeMainContainer()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(dateProvider: dateProvider)
                .task {
                    await MainActor.run {
                        SampleDataSeeder.seedIfNeeded(context: modelContainer.mainContext)
                        WidgetStoreSync.applyPendingTogglesIfNeeded(context: modelContainer.mainContext)
                        WidgetStoreSync.updateSnapshot(
                            context: modelContainer.mainContext,
                            dayKey: DayKey.from(Date())
                        )
                    }
                }
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            Task { @MainActor in
                WidgetStoreSync.applyPendingTogglesIfNeeded(context: modelContainer.mainContext)
                WidgetStoreSync.updateSnapshot(
                    context: modelContainer.mainContext,
                    dayKey: DayKey.from(Date())
                )
            }
        }
    }
}

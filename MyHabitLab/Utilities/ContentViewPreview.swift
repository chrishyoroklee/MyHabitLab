import SwiftUI
import SwiftData
import Foundation

#Preview("ContentView with Data") {
    let container = ModelContainerFactory.makePreviewContainer()
    let context = container.mainContext
    let habitOne = Habit(
        name: String(localized: "sample.habit.drink_water.title"),
        iconName: "drop",
        colorName: "Blue",
        detail: String(localized: "sample.habit.drink_water.detail")
    )
    let habitTwo = Habit(
        name: String(localized: "sample.habit.read.title"),
        iconName: "book",
        colorName: "Indigo",
        detail: String(localized: "sample.habit.read.detail")
    )
    context.insert(habitOne)
    context.insert(habitTwo)
    do {
        try context.save()
    } catch {
        assertionFailure("Failed to seed preview habits: \(error)")
    }
    return ContentView(dateProvider: .live)
        .modelContainer(container)
}

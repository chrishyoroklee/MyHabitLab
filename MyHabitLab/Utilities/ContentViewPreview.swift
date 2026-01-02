import SwiftUI
import SwiftData

#Preview("ContentView with Data") {
    let container = ModelContainerFactory.makePreviewContainer()
    let context = container.mainContext
    let habitOne = Habit(
        name: "Drink Water",
        iconName: "drop",
        colorName: "Blue",
        detail: "Stay hydrated throughout the day."
    )
    let habitTwo = Habit(
        name: "Read 10 Pages",
        iconName: "book",
        colorName: "Indigo",
        detail: "A small daily reading goal."
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

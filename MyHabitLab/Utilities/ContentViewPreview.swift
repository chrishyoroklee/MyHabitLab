import SwiftUI
import SwiftData

#Preview("ContentView with Data") {
    let container = ModelContainerFactory.makePreviewContainer()
    SampleDataSeeder.seedIfNeeded(context: container.mainContext)
    return ContentView(dateProvider: .live)
        .modelContainer(container)
}

import SwiftData

enum ModelContainerFactory {
    static func makeMainContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: Habit.self, Completion.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    static func makePreviewContainer() -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(
                for: Habit.self,
                Completion.self,
                configurations: configuration
            )
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }
}

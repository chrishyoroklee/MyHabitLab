import SwiftData

enum ModelContainerFactory {
    static let cloudKitContainerIdentifier = "iCloud.com.hyoroklee.habitlab"

    static func makeMainContainer() -> ModelContainer {
        makeMainContainer(syncEnabled: SyncManager.isSyncEnabled)
    }

    static func makeMainContainer(syncEnabled: Bool) -> ModelContainer {
        syncEnabled ? makeCloudContainer() : makeLocalContainer()
    }

    static func makeLocalContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: Habit.self, Completion.self, HabitReminder.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    static func makeCloudContainer() -> ModelContainer {
        do {
            return try makeCloudContainerUnsafe()
        } catch {
            fatalError("Failed to create CloudKit ModelContainer: \(error)")
        }
    }

    static func makeCloudContainerUnsafe() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            cloudKitDatabase: .private(cloudKitContainerIdentifier)
        )
        return try ModelContainer(
            for: Habit.self,
            Completion.self,
            HabitReminder.self,
            configurations: configuration
        )
    }

    static func makePreviewContainer() -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(
                for: Habit.self,
                Completion.self,
                HabitReminder.self,
                configurations: configuration
            )
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }
}

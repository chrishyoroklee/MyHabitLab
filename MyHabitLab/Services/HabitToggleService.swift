import Foundation
import SwiftData

enum HabitToggleService {
    @MainActor
    static func toggleCompletion(habitId: UUID) throws -> Bool {
        let container = ModelContainerFactory.makeMainContainer()
        let context = ModelContext(container)

        var descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { habit in
                habit.id == habitId
            }
        )
        descriptor.fetchLimit = 1
        guard let habit = try context.fetch(descriptor).first else {
            throw HabitIntentError.habitNotFound
        }

        let dayKey = DayKey.from(Date())
        let completion = HabitCompletionService.toggleCompletion(
            habit: habit,
            dayKey: dayKey,
            context: context
        )
        try context.save()
        WidgetStoreSync.updateSnapshot(context: context, dayKey: dayKey)
        return HabitCompletionService.isComplete(habit: habit, completion: completion)
    }
}

enum HabitIntentError: LocalizedError {
    case habitNotFound

    var errorDescription: String? {
        switch self {
        case .habitNotFound:
            return String(localized: "error.habit_not_found")
        }
    }
}

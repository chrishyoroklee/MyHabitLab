import Foundation
import SwiftData

enum HabitLookup {
    @MainActor
    static func fetchHabit(id: UUID) throws -> Habit? {
        let context = ModelContext(ModelContainerFactory.makeMainContainer())
        var descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { habit in
                habit.id == id
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    @MainActor
    static func fetchHabits(ids: [UUID]) throws -> [Habit] {
        var habits: [Habit] = []
        for id in ids {
            if let habit = try fetchHabit(id: id) {
                habits.append(habit)
            }
        }
        return habits
    }

    @MainActor
    static func fetchSuggestedHabits(limit: Int = 6) throws -> [Habit] {
        let context = ModelContext(ModelContainerFactory.makeMainContainer())
        var descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { habit in
                habit.isArchived == false
            }
        )
        descriptor.fetchLimit = limit
        descriptor.sortBy = [SortDescriptor(\Habit.createdAt)]
        return try context.fetch(descriptor)
    }

    @MainActor
    static func searchHabits(matching query: String, limit: Int = 10) throws -> [Habit] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            return try fetchSuggestedHabits(limit: limit)
        }

        let context = ModelContext(ModelContainerFactory.makeMainContainer())
        var descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { habit in
                habit.isArchived == false && habit.name.localizedStandardContains(trimmed)
            }
        )
        descriptor.fetchLimit = limit
        descriptor.sortBy = [SortDescriptor(\Habit.createdAt)]
        return try context.fetch(descriptor)
    }
}

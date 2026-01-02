import SwiftData

enum SampleDataSeeder {
    static func seedIfNeeded(context: ModelContext) {
        var descriptor = FetchDescriptor<Habit>()
        descriptor.fetchLimit = 1
        do {
            let existing = try context.fetch(descriptor)
            guard existing.isEmpty else { return }
        } catch {
            assertionFailure("Failed to fetch habits for seeding: \(error)")
            return
        }

        let habit = Habit(
            name: "Drink Water",
            detail: "Stay hydrated throughout the day."
        )
        context.insert(habit)

        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save sample habits: \(error)")
        }
    }
}

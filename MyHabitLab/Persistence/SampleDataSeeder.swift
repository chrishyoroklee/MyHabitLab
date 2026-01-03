import SwiftData
import Foundation

@MainActor
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
            name: String(localized: "sample.habit.drink_water.title"),
            iconName: "drop",
            colorName: "Blue",
            detail: String(localized: "sample.habit.drink_water.detail")
        )
        context.insert(habit)

        do {
            try context.save()
            WidgetStoreSync.updateSnapshot(
                context: context,
                dayKey: DayKey.from(Date())
            )
        } catch {
            assertionFailure("Failed to save sample habits: \(error)")
        }
    }
}

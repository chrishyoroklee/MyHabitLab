import SwiftData
import WidgetKit

@MainActor
enum WidgetStoreSync {
    static func applyPendingTogglesIfNeeded(context: ModelContext) {
        var state = WidgetSharedStore.loadState()
        guard !state.pendingToggles.isEmpty else { return }

        for toggle in state.pendingToggles {
            applyToggle(toggle, context: context)
        }

        do {
            try context.save()
        } catch {
            assertionFailure("Failed to apply widget toggles: \(error)")
        }

        state.pendingToggles = []
        WidgetSharedStore.saveState(state)
        updateSnapshot(context: context, dayKey: DayKey.from(Date()))
    }

    static func updateSnapshot(context: ModelContext, dayKey: Int) {
        let habits = fetchHabits(context: context)
        let snapshots = habits.map { habit in
            WidgetHabitSnapshot(
                id: habit.id,
                name: habit.name,
                iconName: habit.iconName,
                colorName: habit.colorName,
                isCompletedToday: habit.completions.contains { $0.dayKey == dayKey }
            )
        }
        WidgetSharedStore.updateHabits(snapshots)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func fetchHabits(context: ModelContext) -> [Habit] {
        var descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { habit in
                habit.isArchived == false
            }
        )
        descriptor.sortBy = [SortDescriptor(\Habit.createdAt)]
        do {
            return try context.fetch(descriptor)
        } catch {
            assertionFailure("Failed to fetch habits for widget snapshot: \(error)")
            return []
        }
    }

    private static func applyToggle(_ toggle: WidgetPendingToggle, context: ModelContext) {
        var descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { habit in
                habit.id == toggle.habitId
            }
        )
        descriptor.fetchLimit = 1
        do {
            let results = try context.fetch(descriptor)
            guard let habit = results.first else { return }

            if let existing = habit.completions.first(where: { $0.dayKey == toggle.dayKey }) {
                context.delete(existing)
            } else {
                let completion = Completion(habit: habit, dayKey: toggle.dayKey, value: 1)
                context.insert(completion)
            }
        } catch {
            assertionFailure("Failed to fetch habit for widget toggle: \(error)")
        }
    }
}

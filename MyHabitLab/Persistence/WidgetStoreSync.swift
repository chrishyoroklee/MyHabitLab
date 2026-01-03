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
            let completionValues = HabitCompletionService.completionValueByDayKey(for: habit)
            let completionValue = completionValues[dayKey] ?? 0
            let isCompletedToday = HabitCompletionService.isComplete(habit: habit, completionValue: completionValue)
            return WidgetHabitSnapshot(
                id: habit.id,
                name: habit.name,
                iconName: habit.iconName,
                colorName: habit.colorName,
                isCompletedToday: isCompletedToday,
                trackingModeRaw: habit.trackingModeRaw,
                completionValueBase: completionValue,
                unitDisplayName: habit.unitDisplayName,
                unitBaseScale: habit.unitBaseScale,
                unitDisplayPrecision: habit.unitDisplayPrecision,
                unitGoalBaseValue: HabitCompletionService.goalBaseValue(for: habit),
                unitDefaultIncrementBaseValue: HabitCompletionService.defaultIncrementBaseValue(for: habit),
                scheduleMask: habit.scheduleMask,
                extraCompletionPolicyRaw: habit.extraCompletionPolicyRaw
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

            _ = HabitCompletionService.toggleCompletion(
                habit: habit,
                dayKey: toggle.dayKey,
                context: context
            )
        } catch {
            assertionFailure("Failed to fetch habit for widget toggle: \(error)")
        }
    }
}

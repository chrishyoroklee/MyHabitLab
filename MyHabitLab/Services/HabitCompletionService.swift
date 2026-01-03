import Foundation
import SwiftData

enum HabitCompletionService {
    static func completionValueByDayKey(for habit: Habit) -> [Int: Int] {
        habit.completions.reduce(into: [:]) { partialResult, completion in
            let current = partialResult[completion.dayKey] ?? 0
            partialResult[completion.dayKey] = max(current, completion.value)
        }
    }

    static func goalBaseValue(for habit: Habit) -> Int {
        max(habit.unitGoalBaseValue ?? 1, 1)
    }

    static func defaultIncrementBaseValue(for habit: Habit) -> Int {
        max(habit.unitDefaultIncrementBaseValue ?? 1, 1)
    }

    static func isComplete(habit: Habit, completionValue: Int?) -> Bool {
        let value = completionValue ?? 0
        switch habit.trackingMode {
        case .checkmark:
            return value > 0
        case .unit:
            return HabitProgress.isComplete(currentBase: value, goalBase: goalBaseValue(for: habit))
        }
    }

    static func isComplete(habit: Habit, completion: Completion?) -> Bool {
        isComplete(habit: habit, completionValue: completion?.value)
    }

    static func completedDayKeys(for habit: Habit) -> Set<Int> {
        let values = completionValueByDayKey(for: habit)
        return Set(values.compactMap { dayKey, value in
            isComplete(habit: habit, completionValue: value) ? dayKey : nil
        })
    }

    static func progressText(habit: Habit, completionValue: Int?) -> String? {
        guard habit.trackingMode == .unit, let unit = habit.unitConfiguration else { return nil }
        let current = completionValue ?? 0
        let goalBase = goalBaseValue(for: habit)
        return HabitProgress.formattedProgress(
            currentBase: current,
            goalBase: goalBase,
            unit: unit
        )
    }

    @MainActor
    @discardableResult
    static func toggleCompletion(
        habit: Habit,
        dayKey: Int,
        context: ModelContext
    ) -> Completion? {
        let dayCompletions = habit.completions.filter { $0.dayKey == dayKey }
        let existing = dayCompletions.first
        if dayCompletions.count > 1 {
            for extra in dayCompletions.dropFirst() {
                context.delete(extra)
            }
        }

        switch habit.trackingMode {
        case .checkmark:
            if let completion = existing {
                context.delete(completion)
                return nil
            } else {
                let completion = Completion(habit: habit, dayKey: dayKey, value: 1)
                context.insert(completion)
                return completion
            }
        case .unit:
            let goalBase = goalBaseValue(for: habit)
            let incrementBase = defaultIncrementBaseValue(for: habit)
            if let completion = existing {
                if HabitProgress.isComplete(currentBase: completion.value, goalBase: goalBase) {
                    context.delete(completion)
                    return nil
                }
                let updated = min(completion.value + incrementBase, goalBase)
                completion.value = updated
                return completion
            } else {
                let startingValue = min(incrementBase, goalBase)
                let completion = Completion(habit: habit, dayKey: dayKey, value: startingValue)
                context.insert(completion)
                return completion
            }
        }
    }
}

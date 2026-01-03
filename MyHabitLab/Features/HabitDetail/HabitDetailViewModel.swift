import Foundation

struct HabitDetailViewModel {
    let habit: Habit
    let dateProvider: DateProvider

    var completionValues: [Int: Int] {
        HabitCompletionService.completionValueByDayKey(for: habit)
    }

    var completedDayKeys: Set<Int> {
        HabitCompletionService.completedDayKeys(for: habit)
    }

    var streakStats: StreakStats {
        StreakCalculator.calculate(
            completionValuesByDayKey: completionValues,
            trackingMode: habit.trackingMode,
            goalBaseValue: habit.unitGoalBaseValue,
            scheduleMask: habit.scheduleMask,
            extraCompletionPolicy: habit.extraCompletionPolicy,
            today: dateProvider.now(),
            calendar: dateProvider.calendar,
            timeZone: dateProvider.calendar.timeZone
        )
    }

    var totalCompletions: Int {
        completionValues.reduce(0) { partial, entry in
            HabitCompletionService.isComplete(habit: habit, completionValue: entry.value) ? partial + 1 : partial
        }
    }

    var completionRateText: String {
        percentString(streakStats.completionRateLast30Days)
    }

    var isScheduledToday: Bool {
        HabitSchedule.isScheduled(
            on: dateProvider.today().start,
            scheduleMask: habit.scheduleMask,
            calendar: dateProvider.calendar
        )
    }

    var todayProgressText: String? {
        HabitCompletionService.progressText(
            habit: habit,
            completionValue: completionValues[dateProvider.dayKey()]
        )
    }

    var targetLabel: String {
        habit.trackingMode == .unit ? "Goal" : "Schedule"
    }

    var targetSummary: String {
        if habit.trackingMode == .unit, let unit = habit.unitConfiguration {
            let goalBase = HabitCompletionService.goalBaseValue(for: habit)
            return HabitProgress.formattedDisplay(baseValue: goalBase, unit: unit)
        }
        let schedule = WeekdaySet(rawValue: habit.scheduleMask)
        return "\(schedule.count)/week"
    }

    private func percentString(_ value: Double) -> String {
        let percentage = Int((value * 100.0).rounded())
        return "\(percentage)%"
    }
}

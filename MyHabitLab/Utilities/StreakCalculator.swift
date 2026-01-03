import Foundation

struct StreakStats: Equatable {
    let currentStreak: Int
    let longestStreak: Int
    let completionRateLast30Days: Double
}

enum StreakCalculator {
    static func calculate(
        completionValuesByDayKey: [Int: Int],
        trackingMode: HabitTrackingMode,
        goalBaseValue: Int?,
        scheduleMask: Int,
        extraCompletionPolicy: ExtraCompletionPolicy,
        today: Date,
        calendar: Calendar = .current,
        timeZone: TimeZone = .current
    ) -> StreakStats {
        var calendar = calendar
        calendar.timeZone = timeZone
        let startOfToday = calendar.startOfDay(for: today)

        guard !completionValuesByDayKey.isEmpty else {
            return StreakStats(currentStreak: 0, longestStreak: 0, completionRateLast30Days: 0)
        }

        let goalBase = max(goalBaseValue ?? 1, 1)
        let earliestDate = completionValuesByDayKey.keys
            .compactMap { DayKey.toDate($0, calendar: calendar, timeZone: timeZone) }
            .min() ?? startOfToday

        func completionValue(for date: Date) -> Int? {
            let dayKey = DayKey.from(date, calendar: calendar, timeZone: timeZone)
            return completionValuesByDayKey[dayKey]
        }

        func isComplete(on date: Date) -> Bool {
            let value = completionValue(for: date)
            switch trackingMode {
            case .checkmark:
                return (value ?? 0) > 0
            case .unit:
                return HabitProgress.isComplete(currentBase: value ?? 0, goalBase: goalBase)
            }
        }

        func countsTowardStats(on date: Date) -> Bool {
            HabitSchedule.countsTowardStreak(
                on: date,
                scheduleMask: scheduleMask,
                policy: extraCompletionPolicy,
                isComplete: isComplete(on: date),
                calendar: calendar
            )
        }

        let currentStreak = calculateCurrentStreak(
            startOfToday: startOfToday,
            earliestDate: earliestDate,
            calendar: calendar,
            countsTowardStats: countsTowardStats,
            isComplete: isComplete
        )

        let longestStreak = calculateLongestStreak(
            startDate: earliestDate,
            endDate: startOfToday,
            calendar: calendar,
            countsTowardStats: countsTowardStats,
            isComplete: isComplete
        )

        let completionRate = calculateCompletionRateLast30Days(
            startOfToday: startOfToday,
            calendar: calendar,
            countsTowardStats: countsTowardStats,
            isComplete: isComplete
        )

        return StreakStats(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            completionRateLast30Days: completionRate
        )
    }

    private static func calculateCurrentStreak(
        startOfToday: Date,
        earliestDate: Date,
        calendar: Calendar,
        countsTowardStats: (Date) -> Bool,
        isComplete: (Date) -> Bool
    ) -> Int {
        var streak = 0
        var cursor = startOfToday

        while cursor >= earliestDate {
            let counts = countsTowardStats(cursor)
            if counts {
                if isComplete(cursor) {
                    streak += 1
                } else {
                    break
                }
            }

            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
        }

        return streak
    }

    private static func calculateLongestStreak(
        startDate: Date,
        endDate: Date,
        calendar: Calendar,
        countsTowardStats: (Date) -> Bool,
        isComplete: (Date) -> Bool
    ) -> Int {
        guard startDate <= endDate else { return 0 }

        var longest = 0
        var current = 0
        var cursor = startDate

        while cursor <= endDate {
            let counts = countsTowardStats(cursor)
            if counts {
                if isComplete(cursor) {
                    current += 1
                    longest = max(longest, current)
                } else {
                    current = 0
                }
            }

            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else {
                break
            }
            cursor = next
        }

        return longest
    }

    private static func calculateCompletionRateLast30Days(
        startOfToday: Date,
        calendar: Calendar,
        countsTowardStats: (Date) -> Bool,
        isComplete: (Date) -> Bool
    ) -> Double {
        guard let start = calendar.date(byAdding: .day, value: -29, to: startOfToday) else {
            return 0
        }

        var completedCount = 0
        var countedDays = 0

        for offset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else {
                continue
            }
            if countsTowardStats(date) {
                countedDays += 1
                if isComplete(date) {
                    completedCount += 1
                }
            }
        }

        guard countedDays > 0 else { return 0 }
        return Double(completedCount) / Double(countedDays)
    }
}

import Foundation

struct StreakStats: Equatable {
    let currentStreak: Int
    let longestStreak: Int
    let completionRateLast30Days: Double
}

enum StreakCalculator {
    static func calculate(
        completedDayKeys: Set<Int>,
        today: Date,
        calendar: Calendar = .current,
        timeZone: TimeZone = .current
    ) -> StreakStats {
        var calendar = calendar
        calendar.timeZone = timeZone
        let startOfToday = calendar.startOfDay(for: today)

        let currentStreak = calculateCurrentStreak(
            completedDayKeys: completedDayKeys,
            startOfToday: startOfToday,
            calendar: calendar,
            timeZone: timeZone
        )

        let longestStreak = calculateLongestStreak(
            completedDayKeys: completedDayKeys,
            calendar: calendar,
            timeZone: timeZone
        )

        let completionRate = calculateCompletionRateLast30Days(
            completedDayKeys: completedDayKeys,
            startOfToday: startOfToday,
            calendar: calendar,
            timeZone: timeZone
        )

        return StreakStats(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            completionRateLast30Days: completionRate
        )
    }

    private static func calculateCurrentStreak(
        completedDayKeys: Set<Int>,
        startOfToday: Date,
        calendar: Calendar,
        timeZone: TimeZone
    ) -> Int {
        var streak = 0
        var cursor = startOfToday

        while true {
            let dayKey = DayKey.from(cursor, calendar: calendar, timeZone: timeZone)
            guard completedDayKeys.contains(dayKey) else {
                break
            }
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
        }

        return streak
    }

    private static func calculateLongestStreak(
        completedDayKeys: Set<Int>,
        calendar: Calendar,
        timeZone: TimeZone
    ) -> Int {
        let dates = completedDayKeys
            .compactMap { DayKey.toDate($0, calendar: calendar, timeZone: timeZone) }
            .sorted()

        guard !dates.isEmpty else { return 0 }

        var longest = 1
        var current = 1
        var previous = dates[0]

        for date in dates.dropFirst() {
            if let expected = calendar.date(byAdding: .day, value: 1, to: previous),
               calendar.isDate(date, inSameDayAs: expected) {
                current += 1
            } else {
                current = 1
            }
            longest = max(longest, current)
            previous = date
        }

        return longest
    }

    private static func calculateCompletionRateLast30Days(
        completedDayKeys: Set<Int>,
        startOfToday: Date,
        calendar: Calendar,
        timeZone: TimeZone
    ) -> Double {
        guard let start = calendar.date(byAdding: .day, value: -29, to: startOfToday) else {
            return 0
        }

        var completedCount = 0
        for offset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else {
                continue
            }
            let dayKey = DayKey.from(date, calendar: calendar, timeZone: timeZone)
            if completedDayKeys.contains(dayKey) {
                completedCount += 1
            }
        }

        return Double(completedCount) / 30.0
    }
}

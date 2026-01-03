import Foundation
import Testing
@testable import MyHabitLab

struct StreakCalculatorTests {
    private func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        let calendar = makeCalendar()
        guard let date = calendar.date(from: components) else {
            #expect(Bool(false), "Failed to build date for \(year)-\(month)-\(day)")
            return Date(timeIntervalSince1970: 0)
        }
        return date
    }

    @Test func currentStreakRequiresTodayCompletion() {
        let calendar = makeCalendar()
        let today = makeDate(year: 2026, month: 1, day: 2)
        let yesterday = makeDate(year: 2026, month: 1, day: 1)
        let completed: [Int: Int] = [
            DayKey.from(yesterday, calendar: calendar, timeZone: calendar.timeZone): 1
        ]

        let stats = StreakCalculator.calculate(
            completionValuesByDayKey: completed,
            trackingMode: .checkmark,
            goalBaseValue: nil,
            scheduleMask: WeekdaySet.all.rawValue,
            extraCompletionPolicy: .totalsOnly,
            today: today,
            calendar: calendar,
            timeZone: calendar.timeZone
        )

        #expect(stats.currentStreak == 0)
    }

    @Test func currentStreakCountsConsecutiveDaysEndingToday() {
        let calendar = makeCalendar()
        let today = makeDate(year: 2026, month: 1, day: 3)
        let dates = [
            makeDate(year: 2026, month: 1, day: 3),
            makeDate(year: 2026, month: 1, day: 2),
            makeDate(year: 2026, month: 1, day: 1)
        ]
        let completed = Dictionary(uniqueKeysWithValues: dates.map {
            (DayKey.from($0, calendar: calendar, timeZone: calendar.timeZone), 1)
        })

        let stats = StreakCalculator.calculate(
            completionValuesByDayKey: completed,
            trackingMode: .checkmark,
            goalBaseValue: nil,
            scheduleMask: WeekdaySet.all.rawValue,
            extraCompletionPolicy: .totalsOnly,
            today: today,
            calendar: calendar,
            timeZone: calendar.timeZone
        )

        #expect(stats.currentStreak == 3)
    }

    @Test func currentStreakSkipsOffDays() {
        let calendar = makeCalendar()
        let today = makeDate(year: 2026, month: 1, day: 7)
        guard let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today) else {
            #expect(Bool(false), "Failed to build two-days-ago date")
            return
        }

        let todaySet = WeekdaySet.from(calendarWeekday: calendar.component(.weekday, from: today))
        let pastSet = WeekdaySet.from(calendarWeekday: calendar.component(.weekday, from: twoDaysAgo))
        let schedule = todaySet.union(pastSet)

        let completed: [Int: Int] = [
            DayKey.from(today, calendar: calendar, timeZone: calendar.timeZone): 1,
            DayKey.from(twoDaysAgo, calendar: calendar, timeZone: calendar.timeZone): 1
        ]

        let stats = StreakCalculator.calculate(
            completionValuesByDayKey: completed,
            trackingMode: .checkmark,
            goalBaseValue: nil,
            scheduleMask: schedule.rawValue,
            extraCompletionPolicy: .totalsOnly,
            today: today,
            calendar: calendar,
            timeZone: calendar.timeZone
        )

        #expect(stats.currentStreak == 2)
    }

    @Test func offDayCompletionCountsForPolicy() {
        let calendar = makeCalendar()
        let today = makeDate(year: 2026, month: 1, day: 6)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
            #expect(Bool(false), "Failed to build yesterday date")
            return
        }

        let schedule = WeekdaySet.from(calendarWeekday: calendar.component(.weekday, from: yesterday))
        let completed: [Int: Int] = [
            DayKey.from(today, calendar: calendar, timeZone: calendar.timeZone): 1,
            DayKey.from(yesterday, calendar: calendar, timeZone: calendar.timeZone): 1
        ]

        let optionBStats = StreakCalculator.calculate(
            completionValuesByDayKey: completed,
            trackingMode: .checkmark,
            goalBaseValue: nil,
            scheduleMask: schedule.rawValue,
            extraCompletionPolicy: .countTowardStreaks,
            today: today,
            calendar: calendar,
            timeZone: calendar.timeZone
        )

        let optionCStats = StreakCalculator.calculate(
            completionValuesByDayKey: completed,
            trackingMode: .checkmark,
            goalBaseValue: nil,
            scheduleMask: schedule.rawValue,
            extraCompletionPolicy: .totalsOnly,
            today: today,
            calendar: calendar,
            timeZone: calendar.timeZone
        )

        #expect(optionBStats.currentStreak == 2)
        #expect(optionCStats.currentStreak == 1)
    }

    @Test func longestStreakSkipsGaps() {
        let calendar = makeCalendar()
        let dates = [
            makeDate(year: 2026, month: 1, day: 1),
            makeDate(year: 2026, month: 1, day: 2),
            makeDate(year: 2026, month: 1, day: 5),
            makeDate(year: 2026, month: 1, day: 6),
            makeDate(year: 2026, month: 1, day: 7)
        ]
        let completed = Dictionary(uniqueKeysWithValues: dates.map {
            (DayKey.from($0, calendar: calendar, timeZone: calendar.timeZone), 1)
        })

        let stats = StreakCalculator.calculate(
            completionValuesByDayKey: completed,
            trackingMode: .checkmark,
            goalBaseValue: nil,
            scheduleMask: WeekdaySet.all.rawValue,
            extraCompletionPolicy: .totalsOnly,
            today: makeDate(year: 2026, month: 1, day: 7),
            calendar: calendar,
            timeZone: calendar.timeZone
        )

        #expect(stats.longestStreak == 3)
    }

    @Test func completionRateUsesLast30DaysIncludingToday() {
        let calendar = makeCalendar()
        let today = makeDate(year: 2026, month: 1, day: 30)
        var completed: [Int: Int] = [:]
        for day in 1...15 {
            let date = makeDate(year: 2026, month: 1, day: day)
            completed[DayKey.from(date, calendar: calendar, timeZone: calendar.timeZone)] = 1
        }

        let stats = StreakCalculator.calculate(
            completionValuesByDayKey: completed,
            trackingMode: .checkmark,
            goalBaseValue: nil,
            scheduleMask: WeekdaySet.all.rawValue,
            extraCompletionPolicy: .totalsOnly,
            today: today,
            calendar: calendar,
            timeZone: calendar.timeZone
        )

        #expect(stats.completionRateLast30Days == 0.5)
    }
}

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
        let completed = Set([
            DayKey.from(yesterday, calendar: calendar, timeZone: calendar.timeZone)
        ])

        let stats = StreakCalculator.calculate(
            completedDayKeys: completed,
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
        let completed = Set(dates.map { DayKey.from($0, calendar: calendar, timeZone: calendar.timeZone) })

        let stats = StreakCalculator.calculate(
            completedDayKeys: completed,
            today: today,
            calendar: calendar,
            timeZone: calendar.timeZone
        )

        #expect(stats.currentStreak == 3)
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
        let completed = Set(dates.map { DayKey.from($0, calendar: calendar, timeZone: calendar.timeZone) })

        let stats = StreakCalculator.calculate(
            completedDayKeys: completed,
            today: makeDate(year: 2026, month: 1, day: 7),
            calendar: calendar,
            timeZone: calendar.timeZone
        )

        #expect(stats.longestStreak == 3)
    }

    @Test func completionRateUsesLast30DaysIncludingToday() {
        let calendar = makeCalendar()
        let today = makeDate(year: 2026, month: 1, day: 30)
        var completed: Set<Int> = []
        for day in 1...15 {
            let date = makeDate(year: 2026, month: 1, day: day)
            completed.insert(DayKey.from(date, calendar: calendar, timeZone: calendar.timeZone))
        }

        let stats = StreakCalculator.calculate(
            completedDayKeys: completed,
            today: today,
            calendar: calendar,
            timeZone: calendar.timeZone
        )

        #expect(stats.completionRateLast30Days == 0.5)
    }
}

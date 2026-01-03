import Foundation
import Testing
@testable import MyHabitLab

struct HabitScheduleTests {
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

    @Test func scheduledDayMatchesMask() {
        let calendar = makeCalendar()
        let date = makeDate(year: 2026, month: 1, day: 5)
        let weekday = calendar.component(.weekday, from: date)
        let schedule = WeekdaySet.from(calendarWeekday: weekday)

        #expect(HabitSchedule.isScheduled(on: date, scheduleMask: schedule.rawValue, calendar: calendar))

        guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else {
            #expect(Bool(false), "Failed to build next date")
            return
        }
        #expect(!HabitSchedule.isScheduled(on: nextDate, scheduleMask: schedule.rawValue, calendar: calendar))
    }

    @Test func extraCompletionPolicyCountsOffDays() {
        let calendar = makeCalendar()
        let date = makeDate(year: 2026, month: 1, day: 6)
        let weekday = calendar.component(.weekday, from: date)
        let schedule = WeekdaySet.from(calendarWeekday: weekday)

        guard let offDate = calendar.date(byAdding: .day, value: 1, to: date) else {
            #expect(Bool(false), "Failed to build off-day date")
            return
        }

        #expect(HabitSchedule.countsTowardStreak(
            on: offDate,
            scheduleMask: schedule.rawValue,
            policy: .countTowardStreaks,
            isComplete: true,
            calendar: calendar
        ))
        #expect(!HabitSchedule.countsTowardStreak(
            on: offDate,
            scheduleMask: schedule.rawValue,
            policy: .countTowardStreaks,
            isComplete: false,
            calendar: calendar
        ))
        #expect(!HabitSchedule.countsTowardStreak(
            on: offDate,
            scheduleMask: schedule.rawValue,
            policy: .totalsOnly,
            isComplete: true,
            calendar: calendar
        ))
    }
}

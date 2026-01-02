import Foundation
import Testing
@testable import MyHabitLab

struct DayKeyRangeTests {
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

    @Test func lastNDaysProducesExpectedRange() {
        let calendar = makeCalendar()
        let endDate = makeDate(year: 2026, month: 1, day: 3)
        let entries = DayKeyRange.lastNDays(
            endingOn: endDate,
            count: 5,
            calendar: calendar,
            timeZone: calendar.timeZone
        )

        #expect(entries.count == 5)
        #expect(entries.first?.dayKey == 20251230)
        #expect(entries.last?.dayKey == 20260103)
        let keys = entries.map { $0.dayKey }
        #expect(Set(keys).count == 5)
    }

    @Test func lastNDaysHandlesZeroCount() {
        let calendar = makeCalendar()
        let entries = DayKeyRange.lastNDays(
            endingOn: makeDate(year: 2026, month: 1, day: 1),
            count: 0,
            calendar: calendar,
            timeZone: calendar.timeZone
        )
        #expect(entries.isEmpty)
    }
}

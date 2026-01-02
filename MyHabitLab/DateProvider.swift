import Foundation

struct DateProvider {
    var now: () -> Date
    var calendar: Calendar

    static let live = DateProvider(
        now: Date.init,
        calendar: Calendar.current
    )
}

extension DateProvider {
    func today() -> Day {
        Day(start: calendar.startOfDay(for: now()))
    }

    func dayKey() -> Int {
        DayKey.from(now(), calendar: calendar, timeZone: calendar.timeZone)
    }
}

import Foundation

struct DayKey {
    static func from(
        _ date: Date,
        calendar: Calendar = .current,
        timeZone: TimeZone = .current
    ) -> Int {
        var calendar = calendar
        calendar.timeZone = timeZone
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return (year * 10000) + (month * 100) + day
    }

    static func toDate(
        _ dayKey: Int,
        calendar: Calendar = .current,
        timeZone: TimeZone = .current
    ) -> Date? {
        let year = dayKey / 10000
        let month = (dayKey / 100) % 100
        let day = dayKey % 100
        var calendar = calendar
        calendar.timeZone = timeZone
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)
    }
}

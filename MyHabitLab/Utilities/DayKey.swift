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
}

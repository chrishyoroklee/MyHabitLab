import Foundation

struct DayKeyEntry: Identifiable, Hashable {
    let date: Date
    let dayKey: Int

    var id: Int { dayKey }
}

enum DayKeyRange {
    static func lastNDays(
        endingOn date: Date,
        count: Int,
        calendar: Calendar = .current,
        timeZone: TimeZone = .current
    ) -> [DayKeyEntry] {
        guard count > 0 else { return [] }
        var calendar = calendar
        calendar.timeZone = timeZone
        let end = calendar.startOfDay(for: date)
        guard let start = calendar.date(byAdding: .day, value: -(count - 1), to: end) else {
            return []
        }

        return (0..<count).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else {
                return nil
            }
            let dayKey = DayKey.from(day, calendar: calendar, timeZone: timeZone)
            return DayKeyEntry(date: day, dayKey: dayKey)
        }
    }
}

import Foundation

struct ReminderScheduleCalculator {
    static func timeOfDayComponents(
        hour: Int,
        minute: Int,
        daysMask: Int
    ) -> [DateComponents] {
        let weekdays = weekdays(from: daysMask)
        return weekdays.map { weekday in
            var components = DateComponents()
            components.weekday = weekday
            components.hour = hour
            components.minute = minute
            return components
        }
    }

    static func intervalComponents(
        intervalMinutes: Int,
        startMinute: Int,
        endMinute: Int,
        daysMask: Int
    ) -> [DateComponents] {
        guard intervalMinutes > 0 else { return [] }
        guard startMinute <= endMinute else { return [] }

        let weekdays = weekdays(from: daysMask)
        var minutes: [Int] = []
        var current = startMinute
        while current <= endMinute {
            minutes.append(current)
            current += intervalMinutes
        }

        return weekdays.flatMap { weekday in
            minutes.map { minuteOffset in
                var components = DateComponents()
                components.weekday = weekday
                components.hour = minuteOffset / 60
                components.minute = minuteOffset % 60
                return components
            }
        }
    }

    static func weekdays(from mask: Int) -> [Int] {
        let schedule = WeekdaySet(rawValue: mask)
        return (1...7).compactMap { weekday in
            schedule.containsWeekday(weekday) ? weekday : nil
        }
    }
}

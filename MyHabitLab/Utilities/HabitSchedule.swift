import Foundation

struct WeekdaySet: OptionSet, Hashable, Codable {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static let sunday = WeekdaySet(rawValue: 1 << 0)
    static let monday = WeekdaySet(rawValue: 1 << 1)
    static let tuesday = WeekdaySet(rawValue: 1 << 2)
    static let wednesday = WeekdaySet(rawValue: 1 << 3)
    static let thursday = WeekdaySet(rawValue: 1 << 4)
    static let friday = WeekdaySet(rawValue: 1 << 5)
    static let saturday = WeekdaySet(rawValue: 1 << 6)
    static let all: WeekdaySet = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]

    static func from(calendarWeekday: Int) -> WeekdaySet {
        switch calendarWeekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return []
        }
    }

    static func from(weekdays: [Int]) -> WeekdaySet {
        weekdays.reduce(into: WeekdaySet()) { partial, weekday in
            partial.insert(WeekdaySet.from(calendarWeekday: weekday))
        }
    }

    func containsWeekday(_ weekday: Int) -> Bool {
        contains(WeekdaySet.from(calendarWeekday: weekday))
    }
}

enum HabitSchedule {
    static func isScheduled(
        on date: Date,
        scheduleMask: Int,
        calendar: Calendar = .current
    ) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        let schedule = WeekdaySet(rawValue: scheduleMask)
        return schedule.containsWeekday(weekday)
    }

    static func countsTowardStreak(
        on date: Date,
        scheduleMask: Int,
        policy: ExtraCompletionPolicy,
        isComplete: Bool = false,
        calendar: Calendar = .current
    ) -> Bool {
        if isScheduled(on: date, scheduleMask: scheduleMask, calendar: calendar) {
            return true
        }

        switch policy {
        case .countTowardStreaks:
            return isComplete
        case .totalsOnly:
            return false
        }
    }
}

extension WeekdaySet {
    var count: Int {
        let allDays: [WeekdaySet] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        return allDays.filter { contains($0) }.count
    }
}

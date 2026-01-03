import Foundation
import Testing
@testable import MyHabitLab

struct ReminderScheduleCalculatorTests {
    @Test func timeOfDayComponentsMatchSelectedDays() {
        let schedule = WeekdaySet.monday.union(.wednesday)
        let components = ReminderScheduleCalculator.timeOfDayComponents(
            hour: 9,
            minute: 30,
            daysMask: schedule.rawValue
        )

        #expect(components.count == 2)
        #expect(components.contains { $0.weekday == 2 && $0.hour == 9 && $0.minute == 30 })
        #expect(components.contains { $0.weekday == 4 && $0.hour == 9 && $0.minute == 30 })
    }

    @Test func intervalComponentsGenerateTimesWithinWindow() {
        let schedule = WeekdaySet.monday
        let components = ReminderScheduleCalculator.intervalComponents(
            intervalMinutes: 60,
            startMinute: 9 * 60,
            endMinute: 11 * 60,
            daysMask: schedule.rawValue
        )

        #expect(components.count == 3)
        #expect(components.contains { $0.weekday == 2 && $0.hour == 9 && $0.minute == 0 })
        #expect(components.contains { $0.weekday == 2 && $0.hour == 10 && $0.minute == 0 })
        #expect(components.contains { $0.weekday == 2 && $0.hour == 11 && $0.minute == 0 })
    }
}

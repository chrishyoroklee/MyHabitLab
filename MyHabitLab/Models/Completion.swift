import Foundation
import SwiftData

@Model
final class Completion {
    @Attribute(.unique) var id: UUID
    var dayKey: Int
    var value: Int
    var createdAt: Date
    @Relationship(inverse: \Habit.completions)
    var habit: Habit?

    init(
        id: UUID = UUID(),
        habit: Habit? = nil,
        dayKey: Int,
        value: Int = 1,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.habit = habit
        self.dayKey = dayKey
        self.value = value
        self.createdAt = createdAt
    }
}

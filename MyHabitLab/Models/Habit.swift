import Foundation
import SwiftData

@Model
final class Habit: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var colorName: String
    var detail: String?
    var reminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var createdAt: Date
    var isArchived: Bool
    @Relationship(deleteRule: .cascade)
    var completions: [Completion]

    var targetPerWeek: Int = 7
    
    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "checkmark.circle",
        colorName: String = "Blue",
        detail: String? = nil,
        targetPerWeek: Int = 7,  // Default to daily
        reminderEnabled: Bool = false,
        reminderHour: Int = 9,
        reminderMinute: Int = 0,
        createdAt: Date = Date(),
        isArchived: Bool = false,
        completions: [Completion] = []
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorName = colorName
        self.detail = detail
        self.targetPerWeek = targetPerWeek
        self.reminderEnabled = reminderEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.createdAt = createdAt
        self.isArchived = isArchived
        self.completions = completions
    }
}

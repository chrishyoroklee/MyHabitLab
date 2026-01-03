import Foundation
import SwiftData

enum HabitTrackingMode: String, Codable, CaseIterable {
    case checkmark
    case unit
}

enum ExtraCompletionPolicy: String, Codable, CaseIterable {
    /// Option B: extras count toward streaks and rates.
    case countTowardStreaks
    /// Option C: extras count only toward totals.
    case totalsOnly
}

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
    var trackingModeRaw: String = HabitTrackingMode.checkmark.rawValue
    var scheduleMask: Int = WeekdaySet.all.rawValue
    var extraCompletionPolicyRaw: String = ExtraCompletionPolicy.totalsOnly.rawValue
    var unitDisplayName: String?
    var unitBaseName: String?
    var unitBaseScale: Int = 1
    var unitDisplayPrecision: Int = 0
    var unitGoalBaseValue: Int?
    var unitDefaultIncrementBaseValue: Int?
    var createdAt: Date
    var isArchived: Bool
    @Relationship(deleteRule: .cascade)
    var completions: [Completion]
    @Relationship(deleteRule: .cascade)
    var reminders: [HabitReminder] = []

    var targetPerWeek: Int = 7

    var trackingMode: HabitTrackingMode {
        get { HabitTrackingMode(rawValue: trackingModeRaw) ?? .checkmark }
        set { trackingModeRaw = newValue.rawValue }
    }

    var extraCompletionPolicy: ExtraCompletionPolicy {
        get { ExtraCompletionPolicy(rawValue: extraCompletionPolicyRaw) ?? .totalsOnly }
        set { extraCompletionPolicyRaw = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "checkmark.circle",
        colorName: String = "Blue",
        detail: String? = nil,
        trackingMode: HabitTrackingMode = .checkmark,
        scheduleMask: Int = WeekdaySet.all.rawValue,
        extraCompletionPolicy: ExtraCompletionPolicy = .totalsOnly,
        unitDisplayName: String? = nil,
        unitBaseName: String? = nil,
        unitBaseScale: Int = 1,
        unitDisplayPrecision: Int = 0,
        unitGoalBaseValue: Int? = nil,
        unitDefaultIncrementBaseValue: Int? = nil,
        targetPerWeek: Int = 7,  // Default to daily
        reminderEnabled: Bool = false,
        reminderHour: Int = 9,
        reminderMinute: Int = 0,
        createdAt: Date = Date(),
        isArchived: Bool = false,
        completions: [Completion] = [],
        reminders: [HabitReminder] = []
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorName = colorName
        self.detail = detail
        self.trackingModeRaw = trackingMode.rawValue
        self.scheduleMask = scheduleMask
        self.extraCompletionPolicyRaw = extraCompletionPolicy.rawValue
        self.unitDisplayName = unitDisplayName
        self.unitBaseName = unitBaseName
        self.unitBaseScale = max(1, unitBaseScale)
        self.unitDisplayPrecision = max(0, unitDisplayPrecision)
        self.unitGoalBaseValue = unitGoalBaseValue
        self.unitDefaultIncrementBaseValue = unitDefaultIncrementBaseValue
        self.targetPerWeek = targetPerWeek
        self.reminderEnabled = reminderEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.createdAt = createdAt
        self.isArchived = isArchived
        self.completions = completions
        self.reminders = reminders
    }
}

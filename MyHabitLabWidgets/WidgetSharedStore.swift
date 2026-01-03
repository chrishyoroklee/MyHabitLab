import Foundation
import WidgetKit

struct WidgetHabitSnapshot: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let iconName: String
    let colorName: String
    let isCompletedToday: Bool
    let trackingModeRaw: String
    let completionValueBase: Int
    let unitDisplayName: String?
    let unitBaseScale: Int
    let unitDisplayPrecision: Int
    let unitGoalBaseValue: Int
    let unitDefaultIncrementBaseValue: Int
    let scheduleMask: Int
    let extraCompletionPolicyRaw: String

    init(
        id: UUID,
        name: String,
        iconName: String,
        colorName: String,
        isCompletedToday: Bool,
        trackingModeRaw: String,
        completionValueBase: Int,
        unitDisplayName: String?,
        unitBaseScale: Int,
        unitDisplayPrecision: Int,
        unitGoalBaseValue: Int,
        unitDefaultIncrementBaseValue: Int,
        scheduleMask: Int,
        extraCompletionPolicyRaw: String
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorName = colorName
        self.isCompletedToday = isCompletedToday
        self.trackingModeRaw = trackingModeRaw
        self.completionValueBase = completionValueBase
        self.unitDisplayName = unitDisplayName
        self.unitBaseScale = unitBaseScale
        self.unitDisplayPrecision = unitDisplayPrecision
        self.unitGoalBaseValue = unitGoalBaseValue
        self.unitDefaultIncrementBaseValue = unitDefaultIncrementBaseValue
        self.scheduleMask = scheduleMask
        self.extraCompletionPolicyRaw = extraCompletionPolicyRaw
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        iconName = try container.decode(String.self, forKey: .iconName)
        colorName = try container.decode(String.self, forKey: .colorName)
        isCompletedToday = try container.decodeIfPresent(Bool.self, forKey: .isCompletedToday) ?? false
        trackingModeRaw = try container.decodeIfPresent(String.self, forKey: .trackingModeRaw) ?? "checkmark"
        completionValueBase = try container.decodeIfPresent(Int.self, forKey: .completionValueBase) ?? (isCompletedToday ? 1 : 0)
        unitDisplayName = try container.decodeIfPresent(String.self, forKey: .unitDisplayName)
        unitBaseScale = try container.decodeIfPresent(Int.self, forKey: .unitBaseScale) ?? 1
        unitDisplayPrecision = try container.decodeIfPresent(Int.self, forKey: .unitDisplayPrecision) ?? 0
        unitGoalBaseValue = try container.decodeIfPresent(Int.self, forKey: .unitGoalBaseValue) ?? 1
        unitDefaultIncrementBaseValue = try container.decodeIfPresent(Int.self, forKey: .unitDefaultIncrementBaseValue) ?? 1
        scheduleMask = try container.decodeIfPresent(Int.self, forKey: .scheduleMask) ?? 127
        extraCompletionPolicyRaw = try container.decodeIfPresent(String.self, forKey: .extraCompletionPolicyRaw) ?? "totalsOnly"
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case iconName
        case colorName
        case isCompletedToday
        case trackingModeRaw
        case completionValueBase
        case unitDisplayName
        case unitBaseScale
        case unitDisplayPrecision
        case unitGoalBaseValue
        case unitDefaultIncrementBaseValue
        case scheduleMask
        case extraCompletionPolicyRaw
    }
}

struct WidgetPendingToggle: Codable, Hashable {
    let habitId: UUID
    let dayKey: Int
    let createdAt: Date
}

struct WidgetSharedState: Codable, Hashable {
    var habits: [WidgetHabitSnapshot]
    var pendingToggles: [WidgetPendingToggle]
    var updatedAt: Date
}

enum WidgetAppGroupIdentifier {
    static let value = "group.com.hyoroklee.habitlab"
}

enum WidgetSharedStore {
    static func loadState() -> WidgetSharedState {
        guard let url = storeURL else {
            return emptyState()
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(WidgetSharedState.self, from: data)
        } catch {
            return emptyState()
        }
    }

    static func saveState(_ state: WidgetSharedState) {
        guard let url = storeURL else { return }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(state)
            try data.write(to: url, options: [.atomic])
        } catch {
            return
        }
    }

    static func toggleHabit(id: UUID, dayKey: Int) {
        var state = loadState()
        guard let index = state.habits.firstIndex(where: { $0.id == id }) else {
            return
        }

        let habit = state.habits[index]
        let updated = toggleSnapshot(habit, dayKey: dayKey)
        state.habits[index] = updated
        state.pendingToggles.append(
            WidgetPendingToggle(habitId: id, dayKey: dayKey, createdAt: Date())
        )
        state.updatedAt = Date()
        saveState(state)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func sampleHabits() -> [WidgetHabitSnapshot] {
        [
            WidgetHabitSnapshot(
                id: UUID(),
                name: String(localized: "widget.sample.drink_water"),
                iconName: "drop",
                colorName: "Electric Blue",
                isCompletedToday: false,
                trackingModeRaw: "unit",
                completionValueBase: 1500,
                unitDisplayName: "L",
                unitBaseScale: 1000,
                unitDisplayPrecision: 1,
                unitGoalBaseValue: 2000,
                unitDefaultIncrementBaseValue: 500,
                scheduleMask: 127,
                extraCompletionPolicyRaw: "totalsOnly"
            ),
            WidgetHabitSnapshot(
                id: UUID(),
                name: String(localized: "widget.sample.read"),
                iconName: "book",
                colorName: "Neon Purple",
                isCompletedToday: true,
                trackingModeRaw: "checkmark",
                completionValueBase: 1,
                unitDisplayName: nil,
                unitBaseScale: 1,
                unitDisplayPrecision: 0,
                unitGoalBaseValue: 1,
                unitDefaultIncrementBaseValue: 1,
                scheduleMask: 127,
                extraCompletionPolicyRaw: "totalsOnly"
            ),
            WidgetHabitSnapshot(
                id: UUID(),
                name: String(localized: "widget.sample.walk"),
                iconName: "figure.walk",
                colorName: "Lime Green",
                isCompletedToday: false,
                trackingModeRaw: "checkmark",
                completionValueBase: 0,
                unitDisplayName: nil,
                unitBaseScale: 1,
                unitDisplayPrecision: 0,
                unitGoalBaseValue: 1,
                unitDefaultIncrementBaseValue: 1,
                scheduleMask: 127,
                extraCompletionPolicyRaw: "totalsOnly"
            )
        ]
    }

    private static var storeURL: URL? {
        if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WidgetAppGroupIdentifier.value) {
            return container.appendingPathComponent("widget-habits.json")
        }

        if let fallback = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let directory = fallback.appendingPathComponent("WidgetStore", isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            } catch {
                return nil
            }
            return directory.appendingPathComponent("widget-habits.json")
        }

        return nil
    }

    private static func emptyState() -> WidgetSharedState {
        WidgetSharedState(habits: [], pendingToggles: [], updatedAt: Date())
    }

    private static func toggleSnapshot(_ habit: WidgetHabitSnapshot, dayKey _: Int) -> WidgetHabitSnapshot {
        let trackingMode = WidgetTrackingMode(rawValue: habit.trackingModeRaw) ?? .checkmark
        let goalBase = max(1, habit.unitGoalBaseValue)
        let incrementBase = max(1, habit.unitDefaultIncrementBaseValue)
        var completionValue = habit.completionValueBase

        switch trackingMode {
        case .checkmark:
            let newCompleted = habit.isCompletedToday == false
            completionValue = newCompleted ? 1 : 0
            return WidgetHabitSnapshot(
                id: habit.id,
                name: habit.name,
                iconName: habit.iconName,
                colorName: habit.colorName,
                isCompletedToday: newCompleted,
                trackingModeRaw: habit.trackingModeRaw,
                completionValueBase: completionValue,
                unitDisplayName: habit.unitDisplayName,
                unitBaseScale: habit.unitBaseScale,
                unitDisplayPrecision: habit.unitDisplayPrecision,
                unitGoalBaseValue: habit.unitGoalBaseValue,
                unitDefaultIncrementBaseValue: habit.unitDefaultIncrementBaseValue,
                scheduleMask: habit.scheduleMask,
                extraCompletionPolicyRaw: habit.extraCompletionPolicyRaw
            )
        case .unit:
            if completionValue >= goalBase {
                completionValue = 0
            } else {
                completionValue = min(completionValue + incrementBase, goalBase)
            }
            let isCompleted = completionValue >= goalBase
            return WidgetHabitSnapshot(
                id: habit.id,
                name: habit.name,
                iconName: habit.iconName,
                colorName: habit.colorName,
                isCompletedToday: isCompleted,
                trackingModeRaw: habit.trackingModeRaw,
                completionValueBase: completionValue,
                unitDisplayName: habit.unitDisplayName,
                unitBaseScale: habit.unitBaseScale,
                unitDisplayPrecision: habit.unitDisplayPrecision,
                unitGoalBaseValue: habit.unitGoalBaseValue,
                unitDefaultIncrementBaseValue: habit.unitDefaultIncrementBaseValue,
                scheduleMask: habit.scheduleMask,
                extraCompletionPolicyRaw: habit.extraCompletionPolicyRaw
            )
        }
    }
}

enum WidgetTrackingMode: String {
    case checkmark
    case unit
}

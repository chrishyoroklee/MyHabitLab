import Foundation

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
        trackingModeRaw = try container.decodeIfPresent(String.self, forKey: .trackingModeRaw) ?? HabitTrackingMode.checkmark.rawValue
        completionValueBase = try container.decodeIfPresent(Int.self, forKey: .completionValueBase) ?? (isCompletedToday ? 1 : 0)
        unitDisplayName = try container.decodeIfPresent(String.self, forKey: .unitDisplayName)
        unitBaseScale = try container.decodeIfPresent(Int.self, forKey: .unitBaseScale) ?? 1
        unitDisplayPrecision = try container.decodeIfPresent(Int.self, forKey: .unitDisplayPrecision) ?? 0
        unitGoalBaseValue = try container.decodeIfPresent(Int.self, forKey: .unitGoalBaseValue) ?? 1
        unitDefaultIncrementBaseValue = try container.decodeIfPresent(Int.self, forKey: .unitDefaultIncrementBaseValue) ?? 1
        scheduleMask = try container.decodeIfPresent(Int.self, forKey: .scheduleMask) ?? WeekdaySet.all.rawValue
        extraCompletionPolicyRaw = try container.decodeIfPresent(String.self, forKey: .extraCompletionPolicyRaw) ?? ExtraCompletionPolicy.totalsOnly.rawValue
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

enum AppGroupIdentifier {
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
            assertionFailure("Failed to write widget store: \(error)")
        }
    }

    static func updateHabits(_ habits: [WidgetHabitSnapshot]) {
        var state = loadState()
        state.habits = habits
        state.updatedAt = Date()
        saveState(state)
    }

    static func enqueueToggle(habitId: UUID, dayKey: Int) {
        var state = loadState()
        state.pendingToggles.append(
            WidgetPendingToggle(habitId: habitId, dayKey: dayKey, createdAt: Date())
        )
        saveState(state)
    }

    private static var storeURL: URL? {
        if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroupIdentifier.value) {
            return container.appendingPathComponent("widget-habits.json")
        }

        if let fallback = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let directory = fallback.appendingPathComponent("WidgetStore", isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            } catch {
                assertionFailure("Failed to create widget store directory: \(error)")
                return nil
            }
            return directory.appendingPathComponent("widget-habits.json")
        }

        return nil
    }

    private static func emptyState() -> WidgetSharedState {
        WidgetSharedState(habits: [], pendingToggles: [], updatedAt: Date())
    }
}

import Foundation
import WidgetKit

struct WidgetHabitSnapshot: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let iconName: String
    let colorName: String
    let isCompletedToday: Bool
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
        let updated = WidgetHabitSnapshot(
            id: habit.id,
            name: habit.name,
            iconName: habit.iconName,
            colorName: habit.colorName,
            isCompletedToday: habit.isCompletedToday == false
        )
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
                name: "Drink Water",
                iconName: "drop",
                colorName: "Blue",
                isCompletedToday: true
            ),
            WidgetHabitSnapshot(
                id: UUID(),
                name: "Read",
                iconName: "book",
                colorName: "Indigo",
                isCompletedToday: false
            ),
            WidgetHabitSnapshot(
                id: UUID(),
                name: "Walk",
                iconName: "figure.walk",
                colorName: "Green",
                isCompletedToday: false
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
}

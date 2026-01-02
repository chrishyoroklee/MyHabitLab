import Foundation

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

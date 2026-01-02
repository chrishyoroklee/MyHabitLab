import SwiftUI
import WidgetKit

struct HabitEntry: TimelineEntry {
    let date: Date
    let habits: [WidgetHabitSnapshot]
}

struct HabitProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(date: Date(), habits: WidgetSharedStore.sampleHabits())
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> Void) {
        let entry = HabitEntry(date: Date(), habits: loadHabits())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> Void) {
        let entry = HabitEntry(date: Date(), habits: loadHabits())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadHabits() -> [WidgetHabitSnapshot] {
        let state = WidgetSharedStore.loadState()
        if state.habits.isEmpty {
            return WidgetSharedStore.sampleHabits()
        }
        return state.habits
    }
}

struct MyHabitLabWidget: Widget {
    let kind = "MyHabitLabWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitProvider()) { entry in
            MyHabitLabWidgetView(entry: entry)
        }
        .configurationDisplayName("widget.display_name")
        .description("widget.description")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MyHabitLabWidgetView: View {
    let entry: HabitEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("widget.today")
                .font(.headline)
            ForEach(displayHabits) { habit in
                WidgetHabitRow(habit: habit)
            }
            Spacer(minLength: 0)
        }
        .padding()
    }

    private var displayHabits: [WidgetHabitSnapshot] {
        let limit = family == .systemSmall ? 3 : 6
        return Array(entry.habits.prefix(limit))
    }
}

struct WidgetHabitRow: View {
    let habit: WidgetHabitSnapshot

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: habit.iconName)
                .foregroundStyle(color)
            Text(habit.name)
                .font(.caption)
                .lineLimit(1)
            Spacer(minLength: 4)
            Button(intent: ToggleHabitCompletionIntent(habitId: habit.id.uuidString)) {
                Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(habit.isCompletedToday ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var color: Color {
        switch habit.colorName {
        case "Green": return .green
        case "Orange": return .orange
        case "Pink": return .pink
        case "Teal": return .teal
        case "Indigo": return .indigo
        default: return .blue
        }
    }
}

#Preview("Small", as: .systemSmall) {
    MyHabitLabWidget()
} timeline: {
    HabitEntry(date: Date(), habits: WidgetSharedStore.sampleHabits())
}

#Preview("Medium", as: .systemMedium) {
    MyHabitLabWidget()
} timeline: {
    HabitEntry(date: Date(), habits: WidgetSharedStore.sampleHabits())
}

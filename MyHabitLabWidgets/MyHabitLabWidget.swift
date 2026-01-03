import SwiftUI
import WidgetKit
import AppIntents

struct SummaryEntry: TimelineEntry {
    let date: Date
    let habits: [WidgetHabitSnapshot]
}

struct SummaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> SummaryEntry {
        SummaryEntry(date: Date(), habits: WidgetSharedStore.sampleHabits())
    }

    func getSnapshot(in context: Context, completion: @escaping (SummaryEntry) -> Void) {
        let entry = SummaryEntry(date: Date(), habits: loadHabits())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SummaryEntry>) -> Void) {
        let entry = SummaryEntry(date: Date(), habits: loadHabits())
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

struct SummaryWidget: Widget {
    let kind = "MyHabitLabSummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SummaryProvider()) { entry in
            SummaryWidgetView(entry: entry)
        }
        .configurationDisplayName("widget.summary.display_name")
        .description("widget.summary.description")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SummaryWidgetView: View {
    let entry: SummaryEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("widget.today")
                    .font(.headline)
                Spacer()
                Text("\(completedCount)/\(countedCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

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

    private var completedCount: Int {
        entry.habits.filter { habit in
            habit.isComplete && habit.countsTowardStats(on: entry.date)
        }.count
    }

    private var countedCount: Int {
        entry.habits.filter { habit in
            habit.countsTowardStats(on: entry.date)
        }.count
    }
}

struct HabitDetailEntry: TimelineEntry {
    let date: Date
    let habit: WidgetHabitSnapshot?
    let configuration: WidgetHabitSelectionIntent
}

struct HabitDetailProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> HabitDetailEntry {
        HabitDetailEntry(date: Date(), habit: WidgetSharedStore.sampleHabits().first, configuration: WidgetHabitSelectionIntent())
    }

    func snapshot(for configuration: WidgetHabitSelectionIntent, in context: Context) async -> HabitDetailEntry {
        HabitDetailEntry(date: Date(), habit: habit(for: configuration), configuration: configuration)
    }

    func timeline(for configuration: WidgetHabitSelectionIntent, in context: Context) async -> Timeline<HabitDetailEntry> {
        let entry = HabitDetailEntry(date: Date(), habit: habit(for: configuration), configuration: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func habit(for configuration: WidgetHabitSelectionIntent) -> WidgetHabitSnapshot? {
        let state = WidgetSharedStore.loadState()
        guard let selection = configuration.habit else {
            return state.habits.first
        }
        return state.habits.first { $0.id == selection.id }
    }
}

struct HabitDetailWidget: Widget {
    let kind = "MyHabitLabHabitWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WidgetHabitSelectionIntent.self, provider: HabitDetailProvider()) { entry in
            HabitDetailWidgetView(entry: entry)
        }
        .configurationDisplayName("widget.habit.display_name")
        .description("widget.habit.description")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HabitDetailWidgetView: View {
    let entry: HabitDetailEntry

    var body: some View {
        if let habit = entry.habit {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: habit.iconName)
                        .foregroundStyle(widgetColor(for: habit.colorName))
                    Text(habit.name)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Button(intent: ToggleHabitCompletionIntent(habitId: habit.id.uuidString)) {
                        Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(habit.isCompletedToday ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                }

                if let progress = habit.progressText() {
                    Text(progress)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(habit.countsTowardStats(on: entry.date) ? "widget.due_today" : "widget.off_day")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("widget.habit.empty.title")
                    .font(.headline)
                Text("widget.habit.empty.message")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .padding()
        }
    }
}

struct WidgetHabitRow: View {
    let habit: WidgetHabitSnapshot

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: habit.iconName)
                .foregroundStyle(widgetColor(for: habit.colorName))
            Text(habit.name)
                .font(.caption)
                .lineLimit(1)
            Spacer(minLength: 4)
            if let progress = habit.progressText() {
                Text(progress)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Button(intent: ToggleHabitCompletionIntent(habitId: habit.id.uuidString)) {
                Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(habit.isCompletedToday ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

private func widgetColor(for name: String) -> Color {
    switch name {
    case "Electric Blue": return Color(red: 0.23, green: 0.51, blue: 0.96)
    case "Neon Purple": return Color(red: 0.85, green: 0.27, blue: 0.94)
    case "Sunset Orange": return Color(red: 0.98, green: 0.45, blue: 0.09)
    case "Hot Pink": return Color(red: 0.93, green: 0.28, blue: 0.60)
    case "Lime Green": return Color(red: 0.13, green: 0.77, blue: 0.37)
    case "Teal Blue": return Color(red: 0.02, green: 0.71, blue: 0.83)
    case "Golden Yellow": return Color(red: 0.92, green: 0.70, blue: 0.03)
    case "Scarlet Red": return Color(red: 0.94, green: 0.27, blue: 0.27)
    case "Green": return .green
    case "Orange": return .orange
    case "Pink": return .pink
    case "Teal": return .teal
    case "Indigo": return .indigo
    default: return .blue
    }
}

private struct WidgetUnitFormatter {
    let displayName: String
    let baseScale: Int
    let precision: Int

    func displayValue(baseValue: Int) -> Double {
        Double(baseValue) / Double(max(1, baseScale))
    }

    func format(_ value: Double, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = precision
        formatter.maximumFractionDigits = precision
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

private enum WidgetExtraCompletionPolicy: String {
    case countTowardStreaks
    case totalsOnly
}

private struct WidgetSchedule {
    static func isScheduled(on date: Date, scheduleMask: Int, calendar: Calendar = .current) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        let bit = 1 << (weekday - 1)
        return (scheduleMask & bit) != 0
    }

    static func countsTowardStats(on date: Date, scheduleMask: Int, policy: WidgetExtraCompletionPolicy, isComplete: Bool) -> Bool {
        if isScheduled(on: date, scheduleMask: scheduleMask) {
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

private extension WidgetHabitSnapshot {
    var trackingMode: WidgetTrackingMode {
        WidgetTrackingMode(rawValue: trackingModeRaw) ?? .checkmark
    }

    var isComplete: Bool {
        switch trackingMode {
        case .checkmark:
            return isCompletedToday
        case .unit:
            return completionValueBase >= max(1, unitGoalBaseValue)
        }
    }

    func countsTowardStats(on date: Date) -> Bool {
        let policy = WidgetExtraCompletionPolicy(rawValue: extraCompletionPolicyRaw) ?? .totalsOnly
        return WidgetSchedule.countsTowardStats(
            on: date,
            scheduleMask: scheduleMask,
            policy: policy,
            isComplete: isComplete
        )
    }

    func progressText(locale: Locale = .current) -> String? {
        guard trackingMode == .unit else { return nil }
        let formatter = WidgetUnitFormatter(
            displayName: unitDisplayName ?? "",
            baseScale: unitBaseScale,
            precision: unitDisplayPrecision
        )
        let current = formatter.format(formatter.displayValue(baseValue: completionValueBase), locale: locale)
        let goal = formatter.format(formatter.displayValue(baseValue: unitGoalBaseValue), locale: locale)
        let name = unitDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let suffix = name.isEmpty ? "" : " \(name)"
        return "\(current)/\(goal)\(suffix)"
    }
}

#Preview("Summary Small", as: .systemSmall) {
    SummaryWidget()
} timeline: {
    SummaryEntry(date: Date(), habits: WidgetSharedStore.sampleHabits())
}

#Preview("Summary Medium", as: .systemMedium) {
    SummaryWidget()
} timeline: {
    SummaryEntry(date: Date(), habits: WidgetSharedStore.sampleHabits())
}

#Preview("Habit Small", as: .systemSmall) {
    HabitDetailWidget()
} timeline: {
    HabitDetailEntry(date: Date(), habit: WidgetSharedStore.sampleHabits().first, configuration: WidgetHabitSelectionIntent())
}

#Preview("Habit Medium", as: .systemMedium) {
    HabitDetailWidget()
} timeline: {
    HabitDetailEntry(date: Date(), habit: WidgetSharedStore.sampleHabits().first, configuration: WidgetHabitSelectionIntent())
}

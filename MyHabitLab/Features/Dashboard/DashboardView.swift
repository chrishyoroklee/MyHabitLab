import SwiftUI
import SwiftData

struct DashboardView: View {
    let dateProvider: DateProvider
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(
        filter: #Predicate<Habit> { habit in
            habit.isArchived == false
        },
        sort: \Habit.createdAt
    )
    private var habits: [Habit]
    @State private var isPresentingNewHabit = false
    @State private var editingHabit: Habit?
    @State private var detailHabit: Habit?
    @State private var todayKey: Int = 0
    @State private var completionByHabitId: [UUID: Completion] = [:]

    var body: some View {
        let today = dateProvider.today()
        let dayKey = todayKey == 0 ? dateProvider.dayKey() : todayKey
        return NavigationStack {
            Group {
                if habits.isEmpty {
                    ContentUnavailableView(
                        "dashboard.no_habits_title",
                        systemImage: "checkmark.circle",
                        description: Text("dashboard.no_habits_message")
                    )
                } else {
                    List {
                        Section {
                            ForEach(habits) { habit in
                                HabitRow(
                                    habit: habit,
                                    isCompleted: completionByHabitId[habit.id] != nil,
                                    onToggle: {
                                        toggleCompletion(for: habit, dayKey: dayKey)
                                    },
                                    onShowHistory: {
                                        editingHabit = habit
                                    },
                                    onShowDetail: {
                                        detailHabit = habit
                                    }
                                )
                            }
                        } header: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("dashboard.section.today")
                                    .font(.headline)
                                Text(today.displayTitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .textCase(nil)
                        }
                    }
                }
            }
            .navigationTitle("dashboard.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingNewHabit = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(Text("dashboard.action.new_habit"))
                }
            }
            .sheet(isPresented: $isPresentingNewHabit, onDismiss: {
                refreshCompletions()
            }) {
                NewHabitSheet()
            }
            .sheet(item: $editingHabit, onDismiss: {
                refreshCompletions()
            }) { habit in
                HabitCalendarEditorView(habit: habit, dateProvider: dateProvider)
            }
            .sheet(item: $detailHabit) { habit in
                HabitDetailView(habit: habit)
            }
            .task {
                refreshCompletions()
            }
            .onChange(of: scenePhase) { _, newValue in
                guard newValue == .active else { return }
                refreshCompletions()
            }
        }
    }

    @MainActor
    private func refreshCompletions() {
        let dayKey = dateProvider.dayKey()
        todayKey = dayKey
        var descriptor = FetchDescriptor<Completion>(
            predicate: #Predicate<Completion> { completion in
                completion.dayKey == dayKey
            }
        )
        do {
            let completions = try modelContext.fetch(descriptor)
            var map: [UUID: Completion] = [:]
            for completion in completions {
                guard let habitId = completion.habit?.id else { continue }
                map[habitId] = completion
            }
            completionByHabitId = map
        } catch {
            assertionFailure("Failed to fetch today's completions: \(error)")
        }
    }

    @MainActor
    private func toggleCompletion(for habit: Habit, dayKey: Int) {
        if let existing = completionByHabitId[habit.id] {
            modelContext.delete(existing)
            completionByHabitId[habit.id] = nil
        } else {
            let completion = Completion(habit: habit, dayKey: dayKey, value: 1)
            modelContext.insert(completion)
            completionByHabitId[habit.id] = completion
        }

        do {
            try modelContext.save()
            WidgetStoreSync.updateSnapshot(
                context: modelContext,
                dayKey: dayKey
            )
        } catch {
            assertionFailure("Failed to toggle completion: \(error)")
        }
    }
}

struct HabitRow: View {
    let habit: Habit
    let isCompleted: Bool
    let onToggle: () -> Void
    let onShowHistory: () -> Void
    let onShowDetail: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HabitIconView(
                name: habit.name,
                iconName: habit.iconName,
                colorName: habit.colorName
            )
            Text(habit.name)
                .lineLimit(2)
                .layoutPriority(1)
            Spacer()
            Button {
                onToggle()
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
                    .foregroundStyle(isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(isCompleted ? "dashboard.accessibility.mark_not_completed" : "dashboard.accessibility.mark_completed"))
            .accessibilityValue(Text(isCompleted ? "calendar.accessibility.completed" : "calendar.accessibility.not_completed"))
            Button {
                onShowHistory()
            } label: {
                Image(systemName: "calendar")
                    .imageScale(.medium)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("dashboard.action.edit_history"))
            Button {
                onShowDetail()
            } label: {
                Image(systemName: "info.circle")
                    .imageScale(.medium)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("dashboard.action.edit_habit"))
        }
        .contentShape(Rectangle())
    }
}

struct HabitIconView: View {
    let name: String
    let iconName: String
    let colorName: String

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
            if iconName.isEmpty {
                Text(initial)
                    .font(.headline)
                    .foregroundStyle(color)
            } else {
                Image(systemName: iconName)
                    .font(.headline)
                    .foregroundStyle(color)
            }
        }
        .frame(width: 36, height: 36)
    }

    private var initial: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "H" : String(trimmed.prefix(1)).uppercased()
    }

    private var color: Color {
        HabitPalette.color(for: colorName)
    }
}

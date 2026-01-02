//
//  ContentView.swift
//  MyHabitLab
//
//  Created by 이효록 on 1/2/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    let dateProvider: DateProvider

    var body: some View {
        TabView {
            DashboardView(dateProvider: dateProvider)
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

struct DashboardView: View {
    let dateProvider: DateProvider
    @Query(
        filter: #Predicate<Habit> { habit in
            habit.isArchived == false
        },
        sort: \Habit.createdAt
    )
    private var habits: [Habit]
    @State private var isPresentingNewHabit = false
    @State private var editingHabit: Habit?

    var body: some View {
        let today = dateProvider.today()
        let dayKey = dateProvider.dayKey()
        return NavigationStack {
            Group {
                if habits.isEmpty {
                    ContentUnavailableView(
                        "No Habits Yet",
                        systemImage: "checkmark.circle",
                        description: Text("Create a habit to start tracking today.")
                    )
                } else {
                    List {
                        Section {
                            ForEach(habits) { habit in
                                HabitRow(
                                    habit: habit,
                                    dayKey: dayKey,
                                    onShowHistory: {
                                        editingHabit = habit
                                    }
                                )
                            }
                        } header: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Today")
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
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingNewHabit = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New Habit")
                }
            }
            .sheet(isPresented: $isPresentingNewHabit) {
                NewHabitSheet()
            }
            .sheet(item: $editingHabit) { habit in
                HabitCalendarEditorView(habit: habit, dateProvider: dateProvider)
            }
        }
    }
}

struct HabitRow: View {
    let habit: Habit
    let dayKey: Int
    let onShowHistory: () -> Void
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 12) {
            HabitIconView(
                name: habit.name,
                iconName: habit.iconName,
                colorName: habit.colorName
            )
            Text(habit.name)
            Spacer()
            Button {
                toggleCompletion()
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
                    .foregroundStyle(isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isCompleted ? "Mark not completed" : "Mark completed")
            Button {
                onShowHistory()
            } label: {
                Image(systemName: "calendar")
                    .imageScale(.medium)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit history")
        }
        .contentShape(Rectangle())
    }

    private var isCompleted: Bool {
        completionForToday != nil
    }

    private var completionForToday: Completion? {
        habit.completions.first { $0.dayKey == dayKey }
    }

    private func toggleCompletion() {
        if let completion = completionForToday {
            modelContext.delete(completion)
        } else {
            let completion = Completion(habit: habit, dayKey: dayKey, value: 1)
            modelContext.insert(completion)
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

struct StatsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Stats Coming Soon",
                systemImage: "chart.bar",
                description: Text("Your progress charts will live here.")
            )
            .navigationTitle("Stats")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Settings Coming Soon",
                systemImage: "gearshape",
                description: Text("Customize reminders and preferences here.")
            )
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView(dateProvider: .live)
}

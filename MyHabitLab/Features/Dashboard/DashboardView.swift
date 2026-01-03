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
            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(today.displayTitle)
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    if habits.isEmpty {
                        ContentUnavailableView(
                            "dashboard.no_habits_title",
                            systemImage: "checkmark.circle",
                            description: Text("dashboard.no_habits_message")
                        )
                        .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(habits) { habit in
                                let completion = completionByHabitId[habit.id]
                                let isScheduledToday = HabitSchedule.isScheduled(
                                    on: today.start,
                                    scheduleMask: habit.scheduleMask,
                                    calendar: dateProvider.calendar
                                )
                                let isCompletedToday = HabitCompletionService.isComplete(
                                    habit: habit,
                                    completion: completion
                                )
                                let progressText = HabitCompletionService.progressText(
                                    habit: habit,
                                    completionValue: completion?.value
                                )
                                let completedDayKeys = HabitCompletionService.completedDayKeys(for: habit)

                                HabitCardView(
                                    habit: habit,
                                    isCompletedToday: isCompletedToday,
                                    isScheduledToday: isScheduledToday,
                                    progressText: progressText,
                                    completedDayKeys: completedDayKeys,
                                    toggleAction: {
                                        toggleCompletion(for: habit, dayKey: dayKey)
                                    }
                                )
                                .onTapGesture {
                                    detailHabit = habit
                                }
                                .contextMenu {
                                    Button {
                                        editingHabit = habit
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
            .background(AppColors.primaryBackground)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("MyHabitLab")
                        .font(.title3)
                        .fontWeight(.black)
                        .fontDesign(.rounded)
                        .fixedSize()
                }
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
                HabitFormView()
            }
            .sheet(item: $editingHabit, onDismiss: {
                refreshCompletions()
            }) { habit in
                HabitCalendarEditorView(habit: habit, dateProvider: dateProvider)
            }
            .sheet(item: $detailHabit) { habit in
                HabitDetailView(habit: habit, dateProvider: dateProvider)
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
                if let existing = map[habitId] {
                    if completion.value > existing.value {
                        map[habitId] = completion
                    }
                } else {
                    map[habitId] = completion
                }
            }
            completionByHabitId = map
        } catch {
            assertionFailure("Failed to fetch today's completions: \(error)")
        }
    }

    @MainActor
    private func toggleCompletion(for habit: Habit, dayKey: Int) -> Bool {
        let completion = HabitCompletionService.toggleCompletion(
            habit: habit,
            dayKey: dayKey,
            context: modelContext
        )

        completionByHabitId[habit.id] = completion

        do {
            try modelContext.save()
            WidgetStoreSync.updateSnapshot(
                context: modelContext,
                dayKey: dayKey
            )
        } catch {
            assertionFailure("Failed to toggle completion: \(error)")
        }

        return HabitCompletionService.isComplete(habit: habit, completion: completion)
    }
}

import SwiftUI
import SwiftData
import UserNotifications
import Foundation

struct HabitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var habit: Habit
    let dateProvider: DateProvider

    @State private var reminderTime: Date
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isShowingPermissionAlert = false
    @State private var isShowingDeniedAlert = false
    @State private var isShowingArchiveConfirm = false

    init(habit: Habit, dateProvider: DateProvider) {
        self.habit = habit
        self.dateProvider = dateProvider
        var components = DateComponents()
        components.hour = habit.reminderHour
        components.minute = habit.reminderMinute
        _reminderTime = State(initialValue: Calendar.current.date(from: components) ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("habit.detail.section.reminder") {
                    Toggle("habit.field.reminder_toggle", isOn: $habit.reminderEnabled)
                        .accessibilityLabel(Text("habit.field.reminder_toggle"))
                    if habit.reminderEnabled {
                        DatePicker("habit.field.reminder_time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .accessibilityLabel(Text("habit.field.reminder_time"))
                    }
                }

                Section("habit.detail.section.status") {
                    Toggle("habit.detail.toggle.archived", isOn: archiveBinding)
                        .accessibilityLabel(Text("habit.detail.toggle.archived"))
                }

                Section("habit.detail.section.history") {
                    Text("habit.detail.history.last_90_days")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HabitHistoryGridView(
                        entries: historyEntries,
                        completedDayKeys: completedDayKeys
                    )
                }
            }
            .navigationTitle(habit.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("habit.detail.action.done") {
                        dismiss()
                    }
                }
            }
            .task {
                authorizationStatus = await ReminderScheduler.authorizationStatus()
            }
            .onChange(of: habit.reminderEnabled) { _, newValue in
                handleReminderToggle(newValue)
            }
            .onChange(of: reminderTime) { _, _ in
                updateReminderTime()
            }
            .alert("permission.notifications.title", isPresented: $isShowingPermissionAlert) {
                Button("permission.notifications.not_now", role: .cancel) {
                    habit.reminderEnabled = false
                }
                Button("permission.notifications.allow") {
                    Task {
                        let granted = await ReminderScheduler.requestAuthorization()
                        authorizationStatus = await ReminderScheduler.authorizationStatus()
                        if granted == false {
                            habit.reminderEnabled = false
                            isShowingDeniedAlert = true
                        }
                        await persistAndSchedule()
                    }
                }
            } message: {
                Text("permission.notifications.message")
            }
            .alert("permission.notifications.denied_title", isPresented: $isShowingDeniedAlert) {
                Button("action.ok", role: .cancel) {}
            } message: {
                Text("permission.notifications.denied_message")
            }
            .confirmationDialog("habit.detail.alert.archive_title", isPresented: $isShowingArchiveConfirm) {
                Button("habit.detail.action.archive", role: .destructive) {
                    habit.isArchived = true
                    Task {
                        await persistAndSchedule()
                        WidgetStoreSync.updateSnapshot(
                            context: modelContext,
                            dayKey: DayKey.from(Date())
                        )
                        dismiss()
                    }
                }
                Button("action.cancel", role: .cancel) {}
            } message: {
                Text("habit.detail.alert.archive_message")
            }
        }
    }

    private var archiveBinding: Binding<Bool> {
        Binding(
            get: { habit.isArchived },
            set: { newValue in
                if newValue {
                    isShowingArchiveConfirm = true
                } else {
                    habit.isArchived = false
                    Task {
                        await persistAndSchedule()
                        WidgetStoreSync.updateSnapshot(
                            context: modelContext,
                            dayKey: DayKey.from(Date())
                        )
                    }
                }
            }
        )
    }

    private func handleReminderToggle(_ enabled: Bool) {
        guard enabled else {
            Task { await persistAndSchedule() }
            return
        }

        if authorizationStatus == .notDetermined {
            isShowingPermissionAlert = true
        } else if authorizationStatus == .denied {
            habit.reminderEnabled = false
            isShowingDeniedAlert = true
        } else {
            Task { await persistAndSchedule() }
        }
    }

    private func updateReminderTime() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        habit.reminderHour = components.hour ?? habit.reminderHour
        habit.reminderMinute = components.minute ?? habit.reminderMinute
        Task { await persistAndSchedule() }
    }

    private var historyEntries: [DayKeyEntry] {
        DayKeyRange.lastNDays(
            endingOn: dateProvider.now(),
            count: 90,
            calendar: dateProvider.calendar,
            timeZone: dateProvider.calendar.timeZone
        )
    }

    private var completedDayKeys: Set<Int> {
        Set(habit.completions.map { $0.dayKey })
    }

    @MainActor
    private func persistAndSchedule() async {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save habit reminder: \(error)")
        }
        await ReminderScheduler.update(for: habit)
    }
}

private struct HabitHistoryGridView: View {
    let entries: [DayKeyEntry]
    let completedDayKeys: Set<Int>

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(entries) { entry in
                let isCompleted = completedDayKeys.contains(entry.dayKey)
                RoundedRectangle(cornerRadius: 3)
                    .fill(isCompleted ? Color.green.opacity(0.8) : Color.secondary.opacity(0.2))
                    .frame(height: 14)
                    .accessibilityLabel(Text(accessibilityLabel(for: entry)))
                    .accessibilityValue(Text(isCompleted ? "calendar.accessibility.completed" : "calendar.accessibility.not_completed"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func accessibilityLabel(for entry: DayKeyEntry) -> String {
        entry.date.formatted(.dateTime.weekday(.abbreviated).month().day().year())
    }
}

import SwiftUI
import SwiftData
import UserNotifications

struct HabitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var habit: Habit

    @State private var reminderTime: Date
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isShowingPermissionAlert = false
    @State private var isShowingDeniedAlert = false
    @State private var isShowingArchiveConfirm = false

    init(habit: Habit) {
        self.habit = habit
        var components = DateComponents()
        components.hour = habit.reminderHour
        components.minute = habit.reminderMinute
        _reminderTime = State(initialValue: Calendar.current.date(from: components) ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder") {
                    Toggle("Daily Reminder", isOn: $habit.reminderEnabled)
                    if habit.reminderEnabled {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section("Status") {
                    Toggle("Archived", isOn: archiveBinding)
                }
            }
            .navigationTitle(habit.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
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
            .alert("Enable Notifications?", isPresented: $isShowingPermissionAlert) {
                Button("Not Now", role: .cancel) {
                    habit.reminderEnabled = false
                }
                Button("Allow") {
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
                Text("Allow notifications so we can send daily habit reminders.")
            }
            .alert("Notifications Disabled", isPresented: $isShowingDeniedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enable notifications in Settings to receive reminders.")
            }
            .confirmationDialog("Archive Habit?", isPresented: $isShowingArchiveConfirm) {
                Button("Archive", role: .destructive) {
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
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Archived habits are hidden from the dashboard.")
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

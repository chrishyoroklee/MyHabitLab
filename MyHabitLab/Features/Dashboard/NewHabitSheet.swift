import SwiftUI
import SwiftData
import UserNotifications

struct NewHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var iconName: String = HabitIconOptions.defaultName()
    @State private var colorName: String = HabitPalette.defaultName()
    @State private var note: String = ""
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isShowingPermissionAlert = false
    @State private var isShowingDeniedAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                    Picker("Icon", selection: $iconName) {
                        ForEach(HabitIconOptions.names, id: \.self) { icon in
                            Label(iconTitle(icon), systemImage: icon)
                                .tag(icon)
                        }
                    }
                }

                Section("Color") {
                    Picker("Color", selection: $colorName) {
                        ForEach(HabitPalette.options) { option in
                            HStack {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 12, height: 12)
                                Text(option.name)
                            }
                            .tag(option.name)
                        }
                    }
                }

                Section("Reminder") {
                    Toggle("Daily Reminder", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section("Note") {
                    TextField("Optional note", text: $note, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("New Habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveHabit()
                    }
                    .disabled(isSaveDisabled)
                }
            }
            .task {
                authorizationStatus = await ReminderScheduler.authorizationStatus()
            }
            .onChange(of: reminderEnabled) { _, newValue in
                guard newValue else { return }
                if authorizationStatus == .notDetermined {
                    isShowingPermissionAlert = true
                } else if authorizationStatus == .denied {
                    isShowingDeniedAlert = true
                    reminderEnabled = false
                }
            }
            .alert("Enable Notifications?", isPresented: $isShowingPermissionAlert) {
                Button("Not Now", role: .cancel) {
                    reminderEnabled = false
                }
                Button("Allow") {
                    Task {
                        let granted = await ReminderScheduler.requestAuthorization()
                        authorizationStatus = await ReminderScheduler.authorizationStatus()
                        if granted == false {
                            reminderEnabled = false
                            isShowingDeniedAlert = true
                        }
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
        }
    }

    private var isSaveDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveHabit() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let reminderHour = timeComponents.hour ?? 9
        let reminderMinute = timeComponents.minute ?? 0
        let habit = Habit(
            name: trimmedName,
            iconName: iconName,
            colorName: colorName,
            detail: trimmedNote.isEmpty ? nil : trimmedNote,
            reminderEnabled: reminderEnabled,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute
        )
        modelContext.insert(habit)
        do {
            try modelContext.save()
            WidgetStoreSync.updateSnapshot(
                context: modelContext,
                dayKey: DayKey.from(Date())
            )
            Task {
                await ReminderScheduler.update(for: habit)
            }
            dismiss()
        } catch {
            assertionFailure("Failed to save habit: \(error)")
        }
    }

    private func iconTitle(_ icon: String) -> String {
        switch icon {
        case "checkmark.circle": return "Check"
        case "drop": return "Water"
        case "book": return "Reading"
        case "flame": return "Workout"
        case "leaf": return "Wellness"
        case "heart": return "Health"
        case "figure.walk": return "Walk"
        case "bolt": return "Energy"
        case "music.note": return "Music"
        default: return "Habit"
        }
    }
}

#Preview("New Habit Sheet") {
    let container = ModelContainerFactory.makePreviewContainer()
    return NewHabitSheet()
        .modelContainer(container)
}

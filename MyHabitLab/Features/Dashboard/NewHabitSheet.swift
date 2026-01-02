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
                Section("habit.section.basics") {
                    TextField("habit.field.name", text: $name)
                        .textInputAutocapitalization(.words)
                        .accessibilityLabel(Text("habit.field.name"))
                    Picker("habit.field.icon", selection: $iconName) {
                        ForEach(HabitIconOptions.names, id: \.self) { icon in
                            Label(iconTitle(icon), systemImage: icon)
                                .tag(icon)
                        }
                    }
                }

                Section("habit.section.color") {
                    Picker("habit.section.color", selection: $colorName) {
                        ForEach(HabitPalette.options) { option in
                            HStack {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 12, height: 12)
                                Text(HabitPalette.displayNameKey(for: option.name))
                            }
                            .tag(option.name)
                        }
                    }
                }

                Section("habit.section.reminder") {
                    Toggle("habit.field.reminder_toggle", isOn: $reminderEnabled)
                        .accessibilityLabel(Text("habit.field.reminder_toggle"))
                    if reminderEnabled {
                        DatePicker("habit.field.reminder_time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .accessibilityLabel(Text("habit.field.reminder_time"))
                    }
                }

                Section("habit.section.note") {
                    TextField("habit.field.note_placeholder", text: $note, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .accessibilityLabel(Text("habit.field.note_placeholder"))
                }
            }
            .navigationTitle("habit.new.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("action.save") {
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
            .alert("permission.notifications.title", isPresented: $isShowingPermissionAlert) {
                Button("permission.notifications.not_now", role: .cancel) {
                    reminderEnabled = false
                }
                Button("permission.notifications.allow") {
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
                Text("permission.notifications.message")
            }
            .alert("permission.notifications.denied_title", isPresented: $isShowingDeniedAlert) {
                Button("action.ok", role: .cancel) {}
            } message: {
                Text("permission.notifications.denied_message")
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

    private func iconTitle(_ icon: String) -> LocalizedStringKey {
        switch icon {
        case "checkmark.circle": return "icon.check"
        case "drop": return "icon.water"
        case "book": return "icon.reading"
        case "flame": return "icon.workout"
        case "leaf": return "icon.wellness"
        case "heart": return "icon.health"
        case "figure.walk": return "icon.walk"
        case "bolt": return "icon.energy"
        case "music.note": return "icon.music"
        default: return "icon.habit"
        }
    }
}

#Preview("New Habit Sheet") {
    let container = ModelContainerFactory.makePreviewContainer()
    return NewHabitSheet()
        .modelContainer(container)
}

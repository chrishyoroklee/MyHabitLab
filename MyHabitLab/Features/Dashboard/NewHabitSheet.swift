import SwiftUI
import SwiftData

struct HabitFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var habitToEdit: Habit?

    @State private var name: String = ""
    @State private var iconName: String = "heart.fill"
    @State private var colorName: String = AppColors.allColorNames.first ?? "Electric Blue"
    @State private var note: String = ""

    @State private var trackingMode: HabitTrackingMode = .checkmark
    @State private var scheduleSelection: WeekdaySet = .all
    @State private var extraCompletionPolicy: ExtraCompletionPolicy = .totalsOnly

    @State private var unitDisplayName: String = "count"
    @State private var unitBaseName: String = "count"
    @State private var unitBaseScale: Int = 1
    @State private var unitDisplayPrecision: Int = 0
    @State private var unitGoalText: String = "1"
    @State private var unitIncrementText: String = "1"
    @State private var selectedUnitPresetId: String? = "count"

    @State private var reminderDrafts: [ReminderDraft] = []

    @State private var selectedIconCategory: IconCategory = .health

    init(habit: Habit? = nil) {
        self.habitToEdit = habit
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.color(for: colorName).opacity(0.1))
                                    .frame(width: 80, height: 80)

                                Image(systemName: iconName)
                                    .font(.system(size: 32))
                                    .foregroundStyle(AppColors.color(for: colorName))
                            }

                            TextField("Name your habit", text: $name)
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .submitLabel(.done)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Tracking") {
                    Picker("Tracking Mode", selection: $trackingMode) {
                        Text("Checkmark").tag(HabitTrackingMode.checkmark)
                        Text("Units").tag(HabitTrackingMode.unit)
                    }
                    .pickerStyle(.segmented)

                    Text(trackingMode == .checkmark
                         ? "Mark a day complete with a single tap."
                         : "Track progress toward a numeric goal.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                }
                .listRowBackground(AppColors.cardBackground)

                if trackingMode == .unit {
                    Section("Unit Goal") {
                        UnitPresetPicker(
                            presets: UnitPreset.presets,
                            selectedId: $selectedUnitPresetId,
                            onSelect: applyPreset
                        )

                        HStack {
                            TextField("Goal", text: $unitGoalText)
                                .keyboardType(.decimalPad)
                            TextField("Unit", text: $unitDisplayName)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }

                        Stepper(
                            value: incrementBinding,
                            in: 1...max(1, goalValue ?? 1),
                            step: incrementStep
                        ) {
                            Text("Default Increment: \(formattedIncrement)")
                        }

                        Text("Base unit: \(unitBaseName) • Stored as \(unitBaseScale)x base units")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .listRowBackground(AppColors.cardBackground)

                    if let validationMessage = unitValidationMessage {
                        Section {
                            Text(validationMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                        .listRowBackground(AppColors.cardBackground)
                    }
                }

                Section("Schedule") {
                    WeekdayPicker(selection: $scheduleSelection)
                    Text("Select the days this habit is due.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .listRowBackground(AppColors.cardBackground)

                Section("Extra completions") {
                    Picker("Extra completions", selection: $extraCompletionPolicy) {
                        Text("Count toward streaks").tag(ExtraCompletionPolicy.countTowardStreaks)
                        Text("Totals only").tag(ExtraCompletionPolicy.totalsOnly)
                    }
                    .pickerStyle(.segmented)

                    Text(extraCompletionPolicy == .countTowardStreaks
                         ? "Off-day completions count toward streaks and rates."
                         : "Off-day completions count only toward totals.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                }
                .listRowBackground(AppColors.cardBackground)

                Section("Reminders") {
                    if reminderDrafts.isEmpty {
                        Text("No reminders yet")
                            .foregroundStyle(.white.opacity(0.6))
                    } else {
                        ForEach($reminderDrafts) { $draft in
                            ReminderEditor(
                                reminder: $draft,
                                onDelete: { deleteReminder(id: draft.id) }
                            )
                        }
                    }

                    Button {
                        addReminder()
                    } label: {
                        Label("Add Reminder", systemImage: "plus")
                    }
                }
                .listRowBackground(AppColors.cardBackground)

                Section("Appearance") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(AppColors.allColorNames, id: \.self) { color in
                                Circle()
                                    .fill(AppColors.color(for: color))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.8), lineWidth: colorName == color ? 2 : 0)
                                    )
                                    .onTapGesture {
                                        withAnimation {
                                            colorName = color
                                        }
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    Picker("Category", selection: $selectedIconCategory) {
                        ForEach(IconCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.menu)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(selectedIconCategory.icons, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundStyle(iconName == icon ? AppColors.color(for: colorName) : Color.white.opacity(0.6))
                                    .padding(8)
                                    .background(iconName == icon ? AppColors.color(for: colorName).opacity(0.1) : Color.clear)
                                    .clipShape(Circle())
                                    .onTapGesture {
                                        iconName = icon
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listRowBackground(AppColors.cardBackground)

                Section("Notes") {
                    TextField("Motivation...", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
                .listRowBackground(AppColors.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .foregroundStyle(.white)
            .background(AppColors.primaryBackground)
            .navigationTitle(habitToEdit == nil ? "New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.bold)
                }
            }
            .onAppear {
                loadHabitIfNeeded()
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var goalValue: Double? {
        parseNumber(unitGoalText)
    }

    private var incrementValue: Double? {
        parseNumber(unitIncrementText)
    }

    private var incrementBinding: Binding<Double> {
        Binding(
            get: { incrementValue ?? 1 },
            set: { newValue in
                unitIncrementText = formattedNumber(newValue, precision: unitDisplayPrecision)
            }
        )
    }

    private var incrementStep: Double {
        pow(10.0, -Double(max(unitDisplayPrecision, 0)))
    }

    private var formattedIncrement: String {
        formattedNumber(incrementValue ?? 1, precision: unitDisplayPrecision)
    }

    private var unitValidationMessage: String? {
        guard trackingMode == .unit else { return nil }
        guard !unitDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "Enter a unit label."
        }
        guard let goal = goalValue, goal >= 1 else {
            return "Goal must be at least 1."
        }
        guard let increment = incrementValue, increment >= 1 else {
            return "Increment must be at least 1."
        }
        guard increment <= goal else {
            return "Increment must be less than or equal to the goal."
        }
        return nil
    }

    private var canSave: Bool {
        guard !trimmedName.isEmpty else { return false }
        guard scheduleSelection.rawValue != 0 else { return false }
        if trackingMode == .unit {
            return unitValidationMessage == nil
        }
        return true
    }

    private func loadHabitIfNeeded() {
        guard let habit = habitToEdit else {
            applyPreset(UnitPreset.presets.first { $0.id == "count" })
            return
        }
        name = habit.name
        iconName = habit.iconName
        colorName = habit.colorName
        note = habit.detail ?? ""
        trackingMode = habit.trackingMode
        scheduleSelection = WeekdaySet(rawValue: habit.scheduleMask)
        extraCompletionPolicy = habit.extraCompletionPolicy

        if trackingMode == .unit {
            unitDisplayName = habit.unitDisplayName ?? "count"
            unitBaseName = habit.unitBaseName ?? unitDisplayName
            unitBaseScale = max(1, habit.unitBaseScale)
            unitDisplayPrecision = max(0, habit.unitDisplayPrecision)
            let unit = HabitUnit(
                displayName: unitDisplayName,
                baseName: unitBaseName,
                baseScale: unitBaseScale,
                displayPrecision: unitDisplayPrecision
            )
            if let goalBase = habit.unitGoalBaseValue {
                let display = HabitProgress.displayValue(fromBase: goalBase, unit: unit)
                unitGoalText = formattedNumber(display, precision: unitDisplayPrecision)
            }
            if let incrementBase = habit.unitDefaultIncrementBaseValue {
                let display = HabitProgress.displayValue(fromBase: incrementBase, unit: unit)
                unitIncrementText = formattedNumber(display, precision: unitDisplayPrecision)
            }
            selectedUnitPresetId = UnitPreset.matchingPresetId(
                displayName: unitDisplayName,
                baseName: unitBaseName,
                baseScale: unitBaseScale,
                precision: unitDisplayPrecision
            )
        }

        reminderDrafts = habit.reminders.map { reminder in
            ReminderDraft.from(reminder: reminder, habitSchedule: scheduleSelection)
        }

        if reminderDrafts.isEmpty, habit.reminderEnabled {
            reminderDrafts = [ReminderDraft.fromLegacy(habit: habit, habitSchedule: scheduleSelection)]
        }
    }

    private func addReminder() {
        reminderDrafts.append(ReminderDraft.defaultReminder(habitSchedule: scheduleSelection))
    }

    private func deleteReminder(id: UUID) {
        reminderDrafts.removeAll { $0.id == id }
    }

    private func applyPreset(_ preset: UnitPreset?) {
        guard let preset else { return }
        selectedUnitPresetId = preset.id
        unitDisplayName = preset.displayName
        unitBaseName = preset.baseName
        unitBaseScale = preset.baseScale
        unitDisplayPrecision = preset.displayPrecision
        if trackingMode == .unit {
            unitGoalText = formattedNumber(preset.defaultGoal, precision: preset.displayPrecision)
            unitIncrementText = formattedNumber(preset.defaultIncrement, precision: preset.displayPrecision)
        }
    }

    private func save() {
        let trimmed = trimmedName
        guard !trimmed.isEmpty else { return }
        guard scheduleSelection.rawValue != 0 else { return }

        let scheduleMask = scheduleSelection.rawValue
        let targetPerWeek = scheduleSelection.count

        let reminderModels = reminderDrafts.map { $0.toModel() }
        let reminderEnabled = reminderModels.contains(where: { $0.isEnabled })
        let firstTimeReminder = reminderModels.first(where: { $0.type == .timeOfDay })

        var savedHabit: Habit?
        if let habit = habitToEdit {
            habit.name = trimmed
            habit.iconName = iconName
            habit.colorName = colorName
            habit.detail = note.isEmpty ? nil : note
            habit.trackingMode = trackingMode
            habit.scheduleMask = scheduleMask
            habit.extraCompletionPolicy = extraCompletionPolicy
            habit.targetPerWeek = targetPerWeek
            habit.reminderEnabled = reminderEnabled
            if let timeReminder = firstTimeReminder {
                habit.reminderHour = timeReminder.hour ?? habit.reminderHour
                habit.reminderMinute = timeReminder.minute ?? habit.reminderMinute
            }

            if trackingMode == .unit {
                applyUnitFields(to: habit)
            } else {
                clearUnitFields(on: habit)
            }

            var existingById = Dictionary(uniqueKeysWithValues: habit.reminders.map { ($0.id, $0) })
            for reminder in reminderModels {
                if let existing = existingById.removeValue(forKey: reminder.id) {
                    existing.typeRaw = reminder.typeRaw
                    existing.isEnabled = reminder.isEnabled
                    existing.hour = reminder.hour
                    existing.minute = reminder.minute
                    existing.intervalMinutes = reminder.intervalMinutes
                    existing.startMinute = reminder.startMinute
                    existing.endMinute = reminder.endMinute
                    existing.daysMask = reminder.daysMask
                } else {
                    reminder.habit = habit
                    modelContext.insert(reminder)
                }
            }
            existingById.values.forEach { modelContext.delete($0) }
            savedHabit = habit
        } else {
            let newHabit = Habit(
                name: trimmed,
                iconName: iconName,
                colorName: colorName,
                detail: note.isEmpty ? nil : note,
                trackingMode: trackingMode,
                scheduleMask: scheduleMask,
                extraCompletionPolicy: extraCompletionPolicy,
                unitDisplayName: nil,
                unitBaseName: nil,
                unitBaseScale: 1,
                unitDisplayPrecision: 0,
                unitGoalBaseValue: nil,
                unitDefaultIncrementBaseValue: nil,
                targetPerWeek: targetPerWeek,
                reminderEnabled: reminderEnabled,
                reminderHour: firstTimeReminder?.hour ?? 9,
                reminderMinute: firstTimeReminder?.minute ?? 0
            )
            if trackingMode == .unit {
                applyUnitFields(to: newHabit)
            }
            modelContext.insert(newHabit)
            reminderModels.forEach { reminder in
                reminder.habit = newHabit
                modelContext.insert(reminder)
            }
            savedHabit = newHabit
        }

        do {
            try modelContext.save()
            if let habit = savedHabit {
                Task { await ReminderScheduler.update(for: habit) }
            }
        } catch {
            assertionFailure("Failed to save habit: \(error)")
        }
        dismiss()
    }

    private func applyUnitFields(to habit: Habit) {
        let displayName = unitDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        habit.unitDisplayName = displayName.isEmpty ? nil : displayName
        habit.unitBaseName = unitBaseName
        habit.unitBaseScale = max(1, unitBaseScale)
        let precision = max(
            unitDisplayPrecision,
            decimalDigits(in: unitGoalText),
            decimalDigits(in: unitIncrementText)
        )
        habit.unitDisplayPrecision = max(0, precision)

        let unit = HabitUnit(
            displayName: habit.unitDisplayName ?? "count",
            baseName: habit.unitBaseName ?? habit.unitDisplayName ?? "count",
            baseScale: habit.unitBaseScale,
            displayPrecision: habit.unitDisplayPrecision
        )
        let goal = goalValue ?? 1
        let increment = incrementValue ?? 1
        habit.unitGoalBaseValue = HabitProgress.baseValue(fromDisplay: goal, unit: unit)
        habit.unitDefaultIncrementBaseValue = HabitProgress.baseValue(fromDisplay: increment, unit: unit)
    }

    private func clearUnitFields(on habit: Habit) {
        habit.unitDisplayName = nil
        habit.unitBaseName = nil
        habit.unitBaseScale = 1
        habit.unitDisplayPrecision = 0
        habit.unitGoalBaseValue = nil
        habit.unitDefaultIncrementBaseValue = nil
    }

    private func parseNumber(_ text: String) -> Double? {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        return formatter.number(from: text)?.doubleValue
    }

    private func formattedNumber(_ value: Double, precision: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = precision
        formatter.maximumFractionDigits = precision
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.*f", precision, value)
    }

    private func decimalDigits(in text: String) -> Int {
        let separators: [Character] = [".", ","]
        guard let index = text.lastIndex(where: { separators.contains($0) }) else { return 0 }
        let decimals = text[text.index(after: index)...]
        return decimals.count
    }
}

private struct UnitPreset: Identifiable, Hashable {
    let id: String
    let title: String
    let displayName: String
    let baseName: String
    let baseScale: Int
    let displayPrecision: Int
    let defaultGoal: Double
    let defaultIncrement: Double

    static let presets: [UnitPreset] = [
        UnitPreset(
            id: "count",
            title: "Count",
            displayName: "count",
            baseName: "count",
            baseScale: 1,
            displayPrecision: 0,
            defaultGoal: 1,
            defaultIncrement: 1
        ),
        UnitPreset(
            id: "minutes",
            title: "Minutes",
            displayName: "min",
            baseName: "min",
            baseScale: 1,
            displayPrecision: 0,
            defaultGoal: 30,
            defaultIncrement: 5
        ),
        UnitPreset(
            id: "hours",
            title: "Hours",
            displayName: "hours",
            baseName: "minutes",
            baseScale: 60,
            displayPrecision: 1,
            defaultGoal: 1,
            defaultIncrement: 1
        ),
        UnitPreset(
            id: "liters",
            title: "Liters",
            displayName: "L",
            baseName: "ml",
            baseScale: 1000,
            displayPrecision: 1,
            defaultGoal: 1,
            defaultIncrement: 1
        ),
        UnitPreset(
            id: "servings",
            title: "Servings",
            displayName: "servings",
            baseName: "half servings",
            baseScale: 2,
            displayPrecision: 1,
            defaultGoal: 1,
            defaultIncrement: 1
        )
    ]

    static func matchingPresetId(
        displayName: String,
        baseName: String,
        baseScale: Int,
        precision: Int
    ) -> String? {
        presets.first {
            $0.displayName == displayName &&
            $0.baseName == baseName &&
            $0.baseScale == baseScale &&
            $0.displayPrecision == precision
        }?.id
    }
}

private struct UnitPresetPicker: View {
    let presets: [UnitPreset]
    @Binding var selectedId: String?
    let onSelect: (UnitPreset?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(presets) { preset in
                    Button {
                        onSelect(preset)
                    } label: {
                        Text(preset.title)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedId == preset.id ? AppColors.cardBackground : Color.white.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct WeekdayPicker: View {
    @Binding var selection: WeekdaySet
    private let calendar = Calendar.current

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { index in
                let weekday = index + 1
                let symbol = calendar.shortWeekdaySymbols[index]
                let daySet = WeekdaySet.from(calendarWeekday: weekday)
                Button {
                    toggle(daySet)
                } label: {
                    Text(String(symbol.prefix(1)))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 32, height: 32)
                        .background(selection.contains(daySet) ? AppColors.cardBackground : Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggle(_ day: WeekdaySet) {
        if selection.contains(day) {
            let next = selection.subtracting(day)
            if next.rawValue != 0 {
                selection = next
            }
        } else {
            selection.insert(day)
        }
    }
}

private struct ReminderDraft: Identifiable, Hashable {
    var id: UUID
    var type: HabitReminderType
    var isEnabled: Bool
    var time: Date
    var intervalMinutes: Int
    var startTime: Date
    var endTime: Date
    var usesCustomDays: Bool
    var customDays: WeekdaySet

    static func defaultReminder(habitSchedule: WeekdaySet) -> ReminderDraft {
        let time = Date(timeIntervalSince1970: 0)
        return ReminderDraft(
            id: UUID(),
            type: .timeOfDay,
            isEnabled: true,
            time: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: time) ?? time,
            intervalMinutes: 60,
            startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: time) ?? time,
            endTime: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: time) ?? time,
            usesCustomDays: false,
            customDays: habitSchedule
        )
    }

    static func from(reminder: HabitReminder, habitSchedule: WeekdaySet) -> ReminderDraft {
        let baseline = Date(timeIntervalSince1970: 0)
        let time = Calendar.current.date(bySettingHour: reminder.hour ?? 9, minute: reminder.minute ?? 0, second: 0, of: baseline) ?? baseline
        let start = Calendar.current.date(bySettingHour: (reminder.startMinute ?? 540) / 60, minute: (reminder.startMinute ?? 540) % 60, second: 0, of: baseline) ?? baseline
        let end = Calendar.current.date(bySettingHour: (reminder.endMinute ?? 1020) / 60, minute: (reminder.endMinute ?? 1020) % 60, second: 0, of: baseline) ?? baseline
        let customDays = WeekdaySet(rawValue: reminder.daysMask ?? habitSchedule.rawValue)

        return ReminderDraft(
            id: reminder.id,
            type: reminder.type,
            isEnabled: reminder.isEnabled,
            time: time,
            intervalMinutes: reminder.intervalMinutes ?? 60,
            startTime: start,
            endTime: end,
            usesCustomDays: reminder.daysMask != nil,
            customDays: customDays
        )
    }

    static func fromLegacy(habit: Habit, habitSchedule: WeekdaySet) -> ReminderDraft {
        let baseline = Date(timeIntervalSince1970: 0)
        let time = Calendar.current.date(bySettingHour: habit.reminderHour, minute: habit.reminderMinute, second: 0, of: baseline) ?? baseline
        return ReminderDraft(
            id: UUID(),
            type: .timeOfDay,
            isEnabled: habit.reminderEnabled,
            time: time,
            intervalMinutes: 60,
            startTime: time,
            endTime: time,
            usesCustomDays: false,
            customDays: habitSchedule
        )
    }

    func toModel() -> HabitReminder {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        let startMinute = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        let endMinute = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)

        return HabitReminder(
            id: id,
            type: type,
            isEnabled: isEnabled,
            hour: type == .timeOfDay ? timeComponents.hour : nil,
            minute: type == .timeOfDay ? timeComponents.minute : nil,
            intervalMinutes: type == .interval ? intervalMinutes : nil,
            startMinute: type == .interval ? startMinute : nil,
            endMinute: type == .interval ? endMinute : nil,
            daysMask: usesCustomDays ? customDays.rawValue : nil
        )
    }
}

private struct ReminderEditor: View {
    @Binding var reminder: ReminderDraft
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Reminder")
                    .font(.headline)
                Spacer()
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
            }

            Toggle("Enabled", isOn: $reminder.isEnabled)

            Picker("Type", selection: $reminder.type) {
                Text("Time of day").tag(HabitReminderType.timeOfDay)
                Text("Interval").tag(HabitReminderType.interval)
            }
            .pickerStyle(.segmented)

            if reminder.type == .timeOfDay {
                DatePicker("Time", selection: $reminder.time, displayedComponents: .hourAndMinute)
            } else {
                Stepper(value: $reminder.intervalMinutes, in: 15...720, step: 5) {
                    Text("Every \(reminder.intervalMinutes) minutes")
                }
                DatePicker("Start", selection: $reminder.startTime, displayedComponents: .hourAndMinute)
                DatePicker("End", selection: $reminder.endTime, displayedComponents: .hourAndMinute)
                Text("Intervals repeat inside this daily window.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Toggle("Custom days", isOn: $reminder.usesCustomDays)
            if reminder.usesCustomDays {
                WeekdayPicker(selection: $reminder.customDays)
            } else {
                Text("Uses habit schedule")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.vertical, 8)
    }
}

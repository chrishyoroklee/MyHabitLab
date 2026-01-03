import SwiftUI
import SwiftData

struct HabitCalendarEditorView: View {
    let habit: Habit
    let dateProvider: DateProvider

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var editingDay: DayCell?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("calendar.last_90_days")
                        .font(.headline)
                        .foregroundStyle(.white)

                    LazyVGrid(columns: gridColumns, spacing: 8) {
                        ForEach(dayCells) { cell in
                            Button {
                                handleDayTap(cell)
                            } label: {
                                DayCellView(
                                    cell: cell,
                                    isCompleted: isCompleted(cell),
                                    color: AppColors.color(for: habit.colorName)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(accessibilityLabel(for: cell))
                            .accessibilityValue(Text(isCompleted(cell) ? "calendar.accessibility.completed" : "calendar.accessibility.not_completed"))
                        }
                    }
                }
                .padding()
            }
            .background(AppColors.primaryBackground)
            .navigationTitle(habit.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("calendar.done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $editingDay) { cell in
                UnitDayEditorSheet(
                    habit: habit,
                    day: cell,
                    existingBaseValue: completionValue(for: cell.dayKey),
                    onSave: { baseValue in
                        setCompletionValue(for: cell.dayKey, baseValue: baseValue)
                    },
                    onClear: {
                        clearCompletion(for: cell.dayKey)
                    }
                )
            }
        }
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    }

    private var dayCells: [DayCell] {
        let calendar = dateProvider.calendar
        let today = calendar.startOfDay(for: dateProvider.now())
        guard let start = calendar.date(byAdding: .day, value: -89, to: today) else {
            return []
        }

        return (0..<90).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else {
                return nil
            }
            let dayKey = DayKey.from(date, calendar: calendar, timeZone: calendar.timeZone)
            return DayCell(date: date, dayKey: dayKey)
        }
    }

    private var completionValuesByDayKey: [Int: Int] {
        HabitCompletionService.completionValueByDayKey(for: habit)
    }

    private func completionValue(for dayKey: Int) -> Int? {
        completionValuesByDayKey[dayKey]
    }

    private func isCompleted(_ cell: DayCell) -> Bool {
        HabitCompletionService.isComplete(
            habit: habit,
            completionValue: completionValuesByDayKey[cell.dayKey]
        )
    }

    private func handleDayTap(_ cell: DayCell) {
        if habit.trackingMode == .unit {
            editingDay = cell
        } else {
            toggleCompletion(for: cell)
        }
    }

    private func toggleCompletion(for cell: DayCell) {
        if let completion = habit.completions.first(where: { $0.dayKey == cell.dayKey }) {
            modelContext.delete(completion)
        } else {
            let completion = Completion(habit: habit, dayKey: cell.dayKey, value: 1)
            modelContext.insert(completion)
        }

        do {
            try modelContext.save()
            WidgetStoreSync.updateSnapshot(
                context: modelContext,
                dayKey: dateProvider.dayKey()
            )
        } catch {
            assertionFailure("Failed to toggle completion: \(error)")
        }
    }

    private func setCompletionValue(for dayKey: Int, baseValue: Int) {
        if baseValue <= 0 {
            clearCompletion(for: dayKey)
            return
        }

        let completions = habit.completions.filter { $0.dayKey == dayKey }
        if let completion = completions.first {
            completion.value = baseValue
            for extra in completions.dropFirst() {
                modelContext.delete(extra)
            }
        } else {
            let completion = Completion(habit: habit, dayKey: dayKey, value: baseValue)
            modelContext.insert(completion)
        }

        do {
            try modelContext.save()
            WidgetStoreSync.updateSnapshot(
                context: modelContext,
                dayKey: dateProvider.dayKey()
            )
        } catch {
            assertionFailure("Failed to update completion value: \(error)")
        }
    }

    private func clearCompletion(for dayKey: Int) {
        let completions = habit.completions.filter { $0.dayKey == dayKey }
        guard !completions.isEmpty else { return }
        completions.forEach { modelContext.delete($0) }

        do {
            try modelContext.save()
            WidgetStoreSync.updateSnapshot(
                context: modelContext,
                dayKey: dateProvider.dayKey()
            )
        } catch {
            assertionFailure("Failed to clear completion: \(error)")
        }
    }

    private func accessibilityLabel(for cell: DayCell) -> String {
        let formatted = cell.date.formatted(.dateTime.weekday(.abbreviated).month().day().year())
        return formatted
    }
}

private struct DayCell: Identifiable {
    let date: Date
    let dayKey: Int

    var id: Int { dayKey }
}

private struct DayCellView: View {
    let cell: DayCell
    let isCompleted: Bool
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(isCompleted ? color.opacity(0.8) : AppColors.cardBackground)
            Text(dayNumber)
                .font(.caption2)
                .minimumScaleFactor(0.6)
                .foregroundStyle(isCompleted ? .white : .white.opacity(0.7))
        }
        .frame(height: 32)
    }

    private var dayNumber: String {
        cell.date.formatted(.dateTime.day())
    }
}

private struct UnitDayEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let habit: Habit
    let day: DayCell
    let existingBaseValue: Int?
    let onSave: (Int) -> Void
    let onClear: () -> Void

    @State private var valueText: String

    init(
        habit: Habit,
        day: DayCell,
        existingBaseValue: Int?,
        onSave: @escaping (Int) -> Void,
        onClear: @escaping () -> Void
    ) {
        self.habit = habit
        self.day = day
        self.existingBaseValue = existingBaseValue
        self.onSave = onSave
        self.onClear = onClear

        let unit = habit.unitConfiguration ?? HabitUnit(
            displayName: habit.unitDisplayName ?? "count",
            baseName: habit.unitBaseName ?? habit.unitDisplayName ?? "count",
            baseScale: habit.unitBaseScale,
            displayPrecision: habit.unitDisplayPrecision
        )
        let goalBase = HabitCompletionService.goalBaseValue(for: habit)
        let initialBase = existingBaseValue ?? goalBase
        let initialDisplay = HabitProgress.displayValue(fromBase: initialBase, unit: unit)
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = unit.displayPrecision
        formatter.maximumFractionDigits = unit.displayPrecision
        let formatted = formatter.string(from: NSNumber(value: initialDisplay)) ?? "\(initialDisplay)"
        _valueText = State(initialValue: formatted)
    }

    var body: some View {
        let unit = habit.unitConfiguration ?? HabitUnit(
            displayName: habit.unitDisplayName ?? "count",
            baseName: habit.unitBaseName ?? habit.unitDisplayName ?? "count",
            baseScale: habit.unitBaseScale,
            displayPrecision: habit.unitDisplayPrecision
        )
        let goalBase = HabitCompletionService.goalBaseValue(for: habit)
        let incrementBase = HabitCompletionService.defaultIncrementBaseValue(for: habit)
        let goalDisplay = formatDisplay(HabitProgress.displayValue(fromBase: goalBase, unit: unit), precision: unit.displayPrecision)
        let incrementDisplay = formatDisplay(HabitProgress.displayValue(fromBase: incrementBase, unit: unit), precision: unit.displayPrecision)
        let dateLabel = day.date.formatted(.dateTime.weekday(.wide).month().day().year())

        NavigationStack {
            Form {
                Section {
                    Text(dateLabel)
                        .font(.headline)
                    Text(habit.name)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .listRowBackground(AppColors.cardBackground)

                Section("Value") {
                    TextField("Amount", text: $valueText)
                        .keyboardType(.decimalPad)
                }
                .listRowBackground(AppColors.cardBackground)

                Section("Quick Fill") {
                    Button("Use Goal (\(goalDisplay))") {
                        valueText = goalDisplay
                    }
                    Button("Use Increment (\(incrementDisplay))") {
                        valueText = incrementDisplay
                    }
                }
                .listRowBackground(AppColors.cardBackground)

                if existingBaseValue != nil {
                    Section {
                        Button("action.clear", role: .destructive) {
                            onClear()
                            dismiss()
                        }
                    }
                    .listRowBackground(AppColors.cardBackground)
                }
            }
            .foregroundStyle(.white)
            .scrollContentBackground(.hidden)
            .background(AppColors.primaryBackground)
            .navigationTitle("Edit Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("action.save") { saveValue(unit: unit) }
                        .disabled(parsedValue == nil)
                }
            }
        }
    }

    private var parsedValue: Double? {
        parseNumber(valueText)
    }

    private func saveValue(unit: HabitUnit) {
        guard let value = parsedValue else { return }
        if value <= 0 {
            onClear()
            dismiss()
            return
        }
        let base = HabitProgress.baseValue(fromDisplay: value, unit: unit)
        onSave(base)
        dismiss()
    }

    private func parseNumber(_ text: String) -> Double? {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        return formatter.number(from: text)?.doubleValue
    }

    private func formatDisplay(_ value: Double, precision: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = precision
        formatter.maximumFractionDigits = precision
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

#Preview("Calendar Editor") {
    let container = ModelContainerFactory.makePreviewContainer()
    let context = container.mainContext
    let habit = Habit(name: "Read", iconName: "book", colorName: "Indigo")
    context.insert(habit)
    let dayKey = DayKey.from(Date())
    context.insert(Completion(habit: habit, dayKey: dayKey, value: 1))
    return HabitCalendarEditorView(habit: habit, dateProvider: .live)
        .modelContainer(container)
}

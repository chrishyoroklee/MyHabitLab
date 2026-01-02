import SwiftUI
import SwiftData

struct NewHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var iconName: String = HabitIconOptions.defaultName()
    @State private var colorName: String = HabitPalette.defaultName()
    @State private var note: String = ""

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
        }
    }

    private var isSaveDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveHabit() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let habit = Habit(
            name: trimmedName,
            iconName: iconName,
            colorName: colorName,
            detail: trimmedNote.isEmpty ? nil : trimmedNote
        )
        modelContext.insert(habit)
        do {
            try modelContext.save()
            WidgetStoreSync.updateSnapshot(
                context: modelContext,
                dayKey: DayKey.from(Date())
            )
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

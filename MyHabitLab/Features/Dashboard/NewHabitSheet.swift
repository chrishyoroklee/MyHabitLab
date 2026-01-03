import SwiftUI
import SwiftData
import UserNotifications

struct HabitFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var habitToEdit: Habit?
    
    @State private var name: String = ""
    @State private var iconName: String = "heart.fill"
    @State private var colorName: String = AppColors.allColorNames.first!
    @State private var targetPerWeek: Int = 7
    @State private var note: String = ""
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Date()
    
    @State private var selectedIconCategory: IconCategory = .health
    
    // Init for editing
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
                            // Preview Icon
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
                
                Section("Frequency") {
                    Stepper("\(targetPerWeek) days / week", value: $targetPerWeek, in: 1...7)
                }
                
                Section("Appearance") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(AppColors.allColorNames, id: \.self) { color in
                                Circle()
                                    .fill(AppColors.color(for: color))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: colorName == color ? 2 : 0)
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
                                    .foregroundStyle(iconName == icon ? AppColors.color(for: colorName) : Color.secondary)
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
                
                Section("Reminders") {
                    Toggle("Enable Reminder", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
                
                Section("Notes") {
                    TextField("Motivation...", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(habitToEdit == nil ? "New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .fontWeight(.bold)
                }
            }
            .onAppear {
                if let habit = habitToEdit {
                    name = habit.name
                    iconName = habit.iconName
                    colorName = habit.colorName
                    targetPerWeek = habit.targetPerWeek
                    note = habit.detail ?? ""
                    reminderEnabled = habit.reminderEnabled
                    let components = DateComponents(hour: habit.reminderHour, minute: habit.reminderMinute)
                    reminderTime = Calendar.current.date(from: components) ?? Date()
                }
            }
        }
    }
    
    private func save() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        
        if let habit = habitToEdit {
            // Edit
            habit.name = name
            habit.iconName = iconName
            habit.colorName = colorName
            habit.targetPerWeek = targetPerWeek
            habit.detail = note.isEmpty ? nil : note
            habit.reminderEnabled = reminderEnabled
            habit.reminderHour = components.hour ?? 9
            habit.reminderMinute = components.minute ?? 0
        } else {
            // Create
            let habit = Habit(
                name: name,
                iconName: iconName,
                colorName: colorName,
                detail: note.isEmpty ? nil : note,
                targetPerWeek: targetPerWeek,
                reminderEnabled: reminderEnabled,
                reminderHour: components.hour ?? 9,
                reminderMinute: components.minute ?? 0
            )
            modelContext.insert(habit)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

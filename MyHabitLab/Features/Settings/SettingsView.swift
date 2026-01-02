import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportDocument: JSONFileDocument?
    @State private var isShowingAlert = false
    @State private var alertMessage = ""
    @Query(
        filter: #Predicate<Habit> { habit in
            habit.isArchived == true
        },
        sort: \Habit.createdAt
    )
    private var archivedHabits: [Habit]

    var body: some View {
        NavigationStack {
            List {
                Section("Data") {
                    Button("Export Data") {
                        Task {
                            await exportData()
                        }
                    }
                    Button("Import Data") {
                        isImporting = true
                    }
                }
                Section("Habits") {
                    if archivedHabits.isEmpty {
                        Text("No archived habits.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(archivedHabits) { habit in
                            HStack {
                                Text(habit.name)
                                Spacer()
                                Button("Restore") {
                                    restore(habit)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                Section("About") {
                    LabeledContent("Version", value: versionDescription)
                }
            }
            .navigationTitle("Settings")
            .fileExporter(
                isPresented: $isExporting,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "MyHabitLab-export"
            ) { result in
                if case .failure(let error) = result {
                    alertMessage = "Export failed: \(error.localizedDescription)"
                    isShowingAlert = true
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let url):
                    Task {
                        await importData(from: url)
                    }
                case .failure(let error):
                    alertMessage = "Import failed: \(error.localizedDescription)"
                    isShowingAlert = true
                }
            }
            .alert("Export / Import", isPresented: $isShowingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func exportData() async {
        do {
            let data = try await ExportImportService.exportData(context: modelContext)
            exportDocument = JSONFileDocument(data: data)
            isExporting = true
        } catch {
            alertMessage = "Export failed: \(error.localizedDescription)"
            isShowingAlert = true
        }
    }

    private func importData(from url: URL) async {
        do {
            let data = try await ExportImportService.readData(from: url)
            try await ExportImportService.importData(data, context: modelContext)
            WidgetStoreSync.updateSnapshot(
                context: modelContext,
                dayKey: DayKey.from(Date())
            )
            let habits = try modelContext.fetch(FetchDescriptor<Habit>())
            await ReminderScheduler.syncAll(habits: habits)
            alertMessage = "Import complete."
            isShowingAlert = true
        } catch {
            alertMessage = "Import failed: \(error.localizedDescription)"
            isShowingAlert = true
        }
    }

    private func restore(_ habit: Habit) {
        habit.isArchived = false
        do {
            try modelContext.save()
            WidgetStoreSync.updateSnapshot(
                context: modelContext,
                dayKey: DayKey.from(Date())
            )
            Task {
                await ReminderScheduler.update(for: habit)
            }
        } catch {
            alertMessage = "Failed to restore habit: \(error.localizedDescription)"
            isShowingAlert = true
        }
    }

    private var versionDescription: String {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Foundation

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
                Section("settings.section.data") {
                    Button("settings.action.export") {
                        Task {
                            await exportData()
                        }
                    }
                    Button("settings.action.import") {
                        isImporting = true
                    }
                }
                Section("settings.section.habits") {
                    if archivedHabits.isEmpty {
                        Text("settings.no_archived")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(archivedHabits) { habit in
                            HStack {
                                Text(habit.name)
                                    .lineLimit(2)
                                    .layoutPriority(1)
                                Spacer()
                                Button("settings.action.restore") {
                                    restore(habit)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                Section("settings.section.about") {
                    LabeledContent("settings.about.version", value: versionDescription)
                }
            }
            .scrollContentBackground(.hidden) // Remove system default light/gray background
            .background(AppColors.primaryBackground) // Force dark background

            .fileExporter(
                isPresented: $isExporting,
                document: exportDocument,
                contentType: .json,
                defaultFilename: String(localized: "settings.export.filename")
            ) { result in
                if case .failure(let error) = result {
                    alertMessage = String(format: String(localized: "error.export_failed"), error.localizedDescription)
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
                    alertMessage = String(format: String(localized: "error.import_failed"), error.localizedDescription)
                    isShowingAlert = true
                }
            }
            .alert("settings.alert.title", isPresented: $isShowingAlert) {
                Button("action.ok", role: .cancel) {}
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
            alertMessage = String(format: String(localized: "error.export_failed"), error.localizedDescription)
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
            alertMessage = String(localized: "settings.import.complete")
            isShowingAlert = true
        } catch {
            alertMessage = String(format: String(localized: "error.import_failed"), error.localizedDescription)
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
            alertMessage = String(format: String(localized: "error.restore_failed"), error.localizedDescription)
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

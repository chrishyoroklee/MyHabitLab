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
    @State private var isSyncEnabled = SyncManager.isSyncEnabled
    @State private var isSyncMigrating = false
    @State private var pendingSyncValue: Bool?
    @State private var isShowingSyncConfirm = false
    @State private var isShowingSyncAlert = false
    @State private var syncAlertTitle = ""
    @State private var syncAlertMessage = ""
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
                Section("Sync") {
                    Toggle("Sync with iCloud (Optional)", isOn: syncToggleBinding)
                        .disabled(isSyncMigrating)
                    Text("Keeps habits and history in sync across devices. Requires a restart after changes.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.6))
                    if isSyncMigrating {
                        ProgressView("Migrating data...")
                    }
                }
                .listRowBackground(AppColors.cardBackground)
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
                .listRowBackground(AppColors.cardBackground)
                Section("settings.section.habits") {
                    if archivedHabits.isEmpty {
                        Text("settings.no_archived")
                            .foregroundStyle(.white.opacity(0.6))
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
                .listRowBackground(AppColors.cardBackground)
                Section("settings.section.about") {
                    LabeledContent("settings.about.version", value: versionDescription)
                }
                .listRowBackground(AppColors.cardBackground)
            }
            .foregroundStyle(.white)
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
            .alert("Sync with iCloud?", isPresented: $isShowingSyncConfirm) {
                Button("Cancel", role: .cancel) {
                    pendingSyncValue = nil
                }
                Button("Continue") {
                    guard let pending = pendingSyncValue else { return }
                    Task {
                        await applySyncChange(to: pending)
                    }
                }
            } message: {
                Text("This will migrate your data and requires a restart to take effect.")
            }
            .alert(syncAlertTitle, isPresented: $isShowingSyncAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(syncAlertMessage)
            }
        }
    }

    private var syncToggleBinding: Binding<Bool> {
        Binding(
            get: { isSyncEnabled },
            set: { newValue in
                pendingSyncValue = newValue
                isShowingSyncConfirm = true
            }
        )
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

    @MainActor
    private func applySyncChange(to enabled: Bool) async {
        isSyncMigrating = true
        do {
            try await SyncManager.migrate(to: enabled, context: modelContext)
            isSyncEnabled = enabled
            syncAlertTitle = "Restart Required"
            syncAlertMessage = "Sync settings updated. Restart the app to apply the change."
        } catch {
            isSyncEnabled = SyncManager.isSyncEnabled
            syncAlertTitle = "Sync Failed"
            syncAlertMessage = "Unable to migrate data: \(error.localizedDescription)"
        }
        pendingSyncValue = nil
        isSyncMigrating = false
        isShowingSyncAlert = true
    }
}

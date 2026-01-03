import Foundation
import SwiftData

enum SyncManager {
    private static let syncEnabledKey = "sync.icloud.enabled"

    static var isSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: syncEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: syncEnabledKey) }
    }

    @MainActor
    static func migrate(to enabled: Bool, context: ModelContext) async throws {
        let data = try await ExportImportService.exportData(context: context)
        let targetContainer = enabled
            ? try ModelContainerFactory.makeCloudContainerUnsafe()
            : ModelContainerFactory.makeLocalContainer()
        let targetContext = targetContainer.mainContext
        try await ExportImportService.importData(data, context: targetContext)
        isSyncEnabled = enabled
    }
}

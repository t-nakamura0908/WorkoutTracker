import SwiftUI
import SwiftData
import UserNotifications

@main
struct WorkoutTrackerApp: App {
    let sharedModelContainer: ModelContainer = Self.makeContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([
            WorkoutSession.self,
            WorkoutExercise.self,
            ExerciseSet.self,
            DailyCondition.self,
            WorkoutTemplate.self,
            TemplateExercise.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        // 正常に生成できた場合はそのまま返す
        if let container = try? ModelContainer(for: schema, configurations: [config]) {
            return container
        }

        // スキーマ変更などで既存ストアと不一致の場合、ストアを削除して再生成
        // 注意: この処理は保存済みデータがすべて削除されます
        deleteExistingStore()

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer再生成失敗: \(error)")
        }
    }

    private static func deleteExistingStore() {
        guard let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first
        else { return }

        let storeFiles = [
            "default.store",
            "default.store-shm",
            "default.store-wal"
        ]
        for file in storeFiles {
            let url = appSupport.appending(path: file)
            try? FileManager.default.removeItem(at: url)
        }
    }
}

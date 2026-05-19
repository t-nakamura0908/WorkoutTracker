import SwiftUI
import SwiftData
import UserNotifications

@main
struct WorkoutTrackerApp: App {
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutSession.self,
            WorkoutExercise.self,
            ExerciseSet.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer生成失敗: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

import Foundation
import SwiftData
import Observation

@Observable
final class HomeViewModel {
    var todaySession: WorkoutSession?
    var todayCondition: DailyCondition?
    var recentSessions: [WorkoutSession] = []
    var currentStreak: Int = 0
    var isLoading = false
    var errorMessage: String?
    var showingWorkout = false

    private let container: ModelContainer
    /// フェッチしたオブジェクトが有効な間、コンテキストを保持する
    private var loadContext: ModelContext?

    init(container: ModelContainer) {
        self.container = container
    }

    @MainActor
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            // 古いオブジェクト参照を解放してから新しいコンテキストで取得
            todaySession = nil
            todayCondition = nil
            recentSessions = []

            // 毎回フレッシュなコンテキストを作成する。
            // これにより editContext が save() した内容を確実に反映できる
            // （主コンテキストのキャッシュに依存しない）。
            let ctx = ModelContext(container)
            loadContext = ctx
            let repo = WorkoutRepository(modelContext: ctx)

            todaySession = try repo.fetchSession(for: .now)
            todayCondition = try repo.fetchCondition(for: .now)
            let all = try repo.fetchSessions()
            recentSessions = Array(all.prefix(5))
            currentStreak = Self.calculateStreak(from: all)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func createTodaySession(context: ModelContext) async {
        showingWorkout = true
    }

    var weeklyCount: Int {
        let weekAgo = Date.now.adding(days: -7)
        return recentSessions.filter { $0.date >= weekAgo }.count
    }

    var totalVolume: Double {
        recentSessions.prefix(7).reduce(0) { $0 + $1.totalVolume }
    }

    private static func calculateStreak(from sessions: [WorkoutSession]) -> Int {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let dateSet = Set(sessions.map { fmt.string(from: $0.date) })

        var streak = 0
        var check = Date.now

        if !dateSet.contains(fmt.string(from: check)) {
            check = check.adding(days: -1)
        }
        while dateSet.contains(fmt.string(from: check)) {
            streak += 1
            check = check.adding(days: -1)
        }
        return streak
    }
}

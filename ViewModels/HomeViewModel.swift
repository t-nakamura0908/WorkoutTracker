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

    private let repository: WorkoutRepositoryProtocol

    init(repository: WorkoutRepositoryProtocol) {
        self.repository = repository
    }

    @MainActor
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            // context.rollback() 後は @Observable の変更通知が発行されないため、
            // 一度 nil / 空配列にしてから再代入することで SwiftUI にビューの再構築を強制する。
            // fetchSession/fetchSessions は同期関数なので nil → 再代入は同一 RunLoop tick で
            // コアレスされ、画面上のちらつきは発生しない。
            todaySession = nil
            recentSessions = []

            todaySession = try repository.fetchSession(for: .now)
            todayCondition = try repository.fetchCondition(for: .now)
            let all = try repository.fetchSessions()
            recentSessions = Array(all.prefix(5))
            currentStreak = Self.calculateStreak(from: all)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func createTodaySession(context: ModelContext) async {
        guard todaySession == nil else {
            showingWorkout = true
            return
        }
        // WorkoutView の「保存」ボタンで初めて永続化するため、ここでは insert のみ
        let session = WorkoutSession(date: .now)
        context.insert(session)
        todaySession = session
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

        // 今日に記録がなければ昨日から数える
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

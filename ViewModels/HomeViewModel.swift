import Foundation
import SwiftData
import Observation

@Observable
final class HomeViewModel {
    var todaySession: WorkoutSession?
    var recentSessions: [WorkoutSession] = []
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
            todaySession = try repository.fetchSession(for: .now)
            let all = try repository.fetchSessions()
            recentSessions = Array(all.prefix(5))
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
        let repo = WorkoutRepository(modelContext: context)
        let session = WorkoutSession(date: .now)
        do {
            try repo.save(session: session)
            todaySession = session
            showingWorkout = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var weeklyCount: Int {
        let weekAgo = Date.now.adding(days: -7)
        return recentSessions.filter { $0.date >= weekAgo }.count
    }

    var totalVolume: Double {
        recentSessions.prefix(7).reduce(0) { $0 + $1.totalVolume }
    }
}

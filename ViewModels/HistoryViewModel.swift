import Foundation
import SwiftData
import Observation

@Observable
final class HistoryViewModel {
    var sessions: [WorkoutSession] = []
    var filteredSessions: [WorkoutSession] = []
    var searchText = "" {
        didSet { applyFilter() }
    }
    var isLoading = false
    var errorMessage: String?
    var exerciseNames: [String] = []

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
            sessions = []
            filteredSessions = []

            let ctx = ModelContext(container)
            loadContext = ctx
            let repo = WorkoutRepository(modelContext: ctx)

            sessions = try repo.fetchSessions()
            exerciseNames = try repo.fetchAllExerciseNames()
            applyFilter()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func deleteSession(_ session: WorkoutSession) async {
        let sessionID = session.persistentModelID
        do {
            let ctx = ModelContext(container)
            if let toDelete = ctx.model(for: sessionID) as? WorkoutSession {
                try WorkoutRepository(modelContext: ctx).delete(session: toDelete)
            }
            sessions.removeAll { $0.persistentModelID == sessionID }
            applyFilter()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sessions(for date: Date) -> WorkoutSession? {
        sessions.first { $0.date.isSameDay(as: date) }
    }

    var groupedSessions: [(String, [WorkoutSession])] {
        let grouped = Dictionary(grouping: filteredSessions) { session in
            session.date.monthString
        }
        return grouped.sorted { $0.key > $1.key }
    }

    private func applyFilter() {
        if searchText.isEmpty {
            filteredSessions = sessions
        } else {
            filteredSessions = sessions.filter { session in
                session.exercises.contains { exercise in
                    exercise.name.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
    }
}

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
    var selectedSegment = 0
    var isLoading = false
    var errorMessage: String?
    var exerciseNames: [String] = []
    var selectedExerciseName: String?

    private let repository: WorkoutRepositoryProtocol

    init(repository: WorkoutRepositoryProtocol) {
        self.repository = repository
    }

    @MainActor
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            // rollback 後の @Observable 通知漏れ対策: 一度空にしてから再代入
            sessions = []
            filteredSessions = []

            sessions = try repository.fetchSessions()
            exerciseNames = try repository.fetchAllExerciseNames()
            applyFilter()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func deleteSession(_ session: WorkoutSession, context: ModelContext) async {
        let repo = WorkoutRepository(modelContext: context)
        do {
            try repo.delete(session: session)
            sessions.removeAll { $0.id == session.id }
            applyFilter()
        } catch {
            errorMessage = error.localizedDescription
        }
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

    func sessions(for date: Date) -> WorkoutSession? {
        sessions.first { $0.date.isSameDay(as: date) }
    }

    var groupedSessions: [(String, [WorkoutSession])] {
        let grouped = Dictionary(grouping: filteredSessions) { session in
            session.date.monthString
        }
        return grouped.sorted { $0.key > $1.key }
    }
}

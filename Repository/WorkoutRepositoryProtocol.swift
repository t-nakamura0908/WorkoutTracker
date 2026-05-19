import Foundation
import SwiftData

protocol WorkoutRepositoryProtocol {
    func fetchSessions() throws -> [WorkoutSession]
    func fetchSession(for date: Date) throws -> WorkoutSession?
    func fetchSessions(in month: Date) throws -> [WorkoutSession]
    func fetchExerciseHistory(name: String) throws -> [WorkoutExercise]
    func fetchAllExerciseNames() throws -> [String]
    func save(session: WorkoutSession) throws
    func delete(session: WorkoutSession) throws
    func delete(exercise: WorkoutExercise) throws
}

import Foundation
import SwiftData

protocol WorkoutRepositoryProtocol {
    // MARK: - WorkoutSession
    func fetchSessions() throws -> [WorkoutSession]
    func fetchSession(for date: Date) throws -> WorkoutSession?
    func fetchSessions(in month: Date) throws -> [WorkoutSession]
    func fetchExerciseHistory(name: String) throws -> [WorkoutExercise]
    func fetchAllExerciseNames() throws -> [String]
    func save(session: WorkoutSession) throws
    func delete(session: WorkoutSession) throws
    func delete(exercise: WorkoutExercise) throws

    // MARK: - DailyCondition
    func fetchCondition(for date: Date) throws -> DailyCondition?
    func fetchConditions() throws -> [DailyCondition]
    func save(condition: DailyCondition) throws

    // MARK: - WorkoutTemplate
    func fetchTemplates() throws -> [WorkoutTemplate]
    func save(template: WorkoutTemplate) throws
    func delete(template: WorkoutTemplate) throws
}

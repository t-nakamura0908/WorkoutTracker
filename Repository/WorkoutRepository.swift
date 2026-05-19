import Foundation
import SwiftData

final class WorkoutRepository: WorkoutRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - WorkoutSession

    func fetchSessions() throws -> [WorkoutSession] {
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchSession(for date: Date) throws -> WorkoutSession? {
        let start = date.startOfDay
        let end = date.endOfDay
        let predicate = #Predicate<WorkoutSession> { session in
            session.date >= start && session.date <= end
        }
        return try modelContext.fetch(FetchDescriptor<WorkoutSession>(predicate: predicate)).first
    }

    func fetchSessions(in month: Date) throws -> [WorkoutSession] {
        let start = month.startOfMonth
        let end = month.endOfMonth
        let predicate = #Predicate<WorkoutSession> { session in
            session.date >= start && session.date <= end
        }
        return try modelContext.fetch(FetchDescriptor<WorkoutSession>(predicate: predicate))
    }

    func fetchExerciseHistory(name: String) throws -> [WorkoutExercise] {
        let predicate = #Predicate<WorkoutExercise> { exercise in
            exercise.name == name
        }
        let descriptor = FetchDescriptor<WorkoutExercise>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.session?.date, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchAllExerciseNames() throws -> [String] {
        let exercises = try modelContext.fetch(FetchDescriptor<WorkoutExercise>())
        return Set(exercises.map(\.name)).sorted()
    }

    func save(session: WorkoutSession) throws {
        modelContext.insert(session)
        try modelContext.save()
    }

    func delete(session: WorkoutSession) throws {
        modelContext.delete(session)
        try modelContext.save()
    }

    func delete(exercise: WorkoutExercise) throws {
        modelContext.delete(exercise)
        try modelContext.save()
    }

    // MARK: - DailyCondition

    func fetchCondition(for date: Date) throws -> DailyCondition? {
        let start = date.startOfDay
        let end = date.endOfDay
        let predicate = #Predicate<DailyCondition> { c in
            c.date >= start && c.date <= end
        }
        return try modelContext.fetch(FetchDescriptor<DailyCondition>(predicate: predicate)).first
    }

    func fetchConditions() throws -> [DailyCondition] {
        let descriptor = FetchDescriptor<DailyCondition>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func save(condition: DailyCondition) throws {
        modelContext.insert(condition)
        try modelContext.save()
    }

    // MARK: - WorkoutTemplate

    func fetchTemplates() throws -> [WorkoutTemplate] {
        let descriptor = FetchDescriptor<WorkoutTemplate>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func save(template: WorkoutTemplate) throws {
        modelContext.insert(template)
        try modelContext.save()
    }

    func delete(template: WorkoutTemplate) throws {
        modelContext.delete(template)
        try modelContext.save()
    }
}

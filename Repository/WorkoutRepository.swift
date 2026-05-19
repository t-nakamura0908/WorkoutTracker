import Foundation
import SwiftData

final class WorkoutRepository: WorkoutRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

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
        let descriptor = FetchDescriptor<WorkoutSession>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    func fetchSessions(in month: Date) throws -> [WorkoutSession] {
        let start = month.startOfMonth
        let end = month.endOfMonth
        let predicate = #Predicate<WorkoutSession> { session in
            session.date >= start && session.date <= end
        }
        let descriptor = FetchDescriptor<WorkoutSession>(predicate: predicate)
        return try modelContext.fetch(descriptor)
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
        let descriptor = FetchDescriptor<WorkoutExercise>()
        let exercises = try modelContext.fetch(descriptor)
        let names = Set(exercises.map(\.name))
        return names.sorted()
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
}

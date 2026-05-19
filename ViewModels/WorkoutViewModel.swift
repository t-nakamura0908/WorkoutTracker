import Foundation
import SwiftData
import Observation

@Observable
final class WorkoutViewModel {
    var session: WorkoutSession
    var showingAddExercise = false
    var errorMessage: String?
    var isSaving = false

    private let repository: WorkoutRepositoryProtocol

    init(session: WorkoutSession, repository: WorkoutRepositoryProtocol) {
        self.session = session
        self.repository = repository
    }

    func addExercise(name: String, context: ModelContext) {
        let order = session.exercises.count
        let exercise = WorkoutExercise(name: name, order: order)
        exercise.session = session
        session.exercises.append(exercise)
        context.insert(exercise)
        saveContext(context)
    }

    func deleteExercise(_ exercise: WorkoutExercise, context: ModelContext) {
        session.exercises.removeAll { $0.id == exercise.id }
        context.delete(exercise)
        saveContext(context)
        reorderExercises(context: context)
    }

    func addSet(to exercise: WorkoutExercise, context: ModelContext) {
        let setNumber = exercise.sets.count + 1
        let lastSet = exercise.sortedSets.last
        let newSet = ExerciseSet(
            setNumber: setNumber,
            weight: lastSet?.weight ?? 0,
            reps: lastSet?.reps ?? 10
        )
        newSet.exercise = exercise
        exercise.sets.append(newSet)
        context.insert(newSet)
        saveContext(context)
    }

    func deleteSet(_ set: ExerciseSet, from exercise: WorkoutExercise, context: ModelContext) {
        exercise.sets.removeAll { $0.id == set.id }
        context.delete(set)
        saveContext(context)
        renumberSets(in: exercise)
        saveContext(context)
    }

    func updateNotes(_ notes: String, context: ModelContext) {
        session.notes = notes
        saveContext(context)
    }

    private func renumberSets(in exercise: WorkoutExercise) {
        exercise.sortedSets.enumerated().forEach { index, set in
            set.setNumber = index + 1
        }
    }

    private func reorderExercises(context: ModelContext) {
        session.sortedExercises.enumerated().forEach { index, exercise in
            exercise.order = index
        }
    }

    private func saveContext(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

import Foundation
import SwiftData
import Observation

@Observable
final class WorkoutViewModel {
    var session: WorkoutSession
    var showingAddExercise = false
    var errorMessage: String?
    var isSaving = false

    // インターバルタイマー
    var intervalRemainingSeconds: Int = 0
    var intervalTotalSeconds: Int = 0
    var isIntervalRunning = false
    var intervalFinished = false

    private let repository: WorkoutRepositoryProtocol
    private var intervalTimer: Timer?

    init(session: WorkoutSession, repository: WorkoutRepositoryProtocol) {
        self.session = session
        self.repository = repository
    }

    // MARK: - Exercise / Set 操作

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

    // MARK: - セット完了 + インターバル開始

    func completeSet(_ set: ExerciseSet, exercise: WorkoutExercise, context: ModelContext) {
        set.isCompleted = true
        saveContext(context)
        startInterval(seconds: exercise.defaultIntervalSeconds)
    }

    func uncompleteSet(_ set: ExerciseSet, context: ModelContext) {
        set.isCompleted = false
        saveContext(context)
    }

    // MARK: - インターバルタイマー

    func startInterval(seconds: Int) {
        stopInterval()
        intervalTotalSeconds = seconds
        intervalRemainingSeconds = seconds
        isIntervalRunning = true
        intervalFinished = false

        NotificationManager.shared.scheduleTimerNotification(after: Double(seconds))

        intervalTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tickInterval()
        }
        RunLoop.main.add(intervalTimer!, forMode: .common)
    }

    func stopInterval() {
        intervalTimer?.invalidate()
        intervalTimer = nil
        isIntervalRunning = false
        NotificationManager.shared.cancelTimerNotification()
    }

    var intervalProgress: Double {
        guard intervalTotalSeconds > 0 else { return 0 }
        return Double(intervalRemainingSeconds) / Double(intervalTotalSeconds)
    }

    var intervalDisplayTime: String {
        let m = intervalRemainingSeconds / 60
        let s = intervalRemainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func tickInterval() {
        guard intervalRemainingSeconds > 0 else {
            stopInterval()
            intervalFinished = true
            return
        }
        intervalRemainingSeconds -= 1
    }

    // MARK: - Private helpers

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

    deinit {
        stopInterval()
    }
}

import Foundation
import SwiftData
import Observation

@Observable
final class WorkoutViewModel {
    var session: WorkoutSession
    var showingAddExercise = false
    var errorMessage: String?
    var isSaving = false
    /// 開いてから一度でも変更があった場合 true。キャンセル確認の表示判定に使用。
    var isDirty = false

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
        isDirty = true
        let order = session.exercises.count
        let exercise = WorkoutExercise(name: name, order: order)
        exercise.session = session
        session.exercises.append(exercise)
        context.insert(exercise)
        saveContext(context)
    }

    func deleteExercise(_ exercise: WorkoutExercise, context: ModelContext) {
        isDirty = true
        session.exercises.removeAll { $0.id == exercise.id }
        context.delete(exercise)
        saveContext(context)
        reorderExercises(context: context)
    }

    func addSet(to exercise: WorkoutExercise, context: ModelContext) {
        isDirty = true
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
        isDirty = true
        exercise.sets.removeAll { $0.id == set.id }
        context.delete(set)
        saveContext(context)
        renumberSets(in: exercise)
        saveContext(context)
    }

    func updateNotes(_ notes: String, context: ModelContext) {
        isDirty = true
        session.notes = notes
        saveContext(context)
    }

    // MARK: - テンプレート適用

    func applyTemplate(_ template: WorkoutTemplate, context: ModelContext) {
        isDirty = true
        for templateExercise in template.sortedExercises {
            let exercise = WorkoutExercise(
                name: templateExercise.name,
                order: session.exercises.count,
                defaultIntervalSeconds: templateExercise.defaultIntervalSeconds
            )
            exercise.session = session
            session.exercises.append(exercise)
            context.insert(exercise)

            for i in 1...max(1, templateExercise.defaultSets) {
                let set = ExerciseSet(
                    setNumber: i,
                    weight: templateExercise.defaultWeight,
                    reps: templateExercise.defaultReps
                )
                set.exercise = exercise
                exercise.sets.append(set)
                context.insert(set)
            }
        }
        saveContext(context)
    }

    // MARK: - セット完了 + インターバル開始

    func completeSet(_ set: ExerciseSet, exercise: WorkoutExercise, context: ModelContext) {
        isDirty = true
        set.isCompleted = true
        saveContext(context)
        startInterval(seconds: exercise.defaultIntervalSeconds)
    }

    func uncompleteSet(_ set: ExerciseSet, context: ModelContext) {
        isDirty = true
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

    // MARK: - 明示的な保存 / キャンセル

    func save(context: ModelContext) {
        do {
            try context.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancel(context: ModelContext) {
        context.rollback()
    }

    // MARK: - Private helpers

    /// 変更をメモリに蓄積するだけで保存しない（保存は save(context:) で明示的に行う）
    private func saveContext(_ context: ModelContext) {
        // no-op: auto-save を行わない
    }

    deinit {
        stopInterval()
    }
}

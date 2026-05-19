import Foundation
import SwiftData

@Model
final class ExerciseSet {
    var id: UUID
    var setNumber: Int
    var weight: Double
    var reps: Int
    var isCompleted: Bool

    var exercise: WorkoutExercise?

    init(setNumber: Int, weight: Double = 0, reps: Int = 0) {
        self.id = UUID()
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.isCompleted = false
    }

    var volume: Double {
        weight * Double(reps)
    }
}

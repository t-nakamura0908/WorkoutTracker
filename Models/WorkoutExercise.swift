import Foundation
import SwiftData

@Model
final class WorkoutExercise {
    var id: UUID
    var name: String
    var order: Int
    var memo: String

    var session: WorkoutSession?

    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.exercise)
    var sets: [ExerciseSet]

    init(name: String, order: Int = 0, memo: String = "") {
        self.id = UUID()
        self.name = name
        self.order = order
        self.memo = memo
        self.sets = []
    }

    var sortedSets: [ExerciseSet] {
        sets.sorted { $0.setNumber < $1.setNumber }
    }

    var totalVolume: Double {
        sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }

    var maxWeight: Double {
        sets.map(\.weight).max() ?? 0
    }

    var totalReps: Int {
        sets.reduce(0) { $0 + $1.reps }
    }
}

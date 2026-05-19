import Foundation
import SwiftData

@Model
final class TemplateExercise {
    var id: UUID
    var name: String
    var order: Int
    var defaultSets: Int
    var defaultWeight: Double
    var defaultReps: Int
    var defaultIntervalSeconds: Int

    var template: WorkoutTemplate?

    init(
        name: String,
        order: Int = 0,
        defaultSets: Int = 3,
        defaultWeight: Double = 0,
        defaultReps: Int = 10,
        defaultIntervalSeconds: Int = 90
    ) {
        self.id = UUID()
        self.name = name
        self.order = order
        self.defaultSets = defaultSets
        self.defaultWeight = defaultWeight
        self.defaultReps = defaultReps
        self.defaultIntervalSeconds = defaultIntervalSeconds
    }
}

import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var exercises: [TemplateExercise]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = .now
        self.exercises = []
    }

    var sortedExercises: [TemplateExercise] {
        exercises.sorted { $0.order < $1.order }
    }

    var summaryText: String {
        sortedExercises.prefix(3).map(\.name).joined(separator: "・")
    }
}

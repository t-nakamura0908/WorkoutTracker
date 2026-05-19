import Foundation
import SwiftUI
import SwiftData
import Observation

@Observable
final class TemplateViewModel {
    var templates: [WorkoutTemplate] = []
    var isLoading = false
    var errorMessage: String?

    private let repository: WorkoutRepositoryProtocol

    init(repository: WorkoutRepositoryProtocol) {
        self.repository = repository
    }

    @MainActor
    func loadTemplates() async {
        isLoading = true
        defer { isLoading = false }
        do {
            templates = try repository.fetchTemplates()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func deleteTemplate(_ template: WorkoutTemplate, context: ModelContext) {
        let repo = WorkoutRepository(modelContext: context)
        do {
            try repo.delete(template: template)
            templates.removeAll { $0.id == template.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - TemplateEditorViewModel

@Observable
final class TemplateEditorViewModel {
    var name: String
    var exercises: [TemplateExercise]
    var errorMessage: String?

    private let template: WorkoutTemplate?

    init(template: WorkoutTemplate? = nil) {
        self.template = template
        self.name = template?.name ?? ""
        self.exercises = template?.sortedExercises ?? []
    }

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    func addExercise(name: String) {
        let ex = TemplateExercise(name: name, order: exercises.count)
        exercises.append(ex)
    }

    func deleteExercise(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
        reorder()
    }

    func moveExercise(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
        reorder()
    }

    @MainActor
    func save(context: ModelContext) {
        let repo = WorkoutRepository(modelContext: context)
        let target = template ?? WorkoutTemplate(name: name)
        target.name = name

        // 既存エクササイズを削除して再登録
        for ex in target.exercises {
            context.delete(ex)
        }
        target.exercises = []

        for (index, ex) in exercises.enumerated() {
            ex.order = index
            ex.template = target
            target.exercises.append(ex)
            context.insert(ex)
        }

        do {
            try repo.save(template: target)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func reorder() {
        exercises.enumerated().forEach { index, ex in ex.order = index }
    }
}

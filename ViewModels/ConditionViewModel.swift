import Foundation
import SwiftData
import Observation

@Observable
final class ConditionViewModel {
    var condition: DailyCondition
    var isLoading = false
    var isSaved = false
    var errorMessage: String?

    private let repository: WorkoutRepositoryProtocol
    private let isNew: Bool

    init(condition: DailyCondition, repository: WorkoutRepositoryProtocol, isNew: Bool) {
        self.condition = condition
        self.repository = repository
        self.isNew = isNew
    }

    @MainActor
    func save(context: ModelContext) async {
        let repo = WorkoutRepository(modelContext: context)
        do {
            try repo.save(condition: condition)
            isSaved = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var conditionLabel: String { scoreLabel(condition.conditionScore) }
    var sleepLabel: String     { scoreLabel(condition.sleepScore) }
    var fatigueLabel: String   { scoreLabel(condition.fatigueScore) }

    private func scoreLabel(_ score: Int) -> String {
        switch score {
        case 1: return "とても悪い"
        case 2: return "悪い"
        case 3: return "普通"
        case 4: return "良い"
        default: return "とても良い"
        }
    }
}

// MARK: - HomeViewModel への追加

extension HomeViewModel {
    @MainActor
    func loadCondition(context: ModelContext) async {
        let repo = WorkoutRepository(modelContext: context)
        todayCondition = try? repo.fetchCondition(for: .now)
    }
}

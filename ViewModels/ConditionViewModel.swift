import Foundation
import SwiftData
import Observation

@Observable
final class ConditionViewModel {
    var condition: DailyCondition
    var isDirty = false
    var errorMessage: String?

    init(condition: DailyCondition) {
        self.condition = condition
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

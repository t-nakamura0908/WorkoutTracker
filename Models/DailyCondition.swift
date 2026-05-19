import Foundation
import SwiftData

@Model
final class DailyCondition {
    var id: UUID
    var date: Date
    /// 体調 1-5
    var conditionScore: Int
    /// 睡眠の質 1-5
    var sleepScore: Int
    /// 疲労度 1（疲労大）〜5（疲労なし）
    var fatigueScore: Int
    /// 体重 kg（0 = 未入力）
    var bodyWeight: Double
    /// 体脂肪率 %（0 = 未入力）
    var bodyFatPercentage: Double
    /// タンパク質摂取量 g（0 = 未入力）
    var proteinIntake: Double
    var notes: String

    init(
        date: Date = .now,
        conditionScore: Int = 3,
        sleepScore: Int = 3,
        fatigueScore: Int = 3,
        bodyWeight: Double = 0,
        bodyFatPercentage: Double = 0,
        proteinIntake: Double = 0,
        notes: String = ""
    ) {
        self.id = UUID()
        self.date = date
        self.conditionScore = conditionScore
        self.sleepScore = sleepScore
        self.fatigueScore = fatigueScore
        self.bodyWeight = bodyWeight
        self.bodyFatPercentage = bodyFatPercentage
        self.proteinIntake = proteinIntake
        self.notes = notes
    }

    var hasBodyData: Bool {
        bodyWeight > 0 || bodyFatPercentage > 0
    }
}

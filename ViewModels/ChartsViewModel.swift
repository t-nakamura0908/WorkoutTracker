import Foundation
import SwiftUI
import SwiftData
import Observation

// MARK: - Supporting Types

enum ChartPeriod: String, CaseIterable, Identifiable {
    case oneMonth  = "1ヶ月"
    case threeMonths = "3ヶ月"
    case sixMonths = "6ヶ月"
    case oneYear   = "1年"
    case all       = "全期間"

    var id: String { rawValue }

    var startDate: Date {
        switch self {
        case .oneMonth:     return Date.now.adding(days: -30)
        case .threeMonths:  return Date.now.adding(days: -90)
        case .sixMonths:    return Date.now.adding(days: -180)
        case .oneYear:      return Date.now.adding(days: -365)
        case .all:          return .distantPast
        }
    }
}

enum ChartTab: String, CaseIterable, Identifiable {
    case weight  = "重量"
    case oneRM   = "1RM推定"
    case reps    = "回数"
    case monthly = "月別"
    case body    = "体重"
    case muscle  = "筋群"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .weight:  return "scalemass.fill"
        case .oneRM:   return "trophy.fill"
        case .reps:    return "repeat"
        case .monthly: return "calendar"
        case .body:    return "figure.stand"
        case .muscle:  return "figure.strengthtraining.traditional"
        }
    }

    var requiresExercisePicker: Bool {
        self == .weight || self == .oneRM || self == .reps
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
    var isPR: Bool = false
}

struct MuscleGroupVolume: Identifiable {
    let id = UUID()
    let name: String
    let volume: Double
    let color: Color
}


// MARK: - ChartsViewModel

@Observable
final class ChartsViewModel {
    // ナビゲーション
    var selectedTab: ChartTab = .weight
    var selectedPeriod: ChartPeriod = .threeMonths {
        didSet { Task { await loadAllData() } }
    }
    var selectedExerciseName: String = "" {
        didSet {
            guard oldValue != selectedExerciseName else { return }
            Task { await loadExerciseData(name: selectedExerciseName) }
        }
    }
    var exerciseNames: [String] = []

    // チャートデータ
    var weightData: [ChartDataPoint] = []
    var oneRMData:  [ChartDataPoint] = []
    var repsData:   [ChartDataPoint] = []
    var monthlyCountData: [ChartDataPoint] = []
    var bodyWeightData: [ChartDataPoint] = []
    var bodyFatData:    [ChartDataPoint] = []
    var muscleGroupData: [MuscleGroupVolume] = []


    var isLoading    = false
    var errorMessage: String?

    private let repository: WorkoutRepositoryProtocol

    // 筋群マッピング
    private static let muscleGroupMap: [String: String] = [
        "ベンチプレス": "胸", "インクラインベンチプレス": "胸", "チェストフライ": "胸", "ダンベルフライ": "胸",
        "スクワット": "脚", "レッグプレス": "脚", "ルーマニアンデッドリフト": "脚",
        "ワイドスクワット": "脚", "レッグカール": "脚", "レッグエクステンション": "脚",
        "デッドリフト": "背中", "ラットプルダウン": "背中", "ベントオーバーロウ": "背中",
        "プルアップ": "背中", "シーテッドロウ": "背中",
        "ショルダープレス": "肩", "サイドレイズ": "肩", "フェイスプル": "肩", "フロントレイズ": "肩",
        "ダンベルカール": "腕", "トライセプスプッシュダウン": "腕", "ディップス": "腕", "ハンマーカール": "腕",
        "プランク": "体幹", "クランチ": "体幹", "レッグレイズ": "体幹", "ロシアンツイスト": "体幹"
    ]

    static let muscleGroupColors: [String: Color] = [
        "胸": .blue, "背中": .green, "脚": .orange,
        "肩": .purple, "腕": .pink, "体幹": .yellow, "その他": .gray
    ]

    init(repository: WorkoutRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - ロード

    @MainActor
    func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            exerciseNames = try repository.fetchAllExerciseNames()
            if selectedExerciseName.isEmpty, let first = exerciseNames.first {
                selectedExerciseName = first
            }
            await loadAllData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadAllData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadExerciseData(name: self.selectedExerciseName) }
            group.addTask { await self.loadMonthlyData() }
            group.addTask { await self.loadBodyData() }
            group.addTask { await self.loadMuscleGroupData() }
        }
    }

    // MARK: 種目データ（重量 / 1RM / 回数）

    @MainActor
    func loadExerciseData(name: String) async {
        guard !name.isEmpty else { return }
        do {
            let history = try repository.fetchExerciseHistory(name: name)
            let filtered = history.filter { ($0.session?.date ?? .distantPast) >= selectedPeriod.startDate }

            var maxWeight: Double = 0
            var maxOneRM:  Double = 0

            weightData = filtered.compactMap { exercise -> ChartDataPoint? in
                guard let date = exercise.session?.date else { return nil }
                let w = exercise.sets.map(\.weight).max() ?? 0
                let isPR = w > maxWeight
                if isPR { maxWeight = w }
                return ChartDataPoint(date: date, value: w, label: name, isPR: isPR)
            }

            oneRMData = filtered.compactMap { exercise -> ChartDataPoint? in
                guard let date = exercise.session?.date else { return nil }
                let orm = exercise.sets.map { estimateOneRM(weight: $0.weight, reps: $0.reps) }.max() ?? 0
                let isPR = orm > maxOneRM
                if isPR { maxOneRM = orm }
                return ChartDataPoint(date: date, value: orm, label: name, isPR: isPR)
            }

            repsData = filtered.compactMap { exercise -> ChartDataPoint? in
                guard let date = exercise.session?.date else { return nil }
                return ChartDataPoint(date: date, value: Double(exercise.totalReps), label: name)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: 月別回数

    @MainActor
    private func loadMonthlyData() async {
        do {
            let sessions = try repository.fetchSessions()
            let filtered = sessions.filter { $0.date >= selectedPeriod.startDate }
            let grouped = Dictionary(grouping: filtered) { $0.date.startOfMonth }
            monthlyCountData = grouped.map { date, s in
                ChartDataPoint(date: date, value: Double(s.count), label: "")
            }.sorted { $0.date < $1.date }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: 体重・体脂肪

    @MainActor
    private func loadBodyData() async {
        do {
            let conditions = try repository.fetchConditions()
            let filtered = conditions.filter { $0.date >= selectedPeriod.startDate }
            bodyWeightData = filtered
                .filter { $0.bodyWeight > 0 }
                .map { ChartDataPoint(date: $0.date, value: $0.bodyWeight, label: "体重") }
                .sorted { $0.date < $1.date }
            bodyFatData = filtered
                .filter { $0.bodyFatPercentage > 0 }
                .map { ChartDataPoint(date: $0.date, value: $0.bodyFatPercentage, label: "体脂肪率") }
                .sorted { $0.date < $1.date }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: 筋群別ボリューム

    @MainActor
    private func loadMuscleGroupData() async {
        do {
            let sessions = try repository.fetchSessions()
            let filtered = sessions.filter { $0.date >= selectedPeriod.startDate }
            var volumes: [String: Double] = [:]
            for session in filtered {
                for exercise in session.exercises {
                    let group = Self.muscleGroupMap[exercise.name] ?? "その他"
                    volumes[group, default: 0] += exercise.totalVolume
                }
            }
            muscleGroupData = volumes.map { name, vol in
                MuscleGroupVolume(name: name, volume: vol, color: Self.muscleGroupColors[name] ?? .gray)
            }.sorted { $0.volume > $1.volume }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - ヘルパー

    /// エプリー式: weight × (1 + reps / 30)
    private func estimateOneRM(weight: Double, reps: Int) -> Double {
        guard weight > 0, reps > 0 else { return 0 }
        guard reps > 1 else { return weight }
        let raw = weight * (1.0 + Double(reps) / 30.0)
        return (raw * 10).rounded() / 10
    }

    var totalMuscleVolume: Double {
        muscleGroupData.reduce(0) { $0 + $1.volume }
    }
}

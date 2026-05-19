import Foundation
import Observation

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
}

@Observable
final class ChartsViewModel {
    var exerciseNames: [String] = []
    var selectedExerciseName: String = ""
    var weightData: [ChartDataPoint] = []
    var repsData: [ChartDataPoint] = []
    var monthlyCountData: [ChartDataPoint] = []
    var isLoading = false
    var errorMessage: String?
    var selectedChartTab = 0

    private let repository: WorkoutRepositoryProtocol

    init(repository: WorkoutRepositoryProtocol) {
        self.repository = repository
    }

    @MainActor
    func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            exerciseNames = try repository.fetchAllExerciseNames()
            if let first = exerciseNames.first {
                selectedExerciseName = first
                await loadExerciseData(name: first)
            }
            await loadMonthlyData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadExerciseData(name: String) async {
        do {
            let history = try repository.fetchExerciseHistory(name: name)
            weightData = history.compactMap { exercise -> ChartDataPoint? in
                guard let date = exercise.session?.date else { return nil }
                return ChartDataPoint(date: date, value: exercise.maxWeight, label: exercise.name)
            }
            repsData = history.compactMap { exercise -> ChartDataPoint? in
                guard let date = exercise.session?.date else { return nil }
                return ChartDataPoint(date: date, value: Double(exercise.totalReps), label: exercise.name)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func loadMonthlyData() async {
        do {
            let sessions = try repository.fetchSessions()
            let grouped = Dictionary(grouping: sessions) { session -> String in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM"
                return formatter.string(from: session.date)
            }
            monthlyCountData = grouped.compactMap { key, sessions -> ChartDataPoint? in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM"
                guard let date = formatter.date(from: key) else { return nil }
                return ChartDataPoint(date: date, value: Double(sessions.count), label: key)
            }.sorted { $0.date < $1.date }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

import Foundation
import Observation

@Observable
final class CalendarViewModel {
    var currentMonth: Date = .now
    var selectedDate: Date = .now {
        didSet {
            Task { await loadSelectedDateData() }
        }
    }
    var sessionDates: Set<String> = []
    var conditionDates: Set<String> = []
    var selectedCondition: DailyCondition?
    var isLoading = false
    var errorMessage: String?

    private let repository: WorkoutRepositoryProtocol
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init(repository: WorkoutRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - 月データ読み込み

    @MainActor
    func loadMonth() async {
        isLoading = true
        defer { isLoading = false }
        do {
            // トレーニングセッション
            let sessions = try repository.fetchSessions(in: currentMonth)
            sessionDates = Set(sessions.map { dateFormatter.string(from: $0.date) })

            // コンディション（全件取得 → 当月フィルタ）
            let allConditions = try repository.fetchConditions()
            let monthStart = currentMonth.startOfMonth
            let monthEnd = currentMonth.endOfMonth
            conditionDates = Set(
                allConditions
                    .filter { $0.date >= monthStart && $0.date <= monthEnd }
                    .map { dateFormatter.string(from: $0.date) }
            )

            // 選択日のコンディションを読み込む
            await loadSelectedDateData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - 選択日データ読み込み

    @MainActor
    func loadSelectedDateData() async {
        do {
            selectedCondition = try repository.fetchCondition(for: selectedDate)
        } catch {
            selectedCondition = nil
        }
    }

    // MARK: - 月移動

    func nextMonth() {
        currentMonth = currentMonth.adding(months: 1)
    }

    func previousMonth() {
        currentMonth = currentMonth.adding(months: -1)
    }

    // MARK: - ヘルパー

    func hasWorkout(on date: Date) -> Bool {
        sessionDates.contains(dateFormatter.string(from: date))
    }

    func hasCondition(on date: Date) -> Bool {
        conditionDates.contains(dateFormatter.string(from: date))
    }

    var calendarDays: [Date?] {
        let calendar = Calendar.current
        let firstDay = currentMonth.startOfMonth
        let weekday = calendar.component(.weekday, from: firstDay)
        let leadingEmpty = (weekday - calendar.firstWeekday + 7) % 7

        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        var days: [Date?] = Array(repeating: nil, count: leadingEmpty)
        for day in range {
            days.append(calendar.date(bySetting: .day, value: day, of: firstDay))
        }
        return days
    }
}

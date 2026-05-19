import Foundation
import Observation

@Observable
final class CalendarViewModel {
    var currentMonth: Date = .now
    var selectedDate: Date = .now
    var sessionDates: Set<String> = []
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

    @MainActor
    func loadMonth() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let sessions = try repository.fetchSessions(in: currentMonth)
            sessionDates = Set(sessions.map { dateFormatter.string(from: $0.date) })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func nextMonth() {
        currentMonth = currentMonth.adding(months: 1)
    }

    func previousMonth() {
        currentMonth = currentMonth.adding(months: -1)
    }

    func hasWorkout(on date: Date) -> Bool {
        sessionDates.contains(dateFormatter.string(from: date))
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

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CalendarViewModel?
    let historyViewModel: HistoryViewModel
    @State private var selectedSession: WorkoutSession?

    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    CalendarContentView(
                        viewModel: vm,
                        historyViewModel: historyViewModel,
                        selectedSession: $selectedSession
                    )
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .task {
            let repo = WorkoutRepository(modelContext: modelContext)
            let vm = CalendarViewModel(repository: repo)
            viewModel = vm
            await vm.loadMonth()
        }
        .sheet(item: $selectedSession) { session in
            WorkoutView(session: session)
        }
    }
}

private struct CalendarContentView: View {
    @Bindable var viewModel: CalendarViewModel
    let historyViewModel: HistoryViewModel
    @Binding var selectedSession: WorkoutSession?

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                monthNavigation
                weekdayHeader
                calendarGrid
                if let session = historyViewModel.sessions(for: viewModel.selectedDate) {
                    selectedDayDetail(session: session)
                } else {
                    Text(viewModel.selectedDate.displayString + " は記録なし")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
            .padding()
        }
        .onChange(of: viewModel.currentMonth) { _, _ in
            Task { await viewModel.loadMonth() }
        }
    }

    private var monthNavigation: some View {
        HStack {
            Button {
                withAnimation { viewModel.previousMonth() }
            } label: {
                Image(systemName: "chevron.left")
                    .padding(8)
                    .background(.regularMaterial, in: Circle())
            }

            Spacer()

            Text(viewModel.currentMonth.monthString)
                .font(.title3.bold())

            Spacer()

            Button {
                withAnimation { viewModel.nextMonth() }
            } label: {
                Image(systemName: "chevron.right")
                    .padding(8)
                    .background(.regularMaterial, in: Circle())
            }
        }
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(viewModel.calendarDays.enumerated()), id: \.offset) { _, date in
                if let date {
                    CalendarDayCell(
                        date: date,
                        isSelected: date.isSameDay(as: viewModel.selectedDate),
                        isToday: date.isToday,
                        hasWorkout: viewModel.hasWorkout(on: date)
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.2)) {
                            viewModel.selectedDate = date
                        }
                    }
                } else {
                    Color.clear
                        .frame(height: 44)
                }
            }
        }
    }

    private func selectedDayDetail(session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.selectedDate.displayString)
                .font(.headline)

            WorkoutCardView(session: session)
                .onTapGesture {
                    selectedSession = session
                }
        }
    }
}

private struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasWorkout: Bool

    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(.blue)
            } else if isToday {
                Circle()
                    .stroke(.blue, lineWidth: 1.5)
            }

            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.subheadline.bold())
                    .foregroundStyle(isSelected ? .white : .primary)

                if hasWorkout {
                    Circle()
                        .fill(isSelected ? .white : .blue)
                        .frame(width: 4, height: 4)
                }
            }
        }
        .frame(height: 44)
    }
}

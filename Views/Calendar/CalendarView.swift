import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CalendarViewModel?
    let historyViewModel: HistoryViewModel
    @State private var selectedSession: WorkoutSession?
    @State private var showingCondition = false

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    CalendarContentView(
                        viewModel: vm,
                        historyViewModel: historyViewModel,
                        selectedSession: $selectedSession,
                        showingCondition: $showingCondition
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
                .onDisappear { Task { await viewModel?.loadMonth() } }
        }
        .sheet(isPresented: $showingCondition) {
            if let vm = viewModel {
                ConditionView(existingCondition: vm.selectedCondition) {
                    Task { await vm.loadMonth() }
                }
            }
        }
    }
}

// MARK: - CalendarContentView

private struct CalendarContentView: View {
    @Bindable var viewModel: CalendarViewModel
    let historyViewModel: HistoryViewModel
    @Binding var selectedSession: WorkoutSession?
    @Binding var showingCondition: Bool

    private let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                monthNavigation
                weekdayHeader
                calendarGrid
                Divider()
                selectedDaySection
            }
            .padding()
        }
        .onChange(of: viewModel.currentMonth) { _, _ in
            Task { await viewModel.loadMonth() }
        }
    }

    // MARK: 月ナビゲーション

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

    // MARK: 曜日ヘッダー

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

    // MARK: カレンダーグリッド

    private var calendarGrid: some View {
        let columns = Array(repeating: GridItem(.flexible()), count: 7)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(viewModel.calendarDays.enumerated()), id: \.offset) { _, date in
                if let date {
                    CalendarDayCell(
                        date: date,
                        isSelected: date.isSameDay(as: viewModel.selectedDate),
                        isToday: date.isToday,
                        hasWorkout: viewModel.hasWorkout(on: date),
                        hasCondition: viewModel.hasCondition(on: date)
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.2)) {
                            viewModel.selectedDate = date
                        }
                    }
                } else {
                    Color.clear.frame(height: 48)
                }
            }
        }
    }

    // MARK: 凡例

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(color: .blue, label: "トレーニング")
            legendItem(color: .green, label: "コンディション")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
        }
    }

    // MARK: 選択日の詳細

    private var selectedDaySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(viewModel.selectedDate.displayString)
                    .font(.headline)
                Spacer()
                legend
            }

            // トレーニング記録
            VStack(alignment: .leading, spacing: 6) {
                Label("トレーニング", systemImage: "dumbbell.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)

                if let session = historyViewModel.sessions(for: viewModel.selectedDate) {
                    WorkoutCardView(session: session)
                        .tappableCard { selectedSession = session }
                } else {
                    emptyRow(icon: "dumbbell", label: "トレーニングの記録なし", color: .blue)
                }
            }

            // コンディション記録
            VStack(alignment: .leading, spacing: 6) {
                Label("コンディション", systemImage: "heart.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)

                if let condition = viewModel.selectedCondition {
                    ConditionCardView(condition: condition)
                        .tappableCard { showingCondition = true }
                } else {
                    emptyRow(icon: "heart", label: "タップして記録する", color: .green)
                        .tappableCard { showingCondition = true }
                }
            }
        }
    }

    private func emptyRow(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color.opacity(0.5))
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - CalendarDayCell

private struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasWorkout: Bool
    let hasCondition: Bool

    var body: some View {
        ZStack {
            // 背景
            if isSelected {
                Circle().fill(.blue)
            } else if isToday {
                Circle().stroke(.blue, lineWidth: 1.5)
            }

            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.subheadline.bold())
                    .foregroundStyle(isSelected ? .white : .primary)

                // 記録ドット
                HStack(spacing: 2) {
                    if hasWorkout {
                        Circle()
                            .fill(isSelected ? .white : .blue)
                            .frame(width: 4, height: 4)
                    }
                    if hasCondition {
                        Circle()
                            .fill(isSelected ? .white.opacity(0.85) : .green)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 6)
            }
        }
        .frame(height: 48)
    }
}

// MARK: - tappableCard modifier

private extension View {
    /// タップエリアを全面に広げ、押下時に軽くスケールするカード用モディファイア
    func tappableCard(action: @escaping () -> Void) -> some View {
        TappableCardWrapper(content: self, action: action)
    }
}

private struct TappableCardWrapper<Content: View>: View {
    let content: Content
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        content
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in
                        isPressed = false
                        action()
                    }
            )
    }
}

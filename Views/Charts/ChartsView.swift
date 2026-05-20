import SwiftUI
import Charts
import SwiftData

// MARK: - ChartsView

struct ChartsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ChartsViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    ChartsContentView(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("グラフ")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            let repo = WorkoutRepository(modelContext: modelContext)
            let vm = ChartsViewModel(repository: repo)
            viewModel = vm
            await vm.loadInitialData()
        }
    }
}

// MARK: - ChartsContentView

private struct ChartsContentView: View {
    @Bindable var viewModel: ChartsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                summarySection
                periodPicker
                tabSelector
                chartContent
            }
            .padding(.vertical)
        }
        .refreshable { await viewModel.loadInitialData() }
        .alert("エラー", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: 今月の種目別実績カード

    private var summarySection: some View {
        MonthlyHighlightCard(
            stats: viewModel.monthlyExerciseStats,
            streak: viewModel.currentStreak
        )
        .padding(.horizontal)
    }

    // MARK: 期間ピッカー

    private var periodPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ChartPeriod.allCases) { period in
                    Button(period.rawValue) {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.selectedPeriod = period
                        }
                    }
                    .font(.subheadline.bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        viewModel.selectedPeriod == period
                            ? Color.blue
                            : Color.secondary.opacity(0.15),
                        in: Capsule()
                    )
                    .foregroundStyle(
                        viewModel.selectedPeriod == period ? .white : .primary
                    )
                    .animation(.spring(response: 0.2), value: viewModel.selectedPeriod)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: タブセレクター

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ChartTab.allCases) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.icon)
                                .font(.caption)
                            Text(tab.rawValue)
                                .font(.subheadline.bold())
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.selectedTab == tab
                                ? Color.blue
                                : Color.secondary.opacity(0.15),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .foregroundStyle(
                            viewModel.selectedTab == tab ? .white : .primary
                        )
                    }
                    .animation(.spring(response: 0.2), value: viewModel.selectedTab)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: チャート本体

    @ViewBuilder
    private var chartContent: some View {
        switch viewModel.selectedTab {
        case .weight:
            exercisePickerMenu
            WeightChartCard(data: viewModel.weightData, exerciseName: viewModel.selectedExerciseName)
        case .oneRM:
            exercisePickerMenu
            OneRMChartCard(data: viewModel.oneRMData, exerciseName: viewModel.selectedExerciseName)
        case .reps:
            exercisePickerMenu
            RepsChartCard(data: viewModel.repsData, exerciseName: viewModel.selectedExerciseName)
        case .monthly:
            MonthlyChartCard(data: viewModel.monthlyCountData)
        case .body:
            BodyCompositionCard(
                weightData: viewModel.bodyWeightData,
                fatData: viewModel.bodyFatData
            )
        case .muscle:
            MuscleGroupCard(
                data: viewModel.muscleGroupData,
                total: viewModel.totalMuscleVolume
            )
        }
    }

    // MARK: 種目ドロップダウン（Menu）

    private var exercisePickerMenu: some View {
        Menu {
            ForEach(viewModel.exerciseNames, id: \.self) { name in
                Button(name) {
                    viewModel.selectedExerciseName = name
                }
            }
        } label: {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .font(.subheadline)
                Text(viewModel.selectedExerciseName.isEmpty ? "種目を選択" : viewModel.selectedExerciseName)
                    .font(.subheadline.bold())
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(.primary)
            .padding(.horizontal)
        }
    }
}

// MARK: - MonthlyHighlightCard

private struct MonthlyHighlightCard: View {
    let stats: [MonthlyExerciseStat]
    let streak: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // ヘッダー
            HStack {
                Text("今月の実績")
                    .font(.headline)
                Spacer()
                if streak > 0 {
                    Label("\(streak)日連続", systemImage: "flame.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                }
            }

            if stats.isEmpty {
                Text("今月のトレーニング記録がありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                // テーブルヘッダー
                HStack {
                    Text("種目")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("最高重量")
                        .frame(width: 76, alignment: .trailing)
                    Text("総回数")
                        .frame(width: 60, alignment: .trailing)
                }
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.bottom, 2)

                Divider()

                // 種目行
                ForEach(stats) { stat in
                    ExerciseStatRow(stat: stat)
                    if stat.id != stats.last?.id {
                        Divider().padding(.leading, 0)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct ExerciseStatRow: View {
    let stat: MonthlyExerciseStat

    var body: some View {
        HStack(alignment: .center) {
            // 種目名 + セッション数バッジ
            HStack(spacing: 6) {
                Text(stat.name)
                    .font(.subheadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text("\(stat.sessionCount)回")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.7), in: Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 最高重量
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(stat.maxWeight > 0 ? String(format: "%.1f", stat.maxWeight) : "−")
                    .font(.subheadline.bold())
                if stat.maxWeight > 0 {
                    Text("kg")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 76, alignment: .trailing)

            // 総回数
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("\(stat.totalReps)")
                    .font(.subheadline.bold())
                Text("回")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - WeightChartCard

private struct WeightChartCard: View {
    let data: [ChartDataPoint]
    let exerciseName: String

    var body: some View {
        ChartCard(title: "\(exerciseName) 最大重量推移", yLabel: "kg") {
            if data.isEmpty {
                ChartEmptyView()
            } else {
                Chart(data) { point in
                    LineMark(
                        x: .value("日付", point.date),
                        y: .value("重量", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue)

                    AreaMark(
                        x: .value("日付", point.date),
                        y: .value("重量", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue.opacity(0.08))

                    PointMark(
                        x: .value("日付", point.date),
                        y: .value("重量", point.value)
                    )
                    .foregroundStyle(point.isPR ? .yellow : .blue)
                    .symbolSize(point.isPR ? 100 : 50)
                    .annotation(position: .top) {
                        if point.isPR {
                            PRBadge()
                        }
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
            }
        }
    }
}

// MARK: - OneRMChartCard

private struct OneRMChartCard: View {
    let data: [ChartDataPoint]
    let exerciseName: String

    var body: some View {
        ChartCard(title: "\(exerciseName) 推定1RM推移", yLabel: "kg") {
            if data.isEmpty {
                ChartEmptyView()
            } else {
                Chart(data) { point in
                    LineMark(
                        x: .value("日付", point.date),
                        y: .value("1RM", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.purple)

                    AreaMark(
                        x: .value("日付", point.date),
                        y: .value("1RM", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.purple.opacity(0.08))

                    PointMark(
                        x: .value("日付", point.date),
                        y: .value("1RM", point.value)
                    )
                    .foregroundStyle(point.isPR ? .yellow : .purple)
                    .symbolSize(point.isPR ? 100 : 50)
                    .annotation(position: .top) {
                        if point.isPR {
                            PRBadge()
                        }
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
            }
        } footer: {
            Text("エプリー式: 重量 × (1 + 回数 ÷ 30) で算出")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - RepsChartCard

private struct RepsChartCard: View {
    let data: [ChartDataPoint]
    let exerciseName: String

    var body: some View {
        ChartCard(title: "\(exerciseName) 総回数推移", yLabel: "回") {
            if data.isEmpty {
                ChartEmptyView()
            } else {
                Chart(data) { point in
                    BarMark(
                        x: .value("日付", point.date),
                        y: .value("回数", point.value)
                    )
                    .foregroundStyle(.green.gradient)
                    .cornerRadius(4)
                }
            }
        }
    }
}

// MARK: - MonthlyChartCard

private struct MonthlyChartCard: View {
    let data: [ChartDataPoint]

    var body: some View {
        ChartCard(title: "月別トレーニング回数", yLabel: "回") {
            if data.isEmpty {
                ChartEmptyView()
            } else {
                Chart(data) { point in
                    BarMark(
                        x: .value("月", point.date, unit: .month),
                        y: .value("回数", point.value)
                    )
                    .foregroundStyle(.orange.gradient)
                    .cornerRadius(4)
                    .annotation(position: .top) {
                        Text("\(Int(point.value))")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) {
                        AxisValueLabel(
                            format: .dateTime
                                .month(.abbreviated)
                                .locale(Locale(identifier: "ja_JP"))
                        )
                    }
                }
            }
        }
    }
}

// MARK: - BodyCompositionCard

private struct BodyCompositionCard: View {
    let weightData: [ChartDataPoint]
    let fatData: [ChartDataPoint]

    var body: some View {
        VStack(spacing: 12) {
            // 体重グラフ
            ChartCard(title: "体重推移", yLabel: "kg") {
                if weightData.isEmpty {
                    ChartEmptyView()
                } else {
                    Chart(weightData) { point in
                        LineMark(
                            x: .value("日付", point.date),
                            y: .value("体重", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.blue)

                        AreaMark(
                            x: .value("日付", point.date),
                            y: .value("体重", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.blue.opacity(0.08))

                        PointMark(
                            x: .value("日付", point.date),
                            y: .value("体重", point.value)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(45)
                    }
                    .chartYScale(domain: .automatic(includesZero: false))
                }
            }

            // 体脂肪率グラフ
            ChartCard(title: "体脂肪率推移", yLabel: "%") {
                if fatData.isEmpty {
                    ChartEmptyView()
                } else {
                    Chart(fatData) { point in
                        LineMark(
                            x: .value("日付", point.date),
                            y: .value("体脂肪率", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.red)

                        AreaMark(
                            x: .value("日付", point.date),
                            y: .value("体脂肪率", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.red.opacity(0.08))

                        PointMark(
                            x: .value("日付", point.date),
                            y: .value("体脂肪率", point.value)
                        )
                        .foregroundStyle(.red)
                        .symbolSize(45)
                    }
                    .chartYScale(domain: .automatic(includesZero: false))
                }
            }
        }
    }
}

// MARK: - MuscleGroupCard

private struct MuscleGroupCard: View {
    let data: [MuscleGroupVolume]
    let total: Double

    var body: some View {
        VStack(spacing: 12) {
            // ドーナツチャート
            ChartCard(title: "筋群別ボリューム内訳", yLabel: "") {
                if data.isEmpty {
                    ChartEmptyView()
                } else {
                    HStack(spacing: 20) {
                        Chart(data) { group in
                            SectorMark(
                                angle: .value("ボリューム", group.volume),
                                innerRadius: .ratio(0.55),
                                angularInset: 2
                            )
                            .foregroundStyle(group.color)
                            .cornerRadius(4)
                        }
                        .frame(height: 180)

                        // 凡例
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(data) { group in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(group.color)
                                        .frame(width: 10, height: 10)
                                    Text(group.name)
                                        .font(.caption)
                                    Spacer()
                                    Text(total > 0
                                         ? "\(Int(group.volume / total * 100))%"
                                         : "0%")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: 120)
                    }
                    .padding(.horizontal, 4)
                }
            }

            // 積み上げ棒グラフ（ボリューム量）
            ChartCard(title: "筋群別ボリューム量", yLabel: "kg") {
                if data.isEmpty {
                    ChartEmptyView()
                } else {
                    Chart(data) { group in
                        BarMark(
                            x: .value("ボリューム", group.volume),
                            y: .value("筋群", group.name)
                        )
                        .foregroundStyle(group.color)
                        .cornerRadius(4)
                        .annotation(position: .trailing) {
                            Text(String(format: "%.0f", group.volume))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .chartXAxisLabel("kg")
                    .frame(height: CGFloat(data.count * 44))
                }
            }
        }
    }
}

// MARK: - 共通部品

private struct ChartCard<Content: View, Footer: View>: View {
    let title: String
    let yLabel: String
    @ViewBuilder let content: () -> Content
    @ViewBuilder var footer: () -> Footer

    init(
        title: String,
        yLabel: String,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) {
        self.title = title
        self.yLabel = yLabel
        self.content = content
        self.footer = footer
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            content()
                .frame(minHeight: 180)
                .if(!yLabel.isEmpty) { view in
                    view.chartYAxisLabel(yLabel)
                }

            footer()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

private struct ChartEmptyView: View {
    var body: some View {
        Text("データがありません")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 120)
    }
}

private struct PRBadge: View {
    var body: some View {
        Image(systemName: "trophy.fill")
            .font(.caption)
            .foregroundStyle(.yellow)
            .shadow(color: .orange.opacity(0.4), radius: 2)
    }
}

// MARK: - View Extension

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition { transform(self) } else { self }
    }
}

#Preview {
    ChartsView()
        .modelContainer(
            for: [WorkoutSession.self, WorkoutExercise.self, ExerciseSet.self, DailyCondition.self],
            inMemory: true
        )
}

import SwiftUI
import Charts
import SwiftData

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

private struct ChartsContentView: View {
    @Bindable var viewModel: ChartsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Picker("チャート", selection: $viewModel.selectedChartTab) {
                    Text("重量").tag(0)
                    Text("回数").tag(1)
                    Text("月別").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch viewModel.selectedChartTab {
                case 0:
                    exercisePicker
                    weightChart
                case 1:
                    exercisePicker
                    repsChart
                default:
                    monthlyChart
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await viewModel.loadInitialData()
        }
        .alert("エラー", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var exercisePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.exerciseNames, id: \.self) { name in
                    Button(name) {
                        viewModel.selectedExerciseName = name
                        Task { await viewModel.loadExerciseData(name: name) }
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        viewModel.selectedExerciseName == name ? Color.blue : Color.secondary.opacity(0.15),
                        in: Capsule()
                    )
                    .foregroundStyle(viewModel.selectedExerciseName == name ? .white : .primary)
                }
            }
            .padding(.horizontal)
        }
    }

    private var weightChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(viewModel.selectedExerciseName) 最大重量推移")
                .font(.headline)
                .padding(.horizontal)

            if viewModel.weightData.isEmpty {
                chartEmptyView
            } else {
                Chart(viewModel.weightData) { point in
                    LineMark(
                        x: .value("日付", point.date),
                        y: .value("重量", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue)

                    PointMark(
                        x: .value("日付", point.date),
                        y: .value("重量", point.value)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(60)
                }
                .frame(height: 220)
                .chartYAxisLabel("kg")
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var repsChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(viewModel.selectedExerciseName) 総回数推移")
                .font(.headline)
                .padding(.horizontal)

            if viewModel.repsData.isEmpty {
                chartEmptyView
            } else {
                Chart(viewModel.repsData) { point in
                    BarMark(
                        x: .value("日付", point.date),
                        y: .value("回数", point.value)
                    )
                    .foregroundStyle(.green.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 220)
                .chartYAxisLabel("回")
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var monthlyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("月別トレーニング回数")
                .font(.headline)
                .padding(.horizontal)

            if viewModel.monthlyCountData.isEmpty {
                chartEmptyView
            } else {
                Chart(viewModel.monthlyCountData) { point in
                    BarMark(
                        x: .value("月", point.date, unit: .month),
                        y: .value("回数", point.value)
                    )
                    .foregroundStyle(.orange.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 220)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { value in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).locale(Locale(identifier: "ja_JP")))
                    }
                }
                .chartYAxisLabel("回")
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var chartEmptyView: some View {
        Text("データがありません")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 220)
    }
}

#Preview {
    ChartsView()
        .modelContainer(for: [WorkoutSession.self, WorkoutExercise.self, ExerciseSet.self], inMemory: true)
}
